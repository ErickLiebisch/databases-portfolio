# Reflection 4 — Module 4: Data Integrity, Constraints & Edge Triggers

## Take-away

Without a server or an admin, the database itself must refuse garbage, like an interlock on a machine. A rule is only real if I have seen it reject something. The keyword in the error tells me the layer: `UNIQUE`/`PRIMARY KEY`/`NOT NULL` = entity, `FOREIGN KEY` = referential, `CHECK`/type = semantic.

## What was good?

Watching the same three junk rows go into a table without rules and then be rejected one by one, each by a different rule. Running `ingest.py` twice and seeing 10 rows both times (idempotent). And the triggers writing the alarm and the audit row (2.7 → 1.4) by themselves.

## What was difficult?

Putting the errors into the three layers: at first I mixed up entity, referential and semantic, until I used the keyword in the error as a guide. Also, I thought `UPSERT` would change the CSV file; the file is only the delivery, the table is what changes. And I thought `mode=ro` was how PostgreSQL controls access, but there it is `GRANT` on the server.

## Exploration and show stoppers

`CHECK` lets `NULL` pass: with no value the answer is "unknown", not "false", so a `CHECK` needs `NOT NULL` next to it. A value like 4,999 °C is inside the range but still wrong. And `PRAGMA foreign_keys` is off by default: without it, a reading for a sensor that does not exist would be stored silently. On Windows, `.output` did not save the error messages (they go to stderr), so I used `cmd /c "... > file 2>&1"`.

## Interaction with peers and instructors

My pod: [Roberto Navia Guillén](https://github.com/RobertoNaviaGuillen/databases-portfolio), Levi, Ian and Sophia.

## How did you verify AI suggestions?

Before every run I made a prediction (how many rows get in, what `energy_j` is, how many rows after two ingest runs, whether a trigger makes inserts slower) and then checked it against the output files. I did not trust "triggers are expensive": I measured 10,000 inserts, 3 runs each, median 6.0 ms without and 11.8 ms with the trigger.

## Help and extra work

Claude prepared the SQL scripts, `ingest.py` and `trigger_cost.py`, adapted the Linux commands to Windows (`attrib` instead of `chmod`) and explained the concepts with workshop examples (interlock, presence sensor, limit switch, entry log); I ran everything, made predictions first and answered the questions in my own words.
