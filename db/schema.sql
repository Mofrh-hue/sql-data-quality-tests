-- Schema for a small online tool shop.
-- Foreign keys are declared but NOT enforced by SQLite unless PRAGMA foreign_keys = ON,
-- which is how broken references can slip into a real database. The checks find them.

CREATE TABLE customers (
    customer_id  INTEGER PRIMARY KEY,
    full_name    TEXT    NOT NULL,
    email        TEXT    NOT NULL,
    country      TEXT    NOT NULL,
    created_at   TEXT    NOT NULL           -- ISO date: YYYY-MM-DD
);

CREATE TABLE products (
    product_id   INTEGER PRIMARY KEY,
    name         TEXT    NOT NULL,
    category     TEXT    NOT NULL,
    price        NUMERIC NOT NULL,          -- current list price
    stock        INTEGER NOT NULL
);

CREATE TABLE orders (
    order_id     INTEGER PRIMARY KEY,
    customer_id  INTEGER NOT NULL REFERENCES customers (customer_id),
    status       TEXT    NOT NULL,          -- new, paid, shipped, cancelled
    created_at   TEXT    NOT NULL,          -- ISO date
    shipped_at   TEXT,                      -- ISO date, only for shipped orders
    total        NUMERIC NOT NULL           -- stored total, must equal the sum of the lines
);

CREATE TABLE order_items (
    order_item_id INTEGER PRIMARY KEY,
    order_id      INTEGER NOT NULL REFERENCES orders (order_id),
    product_id    INTEGER NOT NULL REFERENCES products (product_id),
    quantity      INTEGER NOT NULL,
    unit_price    NUMERIC NOT NULL          -- price at the time of the order
);

CREATE TABLE payments (
    payment_id   INTEGER PRIMARY KEY,
    order_id     INTEGER NOT NULL REFERENCES orders (order_id),
    amount       NUMERIC NOT NULL,
    method       TEXT    NOT NULL,          -- card, wallet, cash_on_delivery
    paid_at      TEXT    NOT NULL,
    refunded     INTEGER NOT NULL DEFAULT 0 -- 1 when the money was returned
);
