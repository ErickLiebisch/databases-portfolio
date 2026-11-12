# Module 6 — Engine notes

## Task A — the card sort

| Card | Engine | Why | Cost I accept |
|---|---|---|---|
| 1. Three machines append a reading every 3 s, nothing is updated, a crash must not lose committed rows | **SQLite** | ACID: a committed row survives a power cut, and integrity rules run on every write | one writer at a time (plenty for 3 machines) |
| 2. Weekly averages and peaks per machine over two years | **DuckDB** (over Parquet) | columnar: it reads only the columns the report needs and aggregates millions of values at once | bad at writing single rows |
| 3. Dashboard remembers the last filter per session (get/set by key) | **Key-value** | the access pattern is exactly "open locker X" | no questions across sessions |
| 4. Vendor metadata gains a field every few months, queried by vendor and firmware | **JSON in SQLite** | new fields without a schema migration, still queryable with `json_extract` | weaker typing; I must index the paths I filter on |

**Cards 1 and 2 use the same data but different engines.** That is not a contradiction: you *write* in rows (a logbook, one line at a time) and *analyze* in columns (a spreadsheet, one column at once). Picking the same engine for both would mean accepting either slow reports or unsafe writes.

## Two ways to talk to an engine

All four engines are embedded: they run inside the program I start, there is no server.
- **Way A — terminal + `.sql` file:** `sqlite3 base.db`, then `.read file.sql` (Task 1).
- **Way B — a `.py` file that imports the engine:** `import sqlite3`, `import duckdb`, `import shelve`, run with `uv run python file.py` (Tasks 2 and 3).
