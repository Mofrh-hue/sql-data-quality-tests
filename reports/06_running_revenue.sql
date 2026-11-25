-- Cumulative revenue day by day (paid and shipped orders).
-- Shows: running total with SUM() OVER (ORDER BY ...)
WITH daily AS (
    SELECT created_at AS day, SUM(total) AS revenue
    FROM orders
    WHERE status IN ('paid', 'shipped')
    GROUP BY created_at
)
SELECT day,
       ROUND(revenue, 2)                               AS revenue,
       ROUND(SUM(revenue) OVER (ORDER BY day), 2)      AS running_total
FROM daily
ORDER BY day;
