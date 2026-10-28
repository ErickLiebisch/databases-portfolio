"""Demonstrate SQL injection and its one correct fix: bound parameters.

Run with:  uv run python Module03/injection_demo.py
"""
import sqlite3
from pathlib import Path

DB = Path(__file__).with_name("warehouse.db")
if not DB.exists():
    raise SystemExit(f"{DB} not found — run the Module 3 setup first")

conn = sqlite3.connect(DB)

def vulnerable(name: str):
    """DON'T DO THIS. String-building the query is the bug."""
    sql = f"SELECT customer_id, name FROM customer WHERE name = '{name}'"
    return conn.execute(sql).fetchall()          # a quote in `name` breaks or hijacks this

def safe(name: str):
    """DO THIS. The value can never be parsed as SQL."""
    sql = "SELECT customer_id, name FROM customer WHERE name = ?"
    return conn.execute(sql, (name,)).fetchall()  # note the bound tuple

if __name__ == "__main__":
    print("normal   :", vulnerable("Customer 1"))
    try:
        print("apostrophe:", vulnerable("O'Brien"))
    except sqlite3.Error as e:
        print("apostrophe: crashed with", e)
    try:
        rows = vulnerable("' OR '1'='1")
        print(f"injected : returned {len(rows)} rows, first 3:", rows[:3])
    except sqlite3.Error as e:
        print("injected : crashed with", e)
    print("safe     :", safe("' OR '1'='1"))       # returns [] — the payload is just data
    print("safe     :", safe("O'Brien"))
