-- Rule:     If a cancelled order was paid, the payment is refunded.
-- Why:      Customers charged for orders they never receive.
-- Severity: High
SELECT o.order_id, p.payment_id, p.amount
FROM orders   AS o
JOIN payments AS p ON p.order_id = o.order_id
WHERE o.status = 'cancelled'
  AND p.refunded = 0;
