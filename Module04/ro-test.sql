-- Module 4, Task 4: can a read-only connection change data?
-- Run against a read-only connection (see Module04/README.md)
.headers on
.mode column
.print '--- report readers see the view:'
SELECT * FROM machine_health;
.print '--- readings before:'
SELECT COUNT(*) AS readings FROM reading;
.print '--- try to delete everything (must fail):'
DELETE FROM reading;
.print '--- readings after:'
SELECT COUNT(*) AS readings FROM reading;
