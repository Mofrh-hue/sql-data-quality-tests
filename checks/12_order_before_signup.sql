-- Rule:     A customer cannot place an order before their account was created.
-- Why:      Usually a time-zone or data-migration bug.
-- Severity: Low
SELECT o.order_id, o.created_at AS ordered_on, c.customer_id, c.created_at AS signed_up_on
FROM orders    AS o
JOIN customers AS c ON c.customer_id = o.customer_id
WHERE o.created_at < c.created_at;
