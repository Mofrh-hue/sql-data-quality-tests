-- Rule:     Every order line points to an existing order and an existing product.
-- Why:      Lines without an order inflate sales; lines without a product cannot be shipped.
-- Severity: High
SELECT oi.order_item_id, oi.order_id, oi.product_id
FROM order_items AS oi
LEFT JOIN orders   AS o ON o.order_id   = oi.order_id
LEFT JOIN products AS p ON p.product_id = oi.product_id
WHERE o.order_id IS NULL
   OR p.product_id IS NULL;
