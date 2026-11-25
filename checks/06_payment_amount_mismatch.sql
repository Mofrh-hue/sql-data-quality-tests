-- Rule:     A payment amount equals the total of the order it pays for.
-- Why:      Under- or over-charging the customer.
-- Severity: Critical
SELECT p.payment_id, p.order_id, p.amount, o.total
FROM payments AS p
JOIN orders   AS o ON o.order_id = p.order_id
WHERE ROUND(p.amount, 2) <> ROUND(o.total, 2);
