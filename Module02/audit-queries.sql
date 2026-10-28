-- Module 2: prove the cardinalities and the integrity defects with queries.
-- Run from the repo root:  sqlite3 Module02/legacy.db ".read Module02/audit-queries.sql"
.output Module02/audit-results.txt
.echo on
.mode column
.headers on
.timer on

-- Cardinality: how many parts does each job use? (the m:n hiding in a text column)
SELECT job_id, parts_used,
       LENGTH(parts_used) - LENGTH(REPLACE(parts_used, ',', '')) + 1 AS n_parts
FROM maint_job;

-- Defect 1: orphan maintenance jobs (machine_name not in machine)
SELECT m.job_id, m.machine_name
FROM maint_job m
LEFT JOIN machine x ON m.machine_name = x.machine_name
WHERE x.machine_name IS NULL;

-- Defect 2: duplicate natural keys in part
SELECT part_no, COUNT(*) AS copies
FROM part GROUP BY part_no HAVING COUNT(*) > 1;

-- Defect 3: unit_price stored as text, so a "price below 15" comparison is alphabetical
SELECT part_no, unit_price FROM part WHERE unit_price < '15';

-- Defect 4: installed dates that are not dates
SELECT machine_name, installed FROM machine
WHERE installed NOT GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]';

-- Defect 5: the m:n list only "joins" when it holds exactly one part
SELECT j.job_id, p.description
FROM maint_job j
JOIN part p ON p.part_no = j.parts_used;
.output stdout
