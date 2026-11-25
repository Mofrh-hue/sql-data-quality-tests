-- Units sold per product (paid and shipped orders), best sellers first.
-- Shows: three-table JOIN, SUM, DENSE_RANK() for ties
SELECT DENSE_RANK() OVER (ORDER BY SUM(oi.quantity) DESC) AS rank,
       p.name,
       SUM(oi.quantity) AS units_sold
FROM order_items AS oi
JOIN orders      AS o ON o.order_id   = oi.order_id
JOIN products    AS p ON p.product_id = oi.product_id
WHERE o.status IN ('paid', 'shipped')
GROUP BY p.product_id, p.name
ORDER BY units_sold DESC, p.name;
