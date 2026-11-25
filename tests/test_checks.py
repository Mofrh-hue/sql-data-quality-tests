"""The data-quality checks must pass on clean data and catch every known defect."""
import pytest

import dq

CHECK_IDS = [p.stem for p in dq.CHECKS]

# What each check must find in the buggy database (see db/defects.sql).
# Key column -> expected values, so a check that finds the wrong rows also fails.
EXPECTED_DEFECTS = {
    '01_orphan_orders': ('order_id', [31]),
    '02_orphan_order_items': ('order_item_id', [63]),
    '03_invalid_quantity': ('order_item_id', [64]),
    '04_order_total_mismatch': ('order_id', 'MIN new order'),
    '05_paid_orders_without_payment': ('order_id', ['MIN shipped order', '2nd shipped order']),
    '06_payment_amount_mismatch': ('order_id', 'MIN paid order'),
    '07_cancelled_not_refunded': ('order_id', 'MIN cancelled order with a payment'),
    '08_duplicate_customer_emails': ('customer_id', [2, 13]),
    '09_invalid_email_format': ('customer_id', [14, 15]),
    '10_shipping_dates': ('order_id', 'MAX shipped order'),
    '11_product_price_and_stock': ('product_id', [7]),
    '12_order_before_signup': ('order_id', 'MAX paid order'),
}

# Resolves the "MIN/MAX ... order" descriptions against the clean data,
# using the same rule as defects.sql, so the expectations never go stale.
LOOKUPS = {
    'MIN new order': "SELECT MIN(order_id) FROM orders WHERE status = 'new'",
    'MIN shipped order': "SELECT MIN(order_id) FROM orders WHERE status = 'shipped'",
    '2nd shipped order': (
        "SELECT MIN(order_id) FROM orders WHERE status = 'shipped' "
        "AND order_id > (SELECT MIN(order_id) FROM orders WHERE status = 'shipped')"
    ),
    'MAX shipped order': "SELECT MAX(order_id) FROM orders WHERE status = 'shipped'",
    'MIN paid order': "SELECT MIN(order_id) FROM orders WHERE status = 'paid'",
    'MAX paid order': "SELECT MAX(order_id) FROM orders WHERE status = 'paid'",
    'MIN cancelled order with a payment': (
        "SELECT MIN(o.order_id) FROM orders o JOIN payments p ON p.order_id = o.order_id "
        "WHERE o.status = 'cancelled'"
    ),
}


def test_every_check_has_an_expected_defect():
    assert sorted(EXPECTED_DEFECTS) == sorted(CHECK_IDS)


def test_every_check_documents_its_rule_and_severity():
    for path in dq.CHECKS:
        info = dq.check_info(path)
        assert info['rule'], f'{path.name} has no "-- Rule:" line'
        assert info['severity'] in {'Low', 'Medium', 'High', 'Critical'}, path.name


@pytest.mark.parametrize('check', dq.CHECKS, ids=CHECK_IDS)
def test_check_passes_on_clean_data(clean_db, check):
    rows = dq.run_query(clean_db, check)
    assert rows == [], f'{check.stem} found problems in clean data: {rows}'


@pytest.mark.parametrize('check', dq.CHECKS, ids=CHECK_IDS)
def test_check_finds_exactly_the_known_defect(clean_db, buggy_db, check):
    column, expected = EXPECTED_DEFECTS[check.stem]
    if isinstance(expected, str):
        expected = [expected]
    expected = [clean_db.execute(LOOKUPS[e]).fetchone()[0] if isinstance(e, str) else e for e in expected]
    found = sorted(row[column] for row in dq.run_query(buggy_db, check))
    assert found == sorted(expected), f'{check.stem}: expected {column} {expected}, found {found}'


def test_buggy_database_fails_every_check(buggy_db):
    results = dq.run_checks(buggy_db)
    assert [r['name'] for r in results if r['passed']] == []
