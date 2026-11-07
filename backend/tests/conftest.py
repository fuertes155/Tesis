"""
Configuración común de pytest.

Las pruebas corren contra una base de datos SQLite TEMPORAL, nunca contra
data/sql_app_v2.db. Las variables de entorno se fijan antes de importar la app
porque `main.py` crea las tablas y los usuarios semilla al importarse.
"""
import os
import shutil
import sys
import tempfile
import uuid
from pathlib import Path

_mutation_dir = os.environ.get("NEUROAPP_MUTATION_TEST_DIR") if "MUTANT_UNDER_TEST" in os.environ else None
if _mutation_dir:
    _DIR_TEMPORAL = Path(_mutation_dir).resolve()
    if _DIR_TEMPORAL.parent != Path(tempfile.gettempdir()).resolve() or not _DIR_TEMPORAL.name.startswith("neuroapp_pruebas_"):
        raise RuntimeError("Directorio temporal de mutación inválido")
else:
    _DIR_TEMPORAL = Path(tempfile.mkdtemp(prefix="neuroapp_pruebas_"))
    if "MUTANT_UNDER_TEST" in os.environ:
        os.environ["NEUROAPP_MUTATION_TEST_DIR"] = str(_DIR_TEMPORAL)
os.environ["DATABASE_URL"] = f"sqlite:///{(_DIR_TEMPORAL / 'pruebas.db').as_posix()}"
os.environ["DEFAULT_ADMIN_PASSWORD"] = "Password123!"  # clave de los usuarios semilla
os.environ["SECRET_KEY"] = "neuroapp-test-only-secret-at-least-32-characters"

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import pytest  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402

import main  # noqa: E402
from app.core.config import settings  # noqa: E402
from app.infrastructure.database import engine  # noqa: E402

# Candado: si por algún motivo la app no tomó la BD temporal, se aborta todo.
if _DIR_TEMPORAL.as_posix() not in settings.DATABASE_URL:
    raise RuntimeError(f"Las pruebas no están usando la BD temporal: {settings.DATABASE_URL}")

API = "/api/v1"
CLAVE = "Password123!"
DOCTOR = "samuel@gmail.com"  # usuarios semilla creados por main.py
GESTOR = "samuel1@gmail.com"


def pytest_configure(config):
    config.addinivalue_line("markers", "integration: pruebas que recorren la API completa")


def pytest_sessionfinish(session, exitstatus):
    # mutmut ejecuta varias sesiones en el mismo intérprete y procesos fork.
    # La BD temporal debe sobrevivir a la recolección; el contenedor se desecha.
    if "MUTANT_UNDER_TEST" in os.environ:
        return
    engine.dispose()
    shutil.rmtree(_DIR_TEMPORAL, ignore_errors=True)


@pytest.fixture(autouse=True)
def _limpiar_limite_de_peticiones():
    """El limitador de main.py (200 peticiones/min por ruta) no debe afectar a las pruebas."""
    main._rate_limit_store.clear()
    yield


@pytest.fixture
def client():
    return TestClient(main.app)


def _token(client: TestClient, usuario: str) -> dict[str, str]:
    r = client.post(f"{API}/users/auth/login", json={"username": usuario, "password": CLAVE})
    assert r.status_code == 200, r.text
    return {"Authorization": f"Bearer {r.json()['access_token']}"}


@pytest.fixture
def doctor_headers(client):
    return _token(client, DOCTOR)


@pytest.fixture
def gestor_headers(client):
    return _token(client, GESTOR)


@pytest.fixture
def crear_paciente(client, doctor_headers):
    """Crea un paciente único y devuelve el JSON de la API."""

    def _crear(**extra):
        datos = {
            "name": "Paciente Prueba",
            "age": 70,
            "birth_date": "1956-03-14",
            "document_id": f"DOC-{uuid.uuid4().hex[:10]}",
            "diagnosis": "Deterioro cognitivo leve",
            "has_consent": True,
            **extra,
        }
        r = client.post(f"{API}/patients/", json=datos, headers=doctor_headers)
        assert r.status_code == 200, r.text
        return r.json()

    return _crear
