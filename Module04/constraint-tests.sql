-- Module 4, Task 1: prove the constraints work
-- Run inside sqlite3 (edge.db):  .read Module04/constraint-tests.sql
PRAGMA foreign_keys = ON;        -- must be switched on again in every new connection
.headers on
.mode column

-- valid
INSERT INTO sensor VALUES (1,'cnc-01','temp_c','degC'), (2,'cnc-01','vib_rms','mm/s');
INSERT INTO reading(sensor_id, ts, value, interval_s) VALUES (1,'2026-03-01 08:00:00', 41.5, 1);

-- rejected: domain check (impossible temperature)
INSERT INTO reading(sensor_id, ts, value, interval_s) VALUES (1,'2026-03-01 08:00:01', 9000, 1);
-- rejected: STRICT type (text into a REAL)
INSERT INTO reading(sensor_id, ts, value, interval_s) VALUES (1,'2026-03-01 08:00:02', 'hot', 1);
-- rejected: referential integrity (sensor 99 does not exist)
INSERT INTO reading(sensor_id, ts, value, interval_s) VALUES (99,'2026-03-01 08:00:03', 40, 1);
-- rejected: entity integrity (duplicate sensor for the same machine+metric)
INSERT INTO sensor VALUES (3,'cnc-01','temp_c','degC');

-- what survived, and the generated column at work
SELECT * FROM sensor;
SELECT reading_id, sensor_id, ts, value, interval_s, energy_j FROM reading;
