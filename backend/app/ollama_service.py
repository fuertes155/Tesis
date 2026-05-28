from __future__ import annotations

import json
import os
from typing import Any

import httpx


OLLAMA_URL = os.getenv("OLLAMA_URL", "http://localhost:11434/api/generate")
MODELO_OLLAMA = os.getenv("OLLAMA_MODEL", "llama3")
TIMEOUT_SEGUNDOS = float(os.getenv("OLLAMA_TIMEOUT_SECONDS", "300"))
MAX_TOKENS_REPORTE = int(os.getenv("OLLAMA_NUM_PREDICT", "1600"))

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
Actúa como un neuropsicólogo clínico experto en evaluación cognitiva de adultos.
Redacta un reporte neuropsicológico profesional, claro, sobrio y clínicamente útil.

No digas que eres una IA. No inventes diagnósticos médicos definitivos. Si hay signos
de bajo rendimiento, plantea hipótesis clínicas prudentes y recomienda valoración
complementaria cuando corresponda.

CRITERIO DE INTERPRETACIÓN OBLIGATORIO:
- 0% a 40%: Rendimiento BAJO, posible déficit cognitivo.
- 41% a 69%: Rendimiento MEDIO, área a fortalecer.
- 70% a 100%: Rendimiento ALTO, funcionamiento adecuado.

DATOS DEL PACIENTE:
- ID: {datos["paciente_id"]}
- Nombre: {datos["nombre_paciente"]}
- Edad: {datos["edad_paciente"]} años
- Fecha de evaluación: {datos["fecha_evaluacion"]}
- Profesional evaluador: {datos["profesional"]}

PRUEBAS REALIZADAS:
{pruebas_json}

INSTRUCCIONES CLÍNICAS:
1. Interpreta únicamente las pruebas realizadas. Si faltan pruebas, adapta el reporte
   y menciona que el perfil corresponde a una batería parcial.
2. Relaciona los dominios entre sí. Por ejemplo: bajo desempeño en memoria junto con
   atención reducida puede afectar codificación y recuperación de información; bajo
   desempeño ejecutivo puede interferir con control inhibitorio, flexibilidad mental
   y organización de estrategias.
3. Personaliza conclusiones y recomendaciones según el perfil completo del paciente,
   su edad y los porcentajes obtenidos.
4. Usa lenguaje de neuropsicología clínica real, sin frases genéricas ni tono comercial.
5. Mantén formato Markdown, con títulos exactamente como se indican.

ESTRUCTURA OBLIGATORIA DEL REPORTE:

# DATOS DE LA EVALUACIÓN

# PERFIL COGNITIVO
Incluye una tabla con columnas: Prueba, Dominio cognitivo, Porcentaje, Tiempo, Nivel.

# ANÁLISIS POR DOMINIO COGNITIVO
Incluye subsecciones solo para los dominios/pruebas realizadas:
## Memoria Visual
## Atención Sostenida
## Fluidez Verbal
## Funciones Ejecutivas

# INTERPRETACIÓN INTEGRAL
Describe las relaciones entre dominios preservados y afectados.

# CONCLUSIONES Y RECOMENDACIONES
Incluye recomendaciones clínicas, funcionales y de seguimiento.

# FIRMA DEL PROFESIONAL
Incluye el nombre del profesional evaluador y un espacio de firma.
""".strip()


async def generar_reporte_cognitivo(datos: dict[str, Any]) -> str:
    prompt = construir_prompt(datos)
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
        raise OllamaNoDisponibleError(
            "No fue posible conectar con Ollama en localhost:11434. "
            "Verifica que Ollama esté iniciado y que el modelo llama3 esté disponible."
        ) from exc
    except httpx.TimeoutException as exc:
        raise OllamaNoDisponibleError(
            f"Ollama tardó más de {int(TIMEOUT_SEGUNDOS)} segundos en generar el reporte. "
            "Intenta nuevamente o reduce el tamaño del reporte/modelo configurando OLLAMA_NUM_PREDICT."
        ) from exc
    except httpx.HTTPStatusError as exc:
        raise OllamaNoDisponibleError(
            f"Ollama respondió con estado HTTP {exc.response.status_code}."
        ) from exc
    except httpx.HTTPError as exc:
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
