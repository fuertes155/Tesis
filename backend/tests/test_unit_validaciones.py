"""Pruebas unitarias de los esquemas de entrada (Pydantic): normalización y saneamiento."""
from datetime import date

import pytest
from pydantic import ValidationError

from app.domain import entities
from app.routers.reportes import EvaluacionCognitivaSchema


# ── Usuarios ──────────────────────────────────────────────────────────────────

def test_usuario_normaliza_el_correo_a_minusculas_y_sin_espacios():
    u = entities.UserCreate(username="  Ana.Perez@Example.COM ", password="Password123!")
    assert u.username == "ana.perez@example.com"


def test_usuario_capitaliza_el_nombre_completo():
    u = entities.UserCreate(username="a@b.co", password="x", full_name="  maría   fernanda ríos ")
    assert u.full_name == "María Fernanda Ríos"


def test_usuario_con_nombre_vacio_queda_sin_nombre():
    assert entities.UserCreate(username="a@b.co", password="x", full_name="   ").full_name is None


def test_usuario_rol_por_defecto_es_doctor():
    assert entities.UserCreate(username="a@b.co", password="x").role == "doctor"


# ── Pacientes y sesiones (protección contra XSS) ─────────────────────────────

def test_paciente_escapa_html_en_nombre_y_diagnostico():
    p = entities.PatientCreate(
        name="<script>alert('x')</script>Ana",
        age=40,
        diagnosis="<b>DCL</b>",
    )
    assert "<script>" not in p.name
    assert "&lt;script&gt;" in p.name
    assert p.diagnosis == "&lt;b&gt;DCL&lt;/b&gt;"


def test_paciente_recorta_espacios():
    p = entities.PatientCreate(name="  Ana Ríos  ", age=40, phone=" 3001234567 ")
    assert p.name == "Ana Ríos"
    assert p.phone == "3001234567"


def test_paciente_requiere_nombre_y_edad():
    with pytest.raises(ValidationError):
        entities.PatientCreate(name="Ana")


def test_actualizacion_de_paciente_convierte_vacios_en_none():
    assert entities.PatientUpdate(diagnosis="   ").diagnosis is None


def test_sesion_escapa_html_en_las_notas():
    s = entities.SessionCreate(patient_id=1, date="2026-11-06", notes='<img src=x onerror="alert(1)">')
    assert "<img" not in s.notes


# ── Solicitud de reporte cognitivo ───────────────────────────────────────────

def _evaluacion(**cambios):
    datos = {
        "paciente_id": "PAC-1",
        "nombre_paciente": "Ana Ríos",
        "edad_paciente": 70,
        "fecha_evaluacion": "2026-11-04",
        "profesional": "Dr. Prueba",
        "pruebas": [{"nombre_prueba": "Memoria Visual", "porcentaje_obtenido": 50, "tiempo_segundos": 60}],
    }
    datos.update(cambios)
    return EvaluacionCognitivaSchema(**datos)


def test_evaluacion_valida_se_acepta():
    e = _evaluacion()
    assert e.fecha_evaluacion == date(2026, 11, 4)
    assert e.pruebas[0].porcentaje_obtenido == 50


@pytest.mark.parametrize(
    "cambios",
    [
        {"pruebas": []},                                                    # sin pruebas
        {"edad_paciente": 121},                                             # edad fuera de rango
        {"edad_paciente": -1},
        {"nombre_paciente": "   "},                                         # nombre vacío
        {"profesional": ""},
        {"fecha_evaluacion": "06/11/2026"},                                 # formato de fecha
        {"pruebas": [{"nombre_prueba": "Memoria", "porcentaje_obtenido": 101, "tiempo_segundos": 1}]},
        {"pruebas": [{"nombre_prueba": "Memoria", "porcentaje_obtenido": 50, "tiempo_segundos": -1}]},
        {"pruebas": [{"nombre_prueba": " ", "porcentaje_obtenido": 50, "tiempo_segundos": 1}]},
    ],
)
def test_evaluacion_invalida_se_rechaza(cambios):
    with pytest.raises(ValidationError):
        _evaluacion(**cambios)


def test_evaluacion_convierte_textos_opcionales_vacios_en_none():
    e = _evaluacion(diagnostico_paciente="   ", institucion=" Clínica ")
    assert e.diagnostico_paciente is None
    assert e.institucion == "Clínica"


# ── Actualizaciones y casos límite del saneamiento ───────────────────────────

def test_actualizacion_de_usuario_normaliza_correo_y_nombre():
    u = entities.UserUpdate(username="  Ana@Example.COM ", full_name=" ana  ríos ")
    assert (u.username, u.full_name) == ("ana@example.com", "Ana Ríos")
    vacio = entities.UserUpdate(username=None, full_name="   ")
    assert (vacio.username, vacio.full_name) == (None, None)
    assert entities.UserUpdate(full_name=None).full_name is None


def test_paciente_con_texto_solo_de_espacios_queda_vacio():
    assert entities.PatientCreate(name="Ana", age=40, diagnosis="    ").diagnosis == ""


def test_actualizacion_de_paciente_deja_pasar_valores_no_texto():
    assert entities.PatientUpdate(age=55, diagnosis=None).age == 55


def test_actualizacion_de_sesion_escapa_html():
    s = entities.SessionUpdate(notes="<b>nota</b>", status=None)
    assert s.notes == "&lt;b&gt;nota&lt;/b&gt;"
    assert s.status is None


def test_evaluacion_rechaza_nombre_de_prueba_de_solo_espacios():
    with pytest.raises(ValidationError, match="obligatorio"):
        _evaluacion(pruebas=[{"nombre_prueba": "     ", "porcentaje_obtenido": 50, "tiempo_segundos": 1}])


def test_evaluacion_acepta_opcionales_nulos_explicitos():
    assert _evaluacion(documento_paciente=None).documento_paciente is None
