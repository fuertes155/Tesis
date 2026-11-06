"""
Pruebas unitarias del generador local del informe neuropsicológico
(complementan test_ollama_service.py: límites, dominios, umbrales y antecedentes).
"""
import pytest

from app.ollama_service import generar_reporte_local, interpretar_nivel, obtener_dominio

_PRUEBAS = ["Memoria Visual", "Atención Sostenida", "Fluidez Verbal", "Funciones Ejecutivas (Stroop)"]


def _reporte(puntajes=(80, 80, 80, 80), edad=67, metricas=None, diagnostico=None, nombres=_PRUEBAS):
    metricas = metricas or {}
    return generar_reporte_local({
        "paciente_id": "PAC-1",
        "nombre_paciente": "Ana Ríos",
        "edad_paciente": edad,
        "fecha_evaluacion": "2026-11-04",
        "profesional": "Dr. Prueba",
        "diagnostico_paciente": diagnostico,
        "pruebas": [
            {"nombre_prueba": n, "porcentaje_obtenido": p, "tiempo_segundos": 60, "metricas": metricas.get(n)}
            for n, p in zip(nombres, puntajes)
        ],
    })


# ── Niveles de rendimiento ───────────────────────────────────────────────────

@pytest.mark.parametrize(
    ("porcentaje", "nivel"),
    [(0, "BAJO"), (40, "BAJO"), (40.1, "MEDIO"), (69, "MEDIO"), (69.5, "ALTO"), (70, "ALTO"), (100, "ALTO")],
)
def test_interpretar_nivel_en_los_limites(porcentaje, nivel):
    assert interpretar_nivel(porcentaje) == nivel


# ── Dominio cognitivo de cada prueba ─────────────────────────────────────────

@pytest.mark.parametrize(
    ("prueba", "dominio"),
    [
        ("Memoria Visual", "Memoria"),
        ("Atención Sostenida", "Atención"),
        ("atencion sostenida", "Atención"),            # sin tilde
        ("  FLUIDEZ VERBAL  ", "Lenguaje"),            # mayúsculas y espacios
        ("Funciones Ejecutivas (Stroop)", "Funciones Ejecutivas"),
        ("Stroop", "Funciones Ejecutivas"),
        ("Prueba inventada", "Dominio no especificado"),
    ],
)
def test_obtener_dominio(prueba, dominio):
    assert obtener_dominio(prueba) == dominio


# ── Contenido del informe ────────────────────────────────────────────────────

def test_motivo_incluye_paciente_edad_profesional_y_fecha_en_texto():
    reporte = _reporte()
    assert "Ana Ríos, de 67 años, solicitada por Dr. Prueba" in reporte
    assert "el 4 de noviembre de 2026" in reporte
    assert "Se aplicaron 4 pruebas" in reporte


def test_indice_global_es_el_promedio_de_las_pruebas():
    assert "índice de rendimiento global fue de 62.5%" in _reporte(puntajes=(50, 60, 70, 70))


@pytest.mark.parametrize(
    ("puntajes", "meses"),
    [((80, 80, 80, 80), 12), ((60, 80, 80, 80), 6), ((30, 80, 80, 80), 3)],
)
def test_reevaluacion_segun_el_peor_dominio(puntajes, meses):
    assert f"Reevaluación neuropsicológica sugerida en {meses} meses." in _reporte(puntajes=puntajes)


def test_perfil_normal_recomienda_factores_protectores():
    reporte = _reporte(puntajes=(85, 90, 80, 88))
    assert "Factores protectores:" in reporte
    assert "Estudios complementarios:" not in reporte


@pytest.mark.parametrize(
    ("media_ms", "texto"),
    [
        (350, "velocidad de respuesta ágil"),
        (500, "velocidad de respuesta dentro de lo esperado"),
        (700, "velocidad de respuesta levemente enlentecida"),
        (900, "velocidad de respuesta enlentecida"),
    ],
)
def test_observacion_de_atencion_segun_tiempo_de_reaccion(media_ms, texto):
    metricas = {"Atención Sostenida": {"avg_ms": media_ms, "best_ms": media_ms * 0.8, "too_early": 0}}
    reporte = _reporte(metricas=metricas)
    assert f"Tiempo de reacción medio de {media_ms} ms ({texto})" in reporte
    assert "sin respuestas anticipatorias" in reporte


def test_observacion_de_memoria_marca_estilo_lento_sobre_2000_ms():
    lento = _reporte(metricas={"Memoria Visual": {"level": 2, "items_to_remember": 4, "avg_selection_ms": 2400}})
    normal = _reporte(metricas={"Memoria Visual": {"level": 5, "items_to_remember": 7, "avg_selection_ms": 1200}})
    assert "Alcanzó el nivel 2 de la tarea (series de 4 estímulos)" in lento
    assert "estilo de respuesta lento" in lento
    assert "estilo de respuesta lento" not in normal


def test_observacion_de_fluidez_fonologica_con_produccion_reducida():
    reporte = _reporte(metricas={"Fluidez Verbal": {"count": 6, "prompt": "Letra: P", "duration_s": 60}})
    assert "Produjo 6 palabras en 60 s en la condición fonológica (letra: p), producción reducida" in reporte


def test_observacion_de_stroop_con_errores_frecuentes_y_enlentecimiento():
    reporte = _reporte(metricas={"Funciones Ejecutivas (Stroop)": {"correct": 10, "wrong": 10, "avg_ms": 1800}})
    assert "50% de aciertos en ensayos de interferencia (10 errores), con errores de interferencia frecuentes" in reporte
    assert "enlentecido bajo interferencia" in reporte


@pytest.mark.parametrize(
    ("diagnostico", "texto"),
    [
        ("Enfermedad de Parkinson", "enlentecimiento y disfunción ejecutiva"),
        ("Secuelas de ACV isquémico", "antecedente cerebrovascular"),
        ("Traumatismo craneoencefálico leve", "traumatismo craneoencefálico"),
        ("TDAH, presentación combinada", "antecedente de TDAH"),
        ("Epilepsia del lóbulo temporal", "epilepsia y su tratamiento"),
        ("Enfermedad de Alzheimer", "comparar con evaluaciones previas"),
        ("Hipotiroidismo", "correlacionarse con el antecedente clínico reportado (Hipotiroidismo)"),
    ],
)
def test_consideracion_segun_antecedente(diagnostico, texto):
    assert texto in _reporte(puntajes=(60, 60, 60, 60), diagnostico=diagnostico)


def test_antecedente_afectivo_agrega_recomendacion_de_salud_mental():
    assert "Salud mental:" in _reporte(diagnostico="Trastorno de ansiedad generalizada")
    assert "Salud mental:" not in _reporte(diagnostico="Enfermedad de Parkinson")


def test_menor_de_edad_no_recibe_categorias_de_deterioro_del_adulto():
    # Orden de _PRUEBAS: memoria, atención, fluidez (lenguaje), Stroop (ejecutivas).
    reporte = _reporte(puntajes=(70, 45, 50, 72), edad=13)
    assert "Dificultades cognitivas específicas en atención y lenguaje" in reporte
    assert "Deterioro cognitivo leve (DCL)" not in reporte


# ── Funciones auxiliares y conexión con Ollama ───────────────────────────────

import asyncio  # noqa: E402

import httpx  # noqa: E402

from app import ollama_service  # noqa: E402


def test_promedio_de_lista_vacia_es_cero():
    assert ollama_service._promedio([]) == 0.0


def test_numero_y_fecha_toleran_valores_invalidos():
    assert ollama_service._numero("12.5") == 12.5
    assert ollama_service._numero("abc") is None
    assert ollama_service._numero(None) is None
    assert ollama_service._formatear_fecha("2026-11-04") == "4 de noviembre de 2026"
    assert ollama_service._formatear_fecha("sin fecha") == "sin fecha"


def test_glosario_de_metricas_solo_incluye_las_conocidas():
    con_metricas = ollama_service._construir_bloque_metricas(
        [{"metricas_detalladas": {"avg_ms": 500, "too_early": 1, "desconocida": 3}}]
    )
    assert con_metricas.startswith("\nSIGNIFICADO DE LAS MÉTRICAS:")
    assert "avg_ms:" in con_metricas and "too_early:" in con_metricas
    assert "desconocida" not in con_metricas
    assert ollama_service._construir_bloque_metricas([{"metricas_detalladas": {"rara": 1}}]) == ""
    assert ollama_service._construir_bloque_metricas([{}]) == ""


def test_prompt_demasiado_largo_se_trunca(monkeypatch):
    monkeypatch.setattr(ollama_service, "MAX_CHARS_PROMPT", 300)
    datos = {"paciente_id": "P", "nombre_paciente": "Ana", "edad_paciente": 70, "fecha_evaluacion": "2026-11-04",
             "profesional": "Dr.", "pruebas": [{"nombre_prueba": "Memoria Visual", "porcentaje_obtenido": 50,
                                                "tiempo_segundos": 60}]}
    prompt = ollama_service.construir_prompt(datos)
    assert prompt.endswith("[Contenido truncado por límite de contexto.]")
    assert len(prompt) <= 300 + len("\n[Contenido truncado por límite de contexto.]")


def _ollama_simulado(monkeypatch, respuesta: httpx.Response):
    real = httpx.AsyncClient

    def fabrica(*args, **kwargs):
        kwargs["transport"] = httpx.MockTransport(lambda request: respuesta)
        return real(*args, **kwargs)

    monkeypatch.setattr(ollama_service.httpx, "AsyncClient", fabrica)


def test_llamada_a_ollama_devuelve_el_texto_generado(monkeypatch):
    _ollama_simulado(monkeypatch, httpx.Response(200, json={"response": "  Informe generado  "}))
    texto = asyncio.run(ollama_service._generar_reporte_ollama({}, {"prompt": "x"}))
    assert texto == "Informe generado"


def test_ollama_sin_contenido_lanza_error(monkeypatch):
    _ollama_simulado(monkeypatch, httpx.Response(200, json={"response": "   "}))
    with pytest.raises(ollama_service.OllamaNoDisponibleError):
        asyncio.run(ollama_service._generar_reporte_ollama({}, {"prompt": "x"}))


def test_generar_reporte_cognitivo_usa_la_respuesta_de_ollama_si_esta_disponible(monkeypatch):
    async def ollama_ok(datos, payload):
        assert payload["stream"] is False
        return "Informe de Ollama"

    monkeypatch.setattr(ollama_service, "_generar_reporte_ollama", ollama_ok)
    datos = {"paciente_id": "P", "nombre_paciente": "Ana", "edad_paciente": 70, "fecha_evaluacion": "2026-11-04",
             "profesional": "Dr.", "pruebas": [{"nombre_prueba": "Memoria Visual", "porcentaje_obtenido": 50,
                                                "tiempo_segundos": 60}]}
    assert asyncio.run(ollama_service.generar_reporte_cognitivo(datos)) == "Informe de Ollama"
