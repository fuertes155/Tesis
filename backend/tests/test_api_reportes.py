"""Pruebas de integración de los informes neuropsicológicos (BD temporal)."""
import time

import pytest

from conftest import API

pytestmark = pytest.mark.integration


def _solicitud(paciente, **cambios):
    datos = {
        "paciente_id": paciente["document_id"],
        "nombre_paciente": paciente["name"],
        "edad_paciente": paciente["age"],
        "fecha_evaluacion": "2026-11-04",
        "profesional": "Dr. Prueba",
        "diagnostico_paciente": paciente.get("diagnosis"),
        "pruebas": [
            {"nombre_prueba": "Memoria Visual", "porcentaje_obtenido": 50, "tiempo_segundos": 60,
             "metricas": {"level": 2, "items_to_remember": 4, "avg_selection_ms": 2300}},
            {"nombre_prueba": "Atención Sostenida", "porcentaje_obtenido": 74, "tiempo_segundos": 30,
             "metricas": {"avg_ms": 540, "best_ms": 430, "too_early": 0}},
            {"nombre_prueba": "Funciones Ejecutivas (Stroop)", "porcentaje_obtenido": 66, "tiempo_segundos": 30,
             "metricas": {"correct": 16, "wrong": 4, "avg_ms": 640}},
            {"nombre_prueba": "Fluidez Verbal", "porcentaje_obtenido": 75, "tiempo_segundos": 62,
             "metricas": {"count": 10, "prompt": "Letra: M", "duration_s": 60}},
        ],
    }
    datos.update(cambios)
    return datos


def test_generar_reporte_devuelve_informe_completo(client, crear_paciente):
    paciente = crear_paciente(name="Ana Ríos", age=75)
    r = client.post("/evaluacion/generar-reporte", json=_solicitud(paciente))
    assert r.status_code == 200, r.text
    cuerpo = r.json()
    assert cuerpo["nombre_paciente"] == "Ana Ríos"
    assert len(cuerpo["pruebas"]) == 4
    for seccion in ("MOTIVO DE EVALUACIÓN:", "IMPRESIÓN DIAGNÓSTICA:", "RECOMENDACIONES:", "LIMITACIONES:"):
        assert seccion in cuerpo["reporte"]
    assert "Deterioro cognitivo leve (DCL) probable, subtipo amnésico de dominio múltiple" in cuerpo["reporte"]


def test_reporte_queda_asociado_al_paciente_por_documento(client, doctor_headers, crear_paciente):
    paciente = crear_paciente()
    creado = client.post("/evaluacion/generar-reporte", json=_solicitud(paciente)).json()

    por_id = client.get(f"{API}/evaluacion/reportes/{paciente['id']}", headers=doctor_headers).json()
    por_documento = client.get(f"/evaluacion/reportes/{paciente['document_id']}").json()
    assert [x["id"] for x in por_id] == [creado["id"]]
    assert [x["id"] for x in por_documento] == [creado["id"]]


def test_reportes_de_un_paciente_van_del_mas_reciente_al_mas_antiguo(client, doctor_headers, crear_paciente):
    paciente = crear_paciente()
    primero = client.post("/evaluacion/generar-reporte", json=_solicitud(paciente, fecha_evaluacion="2026-06-01")).json()
    time.sleep(0.02)
    segundo = client.post("/evaluacion/generar-reporte", json=_solicitud(paciente)).json()
    lista = client.get(f"{API}/evaluacion/reportes/{paciente['id']}", headers=doctor_headers).json()
    assert [x["id"] for x in lista] == [segundo["id"], primero["id"]]


def test_listado_general_de_reportes_exige_autenticacion(client):
    assert client.get(f"{API}/evaluacion/reportes").status_code == 401


def test_listado_general_incluye_reportes_de_varios_pacientes(client, doctor_headers, crear_paciente):
    a, b = crear_paciente(name="Paciente A"), crear_paciente(name="Paciente B")
    ra = client.post("/evaluacion/generar-reporte", json=_solicitud(a)).json()
    time.sleep(0.02)
    rb = client.post("/evaluacion/generar-reporte", json=_solicitud(b)).json()
    r = client.get(f"{API}/evaluacion/reportes", headers=doctor_headers)
    assert r.status_code == 200
    ids = [x["id"] for x in r.json()]
    assert {ra["id"], rb["id"]} <= set(ids)
    assert ids.index(rb["id"]) < ids.index(ra["id"])  # el más reciente primero


def test_solicitud_invalida_es_rechazada(client, crear_paciente):
    r = client.post("/evaluacion/generar-reporte", json=_solicitud(crear_paciente(), pruebas=[]))
    assert r.status_code == 422


def test_borrar_paciente_conserva_sus_reportes(client, gestor_headers, crear_paciente):
    paciente = crear_paciente()
    creado = client.post("/evaluacion/generar-reporte", json=_solicitud(paciente)).json()
    assert client.delete(f"{API}/patients/{paciente['id']}", headers=gestor_headers).status_code == 200

    # El informe clínico se conserva (ON DELETE SET NULL) y se sigue encontrando por documento.
    por_documento = client.get(f"/evaluacion/reportes/{paciente['document_id']}").json()
    assert [x["id"] for x in por_documento] == [creado["id"]]
