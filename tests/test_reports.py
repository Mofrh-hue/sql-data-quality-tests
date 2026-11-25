"""Each report query is checked against the same numbers calculated in plain Python
from the raw tables, so a wrong JOIN, filter or window function is caught."""
from collections import defaultdict
from itertools import accumulate
from pathlib import Path

import pytest

import dq

SOLD = ('paid', 'shipped')


def report(conn, name):
    path = next(p for p in dq.REPORTS if p.stem == name)
    return dq.run_query(conn, path)


def table(conn, name):
    return [dict(r) for r in conn.execute(f'SELECT * FROM {name}')]


@pytest.fixture(scope='module')
def data(clean_db):
    return {t: table(clean_db, t) for t in ('customers', 'products', 'orders', 'order_items', 'payments')}


def sold_orders(data):
    return [o for o in data['orders'] if o['status'] in SOLD]


def test_every_report_has_a_test():
    tested = {name for name in globals() if name.startswith('test_report_')}
    assert len(tested) == len(dq.REPORTS)


def test_report_revenue_by_month(clean_db, data):
    expected = defaultdict(lambda: [0, 0.0])
    for o in sold_orders(data):
        month = o['created_at'][:7]
        expected[month][0] += 1
        expected[month][1] += o['total']
    rows = report(clean_db, '01_revenue_by_month')
    assert [(r['month'], r['orders'], r['revenue']) for r in rows] == [
        (m, n, round(rev, 2)) for m, (n, rev) in sorted(expected.items())
    ]


def test_report_top_customers(clean_db, data):
    names = {c['customer_id']: c['full_name'] for c in data['customers']}
    spend = defaultdict(float)
    for o in sold_orders(data):
        spend[o['customer_id']] += o['total']
    top3 = sorted(spend.items(), key=lambda kv: -kv[1])[:3]
    rows = report(clean_db, '02_top_customers')
    assert [(r['rank'], r['full_name'], r['total_spent']) for r in rows] == [
        (i + 1, names[cid], round(total, 2)) for i, (cid, total) in enumerate(top3)
    ]


def test_report_best_selling_products(clean_db, data):
    sold_ids = {o['order_id'] for o in sold_orders(data)}
    names = {p['product_id']: p['name'] for p in data['products']}
    units = defaultdict(int)
    for item in data['order_items']:
        if item['order_id'] in sold_ids:
            units[names[item['product_id']]] += item['quantity']
    rows = report(clean_db, '03_best_selling_products')
    assert {r['name']: r['units_sold'] for r in rows} == dict(units)
    # DENSE_RANK: same units -> same rank, and no gaps in the ranking
    distinct = sorted(set(units.values()), reverse=True)
    for r in rows:
        assert r['rank'] == distinct.index(r['units_sold']) + 1, r


def test_report_customers_without_orders(clean_db, data):
    with_orders = {o['customer_id'] for o in data['orders']}
    expected = [c['customer_id'] for c in data['customers'] if c['customer_id'] not in with_orders]
    rows = report(clean_db, '04_customers_without_orders')
    assert [r['customer_id'] for r in rows] == expected
    assert expected, 'the seed data should contain at least one customer without orders'


def test_report_category_sales_share(clean_db, data):
    sold_ids = {o['order_id'] for o in sold_orders(data)}
    category = {p['product_id']: p['category'] for p in data['products']}
    revenue = defaultdict(float)
    for item in data['order_items']:
        if item['order_id'] in sold_ids:
            revenue[category[item['product_id']]] += item['quantity'] * item['unit_price']
    total = sum(revenue.values())
    rows = report(clean_db, '05_category_sales_share')
    assert {r['category']: (r['revenue'], r['share_percent']) for r in rows} == {
        c: (round(v, 2), round(100 * v / total, 1)) for c, v in revenue.items()
    }
    assert sum(r['share_percent'] for r in rows) == pytest.approx(100, abs=0.5)


def test_report_running_revenue(clean_db, data):
    daily = defaultdict(float)
    for o in sold_orders(data):
        daily[o['created_at']] += o['total']
    days = sorted(daily)
    running = list(accumulate(daily[d] for d in days))
    rows = report(clean_db, '06_running_revenue')
    assert [r['day'] for r in rows] == days
    assert [r['running_total'] for r in rows] == [round(x, 2) for x in running]
    assert rows[-1]['running_total'] == round(sum(o['total'] for o in sold_orders(data)), 2)
