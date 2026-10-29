-- Module 4, Task 2: idempotent ingestion with UPSERT
-- Run inside sqlite3 (edge.db):  .read Module04/upsert.sql
PRAGMA foreign_keys = ON;
.headers on
.mode column

-- Make (sensor_id, ts) a genuine natural key so replays collide:
CREATE UNIQUE INDEX IF NOT EXISTS ux_reading_sensor_ts ON reading(sensor_id, ts);

-- Before: the reading of sensor 1 at 08:00:00
SELECT sensor_id, ts, value FROM reading WHERE sensor_id = 1;

-- Replay-safe ingest: insert, or update if the exact reading already exists.
INSERT INTO reading(sensor_id, ts, value, interval_s)
VALUES (1,'2026-03-01 08:00:00', 41.7, 1)          -- same key, corrected value (sensor retried)
ON CONFLICT(sensor_id, ts) DO UPDATE SET value = excluded.value;

-- After: still exactly one row for that key, now with the corrected value
SELECT sensor_id, ts, value FROM reading WHERE sensor_id = 1;
