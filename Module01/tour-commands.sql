DROP TABLE IF EXISTS reading;
CREATE TABLE reading(machine TEXT, vib REAL);
INSERT INTO reading VALUES ('cnc-01', 1.2), ('cnc-02', 2.4), ('cnc-01', 0.9);
.output Module01/shell-tour.txt
.echo on
.tables
.schema reading
.mode column
.headers on
.timer on
SELECT machine, max(vib) AS peak FROM reading GROUP BY machine;
.timer off
.echo off
.output Module01/tour.sql
.dump
.output stdout