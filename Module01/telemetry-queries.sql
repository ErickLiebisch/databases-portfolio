.output Module01/telemetry-results.txt
.echo on
.mode column
.headers on
.timer on
-- 1. How many readings per machine?
SELECT machine, COUNT(*) AS n FROM readings GROUP BY machine;
-- 2. Peak vibration per machine in these two days?
SELECT machine, MAX(vib_rms) AS peak_vib FROM readings GROUP BY machine;
-- 3. How many readings exceeded a 2.0 mm/s vibration alarm?
SELECT COUNT(*) AS alarms FROM readings WHERE vib_rms > 2.0;
.output stdout