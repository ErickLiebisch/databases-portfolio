-- Module 4, Task 4: a safe subset for report readers
-- Run from PowerShell:  sqlite3 Module04/edge.db ".read Module04/access-view.sql"
DROP VIEW IF EXISTS machine_health;
CREATE VIEW machine_health AS
  SELECT s.machine_id, s.metric, MAX(r.value) AS peak, COUNT(*) AS n
  FROM sensor s JOIN reading r USING(sensor_id)
  GROUP BY s.machine_id, s.metric;
