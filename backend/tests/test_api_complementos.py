"""
Pruebas de integración complementarias (BD temporal): sesiones, asignación de
doctor, búsqueda de paciente en reportes, salud del servicio y middleware.
Las ramas defensivas se prueban con inyección de fallos (monkeypatch).
"""
import uuid

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Query
from sqlalchemy.orm import Session as OrmSession

import main
from app.api.v1 import patients as patients_api
from app.infrastructure import models
from conftest import API

pytestmark = pytest.mark.integration


def _sesion(client, headers, paciente_id, **extra):
    return client.post(f"{API}/sessions/", headers=headers, json={
        "patient_id": paciente_id, "date": "2026-11-04", "status": "completed", **extra,
    })


# ── Sesiones ─────────────────────────────────────────────────────────────────

def test_listar_contar_y_consultar_sesiones_de_un_paciente(client, doctor_headers, crear_paciente):
    paciente = crear_paciente()
    ids = [_sesion(client, doctor_headers, paciente["id"]).json()["id"] for _ in range(3)]

    lista = client.get(f"{API}/sessions/", headers=doctor_headers, params={"patient_id": paciente["id"]})
    assert sorted(s["id"] for s in lista.json()) == sorted(ids)

    total = client.get(f"{API}/sessions/count", headers=doctor_headers, params={"patient_id": paciente["id"]})
    assert total.json() == {"count": 3}
    assert client.get(f"{API}/sessions/count", headers=doctor_headers).json()["count"] >= 3
    assert client.get(f"{API}/sessions/", headers=doctor_headers).status_code == 200

    una = client.get(f"{API}/sessions/{ids[0]}", headers=doctor_headers)
    assert una.json()["patient_id"] == paciente["id"]


def test_resultado_con_sesion_inexistente_devuelve_404(client, doctor_headers, crear_paciente):
    r = client.post(f"{API}/sessions/results", headers=doctor_headers, json={
        "patient_id": crear_paciente()["id"], "session_id": 999999, "game_name": "reaction", "score": 70,
    })
    assert r.status_code == 404


def test_sesion_concurrente_con_mismo_external_id_devuelve_la_existente(client, doctor_headers,
                                                                        crear_paciente, monkeypatch):
    paciente = crear_paciente()
    externo = f"s-{uuid.uuid4().hex}"
    original = _sesion(client, doctor_headers, paciente["id"], external_id=externo).json()

    # Simula la carrera: la búsqueda previa no ve la sesión y el INSERT choca con el índice único.
    real_first = Query.first
    estado = {"omitida": False}

    def first(self):
        entidad = self.column_descriptions[0]["entity"]
        if entidad is models.Session and not estado["omitida"]:
            estado["omitida"] = True
            return None
        return real_first(self)

    monkeypatch.setattr(Query, "first", first)
    r = _sesion(client, doctor_headers, paciente["id"], external_id=externo)
    assert r.status_code == 200
    assert r.json()["id"] == original["id"]


def test_error_de_integridad_sin_external_id_se_propaga(doctor_headers, crear_paciente, monkeypatch):
    paciente = crear_paciente()
    real_commit = OrmSession.commit
    estado = {"fallado": False}

    def commit(self):
        if not estado["fallado"]:
            estado["fallado"] = True
            raise IntegrityError("INSERT", {}, Exception("restricción"))
        return real_commit(self)

    monkeypatch.setattr(OrmSession, "commit", commit)
    cliente = TestClient(main.app, raise_server_exceptions=False)
    assert _sesion(cliente, doctor_headers, paciente["id"]).status_code == 500


# ── Pacientes ────────────────────────────────────────────────────────────────

def test_listar_pacientes(client, doctor_headers, crear_paciente):
    paciente = crear_paciente()
    lista = client.get(f"{API}/patients/", headers=doctor_headers, params={"limit": 1000})
    assert paciente["id"] in {p["id"] for p in lista.json()}


def test_asignar_doctor_a_paciente(client, gestor_headers, crear_paciente):
    paciente = crear_paciente()
    doctor = client.get(f"{API}/users/", headers=gestor_headers).json()
    doctor_id = next(u["id"] for u in doctor if u["username"] == "samuel@gmail.com")
    gestor_id = next(u["id"] for u in doctor if u["username"] == "samuel1@gmail.com")

    url = f"{API}/patients/{paciente['id']}/assign-doctor"
    ok = client.put(url, headers=gestor_headers, params={"doctor_id": doctor_id})
    assert ok.status_code == 200
    assert ok.json()["doctor_id"] == doctor_id
    # Un usuario que no es doctor, o un paciente inexistente, no se pueden asignar.
    assert client.put(url, headers=gestor_headers, params={"doctor_id": gestor_id}).status_code == 404
    assert client.put(f"{API}/patients/999999/assign-doctor", headers=gestor_headers,
                      params={"doctor_id": doctor_id}).status_code == 404


def test_actualizar_o_borrar_paciente_inexistente(client, doctor_headers, gestor_headers):
    assert client.put(f"{API}/patients/999999", headers=doctor_headers, json={"age": 50}).status_code == 404
    assert client.delete(f"{API}/patients/999999", headers=gestor_headers).status_code == 404


def test_borrado_que_falla_en_el_servicio_responde_404(client, gestor_headers, crear_paciente, monkeypatch):
    paciente = crear_paciente()
    monkeypatch.setattr(patients_api.PatientService, "delete_patient", staticmethod(lambda db, patient_id: False))
    assert client.delete(f"{API}/patients/{paciente['id']}", headers=gestor_headers).status_code == 404


# ── Reportes: a qué paciente se asocian ──────────────────────────────────────

def _reporte(client, paciente_id, nombre):
    return client.post("/evaluacion/generar-reporte", json={
        "paciente_id": paciente_id, "nombre_paciente": nombre, "edad_paciente": 70,
        "fecha_evaluacion": "2026-11-04", "profesional": "Dr. Prueba",
        "pruebas": [{"nombre_prueba": "Memoria Visual", "porcentaje_obtenido": 60, "tiempo_segundos": 60}],
    })


def test_reporte_se_asocia_por_id_numerico(client, doctor_headers, crear_paciente):
    paciente = crear_paciente()
    _reporte(client, str(paciente["id"]), "Otro Nombre")
    lista = client.get(f"{API}/evaluacion/reportes/{paciente['id']}", headers=doctor_headers).json()
    assert len(lista) == 1


def test_reporte_se_asocia_por_nombre_si_no_hay_documento_ni_id(client, doctor_headers, crear_paciente):
    nombre = f"Paciente {uuid.uuid4().hex[:6]}"
    paciente = crear_paciente(name=nombre)
    _reporte(client, "PAC-SIN-DOCUMENTO", nombre)
    lista = client.get(f"{API}/evaluacion/reportes/{paciente['id']}", headers=doctor_headers).json()
    assert [x["nombre_paciente"] for x in lista] == [nombre]


def test_reporte_sin_paciente_registrado_queda_sin_asociar(client):
    r = _reporte(client, "999999", "Nadie Registrado")
    assert r.status_code == 200
    assert client.get("/evaluacion/reportes/999999").json()[0]["nombre_paciente"] == "Nadie Registrado"


# ── Salud del servicio y middleware ──────────────────────────────────────────

def test_raiz_y_readiness(client):
    assert "Welcome" in client.get("/").json()["message"]
    assert client.get("/readiness").json() == {"ready": True}


class _SesionRota:
    def execute(self, *_):
        raise RuntimeError("BD caída")

    def close(self):
        pass


def test_health_y_readiness_reportan_bd_caida(client, monkeypatch):
    monkeypatch.setattr(main, "SessionLocal", _SesionRota)
    salud = client.get("/health").json()
    assert salud["status"] == "degraded"
    assert salud["database"] == "error"
    assert client.get("/readiness").status_code == 503


def test_middleware_agrega_cabeceras_de_tiempo_y_respeta_proxy(client):
    r = client.get("/health", headers={"X-Forwarded-For": "203.0.113.7, 10.0.0.1"})
    assert r.headers["X-Response-Time"].endswith("ms")
    assert "X-Request-Id" in r.headers
    assert int(r.headers["X-RateLimit-Remaining"]) >= 0


def test_limite_de_peticiones_responde_429(client, monkeypatch):
    monkeypatch.setattr(main, "RATE_LIMIT_MAX", 2)
    codigos = [client.get("/", headers={"X-Real-IP": "198.51.100.9"}).status_code for _ in range(3)]
    assert codigos == [200, 200, 429]


def test_error_no_controlado_responde_500_y_queda_registrado(doctor_headers, monkeypatch, caplog):
    def explota(*_, **__):
        raise RuntimeError("fallo inesperado")

    monkeypatch.setattr(patients_api.PatientService, "get_patients", staticmethod(explota))
    cliente = TestClient(main.app, raise_server_exceptions=False)
    assert cliente.get(f"{API}/patients/", headers=doctor_headers).status_code == 500
    assert any("EXCEPTION" in m for m in caplog.messages)
