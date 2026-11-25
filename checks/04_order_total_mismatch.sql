-- Rule:     The stored order total equals the sum of its lines (quantity x unit price).
-- Why:      A wrong total means the customer is charged the wrong amount.
-- Severity: Critical
SELECT o.order_id,
       o.total                                            AS stored_total,
       ROUND(COALESCE(SUM(oi.quantity * oi.unit_price), 0), 2) AS calculated_total
FROM orders AS o
LEFT JOIN order_items AS oi ON oi.order_id = o.order_id
GROUP BY o.order_id, o.total
HAVING ROUND(o.total, 2) <> ROUND(COALESCE(SUM(oi.quantity * oi.unit_price), 0), 2);
