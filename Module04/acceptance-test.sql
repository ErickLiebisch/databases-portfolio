-- Module 4, Task A: what does a table WITHOUT rules accept?
-- Run inside sqlite3:  .read Module04/acceptance-test.sql
.headers on
.mode column

-- 1. A table with no rules at all
DROP TABLE IF EXISTS t;
CREATE TABLE t(sensor_id INTEGER, metric TEXT, value REAL);
INSERT INTO t VALUES (1,'temp_c',9000), (1,'temp_c','hot'), (2,'bogus',-500);
SELECT * FROM t;

-- 2. The same table with the rules we would actually ship
DROP TABLE IF EXISTS t_safe;
CREATE TABLE t_safe(
    sensor_id INTEGER NOT NULL,
    metric    TEXT    NOT NULL CHECK (metric IN ('temp_c','vib_rms','spindle_load')),
    value     REAL    CHECK (value BETWEEN -273.15 AND 5000),
    PRIMARY KEY (sensor_id, metric)
) STRICT;

-- 3. The same three junk rows, one at a time
INSERT INTO t_safe VALUES (1,'temp_c',9000);
INSERT INTO t_safe VALUES (1,'temp_c','hot');
INSERT INTO t_safe VALUES (2,'bogus',-500);

-- 4. Follow-ups: CHECK with NULL, and a plausible but wrong value
INSERT INTO t_safe VALUES (3,'temp_c',NULL);
INSERT INTO t_safe VALUES (4,'temp_c',4999);
SELECT * FROM t_safe;
