-- Rule:     Order line quantity is at least 1.
-- Why:      Zero or negative quantities usually mean a UI or API validation gap.
-- Severity: Medium
SELECT order_item_id, order_id, product_id, quantity
FROM order_items
WHERE quantity < 1;
