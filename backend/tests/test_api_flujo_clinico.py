"""
Pruebas de integración de la API (BD temporal): autenticación, permisos por rol
y flujo clínico paciente → sesión → resultados.
"""
import time
import uuid

import pytest

from conftest import API, CLAVE

pytestmark = pytest.mark.integration


# ── Autenticación ────────────────────────────────────────────────────────────

def test_health(client):
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json()["status"] in {"healthy", "degraded"}


def test_login_correcto_devuelve_token_y_usuario(client):
    r = client.post(f"{API}/users/auth/login", json={"username": "samuel@gmail.com", "password": CLAVE})
    assert r.status_code == 200
    cuerpo = r.json()
    assert cuerpo["token_type"] == "bearer"
    assert cuerpo["access_token"]
    assert cuerpo["user"]["role"] == "doctor"


def test_login_con_clave_incorrecta_es_rechazado(client):
    r = client.post(f"{API}/users/auth/login", json={"username": "samuel@gmail.com", "password": "Incorrecta1"})
    assert r.status_code == 401


def test_rutas_protegidas_exigen_token(client):
    assert client.get(f"{API}/patients/").status_code == 401
    assert client.get(f"{API}/patients/", headers={"Authorization": "Bearer token-falso"}).status_code == 401


# ── Gestión de usuarios ──────────────────────────────────────────────────────

def test_gestor_registra_doctor_y_este_puede_iniciar_sesion(client, gestor_headers):
    correo = f"doctor_{uuid.uuid4().hex[:8]}@example.com"
    r = client.post(f"{API}/users/register", headers=gestor_headers,
                    json={"username": correo, "password": CLAVE, "role": "doctor", "full_name": "doctor de prueba"})
    assert r.status_code == 201, r.text
    assert r.json()["full_name"] == "Doctor De Prueba"

    login = client.post(f"{API}/users/auth/login", json={"username": correo, "password": CLAVE})
    assert login.status_code == 200


def test_registro_con_clave_debil_es_rechazado(client, gestor_headers):
    r = client.post(f"{API}/users/register", headers=gestor_headers,
                    json={"username": f"x_{uuid.uuid4().hex[:8]}@example.com", "password": "123", "role": "doctor"})
    assert r.status_code == 400


def test_doctor_no_puede_registrar_usuarios(client, doctor_headers):
    r = client.post(f"{API}/users/register", headers=doctor_headers,
                    json={"username": f"x_{uuid.uuid4().hex[:8]}@example.com", "password": CLAVE, "role": "doctor"})
    assert r.status_code == 403


def test_registro_publico_no_permite_crear_gestores(client):
    r = client.post(f"{API}/users/auth/register",
                    json={"username": f"x_{uuid.uuid4().hex[:8]}@example.com", "password": CLAVE, "role": "gestor"})
    assert r.status_code == 403


# ── Pacientes ────────────────────────────────────────────────────────────────

def test_doctor_crea_y_consulta_paciente(client, doctor_headers, crear_paciente):
    paciente = crear_paciente(name="ana  ríos", diagnosis="DCL amnésico")
    r = client.get(f"{API}/patients/{paciente['id']}", headers=doctor_headers)
    assert r.status_code == 200
    assert r.json()["diagnosis"] == "DCL amnésico"
    assert r.json()["birth_date"] == "1956-03-14"


def test_paciente_inexistente_devuelve_404(client, doctor_headers):
    assert client.get(f"{API}/patients/999999", headers=doctor_headers).status_code == 404


def test_actualizar_paciente(client, doctor_headers, crear_paciente):
    paciente = crear_paciente()
    r = client.put(f"{API}/patients/{paciente['id']}", headers=doctor_headers, json={"diagnosis": "Parkinson"})
    assert r.status_code == 200
    assert r.json()["diagnosis"] == "Parkinson"


def test_solo_el_gestor_puede_borrar_pacientes(client, doctor_headers, gestor_headers, crear_paciente):
    paciente = crear_paciente()
    assert client.delete(f"{API}/patients/{paciente['id']}", headers=doctor_headers).status_code == 403
    assert client.delete(f"{API}/patients/{paciente['id']}", headers=gestor_headers).status_code == 200
    assert client.get(f"{API}/patients/{paciente['id']}", headers=doctor_headers).status_code == 404


# ── Sesiones y resultados ────────────────────────────────────────────────────

def _sesion(client, headers, paciente_id, **extra):
    return client.post(f"{API}/sessions/", headers=headers, json={
        "patient_id": paciente_id, "date": "2026-11-04T09:30:00", "status": "completed",
        "notes": "Batería de pruebas finalizada.", "duration_ms": 240000, **extra,
    })


def _resultado(client, headers, paciente_id, juego, puntaje, sesion_id=None):
    return client.post(f"{API}/sessions/results", headers=headers, json={
        "patient_id": paciente_id, "game_name": juego, "score": puntaje,
        "details": {"Memoria": puntaje}, "metrics": {"level": 3}, "session_id": sesion_id,
    })


def test_sesion_para_paciente_inexistente_devuelve_404(client, doctor_headers):
    assert _sesion(client, doctor_headers, 999999).status_code == 404


def test_sesion_con_external_id_repetido_no_se_duplica(client, doctor_headers, crear_paciente):
    paciente = crear_paciente()
    externo = f"s-{uuid.uuid4().hex}"
    primera = _sesion(client, doctor_headers, paciente["id"], external_id=externo)
    segunda = _sesion(client, doctor_headers, paciente["id"], external_id=externo)
    assert primera.status_code == 200
    assert segunda.json()["id"] == primera.json()["id"]


def test_flujo_paciente_sesion_resultados(client, doctor_headers, crear_paciente):
    paciente = crear_paciente()
    sesion = _sesion(client, doctor_headers, paciente["id"])
    assert sesion.status_code == 200

    for juego, puntaje in [("visual_memory", 50), ("reaction", 74), ("stroop", 66), ("fluency", 75)]:
        r = _resultado(client, doctor_headers, paciente["id"], juego, puntaje, sesion.json()["id"])
        assert r.status_code == 201, r.text
        time.sleep(0.02)  # marcas de tiempo distintas para comprobar el orden

    ultimos = client.get(f"{API}/sessions/results/latest", headers=doctor_headers,
                         params={"patient_id": paciente["id"]})
    assert ultimos.status_code == 200
    assert [x["game_name"] for x in ultimos.json()] == ["fluency", "stroop", "reaction", "visual_memory"]

    limitados = client.get(f"{API}/sessions/results/latest", headers=doctor_headers,
                           params={"patient_id": paciente["id"], "limit": 2})
    assert len(limitados.json()) == 2


def test_borrar_paciente_elimina_sesiones_y_resultados(client, doctor_headers, gestor_headers, crear_paciente):
    paciente = crear_paciente()
    sesion = _sesion(client, doctor_headers, paciente["id"]).json()
    _resultado(client, doctor_headers, paciente["id"], "visual_memory", 60, sesion["id"])

    assert client.delete(f"{API}/patients/{paciente['id']}", headers=gestor_headers).status_code == 200

    assert client.get(f"{API}/sessions/{sesion['id']}", headers=doctor_headers).status_code == 404
    restantes = client.get(f"{API}/sessions/results/latest", headers=doctor_headers,
                           params={"patient_id": paciente["id"]})
    assert restantes.json() == []
