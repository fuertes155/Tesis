from __future__ import annotations

import json
import logging
import os
from typing import Any

import httpx


logger = logging.getLogger(__name__)

OLLAMA_URL = os.getenv("OLLAMA_URL", "http://localhost:11434/api/generate")
MODELO_OLLAMA = os.getenv("OLLAMA_MODEL", "llama3")
TIMEOUT_SEGUNDOS = float(os.getenv("OLLAMA_TIMEOUT_SECONDS", "300"))
MAX_TOKENS_REPORTE = int(os.getenv("OLLAMA_NUM_PREDICT", "600"))

DOMINIOS_PRUEBAS = {
    "memoria visual": "Memoria",
    "atención sostenida": "Atención",
    "atencion sostenida": "Atención",
    "fluidez verbal": "Lenguaje",
    "funciones ejecutivas": "Funciones Ejecutivas",
    "funciones ejecutivas (stroop)": "Funciones Ejecutivas",
    "stroop": "Funciones Ejecutivas",
}


class OllamaNoDisponibleError(RuntimeError):
    """Error controlado cuando Ollama no responde o devuelve una salida inválida."""


def interpretar_nivel(porcentaje: float) -> str:
    if porcentaje <= 40:
        return "BAJO"
    if porcentaje <= 69:
        return "MEDIO"
    return "ALTO"


def obtener_dominio(nombre_prueba: str) -> str:
    nombre_normalizado = nombre_prueba.strip().lower()
    for patron, dominio in DOMINIOS_PRUEBAS.items():
        if patron in nombre_normalizado:
            return dominio
    return "Dominio no especificado"


def preparar_pruebas(datos: dict[str, Any]) -> list[dict[str, Any]]:
    pruebas_preparadas: list[dict[str, Any]] = []
    for prueba in datos.get("pruebas", []):
        porcentaje = float(prueba["porcentaje_obtenido"])
        pruebas_preparadas.append(
            {
                "nombre_prueba": prueba["nombre_prueba"],
                "dominio_cognitivo": obtener_dominio(prueba["nombre_prueba"]),
                "porcentaje_obtenido": porcentaje,
                "nivel": interpretar_nivel(porcentaje),
                "tiempo_segundos": prueba["tiempo_segundos"],
            }
        )
    return pruebas_preparadas


def construir_prompt(datos: dict[str, Any]) -> str:
    pruebas = preparar_pruebas(datos)
    pruebas_json = json.dumps(pruebas, ensure_ascii=False, indent=2)

    return f"""
Genera un reporte neuropsicológico breve y clínicamente prudente en español.
Usa encabezados claros, una tabla de resultados y recomendaciones funcionales.
No inventes diagnósticos definitivos; describe hallazgos como hipótesis clínicas cuando corresponda.

Paciente: {datos["nombre_paciente"]} (ID {datos["paciente_id"]}), {datos["edad_paciente"]} años.
Evaluador: {datos["profesional"]}
Fecha: {datos["fecha_evaluacion"]}

Pruebas realizadas:
{pruebas_json}

Incluye:
1. Resumen clínico inicial.
2. Tabla de resultados con Prueba, Dominio cognitivo, Porcentaje, Tiempo y Nivel.
3. Interpretación de relaciones entre dominios afectados y preservados.
4. Conclusiones, recomendaciones de seguimiento y una firma con el profesional evaluador.
""".strip()


async def generar_reporte_cognitivo(datos: dict[str, Any]) -> str:
    prompt = construir_prompt(datos)
    logger.info(
        "Generando reporte cognitivo con modelo=%s, prompt_chars=%d, max_tokens=%d",
        MODELO_OLLAMA,
        len(prompt),
        MAX_TOKENS_REPORTE,
    )
    payload = {
        "model": MODELO_OLLAMA,
        "prompt": prompt,
        "stream": False,
        "options": {
            "temperature": 0.35,
            "top_p": 0.85,
            "num_predict": MAX_TOKENS_REPORTE,
        },
    }

    try:
        timeout = httpx.Timeout(
            TIMEOUT_SEGUNDOS,
            connect=20.0,
            read=TIMEOUT_SEGUNDOS,
            write=20.0,
            pool=20.0,
        )
        async with httpx.AsyncClient(timeout=timeout) as client:
            respuesta = await client.post(OLLAMA_URL, json=payload)
            respuesta.raise_for_status()
    except httpx.ConnectError as exc:
        logger.exception("Error de conexión con Ollama")
        raise OllamaNoDisponibleError(
            "No fue posible conectar con Ollama en localhost:11434. "
            "Verifica que Ollama esté iniciado y que el modelo llama3 esté disponible."
        ) from exc
    except httpx.TimeoutException as exc:
        logger.exception("Ollama excedió el tiempo de espera")
        raise OllamaNoDisponibleError(
            f"Ollama tardó más de {int(TIMEOUT_SEGUNDOS)} segundos en generar el reporte. "
            "Intenta nuevamente o reduce el tamaño del reporte/modelo configurando OLLAMA_NUM_PREDICT."
        ) from exc
    except httpx.HTTPStatusError as exc:
        logger.exception("Ollama respondió con error HTTP %s", exc.response.status_code)
        raise OllamaNoDisponibleError(
            f"Ollama respondió con estado HTTP {exc.response.status_code}."
        ) from exc
    except httpx.HTTPError as exc:
        logger.exception("Error de comunicación con Ollama")
        raise OllamaNoDisponibleError(
            "Ocurrió un error de comunicación con Ollama."
        ) from exc

    contenido = respuesta.json()
    reporte = str(contenido.get("response", "")).strip()
    if not reporte:
        raise OllamaNoDisponibleError(
            "Ollama no devolvió contenido para el reporte neuropsicológico."
        )

    return reporte
