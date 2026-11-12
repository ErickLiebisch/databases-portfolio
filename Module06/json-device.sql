-- Module 6, Task 1: JSON metadata inside SQLite
-- Run from PowerShell:
--   cmd /c "sqlite3 Module06\polyglot.db < Module06\json-device.sql > Module06\json-results.txt 2>&1"
.headers on
.mode column

DROP TABLE IF EXISTS device;
CREATE TABLE device(
    device_id INTEGER PRIMARY KEY,
    name      TEXT NOT NULL,
    meta      TEXT NOT NULL CHECK (json_valid(meta))   -- enforce that it *is* JSON
) STRICT;

INSERT INTO device(name, meta) VALUES
  ('cnc-01', '{"vendor":"Siemens","firmware":"4.2","calibrated":"2026-01-10"}'),
  ('cnc-02', '{"vendor":"Fanuc","firmware":"3.9"}'),
  ('molder-07', '{"vendor":"Arburg","firmware":"8.1","calibrated":"2025-11-02","nozzle_mm":2.5}');

-- The CHECK in action: broken JSON is rejected
INSERT INTO device(name, meta) VALUES ('broken-01', '{"vendor":"Siemens"');

.print '=== 1. Query a path like a column'
SELECT name, json_extract(meta, '$.vendor') AS vendor FROM device;

.print '=== 2. The ->> operator is shorthand'
SELECT name, meta ->> '$.firmware' AS fw, meta ->> '$.calibrated' AS calibrated FROM device;

.print '=== 3. Expand one object into rows'
SELECT d.name, j.key, j.value FROM device d, json_each(d.meta) j WHERE d.name = 'cnc-01';

.print '=== 4. Expression index: same expression in WHERE -> SEARCH'
CREATE INDEX ix_device_vendor ON device(json_extract(meta, '$.vendor'));
EXPLAIN QUERY PLAN SELECT name FROM device WHERE json_extract(meta, '$.vendor') = 'Fanuc';

.print '=== 5. Different expression (->> instead of json_extract) -> ?'
EXPLAIN QUERY PLAN SELECT name FROM device WHERE meta ->> '$.vendor' = 'Fanuc';
