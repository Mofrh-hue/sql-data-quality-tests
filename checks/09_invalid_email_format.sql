-- Rule:     Email addresses look valid: something@domain.tld, no spaces.
-- Why:      Order confirmations and invoices never arrive.
-- Severity: Medium
SELECT customer_id, email
FROM customers
WHERE email NOT LIKE '_%@_%._%'
   OR email LIKE '% %'
   OR email LIKE '%@%@%';
