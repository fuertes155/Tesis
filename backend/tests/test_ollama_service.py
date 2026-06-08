import asyncio

import httpx

from app.ollama_service import MAX_TOKENS_REPORTE, TIMEOUT_SEGUNDOS, construir_prompt, generar_reporte_cognitivo


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

    assert len(prompt) < 1200
    assert "Paciente:" in prompt
    assert "Tabla de resultados" in prompt
    assert "CRITERIO DE INTERPRETACIÓN OBLIGATORIO" not in prompt


def test_max_tokens_reporte_usa_presupuesto_reducido():
    assert MAX_TOKENS_REPORTE == 60


def test_timeout_reporte_es_corto_para_activar_respaldo():
    assert TIMEOUT_SEGUNDOS == 20


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

    assert len(prompt) < 1500
    assert "Pruebas omitidas" in prompt
    assert "Prueba 0" in prompt


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

    assert "REPORTE NEUROPSICOLOGICO (GENERADO LOCALMENTE)" in reporte
    assert "Ana" in reporte
    assert "Memoria Visual" in reporte


def test_generar_reporte_cognitivo_usa_respaldo_local_al_exceder_wait_for(monkeypatch):
    async def colgar(*args, **kwargs):
        await asyncio.sleep(30)

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

    assert "REPORTE NEUROPSICOLOGICO (GENERADO LOCALMENTE)" in reporte
    assert "Ana" in reporte
