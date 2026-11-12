"""Module 6, Task 2: DuckDB analytics over files.

Run from the repo root:  uv run python Module06/analytics.py
Needs Module01/telemetry.db (rebuild it with the Module 1 scripts if missing).
"""
import statistics
import time
from pathlib import Path

import duckdb

root = Path(__file__).resolve().parent.parent          # the portfolio repo root
sqlite_db = root / "Module01" / "telemetry.db"        # built in Module 1
parquet = root / "Module06" / "readings.parquet"

con = duckdb.connect()                       # in-process, embedded, no server

# 1. Attach the SQLite file from Module 1 (the sqlite extension reads it in place):
con.execute("INSTALL sqlite")                # first run downloads + caches this extension
con.execute("LOAD sqlite")
con.execute(f"ATTACH '{sqlite_db}' AS edge (TYPE sqlite, READ_ONLY)")

# 2. Materialize an analytical copy to Parquet at the edge — one file, no server:
con.execute(f"COPY (SELECT * FROM edge.readings) TO '{parquet}' (FORMAT parquet)")

REPORT = """
    SELECT machine, ROUND(AVG(temp_c), 2) AS avg_temp, MAX(vib_rms) AS peak_vib, COUNT(*) AS n
    FROM {source}
    GROUP BY machine
    ORDER BY peak_vib DESC
"""


def timed(source: str) -> tuple[list, list[float]]:
    """Run the weekly report 3 times on one source; return result and times in ms."""
    times = []
    for _ in range(3):
        t0 = time.perf_counter()
        result = con.execute(REPORT.format(source=source)).fetchall()
        times.append(round((time.perf_counter() - t0) * 1000, 1))
    return result, times


# 3. Query the Parquet file directly — no import step, no server:
from_parquet, t_parquet = timed(f"'{parquet}'")
# 4. The same aggregation straight from the SQLite file, for comparison:
from_sqlite, t_sqlite = timed("edge.readings")

print(f"parquet: {from_parquet}")
print(f"         runs {t_parquet} ms | median {statistics.median(t_parquet)} ms")
print(f"sqlite : {from_sqlite}")
print(f"         runs {t_sqlite} ms | median {statistics.median(t_sqlite)} ms")
print(f"same result: {from_parquet == from_sqlite}")
print(f"sizes  : telemetry.db {sqlite_db.stat().st_size:,} bytes | "
      f"readings.parquet {parquet.stat().st_size:,} bytes")
