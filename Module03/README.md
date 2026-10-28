# Module 3 — LLM-Assisted SQL & Query Profiling

Session 3 of the HSBI Databases class. On a warehouse with 60,000 orders and 240,000 order lines I read query plans with `EXPLAIN QUERY PLAN`, benchmarked an index (including where it does **not** help), and reproduced and fixed a SQL injection.

Course page: [Module 3 in the workbook](https://github.com/iotempire/iotempire-teaching/blob/main/full-classes/hsbi-databases-10d/modules/03-llm-assisted-sql-and-query-profiling.md) · Pod mate: [Roberto Navia Guillén's portfolio](https://github.com/RobertoNaviaGuillen/databases-portfolio)

Rebuild the database: `sqlite3 Module03/warehouse.db ".read Module03/setup.sql"` ([setup.sql](setup.sql)) → 60,000 orders, 240,000 order lines.

## Learning Goals

<a id="lg1"></a>
### LG1 — `dql`

Build complex **DQL** queries: joins, aggregation with `GROUP BY`/`HAVING`, subqueries, and window functions.

**Evidence:** [Task 1 — Plans](#task-1), [Task 4 — Algebra](#task-4), [Module 2 defect queries](../Module02/audit-queries.sql) (`LEFT JOIN`, `GROUP BY … HAVING`)

<a id="lg2"></a>
### LG2 — `plan`

Read **`EXPLAIN QUERY PLAN`** as *primary evidence*: say what the engine will do for a given query, tell a `SCAN` from a `SEARCH`, and a table lookup from a covering index.

**Evidence:** [Task 1 — Plans](#task-1)

<a id="lg3"></a>
### LG3 — `index`

**Benchmark** the effect of an index and explain when the planner ignores one.

**Evidence:** [Task 2 — Index benchmark](#task-2)

<a id="lg4"></a>
### LG4 — `verify-ai`

Generate a query with an **LLM**, then **verify** it: correctness, performance, and edge cases.

**Evidence:** [Module 1, Task 7](../Module01/README.md#task-7) (ChatGPT's "overnight" query: wrong time window found by querying the data)

<a id="lg5"></a>
### LG5 — `injection`

**Prevent SQL injection** with bound parameters and demonstrate why string concatenation is exploitable.

**Evidence:** [Task 3 — Injection drill](#task-3)

<a id="task-1"></a>
## Task 1 — Read the plan

**Proves:** [LG1](#lg1), [LG2](#lg2)

Queries: [index-benchmark.sql](index-benchmark.sql) → output: [index-results.txt](index-results.txt)

- `SCAN` = read the whole table row by row (like leafing through a 600-page service manual). `SEARCH … USING INDEX` = jump straight to the rows (like using the manual's index).
- `SEARCH c USING INTEGER PRIMARY KEY` = the customer is found directly by its key for every order.
- **Dashboard** (revenue per city in 2025, 4-table join): `SCAN ol` + `USE TEMP B-TREE FOR GROUP BY / count(DISTINCT) / ORDER BY`. It must read all order lines and build temporary sorted lists for grouping and ordering.

<a id="task-2"></a>
## Task 2 — Index benchmark: prove it or disprove it

**Proves:** [LG3](#lg3)

Single-day lookup (`WHERE o.ordered_on = '2026-02-14'`, 111 orders found in both cases), 3 runs each, `.timer` in the same `sqlite3` session:

| | Plan | Runs (ms) | Median |
|---|---|---|---|
| No index | `SCAN o` | 3.2 / 1.5 / 1.5 | **1.55 ms** |
| `ix_orders_ordered_on` | `SEARCH o USING INDEX ix_orders_ordered_on (ordered_on=?)` | 0.38 / 0.14 / 0.10 | **0.14 ms** |

About **11× faster**, and the changed plan is the stronger proof. Why 3 runs and the median: the first run is always slower (like a cold engine: the file is read from disk into memory), and one measurement alone is noise.

**Where the index does NOT help (negative results):**
- `WHERE date(ordered_on) = '2026-02-14'` → `SCAN orders USING COVERING INDEX`: the function around the column prevents a direct jump, SQLite has to read the whole index.
- The dashboard still does `SCAN ol` with the index present: it needs almost all rows of the year. If you have to read 500 of 600 pages, the index does not help; reading straight through is just as fast.

<a id="task-3"></a>
## Task 3 — The injection drill

**Proves:** [LG5](#lg5)

[injection_demo.py](injection_demo.py) → output: [injection-output.txt](injection-output.txt)

| Input | `vulnerable` (string-built SQL) | `safe` (bound parameter `?`) |
|---|---|---|
| `Customer 1` | 1 row | — |
| `O'Brien` (real surname) | **crash**: syntax error | `[]` (no such customer) |
| `' OR '1'='1` (attack) | **all 2,000 customers** | `[]` |

The attack turns the query into `WHERE name = '' OR '1'='1'`, which is true for every row: the input became part of the command. With `?`, the value is always treated as **data, never as an instruction**.

**Why escaping `'` by hand is not a real fix:** you would have to remember it in every query, for every input, and in every context (numbers, column names, other encodings); one forgotten place is enough. Bound parameters move the responsibility to the database driver, which separates command and data by design.

<a id="task-4"></a>
## Task 4 — One query, from algebra to plan

**Proves:** [LG1](#lg1)

```sql
SELECT o.order_id, o.ordered_on, c.name
FROM orders o JOIN customer c ON c.customer_id = o.customer_id
WHERE o.ordered_on = '2026-02-14';
```

π<sub>order_id, ordered_on, name</sub> ( σ<sub>ordered_on = '2026-02-14'</sub>(orders) ⋈<sub>orders.customer_id = customer.customer_id</sub> customer )

- σ (selection) = `WHERE`: keep only the rows of that day → in the plan: `SEARCH o USING INDEX ix_orders_ordered_on`
- ⋈ (join) = `JOIN … ON`: attach the customer of each order → `SEARCH c USING INTEGER PRIMARY KEY`
- π (projection) = the column list after `SELECT`

## Reflection

[Reflection 3](../Reflections/ref03.md)
