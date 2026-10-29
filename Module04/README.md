# Module 4 — Data Integrity, Constraints & Edge Triggers

Session 4 of the HSBI Databases class. On an edge database (a SQLite file next to the machines, no server, no admin) I made the database itself refuse bad data: constraints, a generated column, replay-safe ingestion with `UPSERT`, triggers for alarms and audit, and access control without `GRANT`.

Course page: [Module 4 in the workbook](https://github.com/iotempire/iotempire-teaching/blob/main/full-classes/hsbi-databases-10d/modules/04-integrity-constraints-and-triggers.md) · Pod mate: [Roberto Navia Guillén's portfolio](https://github.com/RobertoNaviaGuillen/databases-portfolio)

Rebuild the database: `sqlite3 Module04/edge.db ".read Module04/setup.sql"` ([setup.sql](setup.sql)), then run the tasks below in order.

> Windows note: the workbook uses a shell heredoc and `chmod`. In PowerShell I ran the scripts with `.read` / `cmd /c "sqlite3 … < file.sql > results.txt 2>&1"` (so that error messages, which go to *stderr*, are saved too) and used `attrib +R` instead of `chmod 444`.

## Learning Goals

<a id="lg1"></a>
### LG1 — `constraints`

Create tables with `NOT NULL`, `UNIQUE`, `CHECK`, `PRIMARY KEY`, `FOREIGN KEY` and `STRICT` typing.

**Evidence:** [Task A — Acceptance test](#task-a), [Task 1 — Prove the constraints work](#task-1)

<a id="lg2"></a>
### LG2 — `generated`

Use a **generated column** to derive a value in the engine instead of in application code.

**Evidence:** [Task 1](#task-1) (`energy_j = value × interval_s` = 41.5 for the valid row, written by nobody)

<a id="lg3"></a>
### LG3 — `triggers`

Write **triggers** that enforce domain rules and keep audit tables automatically.

**Evidence:** [Task 3 — Triggers](#task-3)

<a id="lg4"></a>
### LG4 — `dml-upsert`

Use **DML** correctly, including `UPSERT` (`ON CONFLICT`) for idempotent ingestion.

**Evidence:** [Task 2 — UPSERT](#task-2)

<a id="lg5"></a>
### LG5 — `dcl`

Reason about **access control (DCL)** when there is no server and no users.

**Evidence:** [Task 4 — Access control](#task-4)

<a id="task-a"></a>
## Task A — What does a table without rules accept?

**Proves:** [LG1](#lg1)

[acceptance-test.sql](acceptance-test.sql) → output: [acceptance-results.txt](acceptance-results.txt)

The unconstrained table `t` accepted all three junk rows silently: `9000` °C, the text `'hot'` as a temperature, and the made-up metric `'bogus'` with `-500` °C. The same rows against `t_safe` (`STRICT`, `PRIMARY KEY`, two `CHECK`s), one at a time:

| Row | Rejected by | Layer | Exact error |
|---|---|---|---|
| `(1,'temp_c',9000)` | `CHECK (value BETWEEN -273.15 AND 5000)` | semantic | `CHECK constraint failed: value BETWEEN -273.15 AND 5000` |
| `(1,'temp_c','hot')` | `STRICT` | semantic (type) | `cannot store TEXT value in REAL column t_safe.value` |
| `(2,'bogus',-500)` | `CHECK (metric IN (...))` | semantic | `CHECK constraint failed: metric IN ('temp_c','vib_rms','spindle_load')` |

**Follow-ups:**
- **`CHECK` with `NULL`:** `(3,'temp_c',NULL)` was accepted. A `CHECK` only rejects a definite *false*; with no value the answer is *unknown*, and unknown passes. Like a quality inspector with a caliper: no part in the tray, nothing to reject. → **`CHECK` needs `NOT NULL` next to it** (the presence sensor before the inspector).
- **Plausible but wrong:** `(4,'temp_c',4999)` was accepted. It is inside the range, but no CNC machine reaches 4,999 °C. A range only stops the physically impossible, not the unlikely.

<a id="task-1"></a>
## Task 1 — Prove the constraints work

**Proves:** [LG1](#lg1), [LG2](#lg2)

[setup.sql](setup.sql) builds `sensor` and `reading` (both `STRICT`); [constraint-tests.sql](constraint-tests.sql) → output: [constraint-results.txt](constraint-results.txt)

| Statement | Layer | Exact error |
|---|---|---|
| reading with value `9000` | semantic | `CHECK constraint failed: value >= -273.15 AND value <= 5000` |
| reading with value `'hot'` | semantic (type) | `cannot store TEXT value in REAL column reading.value` |
| reading for sensor `99` (does not exist) | referential | `FOREIGN KEY constraint failed` |
| second `temp_c` sensor on `cnc-01` | entity | `UNIQUE constraint failed: sensor.machine_id, sensor.metric` |

Only the valid reading survived, and its generated column shows `energy_j = 41.5` (41.5 × 1 s).

How I tell the layers apart: the keyword in the error. `UNIQUE` / `PRIMARY KEY` / `NOT NULL` → **entity** (is every row identifiable?), `FOREIGN KEY` → **referential** (does it point at something that exists?), `CHECK` / type → **semantic** (does the value make sense?).

**`PRAGMA foreign_keys = ON` is per connection and OFF by default.** Without it, the sensor-99 reading would have been stored silently as an orphan. That is why every script and `ingest.py` switch it on first.

<a id="task-2"></a>
## Task 2 — Idempotent edge ingestion with UPSERT

**Proves:** [LG4](#lg4)

After a network outage the gateway does not know what already arrived, so it resends everything. `UPSERT` = *insert the reading if (sensor, time) is new, otherwise only update its value*.

- [upsert.sql](upsert.sql) → [upsert-results.txt](upsert-results.txt): the same key `(1, '2026-03-01 08:00:00')` sent again with a corrected value: still **one** row, value 41.5 → 41.7.
- [ingest.py](ingest.py) loads [replay.csv](replay.csv) (10 readings, one of them already stored) with `executemany` and the same `UPSERT`, run **twice** → [ingest-output.txt](ingest-output.txt):

| Run | Rows in file | Readings before | Readings after |
|---|---|---|---|
| 1st | 10 | 1 | **10** (9 new + 1 updated) |
| 2nd (same file) | 10 | 10 | **10** (nothing duplicated) |

**Idempotent** = running it once or ten times gives the same result, like pressing the elevator button several times. The CSV never changes; only the table does.

<a id="task-3"></a>
## Task 3 — Triggers for alarms and audit

**Proves:** [LG3](#lg3)

[triggers.sql](triggers.sql) → output: [trigger-results.txt](trigger-results.txt)

A trigger is an automatic relay: *when X happens in the table, do Y*, like a limit switch that stops the motor even if the operator looks away.

- `trg_vib_alarm` (`AFTER INSERT`): a vibration reading of **2.7** mm/s on sensor 2 wrote `alarm` row 1, reason `vibration over 2.0 mm/s`.
- `trg_reading_audit` (`AFTER UPDATE OF value`): correcting that reading to **1.4** wrote `audit` row 1: `old_value 2.7 → new_value 1.4`, with a timestamp.
- The 10 readings from `replay.csv` raised no alarm: they were loaded *before* the triggers existed (and all vibration values were ≤ 1.4).

**Trigger cost** ([trigger_cost.py](trigger_cost.py) → [trigger-cost.txt](trigger-cost.txt)): 10,000 vibration readings inserted into a throwaway in-memory copy of the schema, every 10th one over the threshold, median of 3 runs:

| | Runs (ms) | Median | Alarms |
|---|---|---|---|
| Without trigger | 6.0 / 6.0 / 6.0 | **6.0 ms** | 0 |
| With `trg_vib_alarm` | 11.8 / 11.8 / 11.7 | **11.8 ms** | 1,000 |

The trigger almost **doubles** the insert time, because it checks every row and runs a lookup on `sensor`. In absolute terms it is ~1.2 µs per row: for a gateway with a few readings per second that is nothing, and the alarm can never be forgotten. On a massive ingest path it is a design decision, not a free lunch.

<a id="task-4"></a>
## Task 4 — Access control without a server

**Proves:** [LG5](#lg5)

SQLite has no users and no `GRANT`, so I used three locks instead:

1. **A view** ([access-view.sql](access-view.sql)): `machine_health` shows report readers only the peak and count per machine and metric, not the raw table.
2. **A read-only connection**: `sqlite3 file:Module04/edge.db?mode=ro` with [ro-test.sql](ro-test.sql) → [access-results.txt](access-results.txt): the view works, `DELETE FROM reading` fails with `attempt to write a readonly database`, and there are still **11 readings before and after**. (The view shows a vibration peak of 1.4, not 2.7: the audited correction is in effect.)
3. **A read-only file**: `attrib +R Module04\edge.db` (the Windows equivalent of `chmod 444`), then the same [ro-test.sql](ro-test.sql) through a **normal** connection, without `mode=ro` → [file-lock-results.txt](file-lock-results.txt): same `attempt to write a readonly database`, 11 → 11. The operating system blocks the write on its own. `attrib -R` restored write access afterwards.

**Compared with PostgreSQL:** on a server there is a guard at the door: the server knows every user, and the administrator gives each one an access card per area, for example `CREATE ROLE report LOGIN; GRANT SELECT ON reading TO report;`. Even if the report user tries a `DELETE`, the server refuses it, so the decision is not in the hands of whoever connects. In SQLite, `mode=ro` is a pass you give *yourself* when you open the file; someone who opens it without `mode=ro` can write, so only the file lock is really enforced. That is acceptable on an edge gateway, where one program writes and a few trusted readers read, and a small attack surface is an advantage. It does not work for a multi-tenant web app: a file lock is "everyone or no one", but each customer must see their own orders and not the others'. Locking everyone out makes the app useless, and opening it for everyone destroys privacy, so you need per-user rights that only a server can enforce.

## Reflection

[Reflection 4](../Reflections/ref04.md)
