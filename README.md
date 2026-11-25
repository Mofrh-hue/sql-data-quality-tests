# SQL Data-Quality Tests

[![SQL tests](https://github.com/Mofrh-hue/sql-data-quality-tests/actions/workflows/sql-tests.yml/badge.svg)](https://github.com/Mofrh-hue/sql-data-quality-tests/actions/workflows/sql-tests.yml)

SQL checks that test the **data behind an application**, the kind of back-end verification a tester does when the screen looks right but the database might not. The project uses a small online-shop database (customers, products, orders, order lines, payments) in SQLite.

> Learning and portfolio project. All data is made up.

## What's inside

**12 data-quality checks** ([`checks/`](checks)). Each query returns the rows that **break** a business rule, so no rows means the check passed. Every file starts with the rule, why it matters, and a severity.

| # | Rule | Severity |
|---|---|---|
| 01 | Every order belongs to an existing customer | High |
| 02 | Every order line points to an existing order and product | High |
| 03 | Quantity is at least 1 | Medium |
| 04 | Stored order total = sum of its lines | Critical |
| 05 | Paid or shipped orders have a payment that was not refunded | Critical |
| 06 | Payment amount = order total | Critical |
| 07 | Paid orders that were cancelled are refunded | High |
| 08 | One customer per email (ignoring upper/lower case and spaces) | Medium |
| 09 | Email addresses have a valid format | Medium |
| 10 | Ship date is on or after the order date | Medium |
| 11 | Price above zero, stock not negative | High |
| 12 | No orders before the customer signed up | Low |

**6 report queries** ([`reports/`](reports)): monthly revenue, top customers, best sellers, customers without orders, sales share by category, and running revenue. Between them they use `JOIN`, `LEFT JOIN`, `GROUP BY` / `HAVING`, CTEs (`WITH`), and the window functions `RANK`, `DENSE_RANK` and `SUM() OVER`.

**[SQL patterns for testers](docs/sql-for-testers.md)**: the query shapes behind the checks, plus common traps (`NULL`, `NOT IN`, joins that silently drop rows, integer division).

## Two databases: clean and buggy

- `db/schema.sql` + `db/seed.sql` give a **clean** database where every rule holds.
- Adding [`db/defects.sql`](db/defects.sql) gives a **buggy** copy with 14 planted defects, each labelled with the check that should catch it.

```text
$ python dq.py --buggy --show
[FAIL (1 row) ] High     01_orphan_orders
                {'order_id': 31, 'customer_id': 99}
[FAIL (1 row) ] Critical 04_order_total_mismatch
                {'order_id': 5, 'stored_total': 82.34, 'calculated_total': 72.34}
[FAIL (2 rows)] Critical 05_paid_orders_without_payment
                {'order_id': 3, 'status': 'shipped'}
                {'order_id': 6, 'status': 'shipped'}
[FAIL (2 rows)] Medium   08_duplicate_customer_emails
                {'customer_id': 2, 'email': 'omar.khaled@example.com'}
                {'customer_id': 13, 'email': 'OMAR.KHALED@example.com'}
...
0 passed, 12 failed
```

## How the SQL itself is tested

34 pytest tests, run in GitHub Actions on every push:

- **Every check returns nothing on the clean data.** This catches false alarms.
- **Every check finds exactly its planted defect** in the buggy data: the right rows, not just "some rows". This catches checks that are too loose or too strict.
- **Every report is compared with the same numbers calculated in plain Python** from the raw tables. A wrong filter, `JOIN` or window function changes the numbers and fails the test.

I also ran a **mutation test** before publishing: I broke each query on purpose in 17 different ways, for example `RANK` instead of `DENSE_RANK`, `<` instead of `<=`, an inner join instead of an anti-join, or dropping the `refunded = 0` condition. **All 17 broken versions were caught by the tests.** One of these runs showed that no planted defect covered "a shipped order whose payment was refunded", so I added one.

## Run it

Only Python 3 is needed. SQLite is built in.

```bash
pip install -r requirements.txt
pytest -v                    # the full test suite
python dq.py                 # data-quality report on the clean database
python dq.py --buggy --show  # the same checks on the buggy database
```

To explore the data with any SQLite tool (for example [DB Browser for SQLite](https://sqlitebrowser.org)):

```bash
sqlite3 shop.db < db/schema.sql && sqlite3 shop.db < db/seed.sql
```

## Project structure

```
db/schema.sql      Tables and relations
db/seed.sql        Clean sample data
db/defects.sql     Planted defects, one per check
checks/            12 data-quality checks (rows returned = rule broken)
reports/           6 business report queries
dq.py              Builds the database and runs the checks
tests/             pytest: checks on clean/buggy data, reports vs. Python
docs/              SQL patterns and traps for testers
```

---

Author: **Ahmed Mofrh Fahmy**, QA Test Lead · [GitHub profile](https://github.com/Mofrh-hue)
