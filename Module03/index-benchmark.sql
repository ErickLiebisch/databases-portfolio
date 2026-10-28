-- Module 3: read the plan, then prove (or disprove) an index.
-- Run from the repo root:  sqlite3 Module03/warehouse.db ".read Module03/index-benchmark.sql"
.output Module03/index-results.txt
.echo on
.mode column
.headers on
DROP INDEX IF EXISTS ix_orders_ordered_on;

-- ===== A. Single-day lookup, NO index =====
EXPLAIN QUERY PLAN
SELECT o.order_id, o.ordered_on, c.name
FROM orders o JOIN customer c ON c.customer_id = o.customer_id
WHERE o.ordered_on = '2026-02-14';
.timer on
SELECT COUNT(*) FROM orders o JOIN customer c ON c.customer_id = o.customer_id WHERE o.ordered_on = '2026-02-14';
SELECT COUNT(*) FROM orders o JOIN customer c ON c.customer_id = o.customer_id WHERE o.ordered_on = '2026-02-14';
SELECT COUNT(*) FROM orders o JOIN customer c ON c.customer_id = o.customer_id WHERE o.ordered_on = '2026-02-14';
.timer off

-- ===== B. Add ONE index and repeat =====
CREATE INDEX ix_orders_ordered_on ON orders(ordered_on);
EXPLAIN QUERY PLAN
SELECT o.order_id, o.ordered_on, c.name
FROM orders o JOIN customer c ON c.customer_id = o.customer_id
WHERE o.ordered_on = '2026-02-14';
.timer on
SELECT COUNT(*) FROM orders o JOIN customer c ON c.customer_id = o.customer_id WHERE o.ordered_on = '2026-02-14';
SELECT COUNT(*) FROM orders o JOIN customer c ON c.customer_id = o.customer_id WHERE o.ordered_on = '2026-02-14';
SELECT COUNT(*) FROM orders o JOIN customer c ON c.customer_id = o.customer_id WHERE o.ordered_on = '2026-02-14';
.timer off

-- ===== C. Negative result: a function around the column defeats the index =====
EXPLAIN QUERY PLAN
SELECT COUNT(*) FROM orders WHERE date(ordered_on) = '2026-02-14';

-- ===== D. The dashboard (aggregate over all 2025 orders): does the index help here? =====
EXPLAIN QUERY PLAN
SELECT c.city, COUNT(DISTINCT c.customer_id) AS customers,
       SUM(ol.qty * p.price) AS revenue
FROM customer c
JOIN orders o     ON o.customer_id = c.customer_id
JOIN order_line ol ON ol.order_id = o.order_id
JOIN product p    ON p.product_id = ol.product_id
WHERE o.ordered_on >= '2025-01-01' AND o.ordered_on < '2026-01-01'
GROUP BY c.city
ORDER BY revenue DESC;
.output stdout
