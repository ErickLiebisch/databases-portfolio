-- Module 1, Task 7: run, profile and break an LLM-generated query.
-- Run from the repo root:  sqlite3 Module01/telemetry.db ".read Module01/ai-query.sql"
.output Module01/ai-query-results.txt
.echo on
.mode column
.headers on

-- 1. RUN the LLM's query exactly as it was generated
.timer on
SELECT
    machine,
    AVG(spindle_load) AS avg_spindle_load
FROM readings
WHERE time(ts) > '18:00:00'
GROUP BY machine
ORDER BY avg_spindle_load DESC;
.timer off

-- 2. PROFILE it: does SQLite read the whole table?
EXPLAIN QUERY PLAN
SELECT machine, AVG(spindle_load) AS avg_spindle_load
FROM readings
WHERE time(ts) > '18:00:00'
GROUP BY machine
ORDER BY avg_spindle_load DESC;

-- 3. BREAK it: which hours does "after 18:00" really include?
SELECT MIN(time(ts)) AS first_time_included, MAX(time(ts)) AS last_time_included
FROM readings WHERE time(ts) > '18:00:00';

-- 4. My corrected version: night shift = 18:00 to 06:00 (crosses midnight)
SELECT
    machine,
    AVG(spindle_load) AS avg_spindle_load
FROM readings
WHERE time(ts) >= '18:00:00' OR time(ts) < '06:00:00'
GROUP BY machine
ORDER BY avg_spindle_load DESC;
.output stdout
