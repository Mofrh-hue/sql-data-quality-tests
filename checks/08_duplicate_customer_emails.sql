-- Rule:     Each email address belongs to one customer (ignoring upper/lower case and spaces).
-- Why:      Duplicate accounts split order history and break password reset.
-- Severity: Medium
SELECT c.customer_id, c.email
FROM customers AS c
WHERE LOWER(TRIM(c.email)) IN (
        SELECT LOWER(TRIM(email))
        FROM customers
        GROUP BY LOWER(TRIM(email))
        HAVING COUNT(*) > 1
      )
ORDER BY LOWER(TRIM(c.email)), c.customer_id;
