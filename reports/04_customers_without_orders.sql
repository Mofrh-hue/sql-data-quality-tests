-- Customers who signed up but never ordered (for a re-engagement email).
-- Shows: LEFT JOIN + IS NULL ("anti-join")
SELECT c.customer_id, c.full_name, c.email
FROM customers AS c
LEFT JOIN orders AS o ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL
ORDER BY c.customer_id;
