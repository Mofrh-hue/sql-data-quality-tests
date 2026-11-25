-- Known defects, applied on top of seed.sql to build the "buggy" database.
-- Each defect should be caught by exactly one check in checks/.
-- The tests assert that every check finds exactly the rows listed here.

-- DEF-01 -> 01_orphan_orders: an order for a customer that does not exist
INSERT INTO orders (order_id, customer_id, status, created_at, shipped_at, total)
VALUES (31, 99, 'new', '2026-06-01', NULL, 14.15);
INSERT INTO order_items (order_item_id, order_id, product_id, quantity, unit_price)
VALUES (62, 31, 1, 1, 14.15);

-- DEF-02 -> 02_orphan_order_items: a line for an order that does not exist
INSERT INTO order_items (order_item_id, order_id, product_id, quantity, unit_price)
VALUES (63, 999, 2, 1, 12.58);

-- DEF-03 -> 03_invalid_quantity: a line with quantity 0 (adds 0 to the total)
INSERT INTO order_items (order_item_id, order_id, product_id, quantity, unit_price)
VALUES (64, (SELECT MAX(order_id) FROM orders WHERE status = 'new' AND customer_id <> 99), 9, 0, 7.23);

-- DEF-04 -> 04_order_total_mismatch: stored total is 10.00 too high
UPDATE orders SET total = total + 10
WHERE order_id = (SELECT MIN(order_id) FROM orders WHERE status = 'new');

-- DEF-05 -> 05_paid_orders_without_payment: two shipped orders that are not actually paid
--   a) the payment row is missing
DELETE FROM payments
WHERE order_id = (SELECT MIN(order_id) FROM orders WHERE status = 'shipped');
--   b) the only payment was refunded, but the order still shipped
UPDATE payments SET refunded = 1
WHERE order_id = (SELECT MIN(order_id) FROM orders WHERE status = 'shipped'
                  AND order_id > (SELECT MIN(order_id) FROM orders WHERE status = 'shipped'));

-- DEF-06 -> 06_payment_amount_mismatch: customer charged 5.00 too little
UPDATE payments SET amount = amount - 5
WHERE order_id = (SELECT MIN(order_id) FROM orders WHERE status = 'paid');

-- DEF-07 -> 07_cancelled_not_refunded: a cancelled order still holds the money
UPDATE payments SET refunded = 0
WHERE order_id = (SELECT MIN(o.order_id) FROM orders AS o JOIN payments AS p ON p.order_id = o.order_id
                  WHERE o.status = 'cancelled');

-- DEF-08 -> 08_duplicate_customer_emails: same email with different capitalisation
INSERT INTO customers (customer_id, full_name, email, country, created_at)
VALUES (13, 'Omar K.', 'OMAR.KHALED@example.com', 'Egypt', '2026-05-10');

-- DEF-09 -> 09_invalid_email_format: two malformed addresses
INSERT INTO customers (customer_id, full_name, email, country, created_at)
VALUES (14, 'Test User', 'test.user@example', 'UK', '2026-05-11'),
       (15, 'Missing At', 'missing.at.example.com', 'UK', '2026-05-12');

-- DEF-10 -> 10_shipping_dates: shipped two days before it was ordered
UPDATE orders SET shipped_at = DATE(created_at, '-2 days')
WHERE order_id = (SELECT MAX(order_id) FROM orders WHERE status = 'shipped');

-- DEF-11 -> 11_product_price_and_stock: negative stock
UPDATE products SET stock = -3 WHERE product_id = 7;

-- DEF-12 -> 12_order_before_signup: order dated before the customer signed up
UPDATE orders SET created_at = '2025-12-01'
WHERE order_id = (SELECT MAX(order_id) FROM orders WHERE status = 'paid');
