from app.ollama_service import MAX_TOKENS_REPORTE, construir_prompt


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
    assert MAX_TOKENS_REPORTE == 600
