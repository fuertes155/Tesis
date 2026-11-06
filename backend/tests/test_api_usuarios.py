"""
Pruebas de integración de usuarios: autenticación, administración por el gestor,
borrado de cuentas y verificación en dos pasos (2FA). BD temporal.
"""
import time
import uuid

import pyotp
import pytest

from app.api.v1 import users as users_api
from app.core.security import create_access_token
from app.infrastructure import models
from app.infrastructure.database import SessionLocal
from conftest import API, CLAVE

pytestmark = pytest.mark.integration


def _correo(prefijo="usuario"):
    return f"{prefijo}_{uuid.uuid4().hex[:10]}@example.com"


def _registrar(client, gestor_headers, rol="doctor", **extra):
    datos = {"username": _correo(rol), "password": CLAVE, "role": rol, **extra}
    r = client.post(f"{API}/users/register", headers=gestor_headers, json=datos)
    assert r.status_code == 201, r.text
    return r.json()


def _login(client, usuario, clave=CLAVE):
    return client.post(f"{API}/users/auth/login", json={"username": usuario, "password": clave})


@pytest.fixture(autouse=True)
def _limpiar_intentos_2fa():
    users_api._2fa_failed_attempts.clear()
    yield
    users_api._2fa_failed_attempts.clear()


# ── Consulta y autenticación ─────────────────────────────────────────────────

def test_listar_usuarios_y_consultar_mi_perfil(client, doctor_headers):
    lista = client.get(f"{API}/users/", headers=doctor_headers)
    assert lista.status_code == 200
    assert "samuel1@gmail.com" in {u["username"] for u in lista.json()}

    yo = client.get(f"{API}/users/me", headers=doctor_headers)
    assert yo.json()["username"] == "samuel@gmail.com"


def test_login_de_usuario_inexistente(client):
    assert _login(client, "nadie@example.com").status_code == 401


def test_login_falla_de_forma_segura_si_la_verificacion_lanza_error(client, monkeypatch):
    def explota(*_):
        raise RuntimeError("hash corrupto")

    monkeypatch.setattr(users_api.security, "verify_password", explota)
    assert _login(client, "samuel@gmail.com").status_code == 401


def test_login_de_cuenta_inactiva_es_rechazado(client, gestor_headers):
    u = _registrar(client, gestor_headers)
    client.put(f"{API}/users/{u['id']}", headers=gestor_headers, json={"is_active": False})
    assert _login(client, u["username"]).status_code == 403


def test_token_sin_usuario_es_rechazado(client):
    token = create_access_token("", "doctor")
    r = client.get(f"{API}/users/me", headers={"Authorization": f"Bearer {token}"})
    assert r.status_code == 401


def test_token_de_usuario_que_ya_no_existe_es_rechazado(client):
    token = create_access_token("borrado@example.com", "doctor")
    r = client.get(f"{API}/users/me", headers={"Authorization": f"Bearer {token}"})
    assert r.status_code == 401


# ── Registro público ─────────────────────────────────────────────────────────

def test_registro_publico_de_paciente_crea_su_perfil_clinico(client, gestor_headers):
    correo = _correo("paciente")
    r = client.post(f"{API}/users/auth/register",
                    json={"username": correo, "password": CLAVE, "role": "user", "full_name": "lucía gómez"})
    assert r.status_code == 201
    assert r.json()["access_token"]

    pacientes = client.get(f"{API}/patients/", headers=gestor_headers, params={"limit": 1000}).json()
    assert "Lucía Gómez" in {p["name"] for p in pacientes}


def test_registro_publico_rechaza_clave_debil_y_correo_repetido(client):
    assert client.post(f"{API}/users/auth/register",
                       json={"username": _correo(), "password": "debil", "role": "doctor"}).status_code == 400
    assert client.post(f"{API}/users/auth/register",
                       json={"username": "SAMUEL@gmail.com", "password": CLAVE, "role": "doctor"}).status_code == 409


def test_registro_publico_concurrente_responde_409(client, monkeypatch):
    """Si otra petición registra el mismo correo entre la validación y el INSERT."""
    monkeypatch.setattr(users_api, "_get_user_by_username_ci", lambda db, u: None)
    r = client.post(f"{API}/users/auth/register",
                    json={"username": "samuel@gmail.com", "password": CLAVE, "role": "doctor"})
    assert r.status_code == 409


# ── Administración (gestor) ──────────────────────────────────────────────────

def test_gestor_no_puede_registrar_un_correo_repetido(client, gestor_headers):
    r = client.post(f"{API}/users/register", headers=gestor_headers,
                    json={"username": "samuel@gmail.com", "password": CLAVE, "role": "doctor"})
    assert r.status_code == 409


def test_registro_por_gestor_concurrente_responde_409(client, gestor_headers, monkeypatch):
    monkeypatch.setattr(users_api, "_get_user_by_username_ci", lambda db, u: None)
    r = client.post(f"{API}/users/register", headers=gestor_headers,
                    json={"username": "samuel@gmail.com", "password": CLAVE, "role": "doctor"})
    assert r.status_code == 409


def test_restablecer_clave_de_usuario_existente(client, gestor_headers):
    u = _registrar(client, gestor_headers)
    r = client.post(f"{API}/users/reset", headers=gestor_headers,
                    json={"username": u["username"], "password": "NuevaClave9"})
    assert r.status_code == 200
    assert _login(client, u["username"], "NuevaClave9").status_code == 200
    assert _login(client, u["username"], CLAVE).status_code == 401


def test_restablecer_clave_de_usuario_inexistente_lo_crea(client, gestor_headers):
    correo = _correo("nuevo")
    r = client.post(f"{API}/users/reset", headers=gestor_headers,
                    json={"username": correo, "password": CLAVE, "role": "gestor"})
    assert r.status_code == 200
    assert r.json()["role"] == "gestor"
    assert _login(client, correo).status_code == 200


def test_restablecer_clave_debil_o_concurrente(client, gestor_headers, monkeypatch):
    assert client.post(f"{API}/users/reset", headers=gestor_headers,
                       json={"username": _correo(), "password": "123"}).status_code == 400
    monkeypatch.setattr(users_api, "_get_user_by_username_ci", lambda db, u: None)
    r = client.post(f"{API}/users/reset", headers=gestor_headers,
                    json={"username": "samuel@gmail.com", "password": CLAVE})
    assert r.status_code == 409


def test_cambiar_disponibilidad_del_doctor(client, doctor_headers, gestor_headers):
    u = _registrar(client, gestor_headers)
    r = client.put(f"{API}/users/{u['id']}/availability", headers=doctor_headers, params={"is_available": False})
    assert r.status_code == 200
    assert r.json()["is_available"] is False
    assert client.put(f"{API}/users/999999/availability", headers=doctor_headers,
                      params={"is_available": True}).status_code == 404


def test_editar_usuario(client, gestor_headers):
    u = _registrar(client, gestor_headers)
    nuevo_correo = _correo("editado")
    r = client.put(f"{API}/users/{u['id']}", headers=gestor_headers, json={
        "username": nuevo_correo, "full_name": "  ana   ríos ", "role": "gestor",
        "is_active": True, "is_available": False,
    })
    assert r.status_code == 200, r.text
    cuerpo = r.json()
    assert cuerpo["username"] == nuevo_correo
    assert cuerpo["full_name"] == "Ana Ríos"
    assert cuerpo["role"] == "gestor"
    assert cuerpo["is_available"] is False

    with SessionLocal() as db:  # el cambio de rol crea el perfil de administrador
        assert db.query(models.Administrator).filter_by(user_id=u["id"]).count() == 1


def test_editar_usuario_inexistente_o_con_correo_repetido(client, gestor_headers):
    assert client.put(f"{API}/users/999999", headers=gestor_headers, json={"full_name": "X"}).status_code == 404
    u = _registrar(client, gestor_headers)
    r = client.put(f"{API}/users/{u['id']}", headers=gestor_headers, json={"username": "samuel@gmail.com"})
    assert r.status_code == 409


def test_gestor_no_puede_eliminarse_a_si_mismo_ni_a_inexistentes(client, gestor_headers):
    yo = client.get(f"{API}/users/me", headers=gestor_headers).json()
    assert client.delete(f"{API}/users/{yo['id']}", headers=gestor_headers).status_code == 400
    assert client.delete(f"{API}/users/999999", headers=gestor_headers).status_code == 404


def test_borrar_doctor_deja_sus_pacientes_sin_asignar(client, gestor_headers):
    doctor = _registrar(client, gestor_headers)
    paciente = client.post(f"{API}/patients/", headers=gestor_headers,
                           json={"name": "Paciente Asignado", "age": 60, "doctor_id": doctor["id"]}).json()

    assert client.delete(f"{API}/users/{doctor['id']}", headers=gestor_headers).status_code == 200
    assert _login(client, doctor["username"]).status_code == 401
    assert client.get(f"{API}/patients/{paciente['id']}", headers=gestor_headers).json()["doctor_id"] is None


def test_borrar_cuenta_de_paciente_elimina_sus_datos_clinicos(client, gestor_headers):
    correo = _correo("paciente")
    client.post(f"{API}/users/auth/register",
                json={"username": correo, "password": CLAVE, "role": "user", "full_name": "Pedro Pérez"})
    with SessionLocal() as db:
        usuario = db.query(models.User).filter_by(username=correo).one()
        paciente = db.query(models.Patient).filter_by(user_id=usuario.id).one()
        uid, pid = usuario.id, paciente.id

    sesion = client.post(f"{API}/sessions/", headers=gestor_headers,
                         json={"patient_id": pid, "date": "2026-11-04", "status": "completed"}).json()
    client.post(f"{API}/sessions/results", headers=gestor_headers,
                json={"patient_id": pid, "session_id": sesion["id"], "game_name": "reaction", "score": 70})

    assert client.delete(f"{API}/users/{uid}", headers=gestor_headers).status_code == 200
    with SessionLocal() as db:
        assert db.query(models.Patient).filter_by(id=pid).count() == 0
        assert db.query(models.Session).filter_by(patient_id=pid).count() == 0
        assert db.query(models.Result).filter_by(patient_id=pid).count() == 0


# ── Verificación en dos pasos (2FA) ──────────────────────────────────────────

def _usuario_con_2fa(client, gestor_headers, secreto: str | None):
    u = _registrar(client, gestor_headers)
    with SessionLocal() as db:
        fila = db.get(models.User, u["id"])
        fila.is_2fa_enabled = True
        fila.totp_secret = secreto
        db.commit()
    return u["username"]


def _verificar(client, usuario, codigo):
    return client.post(f"{API}/users/verify-2fa", json={"username": usuario, "code": codigo})


def test_2fa_valida_los_datos_obligatorios(client):
    assert client.post(f"{API}/users/verify-2fa", json={"code": "123456"}).status_code == 400
    assert client.post(f"{API}/users/verify-2fa", json={"username": "samuel@gmail.com"}).status_code == 400
    assert _verificar(client, "nadie@example.com", "123456").status_code == 404


def test_2fa_no_activado_deja_continuar(client, gestor_headers):
    u = _registrar(client, gestor_headers)
    r = _verificar(client, u["username"], "000000")
    assert r.status_code == 200
    assert "not enabled" in r.json()["message"]


def test_2fa_activado_sin_secreto_es_un_error_de_configuracion(client, gestor_headers):
    usuario = _usuario_con_2fa(client, gestor_headers, secreto=None)
    assert _verificar(client, usuario, "123456").status_code == 400


def test_2fa_acepta_el_codigo_correcto_y_rechaza_el_incorrecto(client, gestor_headers):
    secreto = pyotp.random_base32()
    usuario = _usuario_con_2fa(client, gestor_headers, secreto)
    assert _verificar(client, usuario, "000000" if pyotp.TOTP(secreto).now() != "000000" else "111111").status_code == 401
    assert _verificar(client, usuario, pyotp.TOTP(secreto).now()).json() == {"status": "success"}


def test_2fa_bloquea_tras_cinco_intentos_y_desbloquea_al_vencer(client, gestor_headers):
    secreto = pyotp.random_base32()
    usuario = _usuario_con_2fa(client, gestor_headers, secreto)
    incorrecto = "000000" if pyotp.TOTP(secreto).now() != "000000" else "111111"

    for _ in range(5):
        assert _verificar(client, usuario, incorrecto).status_code == 401
    assert _verificar(client, usuario, pyotp.TOTP(secreto).now()).status_code == 429  # bloqueado

    users_api._2fa_failed_attempts[usuario]["lockout_until"] = time.time() - 1  # vence el bloqueo
    assert _verificar(client, usuario, pyotp.TOTP(secreto).now()).status_code == 200
