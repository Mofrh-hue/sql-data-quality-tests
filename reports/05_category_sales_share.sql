-- Revenue per product category and its share of all revenue (paid and shipped orders).
-- Shows: SUM() OVER () to compare each group with the total
WITH category_revenue AS (
    SELECT p.category,
           SUM(oi.quantity * oi.unit_price) AS revenue
    FROM order_items AS oi
    JOIN orders      AS o ON o.order_id   = oi.order_id
    JOIN products    AS p ON p.product_id = oi.product_id
    WHERE o.status IN ('paid', 'shipped')
    GROUP BY p.category
)
SELECT category,
       ROUND(revenue, 2)                                    AS revenue,
       ROUND(100.0 * revenue / SUM(revenue) OVER (), 1)     AS share_percent
FROM category_revenue
ORDER BY revenue DESC;
