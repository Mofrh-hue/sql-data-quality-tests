-- Top 3 customers by money spent (paid and shipped orders).
-- Shows: JOIN, aggregation, RANK() window function, CTE
WITH spend AS (
    SELECT c.customer_id,
           c.full_name,
           ROUND(SUM(o.total), 2) AS total_spent,
           COUNT(*)               AS orders
    FROM customers AS c
    JOIN orders    AS o ON o.customer_id = c.customer_id
    WHERE o.status IN ('paid', 'shipped')
    GROUP BY c.customer_id, c.full_name
)
SELECT RANK() OVER (ORDER BY total_spent DESC) AS rank,
       full_name,
       total_spent,
       orders
FROM spend
ORDER BY total_spent DESC
LIMIT 3;
