import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import dq  # noqa: E402


@pytest.fixture(scope='module')
def clean_db():
    conn = dq.build_db(buggy=False)
    yield conn
    conn.close()


@pytest.fixture(scope='module')
def buggy_db():
    conn = dq.build_db(buggy=True)
    yield conn
    conn.close()
