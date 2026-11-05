# Module 5 — Normalization vs. Denormalization Benchmarking Studio

Session 5 of the HSBI Databases class. I found the functional dependencies and the three anomalies of a flat maintenance table, normalized 200,000 rows to 3NF without losing a row, and then **measured** the denormalized "reporting table" shortcut against it: dashboard time, write cost and storage.

Course page: [Module 5 in the workbook](https://github.com/iotempire/iotempire-teaching/blob/main/full-classes/hsbi-databases-10d/modules/05-normalization-vs-denormalization.md) · Pod mate: [Roberto Navia Guillén's portfolio](https://github.com/RobertoNaviaGuillen/databases-portfolio)

Rebuild the database: `sqlite3 Module05/normalize.db ".read Module05/setup.sql"` ([setup.sql](setup.sql)) → 200,000 rows, then [normalize.sql](normalize.sql) and [benchmark.sql](benchmark.sql). On Windows I ran them with `cmd /c "sqlite3 Module05\normalize.db < Module05\<script>.sql > Module05\<results>.txt 2>&1"` so that errors are saved too.

## Learning Goals

<a id="lg1"></a>
### LG1 — `fd`

Derive **functional dependencies** from a relation and identify candidate keys.

**Evidence:** [normalization-notes.md](normalization-notes.md) (FD list, domain vs. only observed, key `(job_id, part_no)`)

<a id="lg2"></a>
### LG2 — `normal-forms`

Normalize a relation to **1NF, 2NF and 3NF**, explaining the anomaly each step removes.

**Evidence:** [Task 1 — Dependencies and anomalies](#task-1), [Task 2 — 3NF](#task-2)

<a id="lg3"></a>
### LG3 — `denormalize`

**Denormalize deliberately** for a hot read path, and predict what it costs on writes and storage.

**Evidence:** [Task 3 — Benchmark](#task-3)

<a id="lg4"></a>
### LG4 — `measure`

**Measure** the trade-off: query latency, write cost and database size, before and after.

**Evidence:** [Task 3 — Benchmark](#task-3)

<a id="lg5"></a>
### LG5 — `decide`

Decide, and defend, where a schema should sit on the normalization spectrum for a given workload.

**Evidence:** [Task 4 — Recommendation](#task-4)

<a id="task-1"></a>
## Task 1 — Name the dependencies and the anomalies

**Proves:** [LG1](#lg1), [LG2](#lg2)

Details: [normalization-notes.md](normalization-notes.md)

- **Dependencies (domain facts):** `machine_id → site`, `part_no → part_price`, `job_id → machine_id`, `job_id → technician`, `job_id → done_on`. Key of a row: `(job_id, part_no)`.
- **Only observed, not a rule:** in the five-row extract `technician → machine_id` seems to hold (tech-0 always on cnc-01), but any technician can repair any machine. A pattern in a few rows is not a dependency; only the domain (or a company decision) makes it one.
- **Update anomaly:** "cnc-01 is in Gütersloh" is stored **4,000 times** in the 200k table. Change only some of the copies and cnc-01 is in two cities at once.
- **Insert anomaly:** a new part that no job has used cannot be stored without inventing a job.
- **Delete anomaly:** deleting job 1 also deletes part P-0002 and its price from the system.

| Form | Rule | What it removed here |
|---|---|---|
| 1NF | atomic values, no lists | the `parts_used` comma list (Module 2) |
| 2NF | no dependency on half of the key `(job_id, part_no)` | `part_price` → table `part` |
| 3NF | no chain non-key → non-key | `job_id → machine_id → site` → `site` in table `machine` |

<a id="task-2"></a>
## Task 2 — Normalize to 3NF

**Proves:** [LG2](#lg2)

[normalize.sql](normalize.sql) → output: [normalize-results.txt](normalize-results.txt)

The key idea: in each new table every thing appears **once**, like a paper work order where the header (machine, technician, date) is written once and the list of parts goes underneath.

| Table | Rows | One row per |
|---|---|---|
| `machine` | 50 | machine |
| `part` | 10 | part |
| `job` | 20,000 | work order (header) |
| `job_part` | 200,000 | part used in a job |

**Integrity check:** `flat_rows = 200,000`, `normalized_rows = 200,000`. Each flat row was "one part used in one job", so the counts must match: fewer would mean lost data, more would mean invented data.

Surprise from reading the output instead of assuming: `part` has **10** rows, not 40. The setup computes `(k % 40) + 1` but `k` only runs from 1 to 10, so only 10 different parts exist.

<a id="task-3"></a>
## Task 3 — The benchmark: the shortcut the operations lead likes

**Proves:** [LG3](#lg3), [LG4](#lg4)

[benchmark.sql](benchmark.sql) → output: [benchmark-results.txt](benchmark-results.txt). `report_jobpart` copies site, technician and price onto every one of the 200,000 rows. Dashboard query: cost per machine and technician since 2026-03-01 (350 result rows in both designs), 3 runs each with `.timer on`.

| Design | Dashboard query (ms) | Insert 1 row (ms) | Move cnc-01 to Bielefeld | Storage (KB) | Redundancy? |
|---|---|---|---|---|---|
| Normalized (3NF) | 47.2 / 45.8 / 45.2 → **45.8** | 1.4 (`job_part`) | **1 row** (0.09 ms) | **7,976** | none |
| Denormalized (`report_jobpart`) | 55.0 / 54.7 / 55.0 → **55.0** | 1.6 | **4,000 rows** (1.9 ms) | **13,760** | site, technician, price on every row |

(For comparison, the original `flat_jobpart` uses 14,532 KB.)

**Plans:**
```
A) normalized                                              B) denormalized
|--SCAN jp                                                 |--SCAN report_jobpart USING INDEX ix_report_machine
|--SEARCH j USING INTEGER PRIMARY KEY (rowid=?)            `--USE TEMP B-TREE FOR GROUP BY
|--SEARCH m USING INDEX sqlite_autoindex_machine_1 (...)
|--SEARCH p USING INDEX sqlite_autoindex_part_1 (...)
`--USE TEMP B-TREE FOR GROUP BY
```

**The surprise: the shortcut was slower.** I predicted the denormalized table would read faster. It did not: 55.0 ms against 45.8 ms. The normalized plan scans `job_part`, a **thin** table (two short columns), and finds each machine, job and part directly by its key. The denormalized plan walks the machine index in order and **jumps** into the fat table 200,000 times, like reading a 600-page manual by jumping through its index instead of reading straight through. On top of that it needs almost twice the storage, and one fact change touches 4,000 rows.

"Denormalized = faster" is an assumption, not a fact. At this size it was false. The 40-second dashboard in the story would have far more data, and there the result could flip, which is exactly why it has to be measured, not guessed. (Single-row inserts are about 1.5 ms in both designs: at that level the difference is noise.)

<a id="task-4"></a>
## Task 4 — Decide and defend

**Proves:** [LG5](#lg5)

**To the operations lead (Yasmin Kaya):** With today's data the dashboard should read the **normalized 3NF tables**, not a reporting copy. My measurements give the normalized design the win on all three counts: the dashboard query takes 45.8 ms against 55.0 ms, it needs 7,976 KB against 13,760 KB, and moving cnc-01 to another site changes 1 row instead of 4,000, so the data can never contradict itself. The transactional tables (`machine`, `part`, `job`, `job_part`) must stay in **3NF** in any case: they are the single source of truth. If the plant grows (for example 100 times more data) and a new benchmark shows that the dashboard becomes slow, a reporting table is acceptable **only as a derived copy** that nobody edits by hand. To keep it from going stale I would use a trigger as in Module 4, an automatic relay on the source table:

```sql
CREATE TRIGGER trg_machine_site_to_report
AFTER UPDATE OF site ON machine
FOR EACH ROW
BEGIN
    UPDATE report_jobpart SET site = NEW.site WHERE machine_id = NEW.machine_id;
END;
```

The change is made once, in `machine`, and the trigger copies it to the 4,000 report rows. Similar triggers would be needed for technician and price changes. The simpler alternative is to rebuild the report table on a schedule (for example every night), accepting that it can be up to one day old. Every one of these choices adds write cost, so the decision has to be measured again when the data grows.

## Reflection

[Reflection 5](../Reflections/ref05.md)
