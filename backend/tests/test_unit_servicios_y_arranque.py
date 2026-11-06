"""
Pruebas unitarias de la capa de servicios, la configuración y el arranque
(migraciones de esquema y usuarios semilla). BD temporal.
"""
import uuid
from pathlib import Path

import pytest
from sqlalchemy import create_engine, inspect, text

import main
from app.api.v1.users import _create_role_profile
from app.application.services import PatientService, SessionService, UserService
from app.core import config
from app.domain import entities
from app.infrastructure import models
from app.infrastructure.database import SessionLocal


@pytest.fixture
def db():
    sesion = SessionLocal()
    try:
        yield sesion
    finally:
        sesion.close()


def _usuario(db, rol="doctor"):
    u = models.User(username=f"{rol}_{uuid.uuid4().hex[:8]}@example.com", hashed_password="x",
                    role=rol, is_active=True, is_available=True)
    db.add(u)
    db.commit()
    db.refresh(u)
    return u


# ── Servicios ────────────────────────────────────────────────────────────────

def test_user_service_crea_y_busca_usuarios(db):
    correo = f"servicio_{uuid.uuid4().hex[:8]}@example.com"
    creado = UserService.create_user(db, entities.UserCreate(username=correo, password="Password123!",
                                                             full_name="ana ríos", document_id="123"))
    assert creado.hashed_password != "Password123!"
    assert UserService.get_user_by_username(db, correo).id == creado.id
    assert UserService.get_user_by_username(db, "nadie@example.com") is None


def test_patient_service_crud_y_asignacion(db):
    doctor, gestor = _usuario(db, "doctor"), _usuario(db, "gestor")
    p = PatientService.create_patient(db, entities.PatientCreate(name="Ana", age=70, has_consent=True))
    assert PatientService.get_patient(db, p.id).name == "Ana"
    assert p.id in {x.id for x in PatientService.get_patients(db, limit=1000)}

    assert PatientService.assign_doctor(db, p.id, doctor.id).doctor_id == doctor.id
    assert PatientService.assign_doctor(db, p.id, gestor.id) is None      # no es doctor
    assert PatientService.assign_doctor(db, 999999, doctor.id) is None    # paciente inexistente

    assert PatientService.delete_patient(db, p.id) is True
    assert PatientService.delete_patient(db, p.id) is False               # ya no existe


def test_session_service_crea_y_lista_sesiones(db):
    p = PatientService.create_patient(db, entities.PatientCreate(name="Ana", age=70))
    s = SessionService.create_session(db, entities.SessionCreate(patient_id=p.id, date="2026-11-04"))
    assert s.status == "scheduled"
    assert s.id in {x.id for x in SessionService.get_sessions(db, limit=1000)}


def test_perfil_de_rol_no_rompe_si_falla_la_bd(db, monkeypatch, caplog):
    u = _usuario(db, "gestor")

    def commit_que_falla():
        raise RuntimeError("disco lleno")

    monkeypatch.setattr(db, "commit", commit_que_falla)
    _create_role_profile(db, u)  # no debe lanzar
    assert "Failed to create role profile" in caplog.text
    assert db.query(models.Administrator).filter_by(user_id=u.id).count() == 0


def test_modulo_de_compatibilidad_de_modelos():
    from app.models.user import User
    assert User is models.User


# ── Configuración ────────────────────────────────────────────────────────────

@pytest.mark.parametrize(
    "url",
    ["postgresql://u:p@localhost/neuro", "sqlite:///:memory:", f"sqlite:///{Path.cwd().resolve().as_posix()}/x.db"],
)
def test_urls_que_no_se_reescriben(url):
    assert config._resolve_sqlite_url(url) == url


def test_ruta_sqlite_relativa_se_resuelve_desde_backend():
    url = config._resolve_sqlite_url("sqlite:///./data/app.db")
    assert url == f"sqlite:///{(config.ROOT_DIR / 'data' / 'app.db').resolve().as_posix()}"


# ── Arranque: migración de esquema y usuarios semilla ───────────────────────

def test_migracion_agrega_columnas_a_una_bd_antigua(tmp_path, monkeypatch):
    motor = create_engine(f"sqlite:///{(tmp_path / 'antigua.db').as_posix()}")
    with motor.begin() as conn:
        conn.execute(text("CREATE TABLE sessions (id INTEGER PRIMARY KEY, patient_id INTEGER, date TEXT)"))
        conn.execute(text("CREATE TABLE users (id INTEGER PRIMARY KEY, username TEXT)"))
        conn.execute(text("CREATE TABLE patients (id INTEGER PRIMARY KEY, name TEXT, registration_date DATETIME)"))
        conn.execute(text("INSERT INTO patients (id, name, registration_date) VALUES (1, 'Ana', '2026-01-02 10:00:00')"))
        conn.execute(text("INSERT INTO sessions (id, patient_id, date) VALUES (1, 1, '2026-01-02')"))

    monkeypatch.setattr(main, "engine", motor)
    main._ensure_db_schema()

    columnas = {t: {c["name"] for c in inspect(motor).get_columns(t)} for t in ("sessions", "users", "patients")}
    assert {"external_id", "created_at"} <= columnas["sessions"]
    assert {"full_name", "document_id", "is_2fa_enabled", "totp_secret"} <= columnas["users"]
    assert {"user_id", "document_id", "institution", "medical_history", "email",
            "external_id", "created_at"} <= columnas["patients"]
    with motor.connect() as conn:  # la fecha de alta se toma del registro antiguo
        assert conn.execute(text("SELECT created_at FROM patients WHERE id = 1")).scalar() == "2026-01-02 10:00:00"
    motor.dispose()


def test_migracion_se_omite_si_la_bd_no_es_sqlite(monkeypatch):
    monkeypatch.setattr(main.settings, "DATABASE_URL", "postgresql://u:p@localhost/neuro")
    monkeypatch.setattr(main, "engine", None)  # si intentara conectarse, fallaría
    main._ensure_db_schema()


def test_usuarios_semilla_se_reparan_al_arrancar(db):
    doctor = db.query(models.User).filter_by(username="samuel@gmail.com").one()
    doctor.role, doctor.is_active, doctor.is_available = "user", False, False
    db.commit()

    main._ensure_seed_users()

    db.refresh(doctor)
    assert (doctor.role, doctor.is_active, doctor.is_available) == ("doctor", True, True)
