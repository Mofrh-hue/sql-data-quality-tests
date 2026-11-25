-- Rule:     Every order belongs to an existing customer.
-- Why:      Orphan orders break invoices, customer history and reporting.
-- Severity: High
SELECT o.order_id, o.customer_id
FROM orders AS o
LEFT JOIN customers AS c ON c.customer_id = o.customer_id
WHERE c.customer_id IS NULL;
