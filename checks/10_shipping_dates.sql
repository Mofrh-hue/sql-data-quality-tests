-- Rule:     Shipped orders have a ship date on or after the order date;
--           orders that are not shipped have no ship date.
-- Why:      Wrong dates break delivery tracking and SLA reports.
-- Severity: Medium
SELECT order_id, status, created_at, shipped_at
FROM orders
WHERE (status = 'shipped'  AND (shipped_at IS NULL OR shipped_at < created_at))
   OR (status <> 'shipped' AND shipped_at IS NOT NULL);
