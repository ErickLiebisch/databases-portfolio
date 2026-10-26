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

WIP

<a id="task-5"></a>
## Task 5 — SQL Island

WIP → [sql-island.md](sql-island.md)

<a id="task-6"></a>
## Task 6 — Load telemetry and query it from Python

**Proves:** [LG4](#lg4), [LG5](#lg5)

WIP

<a id="task-7"></a>
## Task 7 — First LLM-assisted SQL profiling

**Proves:** [LG6](#lg6)

WIP

## Reflection

[Reflection 1](../Reflections/ref01.md)
