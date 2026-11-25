-- Rule:     Orders marked "paid" or "shipped" have a payment that was not refunded.
-- Why:      Goods shipped without payment are lost revenue.
-- Severity: Critical
SELECT o.order_id, o.status
FROM orders AS o
WHERE o.status IN ('paid', 'shipped')
  AND NOT EXISTS (
        SELECT 1
        FROM payments AS p
        WHERE p.order_id = o.order_id
          AND p.refunded = 0
      );
