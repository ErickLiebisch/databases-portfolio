# Module 1 — Introduction & Local-First Foundations

Session 1 of the HSBI Databases class. We set up the portfolio and the toolchain, met SQLite as an **embedded** database, loaded machine telemetry from the Wittkamp CNC story, and verified a first AI-generated query.

Course page: [Module 1 in the workbook](https://github.com/iotempire/iotempire-teaching/blob/main/full-classes/hsbi-databases-10d/modules/01-introduction-and-local-first.md) · Pod mate: [Roberto Navia Guillén's portfolio](https://github.com/RobertoNaviaGuillen/databases-portfolio) · [Syllabus](https://github.com/iotempire/iotempire-teaching/blob/main/full-classes/hsbi-databases-10d/syllabus.md)

## Learning Goals

<a id="lg1"></a>
### LG1 — `class`

Explain how this class works — the CBL/PBL philosophy, the portfolio-based **project work** assessment, and the "moving bar" of a first-time course.

**Evidence:** [Task 1 — How the class works](#task-1)

<a id="lg2"></a>
### LG2 — `portfolio`

Set up your personal GitHub portfolio from the course template, with a clean first commit and a `.gitignore` that keeps databases and secrets out of Git.

**Evidence:** [Task 1](#task-1), [.gitignore](../.gitignore), commit history

<a id="lg3"></a>
### LG3 — `uv`

Set up the entire toolchain reproducibly with **`uv`** — one fixed Python plus SQLite, DuckDB, Datasette, and more — on Windows, macOS, or Linux, and verify it.

**Evidence:** [Task 3 — Toolchain](#task-3)

<a id="lg4"></a>
### LG4 — `embedded`

Explain — with a measurement, not a slide — the difference between an **embedded** database and a **client/server** database, and why most local apps should not run a server.

**Evidence:** [Task 4 — sqlite3 shell](#task-4), [Task 6 — Telemetry](#task-6)

<a id="lg5"></a>
### LG5 — `ingest`

Load real rows into SQLite and query them from Python using **bound parameters**.

**Evidence:** [Task 6 — Telemetry](#task-6)

<a id="lg6"></a>
### LG6 — `verify-ai`

Take a first LLM-generated query, run it, and begin the habit that defines this course: **verify before you trust**.

**Evidence:** [Task 7 — AI query](#task-7)

<a id="task-1"></a>
## Task 1 — Portfolio and how the class works

**Proves:** [LG1](#lg1), [LG2](#lg2)

- Repo created from the template with "Use this template", public, instructor invited as collaborator.
- `.gitignore` keeps `.venv/`, `*.db`, `*.duckdb` and `.env` out of Git: the scripts are committed, the databases are rebuilt from them.
- How the class works (my own words): There is no written exam. I earn points by showing evidence in my GitHub portfolio and proving the learning goals in short checkpoints with my pod, so I need to work continuously. The goals are fixed, but the tasks are negotiable. If I skip a task but prove the same goal another way, that counts.

<a id="task-3"></a>
## Task 3 — Toolchain with uv

**Proves:** [LG3](#lg3)

`uv` pins Python 3.14 ([.python-version](../.python-version)) and locks every library version ([uv.lock](../uv.lock)). Check script: [uv-check.py](../uv-check.py) → output: [uv-check-output.txt](uv-check-output.txt).

Observation: the `sqlite3` command-line shell is version 3.53.4, but Python reports SQLite 3.53.1. Python carries its own copy of SQLite inside: the database engine is a library in my program, not a separate server.

<a id="task-4"></a>
## Task 4 — The sqlite3 shell

**Proves:** [LG4](#lg4)

I created a small table (`reading`) in `Module01/tour.db`, inserted three readings and asked for the peak vibration per machine with `GROUP BY`. The commands are in [tour-commands.sql](tour-commands.sql), the captured session (with `.tables`, `.schema` and a timed query) in [shell-tour.txt](shell-tour.txt), and the whole database as SQL in [tour.sql](tour.sql) (`.dump`).

Experiment: I rebuilt a brand-new database from the dump with `sqlite3 Module01/copia.db ".read Module01/tour.sql"` and got the same three rows back. The `.db` file is the dish, the `.sql` file is the recipe: that is why only the recipe goes into Git.

Most useful dot-command for me: `.dump`, because it turns the whole database into a script anyone can replay.

<a id="task-5"></a>
## Task 5 — SQL Island

WIP → [sql-island.md](sql-island.md)

<a id="task-6"></a>
## Task 6 — Load telemetry and query it from Python

**Proves:** [LG4](#lg4), [LG5](#lg5)

- [generate_telemetry.py](generate_telemetry.py) manufactures 2 days of readings for 3 CNC machines (one reading every 3 s). My check by hand: 2 days × 86,400 s = 172,800 s ÷ 3 s = 57,600 readings per machine × 3 machines = **172,800 rows**, which matches the script.
- [load_telemetry.py](load_telemetry.py) loads the CSV into `telemetry.db` with `executemany("INSERT INTO readings VALUES (?, ?, ?, ?, ?)", rows)`. The `?` are **bound parameters**: every value from the file is treated as data, never as part of the SQL command.
- Queries: [telemetry-queries.sql](telemetry-queries.sql) → results: [telemetry-results.txt](telemetry-results.txt)

| Question | Answer | Time |
|---|---|---|
| Readings per machine | 57,600 each | 0.037 s |
| Peak vibration | cnc-01 2.40 · **cnc-02 3.17** · cnc-03 2.55 mm/s | 0.045 s |
| Readings above the 2.0 mm/s alarm | 11,714 | 0.010 s |
| Alarms per machine (my own query: `WHERE` + `GROUP BY`) | **cnc-02 ≈ 11,675**, cnc-01 and cnc-03 ≈ 20 each | |

The alarms are almost all from cnc-02: the bearing wear from the story is visible in the data, measured instead of guessed.

**Embedded vs. client/server, measured:** `telemetry.db` is **10,526,720 bytes (≈ 10.5 MB)** for 172,800 rows, in a single file, with no server running, and every query above took less than 0.05 s on my laptop. A cloud server with PostgreSQL would add a monthly bill, a network and an administrator for a dataset that fits in one file read by one dashboard: the shop would pay for complexity, not for capacity.

<a id="task-7"></a>
## Task 7 — First LLM-assisted SQL profiling

**Proves:** [LG6](#lg6)

Prompt (ChatGPT): *"Here is my SQLite table: readings(ts TEXT, machine TEXT, temp_c REAL, vib_rms REAL, spindle_load REAL). Write a query that returns, for each machine, the average spindle load for readings taken overnight (after 18:00), ordered by average load descending."*

Generated SQL:

```sql
SELECT machine, AVG(spindle_load) AS avg_spindle_load
FROM readings
WHERE time(ts) > '18:00:00'
GROUP BY machine
ORDER BY avg_spindle_load DESC;
```

Run, profile and break: [ai-query.sql](ai-query.sql) → [ai-query-results.txt](ai-query-results.txt)

- **Run:** it executes without errors.
- **Profile:** `EXPLAIN QUERY PLAN` shows `SCAN readings`: SQLite reads all 172,800 rows, because `time(ts)` wraps the column.
- **Break:** the last time included is 23:59:57, so the night after midnight (00:00–06:00) is missing, and 18:00:00 itself is excluded (`>` instead of `>=`). With a night shift of 18:00–06:00 the ranking changes: cnc-02 moves from last to first.

**Verification note:** The model got the syntax, the grouping and the ordering right. It got the meaning of "overnight" wrong: it only counted 18:00–24:00 and silently dropped the hours after midnight, which changed which machine looked worst. I found it by asking the database which hours the filter really included (`MIN`/`MAX` of `time(ts)`), not by trusting the answer.

## Reflection

[Reflection 1](../Reflections/ref01.md)
