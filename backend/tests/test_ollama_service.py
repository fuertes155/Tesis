import asyncio

import httpx
import pytest

from app.ollama_service import (
    MAX_TOKENS_REPORTE,
    TIMEOUT_SEGUNDOS,
    construir_prompt,
    generar_reporte_cognitivo,
    generar_reporte_local,
)


def test_construir_prompt_es_razonablemente_corto():
    datos = {
        "paciente_id": "P001",
        "nombre_paciente": "Ana",
        "edad_paciente": 45,
        "fecha_evaluacion": "2026-05-28",
        "profesional": "Dr. Test",
        "pruebas": [
            {
                "nombre_prueba": "Memoria Visual",
                "porcentaje_obtenido": 35,
                "tiempo_segundos": 120,
            },
            {
                "nombre_prueba": "Atención Sostenida",
                "porcentaje_obtenido": 60,
                "tiempo_segundos": 90,
            },
        ],
    }

    prompt = construir_prompt(datos)

    assert len(prompt) < 8000
    assert "Nombre completo: Ana" in prompt


def test_max_tokens_reporte_usa_presupuesto_reducido():
    assert MAX_TOKENS_REPORTE == 1300


def test_timeout_reporte_es_corto_para_activar_respaldo():
    assert TIMEOUT_SEGUNDOS == 90.0


def test_construir_prompt_resume_pruebas_para_evitar_sobrecarga():
    datos = {
        "paciente_id": "P001",
        "nombre_paciente": "Ana",
        "edad_paciente": 45,
        "fecha_evaluacion": "2026-05-28",
        "profesional": "Dr. Test",
        "pruebas": [
            {
                "nombre_prueba": f"Prueba {indice}",
                "porcentaje_obtenido": 50 + indice,
                "tiempo_segundos": 60 + indice,
            }
            for indice in range(20)
        ],
    }

    prompt = construir_prompt(datos)

    assert len(prompt) < 8000


def test_generar_reporte_cognitivo_usa_respaldo_local_si_ollama_falla(monkeypatch):
    class FakeClient:
        async def __aenter__(self):
            return self

        async def __aexit__(self, exc_type, exc, tb):
            return False

        async def post(self, url, json):
            raise httpx.TimeoutException("timeout")

    monkeypatch.setattr("app.ollama_service.httpx.AsyncClient", lambda *args, **kwargs: FakeClient())

    datos = {
        "paciente_id": "P001",
        "nombre_paciente": "Ana",
        "edad_paciente": 45,
        "fecha_evaluacion": "2026-05-28",
        "profesional": "Dr. Test",
        "pruebas": [
            {
                "nombre_prueba": "Memoria Visual",
                "porcentaje_obtenido": 35,
                "tiempo_segundos": 120,
            }
        ],
    }

    reporte = asyncio.run(generar_reporte_cognitivo(datos))

    assert reporte is not None and "MOTIVO DE EVALUACIÓN:" in reporte
    assert "Ana" in reporte
    assert "Memoria: Rendimiento por debajo de lo esperado (35.0%)." in reporte


def test_generar_reporte_cognitivo_usa_respaldo_local_al_exceder_wait_for(monkeypatch):
    async def colgar(*args, **kwargs):
        raise asyncio.TimeoutError("timeout")

    monkeypatch.setattr("app.ollama_service._generar_reporte_ollama", colgar)

    datos = {
        "paciente_id": "P001",
        "nombre_paciente": "Ana",
        "edad_paciente": 45,
        "fecha_evaluacion": "2026-05-28",
        "profesional": "Dr. Test",
        "pruebas": [
            {
                "nombre_prueba": "Memoria Visual",
                "porcentaje_obtenido": 35,
                "tiempo_segundos": 120,
            }
        ],
    }

    reporte = asyncio.run(generar_reporte_cognitivo(datos))

    assert reporte is not None and "MOTIVO DE EVALUACIÓN:" in reporte
    assert "Ana" in reporte


def test_reporte_local_tiene_estructura_clinica_y_lee_metricas_de_los_juegos():
    datos = {
        "paciente_id": "P001",
        "nombre_paciente": "Ana",
        "edad_paciente": 67,
        "fecha_evaluacion": "2026-05-28",
        "profesional": "Dr. Test",
        "diagnostico_paciente": "Depresión",
        "pruebas": [
            {"nombre_prueba": "Memoria Visual", "porcentaje_obtenido": 35, "tiempo_segundos": 120,
             "metricas": {"level": 3, "items_to_remember": 5, "avg_selection_ms": 740.4}},
            {"nombre_prueba": "Atención Sostenida", "porcentaje_obtenido": 55, "tiempo_segundos": 90,
             "metricas": {"avg_ms": 612.3, "best_ms": 300, "too_early": 2}},
            {"nombre_prueba": "Fluidez Verbal", "porcentaje_obtenido": 30, "tiempo_segundos": 60,
             "metricas": {"count": 8, "prompt": "Animales", "duration_s": 60}},
            {"nombre_prueba": "Funciones Ejecutivas (Stroop)", "porcentaje_obtenido": 75, "tiempo_segundos": 70,
             "metricas": {"correct": 0, "wrong": 5, "avg_ms": None}},
        ],
    }

    reporte = generar_reporte_local(datos)

    titulos = [linea for linea in reporte.splitlines() if linea.isupper() and linea.endswith(":")]
    assert titulos == [
        "MOTIVO DE EVALUACIÓN:",
        "INSTRUMENTOS APLICADOS:",
        "OBSERVACIONES DE LA EJECUCIÓN:",
        "INTERPRETACIÓN CLÍNICA POR DOMINIO:",
        "IMPRESIÓN CLÍNICA:",
        "IMPRESIÓN DIAGNÓSTICA:",
        "RECOMENDACIONES:",
        "LIMITACIONES:",
    ]
    assert len(reporte.split()) < 650
    assert "en el contexto del antecedente de depresión" in reporte
    # Métricas de proceso con lectura clínica
    assert "Tiempo de reacción medio de 612 ms (velocidad de respuesta levemente enlentecida)" in reporte
    assert "variabilidad intraindividual elevada" in reporte
    assert "2 respuestas anticipatorias" in reporte
    assert "Produjo 8 palabras en 60 s en la condición semántica (animales), producción reducida" in reporte
    assert "0% de aciertos en ensayos de interferencia (5 errores)" in reporte  # 0 aciertos no se pierde
    # Impresión clínica
    assert "perfil heterogéneo: compromiso en memoria y lenguaje, rendimiento limítrofe en atención y preservación de funciones ejecutivas" in reporte
    assert "deterioro cognitivo leve de tipo amnésico" in reporte
    assert "componente afectivo" in reporte
    # Impresión diagnóstica (Petersen / DSM-5)
    assert "Categoría: Deterioro cognitivo leve (DCL) probable, subtipo amnésico de dominio múltiple." in reporte
    assert "Equivalencia DSM-5: Compatible con trastorno neurocognitivo leve" in reporte
    assert "Confirmación: Impresión presuntiva de tamizaje" in reporte
    assert "Valoración funcional:" in reporte
    # Recomendaciones
    assert "Estudios complementarios:" in reporte
    assert "Salud mental:" in reporte
    assert "Reevaluación neuropsicológica sugerida en 3 meses." in reporte


def test_reporte_local_con_una_sola_prueba_advierte_perfil_incompleto_y_edad_no_registrada():
    datos = {
        "paciente_id": "PAC-1",
        "nombre_paciente": "Oscar",
        "edad_paciente": 0,
        "fecha_evaluacion": "2026-09-26",
        "profesional": "Dr. Test",
        "pruebas": [{"nombre_prueba": "Memoria Visual", "porcentaje_obtenido": 97, "tiempo_segundos": 12}],
    }

    reporte = generar_reporte_local(datos)

    assert "de 0 años" not in reporte
    assert "no permiten caracterizar el perfil cognitivo global" in reporte
    assert "Exploración complementaria:" in reporte
    assert "Categoría: Indeterminada." in reporte
    assert "La edad no fue registrada" in reporte
    assert "OBSERVACIONES DE LA EJECUCIÓN:" not in reporte  # sin métricas no hay observaciones
    assert "Reevaluación neuropsicológica sugerida en 12 meses." in reporte


_NOMBRES = ["Memoria Visual", "Atención Sostenida", "Fluidez Verbal", "Funciones Ejecutivas (Stroop)"]


def _categoria(puntajes, edad=67):
    datos = {
        "paciente_id": "P001",
        "nombre_paciente": "Ana",
        "edad_paciente": edad,
        "fecha_evaluacion": "2026-05-28",
        "profesional": "Dr. Test",
        "pruebas": [
            {"nombre_prueba": n, "porcentaje_obtenido": p, "tiempo_segundos": 60}
            for n, p in zip(_NOMBRES, puntajes)
        ],
    }
    reporte = generar_reporte_local(datos)
    return reporte.split("IMPRESIÓN DIAGNÓSTICA:\n")[1].splitlines()[0]


@pytest.mark.parametrize(
    ("puntajes", "edad", "esperado"),
    [
        ([85, 90, 80, 78], 67, "Funcionamiento cognitivo normal"),
        ([85, 65, 80, 78], 67, "rendimiento limítrofe aislado en atención"),
        ([35, 80, 78, 85], 67, "DCL) probable, subtipo amnésico de dominio único"),
        ([35, 55, 78, 85], 67, "DCL) probable, subtipo amnésico de dominio múltiple"),
        ([85, 35, 78, 85], 67, "DCL) probable, subtipo no amnésico de dominio único"),
        ([85, 50, 60, 85], 67, "DCL) probable, subtipo no amnésico de dominio múltiple"),
        ([30, 35, 25, 50], 67, "Deterioro cognitivo mayor probable"),
        ([35, 55, 78, 85], 12, "no aplican a esta edad"),
    ],
)
def test_impresion_diagnostica_segun_puntajes(puntajes, edad, esperado):
    assert esperado in _categoria(puntajes, edad)
