# Module 6 — Polyglot & Embedded Persistence

Session 6 of the HSBI Databases class. Three shapes of problem, three embedded engines, each one measured: flexible vendor metadata as **JSON inside SQLite**, a two-year report with **DuckDB over Parquet**, and dashboard sessions in a **key-value store** compared with SQLite. Then the theory (ACID, BASE, CAP) mapped onto what I ran.

Course page: [Module 6 in the workbook](https://github.com/iotempire/iotempire-teaching/blob/main/full-classes/hsbi-databases-10d/modules/06-polyglot-embedded-persistence.md) · Pod mate: [Roberto Navia Guillén's portfolio](https://github.com/RobertoNaviaGuillen/databases-portfolio)

Rebuild: `cmd /c "sqlite3 Module06\polyglot.db < Module06\json-device.sql > Module06\json-results.txt 2>&1"`, then `uv run python Module06/analytics.py` (needs `Module01/telemetry.db`) and `uv run python Module06/kv_compare.py`. Generated files (`polyglot.db`, `kv.db`, `readings.parquet`, `sessions`) are in `.gitignore`.

## Learning Goals

<a id="lg1"></a>
### LG1 — `json`

Store **semi-structured data (JSON)** inside SQLite and query it with `json_extract`/`json_each` and an expression index.

**Evidence:** [Task 1 — JSON metadata](#task-1)

<a id="lg2"></a>
### LG2 — `columnar`

Use **DuckDB** for analytical queries directly over **Parquet**, and explain why a columnar engine wins.

**Evidence:** [Task 2 — DuckDB analytics](#task-2)

<a id="lg3"></a>
### LG3 — `key-value`

Implement and evaluate a **key-value store** for a simple access pattern.

**Evidence:** [Task 3 — Key-value store](#task-3)

<a id="lg4"></a>
### LG4 — `acid-cap`

Explain **ACID vs. BASE** and the **CAP theorem** in terms of the systems I actually ran.

**Evidence:** [Task 4 — Name the paradigm](#task-4)

<a id="lg5"></a>
### LG5 — `engine-choice`

Choose an engine for a workload and defend the choice with a measurement.

**Evidence:** [Task A — Card sort](#task-a), [Task 2](#task-2), [Task 3](#task-3)

<a id="task-a"></a>
## Task A — Pick the engine for the workload

**Proves:** [LG5](#lg5)

Card sort with reasons and accepted costs: [engine-notes.md](engine-notes.md). In short: readings every 3 s → **SQLite**; two-year report → **DuckDB**; last filter per session → **key-value**; vendor fields that keep changing → **JSON in SQLite**. Cards 1 and 2 share the same data but not the engine: **write in rows, analyze in columns**.

<a id="task-1"></a>
## Task 1 — JSON metadata inside SQLite

**Proves:** [LG1](#lg1)

[json-device.sql](json-device.sql) → output: [json-results.txt](json-results.txt)

Each machine's metadata is a "folder" with different fields, all in one column `meta` guarded by `CHECK (json_valid(meta))`:

- **The CHECK works:** `{"vendor":"Siemens"` (missing its closing `}`) was rejected: `CHECK constraint failed: json_valid(meta)`. Only the 3 valid devices are in the table; `broken-01` is not.
- **A path works like a column:** `json_extract(meta, '$.vendor')` → Siemens, Fanuc, Arburg. With `->>`, `cnc-02` has no `calibrated` field and simply returns an empty value (NULL), no error and no migration.
- **`json_each`** turns cnc-01's object into 3 rows: vendor, firmware, calibrated.
- **Expression index:**

| Query | Plan |
|---|---|
| `WHERE json_extract(meta, '$.vendor') = 'Fanuc'` (same expression as the index) | `SEARCH device USING INDEX ix_device_vendor (<expr>=?)` |
| `WHERE meta ->> '$.vendor' = 'Fanuc'` (same meaning, written differently) | `SCAN device` |

SQLite matches how the expression is **written**, not what it means, like a warehouse index labelled "by vendor (json_extract)": ask "by vendor (->>)" and the clerk does not recognize the label. Same lesson as `date(ordered_on)` in Module 3: write the `WHERE` exactly like the index. This is the classic LLM mistake the workbook warns about.

<a id="task-2"></a>
## Task 2 — DuckDB analytics over files

**Proves:** [LG2](#lg2), [LG5](#lg5)

[analytics.py](analytics.py) → output: [analytics-output.txt](analytics-output.txt). DuckDB attaches the Module 1 `telemetry.db` (172,800 readings) read-only, copies it to `readings.parquet` and runs the weekly report (average temperature, peak vibration, count per machine) 3 times from each source:

| Source | Runs (ms) | Median | File size |
|---|---|---|---|
| **Parquet** (columnar) | 33.4 / 4.1 / 3.6 | **4.1 ms** | **1,163,448 bytes** (1.16 MB) |
| **SQLite** (rows) | 28.5 / 27.3 / 27.8 | **27.8 ms** | 10,526,720 bytes (10.5 MB) |

Same result from both (`same result: True`), with the same vibration peaks as Module 1 (cnc-02 3.168, cnc-03 2.55, cnc-01 2.398). Parquet is about **7× faster** and **9× smaller**. The first Parquet run (33.4 ms) is the cold start again, which is why I use the median.

**Why Parquet is right for the weekly report and wrong for a single new reading:** the report needs only `machine`, `temp_c` and `vib_rms`, and a columnar file lets DuckDB read just those columns, which also compress very well (the same `machine` text repeated thousands of times). But Parquet is like five vacuum-sealed boxes, one per column: adding one reading means opening every box, adding one value to each and sealing them again (in practice, writing a new file), every 3 seconds. SQLite is a logbook: one new line at the end. So the readings are **written in SQLite and analyzed in Parquet + DuckDB**, which is exactly what `analytics.py` does.

<a id="task-3"></a>
## Task 3 — A key-value store for the dashboard sessions

**Proves:** [LG3](#lg3), [LG5](#lg5)

[kv_compare.py](kv_compare.py) → output: [kv-output.txt](kv-output.txt). 50,000 sessions (`session-17 → user-17:filter=city:1`):

| Engine | Set 50,000 | Get 50,000 (one by one) |
|---|---|---|
| `shelve` (key-value) | 5.322 s | **0.262 s** |
| SQLite (`k TEXT PRIMARY KEY`) | **0.064 s** | 1.522 s |

- SQLite stores about 80× faster because `executemany` writes everything in **one transaction**, while `shelve` commits each key separately. `shelve` reads about 6× faster: less work per lookup. Both go straight to the key: the SQLite primary key is an index, so it does not scan all 50,000 rows.
- Discovery while checking the output: the file `Module06/sessions` starts with the bytes `SQLite format 3`. In Python 3.14, `shelve` stores its data **in a SQLite file** underneath (the default `dbm` backend). The "key-value store" here is a way of *using* an engine, not a separate engine.
- **My choice for dashboard sessions: SQLite.** Per operation both are instant (about 0.1 ms to store with `shelve`, 0.03 ms to read with SQLite); nobody notices the difference for one user. What decides is what each one can do.
- **What only SQLite can do:** ask a question across all sessions. One `GROUP BY` returns the sessions per filter: city:0 to city:3 with 12,500 each. These are 12,500 *sessions*, not necessarily different users, because one user can log in several times. With `shelve` I would have to open all 50,000 keys one by one and count in my own code. I would use a pure key-value store only for a cache that nobody ever asks questions about.

<a id="task-4"></a>
## Task 4 — Name the paradigm: ACID, BASE, CAP

**Proves:** [LG4](#lg4)

Interactive explainer I worked through (with a power-cut simulator and a CP/AP/embedded simulator): [ACID, BASE y CAP en la planta](https://claude.ai/artifact/MehraRtzSSKPP5esTvP2qq) (private study page).

Everything I ran in this course was **ACID**, and that was correct, because the data lives on one machine. For example, `Module04/ingest.py` wraps the whole CSV load in `with con:`, one transaction: all rows or none (**atomicity**), and the `CHECK`, `FOREIGN KEY` and `json_valid` rules rejected every invalid row (**consistency**). Eventual consistency did appear once, but only as a copy: `Module06/readings.parquet` is a snapshot of `telemetry.db`, and a reading that arrives tomorrow is not in it until I run `analytics.py` again; the nightly-rebuilt report table in Module 5 would behave the same way. The **CAP theorem** is about several copies of the data on different computers connected by a network: when the network is cut, a system must choose between refusing to answer (CP) and answering with possibly old data (AP). My SQLite file lives in one box next to the machines, with one copy and no network between copies, so there is no partition to tolerate, and it is consistent and available at the same time. That is why choosing embedded persistence is a legitimate engineering decision, not a limitation.

## Reflection

[Reflection 6](../Reflections/ref06.md)
