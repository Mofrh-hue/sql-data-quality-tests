-- Monthly revenue from paid and shipped orders.
-- Shows: GROUP BY, date functions, filtering on status
SELECT STRFTIME('%Y-%m', created_at) AS month,
       COUNT(*)                      AS orders,
       ROUND(SUM(total), 2)          AS revenue
FROM orders
WHERE status IN ('paid', 'shipped')
GROUP BY month
ORDER BY month;
