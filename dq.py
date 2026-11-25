"""Builds the shop database and runs the SQL data-quality checks.

Usage:
    python dq.py              # run all checks against the clean database
    python dq.py --buggy      # run them against the database with known defects
    python dq.py --show       # also print the rows each failing check found
"""
import argparse
import sqlite3
from pathlib import Path

ROOT = Path(__file__).resolve().parent
CHECKS = sorted((ROOT / 'checks').glob('*.sql'))
REPORTS = sorted((ROOT / 'reports').glob('*.sql'))


def build_db(buggy: bool = False) -> sqlite3.Connection:
    """Creates an in-memory database from schema.sql and seed.sql (plus defects.sql if buggy)."""
    conn = sqlite3.connect(':memory:')
    conn.row_factory = sqlite3.Row
    files = ['schema.sql', 'seed.sql'] + (['defects.sql'] if buggy else [])
    for name in files:
        conn.executescript((ROOT / 'db' / name).read_text(encoding='utf-8'))
    return conn


def check_info(path: Path) -> dict:
    """Reads the Rule / Severity header comments of a check file."""
    info = {'name': path.stem, 'rule': '', 'severity': ''}
    for line in path.read_text(encoding='utf-8').splitlines():
        if line.startswith('-- Rule:'):
            info['rule'] = line.split(':', 1)[1].strip()
        elif line.startswith('-- Severity:'):
            info['severity'] = line.split(':', 1)[1].strip()
    return info


def run_query(conn: sqlite3.Connection, path: Path) -> list[dict]:
    return [dict(row) for row in conn.execute(path.read_text(encoding='utf-8')).fetchall()]


def run_checks(conn: sqlite3.Connection) -> list[dict]:
    """Runs every check. A check passes when its query returns no rows."""
    results = []
    for path in CHECKS:
        rows = run_query(conn, path)
        results.append({**check_info(path), 'rows': rows, 'passed': not rows})
    return results


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--buggy', action='store_true', help='use the database with known defects')
    parser.add_argument('--show', action='store_true', help='print the rows found by failing checks')
    args = parser.parse_args()

    results = run_checks(build_db(buggy=args.buggy))
    print(f"Data-quality checks on the {'buggy' if args.buggy else 'clean'} database\n")
    for r in results:
        status = 'PASS' if r['passed'] else f"FAIL ({len(r['rows'])} row{'s' if len(r['rows']) != 1 else ''})"
        print(f"[{status:<13}] {r['severity']:<8} {r['name']}")
        if args.show and not r['passed']:
            for row in r['rows']:
                print('               ', row)
    failed = sum(not r['passed'] for r in results)
    print(f"\n{len(results) - failed} passed, {failed} failed")
    return 1 if failed else 0


if __name__ == '__main__':
    raise SystemExit(main())
