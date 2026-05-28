import sys
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from main import app


def pytest_configure(config):
    config.addinivalue_line("markers", "integration: marks integration tests requiring API runtime")


@pytest.fixture
def client():
    return TestClient(app)
