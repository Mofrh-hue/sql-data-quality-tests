# SQL Patterns for Testers

The query shapes I use most when checking data behind an application. In every pattern, a check **returns the rows that break the rule**, so an empty result means the check passed.

## 1. Missing parent: orphan rows (anti-join)

A child row points to a parent that does not exist.

```sql
SELECT o.order_id
FROM orders AS o
LEFT JOIN customers AS c ON c.customer_id = o.customer_id
WHERE c.customer_id IS NULL;
```

`LEFT JOIN` keeps every order; orders whose customer does not exist come back with `NULL` customer columns.
Used in: `01_orphan_orders.sql`, `02_orphan_order_items.sql`, `reports/04_customers_without_orders.sql`.

## 2. Reconciliation: does the stored number match the details?

```sql
SELECT o.order_id, o.total, SUM(oi.quantity * oi.unit_price) AS calculated
FROM orders AS o
LEFT JOIN order_items AS oi ON oi.order_id = o.order_id
GROUP BY o.order_id, o.total
HAVING ROUND(o.total, 2) <> ROUND(COALESCE(SUM(oi.quantity * oi.unit_price), 0), 2);
```

- `HAVING` filters **after** grouping, which `WHERE` cannot do.
- `ROUND` avoids false alarms from decimal rounding.
- `COALESCE(..., 0)` makes an order with **no lines** show up as a mismatch instead of disappearing.

Used in: `04_order_total_mismatch.sql`, `06_payment_amount_mismatch.sql`.

## 3. Something that should exist, doesn't (`NOT EXISTS`)

```sql
SELECT o.order_id
FROM orders AS o
WHERE o.status = 'shipped'
  AND NOT EXISTS (SELECT 1 FROM payments AS p WHERE p.order_id = o.order_id AND p.refunded = 0);
```

`NOT EXISTS` reads like the rule itself: "shipped, and there is no valid payment".
Used in: `05_paid_orders_without_payment.sql`.

## 4. Duplicates (`GROUP BY` + `HAVING COUNT(*) > 1`)

```sql
SELECT LOWER(TRIM(email)) AS email, COUNT(*)
FROM customers
GROUP BY LOWER(TRIM(email))
HAVING COUNT(*) > 1;
```

Normalise first. `Omar@x.com` and `omar@x.com ` are the same person to a user, but not to a plain `GROUP BY email`.
Used in: `08_duplicate_customer_emails.sql`.

## 5. Range, format and date sanity checks

```sql
WHERE quantity < 1
WHERE price <= 0 OR stock < 0
WHERE email NOT LIKE '_%@_%._%' OR email LIKE '% %'
WHERE shipped_at < created_at
```

Boundary values matter. `quantity < 1` catches 0; `quantity < 0` would let it through.
Used in: `03`, `09`, `10`, `11` and `12`.

## 6. Window functions for reports

| Need | Function |
|---|---|
| Rank with ties, leaving gaps (1, 2, 2, 4) | `RANK() OVER (ORDER BY x DESC)` |
| Rank with ties, no gaps (1, 2, 2, 3) | `DENSE_RANK() OVER (ORDER BY x DESC)` |
| Share of the grand total | `100.0 * x / SUM(x) OVER ()` |
| Running total | `SUM(x) OVER (ORDER BY day)` |

Used in: `reports/02`, `03`, `05` and `06`.

## Traps I test for

- **`NULL` is not equal to anything**, not even another `NULL`. Use `IS NULL`, never `= NULL`.
- **`NOT IN` with a `NULL` in the list returns no rows at all.** Prefer `NOT EXISTS` or a `LEFT JOIN ... IS NULL`.
- **An `INNER JOIN` silently drops rows** that have no match. Count rows before and after joining.
- **`COUNT(column)` skips `NULL`s**, while `COUNT(*)` counts every row.
- **Integer division:** `1 / 2 = 0`. Multiply by `100.0` first to get a decimal result.
- **Text dates sort correctly only in ISO format** (`YYYY-MM-DD`).
