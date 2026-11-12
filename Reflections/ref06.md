# Reflection 6 — Module 6: Polyglot & Embedded Persistence

## Take-away

There is no single best engine, there is a workload: write in rows (SQLite, a logbook), analyze in columns (DuckDB over Parquet, a spreadsheet), open one locker by key (key-value), and keep changing metadata as JSON. All of them run embedded, inside my own program, with no server.

## What was good?

The measurements: Parquet answered the two-year report in 4.1 ms against 27.8 ms and was 9 times smaller. And the discovery that `shelve` is actually a SQLite file underneath. The interactive page with the power-cut and network-cut simulators made ACID and CAP much easier to see.

## What was difficult?

Visualizing "what is what": whether an engine is a command in the terminal or code in a `.py` file. The two-column picture helped (way A: `.sql` + terminal, way B: `.py` that imports the engine). I also mixed up ACID and CAP: I thought ACID needs two computers, but it is CAP that is about several copies on a network; ACID is exactly what SQLite gives on one machine. And I did not see the missing `}` in the broken JSON because I mixed up the SQL quotes with the JSON.

## Exploration and show stoppers

The same meaning written differently (`->>` instead of `json_extract`) does not use the expression index: `SCAN` instead of `SEARCH`. And I thought SQLite would check every key-value row, but a primary key is an index, so it goes straight to the key too.

## Interaction with peers and instructors

My pod: [Roberto Navia Guillén](https://github.com/RobertoNaviaGuillen/databases-portfolio), Levi, Ian and Sophia.

## How did you verify AI suggestions?

I made a prediction before every run and checked it against the output files (`json-results.txt`, `analytics-output.txt`, `kv-output.txt`). I did not accept "the key-value store is faster" in general: it was faster to read, but SQLite was about 80 times faster to store, and per operation both are instant, so the choice came from what each can do, not from speed.

## Help and extra work

Claude prepared `json-device.sql`, `analytics.py` and `kv_compare.py`, adapted the commands to Windows, built the interactive ACID/BASE/CAP page and explained the concepts with workshop examples (logbook, spreadsheet, numbered lockers, vacuum-sealed boxes, two plants with one catalog); I made the predictions, ran everything and answered the questions in my own words.
