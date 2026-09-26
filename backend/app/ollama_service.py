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
TIMEOUT_SEGUNDOS = float(os.getenv("OLLAMA_TIMEOUT_SECONDS", "90"))     # da tiempo al modelo en CPU
MAX_TOKENS_REPORTE = int(os.getenv("OLLAMA_NUM_PREDICT", "700"))         # informe breve (~250 palabras)
MAX_PRUEBAS_PROMPT = int(os.getenv("OLLAMA_MAX_PRUEBAS_PROMPT", "6"))
MAX_CHARS_PROMPT = int(os.getenv("OLLAMA_MAX_PROMPT_CHARS", "6000"))
MAX_PALABRAS_REPORTE = 220

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


def _agrupar_por_dominio(pruebas: list[dict[str, Any]]) -> dict[str, list[dict[str, Any]]]:
    dominios: dict[str, list[dict[str, Any]]] = {}
    for p in pruebas:
        dominios.setdefault(p["dominio_cognitivo"], []).append(p)
    return dominios


def _promedio(pruebas: list[dict[str, Any]]) -> float:
    if not pruebas:
        return 0.0
    return sum(p["porcentaje_obtenido"] for p in pruebas) / len(pruebas)


def _unir(elementos: list[str]) -> str:
    """'a', 'a y b', 'a, b y c'."""
    if len(elementos) <= 1:
        return "".join(elementos)
    return ", ".join(elementos[:-1]) + " y " + elementos[-1]


def _construir_bloque_metricas(pruebas: list[dict[str, Any]]) -> str:
    """Genera un bloque textual con la guía de interpretación de métricas disponibles."""
    tipos_metricas: set[str] = set()
    for p in pruebas:
        m = p.get("metricas_detalladas") or {}
        tipos_metricas.update(m.keys())

    if not tipos_metricas:
        return ""

    glosario = {
        "errores": "respuestas incorrectas; más errores, mayor compromiso",
        "wrong": "respuestas incorrectas; más errores, mayor compromiso",
        "aciertos": "respuestas correctas",
        "correct": "respuestas correctas",
        "omisiones": "estímulos no respondidos; sugieren fallas de atención sostenida",
        "too_early": "respuestas anticipadas; sugieren impulsividad",
        "intrusiones": "falsos positivos; sugieren fallas inhibitorias",
        "intrusions": "falsos positivos; sugieren fallas inhibitorias",
        "tiempo_reaccion_promedio": "latencia media en ms; >600 ms sugiere enlentecimiento",
        "avg_ms": "latencia media en ms; >600 ms sugiere enlentecimiento",
        "avg_selection_ms": "tiempo medio de selección en ms",
        "best_ms": "mejor latencia en ms",
        "precision": "porcentaje de respuestas correctas; <60% indica déficit",
        "precisión": "porcentaje de respuestas correctas; <60% indica déficit",
        "palabras_generadas": "palabras producidas; <10 por minuto sugiere déficit de fluidez",
        "count": "palabras producidas; <10 por minuto sugiere déficit de fluidez",
        "nivel_maximo": "máximo nivel alcanzado",
        "level": "máximo nivel alcanzado",
    }
    guia_items = [f"{clave}: {glosario[clave]}" for clave in sorted(tipos_metricas) if clave in glosario]
    if not guia_items:
        return ""

    return "\nSIGNIFICADO DE LAS MÉTRICAS:\n" + "\n".join(guia_items)


def construir_prompt(datos: dict[str, Any]) -> str:
    pruebas = preparar_pruebas(datos)
    total_pruebas = len(pruebas)
    pruebas_mostradas = pruebas[:MAX_PRUEBAS_PROMPT]
    pruebas_json = json.dumps(pruebas_mostradas, ensure_ascii=False)
    bloque_metricas = _construir_bloque_metricas(pruebas_mostradas)

    nota_pruebas = ""
    if total_pruebas > MAX_PRUEBAS_PROMPT:
        nota_pruebas = f"\n[Se muestran {MAX_PRUEBAS_PROMPT} de {total_pruebas} pruebas.]"

    promedio_global = _promedio(pruebas_mostradas)
    nivel_global = interpretar_nivel(promedio_global)
    dominios_comprometidos = sorted({p["dominio_cognitivo"] for p in pruebas_mostradas if p["nivel"] != "ALTO"})
    dominios_preservados = sorted({p["dominio_cognitivo"] for p in pruebas_mostradas if p["nivel"] == "ALTO"})

    prompt = f"""Eres un neuropsicólogo clínico. Redacta en español un INFORME NEUROPSICOLÓGICO BREVE \
(máximo {MAX_PALABRAS_REPORTE} palabras en total) a partir de una evaluación cognitiva digital.

FORMATO OBLIGATORIO:
Usa exactamente estas 4 secciones y en este orden. Cada título va solo en su línea, en MAYÚSCULAS y terminado en dos puntos.
Texto plano: sin asteriscos, almohadillas, guiones ni viñetas. Sé directo, sin relleno ni repeticiones.

RESUMEN:
Una o dos oraciones con el nivel global y el promedio.
RESULTADOS POR DOMINIO:
Una línea por dominio con este formato exacto: Dominio: puntaje% (NIVEL), interpretación de máximo 15 palabras.
RECOMENDACIONES:
Una línea por cada dominio BAJO o MEDIO con una recomendación concreta. \
Última línea: plazo de control (3 meses si hay nivel BAJO, 6 si hay MEDIO, 12 si todo es ALTO).
CONCLUSIÓN:
Una o dos oraciones de síntesis. Usa calificadores clínicos ("compatible con", "sugiere"); nunca diagnósticos definitivos.

DATOS DEL PACIENTE:
Nombre completo: {datos["nombre_paciente"]}
Edad: {datos["edad_paciente"]} años
Antecedente clínico: {datos.get("diagnostico_paciente") or "No registrado"}
Profesional evaluador/a: {datos["profesional"]}
Fecha de la evaluación: {datos["fecha_evaluacion"]}
Promedio global: {promedio_global:.1f}% ({nivel_global})
Dominios comprometidos (BAJO o MEDIO): {", ".join(dominios_comprometidos) or "ninguno"}
Dominios preservados (ALTO): {", ".join(dominios_preservados) or "ninguno"}

PRUEBAS APLICADAS:
{pruebas_json}{nota_pruebas}
{bloque_metricas}

Escribe solo el informe, sin preámbulos ni despedidas.
""".strip()

    if len(prompt) > MAX_CHARS_PROMPT:
        prompt = prompt[:MAX_CHARS_PROMPT].rstrip() + "\n[Contenido truncado por límite de contexto.]"

    return prompt


# ── Reporte local (sin Ollama) ─────────────────────────────────────────────────

_INTERPRETACION_BREVE: dict[str, dict[str, str]] = {
    "Memoria": {
        "ALTO": "codificación y recuerdo conservados",
        "MEDIO": "leves dificultades para codificar o recuperar información",
        "BAJO": "dificultad marcada para codificar y recuperar información",
    },
    "Atención": {
        "ALTO": "foco atencional estable y respuesta ágil",
        "MEDIO": "fluctuaciones en la atención sostenida",
        "BAJO": "dificultad marcada para sostener la atención",
    },
    "Funciones Ejecutivas": {
        "ALTO": "control inhibitorio y flexibilidad conservados",
        "MEDIO": "leve dificultad en control inhibitorio o flexibilidad",
        "BAJO": "compromiso del control inhibitorio y la flexibilidad cognitiva",
    },
    "Lenguaje": {
        "ALTO": "fluidez verbal y acceso léxico conservados",
        "MEDIO": "leve reducción de la fluidez verbal",
        "BAJO": "reducción marcada de la fluidez verbal y el acceso léxico",
    },
    "Dominio no especificado": {
        "ALTO": "sin alteraciones relevantes",
        "MEDIO": "rendimiento limítrofe",
        "BAJO": "dificultades clínicamente relevantes",
    },
}

_RECOMENDACION_BREVE: dict[str, dict[str, str]] = {
    "BAJO": {
        "Memoria": "derivar a neuropsicología para evaluación ampliada y descartar causas reversibles (B12, tiroides, sueño).",
        "Atención": "valoración por neurología o psiquiatría y entrenamiento atencional estructurado.",
        "Funciones Ejecutivas": "derivar a neuropsicología y neurología; entrenar planificación y autorregulación.",
        "Lenguaje": "derivar a fonoaudiología; considerar neuroimagen si el cambio es progresivo.",
        "Dominio no especificado": "derivar a neuropsicología para evaluación ampliada.",
    },
    "MEDIO": {
        "Memoria": "estimulación cognitiva con estrategias mnemónicas; revisar sueño y estrés.",
        "Atención": "entrenamiento de atención sostenida; revisar sueño y ansiedad.",
        "Funciones Ejecutivas": "estrategias de organización y planificación (agenda, priorización de tareas).",
        "Lenguaje": "ejercicios de fluidez verbal semántica y fonológica.",
        "Dominio no especificado": "estimulación cognitiva y monitoreo periódico.",
    },
}

_MESES_CONTROL = {"BAJO": 3, "MEDIO": 6, "ALTO": 12}

# (claves aceptadas, plantilla). Incluye las claves que envían los juegos de la app.
_FORMATO_METRICAS: tuple[tuple[tuple[str, ...], str], ...] = (
    (("aciertos", "correct"), "aciertos {v:.0f}"),
    (("errores", "wrong"), "errores {v:.0f}"),
    (("tiempo_reaccion_promedio", "avg_ms", "avg_selection_ms"), "tiempo medio {v:.0f} ms"),
    (("omisiones",), "omisiones {v:.0f}"),
    (("too_early",), "anticipaciones {v:.0f}"),
    (("intrusiones", "intrusions"), "intrusiones {v:.0f}"),
    (("precision", "precisión"), "precisión {v:.0f}%"),
    (("palabras_generadas", "count"), "palabras {v:.0f}"),
    (("nivel_maximo", "level"), "nivel alcanzado {v:.0f}"),
    (("secuencias_correctas",), "secuencias correctas {v:.0f}"),
)


def _resumir_metricas(metricas: dict[str, Any] | None, maximo: int = 3) -> str:
    """Resume las métricas clave en una frase corta, p. ej. 'Aciertos 12, errores 2'."""
    if not metricas:
        return ""

    partes: list[str] = []
    for claves, plantilla in _FORMATO_METRICAS:
        clave = next((c for c in claves if c in metricas), None)
        if clave is None:
            continue
        try:
            valor = float(metricas[clave])
        except (TypeError, ValueError):
            continue
        partes.append(plantilla.format(v=valor))
        if len(partes) == maximo:
            break

    texto = ", ".join(partes)
    return texto[:1].upper() + texto[1:]


def _linea_dominio(dominio: str, pruebas: list[dict[str, Any]]) -> str:
    promedio = _promedio(pruebas)
    nivel = interpretar_nivel(promedio)
    interpretacion = _INTERPRETACION_BREVE.get(dominio, _INTERPRETACION_BREVE["Dominio no especificado"])[nivel]
    linea = f"{dominio}: {promedio:.1f}% ({nivel}), {interpretacion}."

    metricas = "; ".join(filter(None, (_resumir_metricas(p.get("metricas_detalladas")) for p in pruebas)))
    if metricas:
        linea += f" {metricas}."
    return linea


def generar_reporte_local(datos: dict[str, Any]) -> str:
    """
    Genera un reporte neuropsicológico breve sin depender de Ollama.
    Produce texto plano compatible con el parser _splitReportSections de Flutter:
    cada encabezado de sección va en MAYÚSCULAS seguido de (:).
    Los datos del paciente no se repiten aquí porque la app ya los muestra aparte.
    """
    pruebas = preparar_pruebas(datos)
    nombre = datos["nombre_paciente"]
    edad = datos["edad_paciente"]
    diagnostico = datos.get("diagnostico_paciente")

    promedio_global = _promedio(pruebas)
    nivel_global = interpretar_nivel(promedio_global)
    n = len(pruebas)

    dominios = _agrupar_por_dominio(pruebas)
    nivel_por_dominio = {d: interpretar_nivel(_promedio(ps)) for d, ps in dominios.items()}
    dominios_bajo = [d for d, nv in nivel_por_dominio.items() if nv == "BAJO"]
    dominios_medio = [d for d, nv in nivel_por_dominio.items() if nv == "MEDIO"]
    dominios_alto = [d for d, nv in nivel_por_dominio.items() if nv == "ALTO"]

    # ── Resumen ───────────────────────────────────────────────────────────────
    resumen = (
        f"{nombre} ({edad} años) obtuvo un rendimiento cognitivo global {nivel_global}, "
        f"con un promedio de {promedio_global:.1f}% en {n} {'prueba' if n == 1 else 'pruebas'}."
    )
    if diagnostico:
        resumen += f" Antecedente reportado: {diagnostico}."

    # ── Resultados por dominio ────────────────────────────────────────────────
    resultados = [_linea_dominio(d, ps) for d, ps in dominios.items()]

    # ── Recomendaciones ───────────────────────────────────────────────────────
    recomendaciones: list[str] = []
    for d in dominios_bajo + dominios_medio:
        recs = _RECOMENDACION_BREVE[nivel_por_dominio[d]]
        recomendaciones.append(f"{d}: {recs.get(d, recs['Dominio no especificado'])}")
    if recomendaciones:
        peor_nivel = "BAJO" if dominios_bajo else "MEDIO"
        recomendaciones.append(f"Control sugerido en {_MESES_CONTROL[peor_nivel]} meses.")
    else:
        recomendaciones.append(
            "Mantener actividad cognitiva, física y social. Control de rutina en 12 meses."
        )

    # ── Conclusión ────────────────────────────────────────────────────────────
    def _minusculas(lista: list[str]) -> str:
        return _unir([d.lower() for d in lista])

    if dominios_bajo:
        conclusion = f"Perfil compatible con compromiso cognitivo en {_minusculas(dominios_bajo)}"
        if dominios_medio:
            conclusion += f" y rendimiento limítrofe en {_minusculas(dominios_medio)}"
        conclusion += ". Se sugiere complementar con valoración clínica especializada."
    elif dominios_medio:
        conclusion = (
            f"Perfil con rendimiento limítrofe en {_minusculas(dominios_medio)}. "
            "Se sugiere seguimiento clínico periódico."
        )
    else:
        conclusion = "Perfil cognitivo preservado en todos los dominios evaluados."
    if dominios_alto and (dominios_bajo or dominios_medio):
        conclusion += f" Se conserva el rendimiento en {_minusculas(dominios_alto)}."

    partes: list[str] = [
        "RESUMEN:",
        resumen,
        "",
        "RESULTADOS POR DOMINIO:",
        *resultados,
        "",
        "RECOMENDACIONES:",
        *recomendaciones,
        "",
        "CONCLUSIÓN:",
        conclusion,
    ]
    return "\n".join(partes)


# ── Comunicación con Ollama ────────────────────────────────────────────────────

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
        "keep_alive": "1h",
        "options": {
            "temperature": 0.3,
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
        logger.warning(
            "Timeout asíncrono al generar reporte con Ollama (%.0fs); se usará el reporte local de respaldo",
            TIMEOUT_SEGUNDOS,
        )
        return generar_reporte_local(datos)
    except (httpx.ConnectError, httpx.TimeoutException, httpx.HTTPStatusError, httpx.HTTPError):
        logger.exception("Ollama no respondió; se usará el reporte local de respaldo")
        return generar_reporte_local(datos)
