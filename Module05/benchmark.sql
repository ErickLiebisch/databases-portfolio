-- Module 5, Task 3: normalized vs denormalized, measured
-- Run inside sqlite3 (normalize.db):  .read Module05/benchmark.sql
.headers on
.mode column

-- The reporting table the operations lead asked for: everything on one row
DROP TABLE IF EXISTS report_jobpart;
CREATE TABLE report_jobpart AS
SELECT j.job_id, m.machine_id, m.site, j.technician, jp.part_no,
       p.part_price, j.done_on
FROM job j
JOIN machine m  ON m.machine_id = j.machine_id
JOIN job_part jp ON jp.job_id = j.job_id
JOIN part p     ON p.part_no = jp.part_no;
CREATE INDEX ix_report_machine ON report_jobpart(machine_id);

-- 1. PLANS
.print '=== A) normalized: plan'
EXPLAIN QUERY PLAN
SELECT m.machine_id, m.site, j.technician, SUM(p.part_price) AS cost
FROM job j
JOIN machine m   ON m.machine_id = j.machine_id
JOIN job_part jp ON jp.job_id = j.job_id
JOIN part p      ON p.part_no = jp.part_no
WHERE j.done_on >= date('2026-03-01')
GROUP BY m.machine_id, j.technician;

.print '=== B) denormalized: plan'
EXPLAIN QUERY PLAN
SELECT machine_id, site, technician, SUM(part_price) AS cost
FROM report_jobpart
WHERE done_on >= date('2026-03-01')
GROUP BY machine_id, technician;

-- 2. TIMINGS: 3 runs each; COUNT(*) around the query keeps the output short
.timer on
.print '=== A) normalized: 3 runs'
SELECT COUNT(*) AS result_rows FROM (
SELECT m.machine_id, m.site, j.technician, SUM(p.part_price) AS cost
FROM job j
JOIN machine m   ON m.machine_id = j.machine_id
JOIN job_part jp ON jp.job_id = j.job_id
JOIN part p      ON p.part_no = jp.part_no
WHERE j.done_on >= date('2026-03-01')
GROUP BY m.machine_id, j.technician);
SELECT COUNT(*) AS result_rows FROM (
SELECT m.machine_id, m.site, j.technician, SUM(p.part_price) AS cost
FROM job j
JOIN machine m   ON m.machine_id = j.machine_id
JOIN job_part jp ON jp.job_id = j.job_id
JOIN part p      ON p.part_no = jp.part_no
WHERE j.done_on >= date('2026-03-01')
GROUP BY m.machine_id, j.technician);
SELECT COUNT(*) AS result_rows FROM (
SELECT m.machine_id, m.site, j.technician, SUM(p.part_price) AS cost
FROM job j
JOIN machine m   ON m.machine_id = j.machine_id
JOIN job_part jp ON jp.job_id = j.job_id
JOIN part p      ON p.part_no = jp.part_no
WHERE j.done_on >= date('2026-03-01')
GROUP BY m.machine_id, j.technician);

.print '=== B) denormalized: 3 runs'
SELECT COUNT(*) AS result_rows FROM (
SELECT machine_id, site, technician, SUM(part_price) AS cost
FROM report_jobpart
WHERE done_on >= date('2026-03-01')
GROUP BY machine_id, technician);
SELECT COUNT(*) AS result_rows FROM (
SELECT machine_id, site, technician, SUM(part_price) AS cost
FROM report_jobpart
WHERE done_on >= date('2026-03-01')
GROUP BY machine_id, technician);
SELECT COUNT(*) AS result_rows FROM (
SELECT machine_id, site, technician, SUM(part_price) AS cost
FROM report_jobpart
WHERE done_on >= date('2026-03-01')
GROUP BY machine_id, technician);

-- 3. WRITE COST: insert one new part usage into both designs
.print '=== write: normalized (1 short row, ids only)'
INSERT INTO part VALUES ('P-0399', 9.99);
INSERT INTO job_part VALUES (1, 'P-0399');
.print '=== write: denormalized (1 long row, every fact copied)'
INSERT INTO report_jobpart VALUES (1,'cnc-02','Gütersloh','tech-1','P-0399',9.99,'2026-01-02');
.print '=== update: move cnc-01 to Bielefeld (normalized: 1 row)'
.changes on
UPDATE machine SET site = 'Bielefeld' WHERE machine_id = 'cnc-01';
.print '=== update: move cnc-01 to Bielefeld (denormalized: every copy)'
UPDATE report_jobpart SET site = 'Bielefeld' WHERE machine_id = 'cnc-01';
.changes off
.timer off

-- 4. STORAGE COST (dbstat: bytes of pages used by each table and its indexes)
.print '=== storage'
SELECT 'normalized (machine + part + job + job_part)' AS design,
       (SELECT SUM(pgsize) FROM dbstat
        WHERE name IN (SELECT name FROM sqlite_schema
                       WHERE tbl_name IN ('job','job_part','part','machine'))) / 1024 AS kb;
SELECT 'denormalized (report_jobpart)' AS design,
       (SELECT SUM(pgsize) FROM dbstat WHERE name IN (SELECT name FROM sqlite_schema
                                               WHERE tbl_name = 'report_jobpart')) / 1024 AS kb;
SELECT 'flat original (flat_jobpart)' AS design,
       (SELECT SUM(pgsize) FROM dbstat WHERE name IN (SELECT name FROM sqlite_schema
                                               WHERE tbl_name = 'flat_jobpart')) / 1024 AS kb;
