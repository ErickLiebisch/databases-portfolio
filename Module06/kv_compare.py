"""Module 6, Task 3: a key-value store vs SQLite for dashboard sessions.

Run from the repo root:  uv run python Module06/kv_compare.py
"""
import shelve
import sqlite3
import time
from pathlib import Path

here = Path(__file__).parent
N = 50_000

# --- key-value store (stdlib shelve: a persistent dict) ---
with shelve.open(str(here / "sessions")) as db:
    t0 = time.perf_counter()
    for i in range(N):
        db[f"session-{i}"] = f"user-{i%100}:filter=city:{i%4}"
    t_set = time.perf_counter() - t0
    t0 = time.perf_counter()
    for i in range(N):
        _ = db[f"session-{i}"]
    t_get = time.perf_counter() - t0

# --- the same access pattern in SQLite ---
conn = sqlite3.connect(here / "kv.db")
conn.execute("CREATE TABLE IF NOT EXISTS session(k TEXT PRIMARY KEY, v TEXT)")
t0 = time.perf_counter()
conn.executemany("INSERT OR REPLACE INTO session(k, v) VALUES (?, ?)",
                 ((f"session-{i}", f"user-{i%100}:filter=city:{i%4}") for i in range(N)))
conn.commit()
sq_set = time.perf_counter() - t0
t0 = time.perf_counter()
for i in range(N):
    conn.execute("SELECT v FROM session WHERE k = ?", (f"session-{i}",)).fetchone()
sq_get = time.perf_counter() - t0

print(f"{N:,} sessions")
print(f"shelve  set={t_set:.3f}s get={t_get:.3f}s")
print(f"sqlite  set={sq_set:.3f}s get={sq_get:.3f}s")

# Something only SQLite can do: ask a question ACROSS all sessions
rows = conn.execute("""
    SELECT substr(v, instr(v, 'filter=') + 7) AS filter, COUNT(*) AS sessions
    FROM session GROUP BY filter ORDER BY filter
""").fetchall()
print("sqlite only - sessions per filter:", rows)
conn.close()
