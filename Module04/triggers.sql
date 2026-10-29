-- Module 4, Task 3: triggers for alarms and audit
-- Run inside sqlite3 (edge.db):  .read Module04/triggers.sql
PRAGMA foreign_keys = ON;
.headers on
.mode column

DROP TRIGGER IF EXISTS trg_vib_alarm;
DROP TRIGGER IF EXISTS trg_reading_audit;
DROP TABLE IF EXISTS alarm;
DROP TABLE IF EXISTS audit;

CREATE TABLE alarm(
    alarm_id  INTEGER PRIMARY KEY,
    sensor_id INTEGER NOT NULL REFERENCES sensor(sensor_id),
    ts        TEXT NOT NULL,
    value     REAL NOT NULL,
    reason    TEXT NOT NULL
) STRICT;

CREATE TABLE audit(
    audit_id  INTEGER PRIMARY KEY,
    reading_id INTEGER NOT NULL,
    old_value REAL,
    new_value REAL,
    changed_at TEXT NOT NULL DEFAULT (datetime('now'))
) STRICT;

-- 1. Semantic rule enforced at write time: vibration above 2.0 mm/s raises an alarm.
CREATE TRIGGER trg_vib_alarm
AFTER INSERT ON reading
FOR EACH ROW
WHEN NEW.value > 2.0 AND (SELECT metric FROM sensor WHERE sensor_id = NEW.sensor_id) = 'vib_rms'
BEGIN
    INSERT INTO alarm(sensor_id, ts, value, reason)
    VALUES (NEW.sensor_id, NEW.ts, NEW.value, 'vibration over 2.0 mm/s');
END;

-- 2. Audit every update, automatically.
CREATE TRIGGER trg_reading_audit
AFTER UPDATE OF value ON reading
FOR EACH ROW
BEGIN
    INSERT INTO audit(reading_id, old_value, new_value)
    VALUES (NEW.reading_id, OLD.value, NEW.value);
END;

-- Exercise them
INSERT INTO reading(sensor_id, ts, value, interval_s) VALUES (2,'2026-03-01 09:00:00', 2.7, 1);  -- alarm!
UPDATE reading SET value = 1.4 WHERE sensor_id = 2 AND ts = '2026-03-01 09:00:00';               -- audit!
SELECT * FROM alarm;
SELECT * FROM audit;
