"""Module 4, Task 3: what does the alarm trigger cost on the ingest path?

Builds a throwaway in-memory copy of the edge schema, inserts 10,000
vibration readings with and without trg_vib_alarm, and reports the median
of 3 runs each.
Run:  uv run python Module04/trigger_cost.py
"""
import sqlite3
import statistics
import time
from pathlib import Path

HERE = Path(__file__).parent
SETUP = (HERE / "setup.sql").read_text(encoding="utf-8")
TRIGGER = """
CREATE TRIGGER trg_vib_alarm
AFTER INSERT ON reading
FOR EACH ROW
WHEN NEW.value > 2.0 AND (SELECT metric FROM sensor WHERE sensor_id = NEW.sensor_id) = 'vib_rms'
BEGIN
    INSERT INTO alarm(sensor_id, ts, value, reason)
    VALUES (NEW.sensor_id, NEW.ts, NEW.value, 'vibration over 2.0 mm/s');
END;
"""
ALARM_TABLE = """
CREATE TABLE alarm(
    alarm_id INTEGER PRIMARY KEY, sensor_id INTEGER NOT NULL, ts TEXT NOT NULL,
    value REAL NOT NULL, reason TEXT NOT NULL
) STRICT;
"""
N = 10_000
# every 10th reading is over the 2.0 mm/s threshold
ROWS = [(2, f"2026-03-02 {i // 3600:02d}:{i // 60 % 60:02d}:{i % 60:02d}",
         2.5 if i % 10 == 0 else 1.2, 1) for i in range(N)]


def one_run(with_trigger: bool) -> tuple[float, int]:
    con = sqlite3.connect(":memory:")
    con.executescript(SETUP)
    con.executescript(ALARM_TABLE)
    con.execute("INSERT INTO sensor VALUES (2,'cnc-01','vib_rms','mm/s')")
    if with_trigger:
        con.executescript(TRIGGER)
    start = time.perf_counter()
    with con:
        con.executemany(
            "INSERT INTO reading(sensor_id, ts, value, interval_s) VALUES (?,?,?,?)", ROWS
        )
    ms = (time.perf_counter() - start) * 1000
    alarms = con.execute("SELECT COUNT(*) FROM alarm").fetchone()[0]
    con.close()
    return ms, alarms


for label, flag in (("without trigger", False), ("with trigger   ", True)):
    runs = [one_run(flag) for _ in range(3)]
    times = [round(ms, 1) for ms, _ in runs]
    print(f"{label}: runs {times} ms | median {statistics.median(times)} ms "
          f"| alarms {runs[0][1]}")
