-- Rule:     Products have a price above zero and stock of zero or more.
-- Why:      Free products or negative stock point to a broken import or a race condition.
-- Severity: High
SELECT product_id, name, price, stock
FROM products
WHERE price <= 0
   OR stock < 0;
