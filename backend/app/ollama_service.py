from __future__ import annotations

import asyncio
import json
import logging
import os
from typing import Any

import httpx


logger = logging.getLogger(__name__)

OLLAMA_URL = os.getenv("OLLAMA_URL", "http://localhost:11434/api/generate")
MODELO_OLLAMA = os.getenv("OLLAMA_MODEL", "llama3")
TIMEOUT_SEGUNDOS = float(os.getenv("OLLAMA_TIMEOUT_SECONDS", "20"))
MAX_TOKENS_REPORTE = int(os.getenv("OLLAMA_NUM_PREDICT", "1000"))
MAX_PRUEBAS_PROMPT = int(os.getenv("OLLAMA_MAX_PRUEBAS_PROMPT", "3"))
MAX_CHARS_PROMPT = int(os.getenv("OLLAMA_MAX_PROMPT_CHARS", "4000"))

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
                "metricas_detalladas": prueba.get("metricas") or prueba.get("detalles"),
            }
        )
    return pruebas_preparadas


def construir_prompt(datos: dict[str, Any]) -> str:
    pruebas = preparar_pruebas(datos)
    total_pruebas = len(pruebas)
    pruebas_mostradas = pruebas[:MAX_PRUEBAS_PROMPT]
    pruebas_json = json.dumps(pruebas_mostradas, ensure_ascii=False, indent=2)
    nota_pruebas = ""
    if total_pruebas > MAX_PRUEBAS_PROMPT:
        omitidas = total_pruebas - MAX_PRUEBAS_PROMPT
        nota_pruebas = (
            f"\nPruebas omitidas: se muestran solo las primeras {MAX_PRUEBAS_PROMPT} de {total_pruebas} "
            f"pruebas para mantener el contexto breve. Se omitieron {omitidas} pruebas adicionales."
        )

    prompt = f"""
Genera un informe neuropsicológico clínicamente prudente en español.
Eres un Neuropsicólogo clínico experto. Usa un estilo formal, organizado y médico.
No inventes diagnósticos definitivos; describe hallazgos como hipótesis clínicas cuando corresponda.
Tus interpretaciones DEBEN basarse en las métricas detalladas (tiempos de reacción, errores, omisiones, precisión) si están disponibles en los datos adjuntos.

Paciente: {datos["nombre_paciente"]} (ID {datos["paciente_id"]}), {datos["edad_paciente"]} años.
Documento: {datos.get("documento_paciente") or "No registrado"}.
Teléfono: {datos.get("telefono_paciente") or "No registrado"}.
Diagnóstico/antecedente registrado: {datos.get("diagnostico_paciente") or "No registrado"}.
Institución: {datos.get("institucion") or "NeuroApp360"}.
Evaluador: {datos["profesional"]}
Fecha: {datos["fecha_evaluacion"]}

Pruebas realizadas (incluyendo métricas detalladas de desempeño):
{pruebas_json}{nota_pruebas}

Instrucciones de Redacción:
1. RESUMEN CUANTITATIVO breve del desempeño global.
2. ANTECEDENTES Y CONTEXTO DE EVALUACIÓN.
3. RESULTADOS DE PRUEBAS: Analiza cualitativa y cuantitativamente cada prueba, integrando las "metricas_detalladas" (como errores o tiempos de reacción altos/bajos) para justificar el nivel (BAJO/MEDIO/ALTO).
4. INTERPRETACIÓN CLÍNICA: Discute los dominios afectados y preservados. Argumenta como un especialista por qué las métricas sugieren esto.
5. RECOMENDACIONES Y SEGUIMIENTO.
6. CONCLUSIÓN y firma con el profesional evaluador.

Mantén las secciones separadas con títulos en mayúscula seguidos de dos puntos.
Incluye una nota ética indicando que el informe no reemplaza una valoración médica integral.
""".strip()

    if len(prompt) > MAX_CHARS_PROMPT:
        prompt = prompt[:MAX_CHARS_PROMPT].rstrip() + "\n[Contenido truncado para evitar sobrecarga del modelo.]"

    return prompt


def generar_reporte_local(datos: dict[str, Any]) -> str:
    pruebas = preparar_pruebas(datos)
    resumen = (
        f"INFORME NEUROPSICOLÓGICO (GENERADO LOCALMENTE)\n\n"
        f"Paciente: {datos['nombre_paciente']} (ID {datos['paciente_id']})\n"
        f"Documento: {datos.get('documento_paciente') or 'No registrado'}\n"
        f"Teléfono: {datos.get('telefono_paciente') or 'No registrado'}\n"
        f"Institución: {datos.get('institucion') or 'NeuroApp360'}\n"
        f"Edad: {datos['edad_paciente']} años\n"
        f"Evaluador: {datos['profesional']}\n"
        f"Fecha: {datos['fecha_evaluacion']}\n\n"
        f"ANTECEDENTES Y CONTEXTO DE EVALUACIÓN:\n"
        f"Se generó este informe con un respaldo local porque el modelo de IA no pudo completar la generación en este momento. "
        f"Se revisaron {len(pruebas)} pruebas cognitivas con interpretación conservadora.\n\n"
    )

    tabla = [
        "Prueba | Dominio | Porcentaje | Nivel | Tiempo (s)",
        "--- | --- | --- | --- | ---",
    ]
    for prueba in pruebas:
        tabla.append(
            f"{prueba['nombre_prueba']} | {prueba['dominio_cognitivo']} | {prueba['porcentaje_obtenido']:.1f}% | {prueba['nivel']} | {prueba['tiempo_segundos']}"
        )

    dominions = {}
    for prueba in pruebas:
        dominions.setdefault(prueba["dominio_cognitivo"], []).append(prueba["porcentaje_obtenido"])

    interpretacion = []
    for dominio, porcentajes in dominions.items():
        promedio = sum(porcentajes) / len(porcentajes)
        interpretacion.append(f"- {dominio}: promedio {promedio:.1f}%, interpretado de forma conservadora con base en los resultados observados.")

    conclusion = (
        "Conclusión: este informe local conserva la estructura del reporte y los resultados medidos, "
        "pero la redacción clínica final quedó en modo respaldo. Se recomienda reintentar la generación con Ollama."
    )

    return "\n".join(
        [
            resumen,
            "RESUMEN CUANTITATIVO:",
            f"Total de pruebas aplicadas: {len(pruebas)}.",
            "",
            "RESULTADOS DE PRUEBAS:",
            *tabla,
            "",
            "INTERPRETACIÓN CLÍNICA:",
            *interpretacion,
            "",
            "RECOMENDACIONES Y SEGUIMIENTO:",
            "Correlacionar los hallazgos con entrevista clínica, historia médica y observación funcional. Programar seguimiento según criterio profesional.",
            "",
            "NOTA ÉTICA Y ALCANCE:",
            "Este informe no reemplaza una valoración médica integral. Debe interpretarse junto con la historia clínica, entrevista y criterio profesional.",
            "",
            f"CONCLUSIÓN: {conclusion}",
            "",
            f"Firma del profesional: {datos['profesional']}",
        ]
    )


async def _generar_reporte_ollama(datos: dict[str, Any], payload: dict[str, Any]) -> str:
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

    contenido = respuesta.json()
    reporte = str(contenido.get("response", "")).strip()
    if not reporte:
        raise OllamaNoDisponibleError(
            "Ollama no devolvió contenido para el reporte neuropsicológico."
        )

    return reporte


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
        reporte = await asyncio.wait_for(
            _generar_reporte_ollama(datos, payload),
            timeout=TIMEOUT_SEGUNDOS,
        )
        return reporte
    except asyncio.TimeoutError:
        logger.warning("Timeout asíncrono al generar reporte con Ollama; se usará el reporte local de respaldo")
        return generar_reporte_local(datos)
    except (httpx.ConnectError, httpx.TimeoutException, httpx.HTTPStatusError, httpx.HTTPError) as exc:
        logger.exception("Ollama no respondió; se usará el reporte local de respaldo")
        return generar_reporte_local(datos)
