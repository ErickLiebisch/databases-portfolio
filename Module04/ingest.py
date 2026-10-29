"""Module 4, Task 2: replay-safe ingest of a CSV into edge.db.

Run it twice:  uv run python Module04/ingest.py Module04/replay.csv
The row count must not grow on the second run.
"""
import csv
import sqlite3
import sys
from pathlib import Path

DB = Path(__file__).parent / "edge.db"

UPSERT = """
INSERT INTO reading(sensor_id, ts, value, interval_s)
VALUES (?, ?, ?, ?)
ON CONFLICT(sensor_id, ts) DO UPDATE SET value = excluded.value
"""


def main(csv_path: str) -> None:
    con = sqlite3.connect(DB)
    con.execute("PRAGMA foreign_keys = ON")
    con.execute(
        "CREATE UNIQUE INDEX IF NOT EXISTS ux_reading_sensor_ts ON reading(sensor_id, ts)"
    )

    with open(csv_path, newline="") as f:
        rows = [
            (int(r["sensor_id"]), r["ts"], float(r["value"]), int(r["interval_s"]))
            for r in csv.DictReader(f)
        ]

    before = con.execute("SELECT COUNT(*) FROM reading").fetchone()[0]
    with con:  # one transaction: all rows or none
        con.executemany(UPSERT, rows)
    after = con.execute("SELECT COUNT(*) FROM reading").fetchone()[0]

    print(f"rows in file: {len(rows)} | readings before: {before} | after: {after}")
    con.close()


if __name__ == "__main__":
    main(sys.argv[1])
