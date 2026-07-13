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
TIMEOUT_SEGUNDOS = float(os.getenv("OLLAMA_TIMEOUT_SECONDS", "90"))     # era 20 — da tiempo al modelo en CPU
MAX_TOKENS_REPORTE = int(os.getenv("OLLAMA_NUM_PREDICT", "1800"))        # era 1000 — informe más completo
MAX_PRUEBAS_PROMPT = int(os.getenv("OLLAMA_MAX_PRUEBAS_PROMPT", "6"))    # era 3 — incluye más pruebas en contexto
MAX_CHARS_PROMPT = int(os.getenv("OLLAMA_MAX_PROMPT_CHARS", "6000"))     # era 4000 — más espacio para datos

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


def _construir_bloque_metricas(pruebas: list[dict[str, Any]]) -> str:
    """Genera un bloque textual con la guía de interpretación de métricas disponibles."""
    tipos_metricas: set[str] = set()
    for p in pruebas:
        m = p.get("metricas_detalladas") or {}
        tipos_metricas.update(m.keys())

    if not tipos_metricas:
        return ""

    guia_items: list[str] = []
    glosario = {
        "errores":                   "Número de respuestas incorrectas. A mayor cantidad, mayor compromiso del proceso evaluado.",
        "omisiones":                 "Estímulos no respondidos. Indican fallas de atención sostenida o procesamiento lento.",
        "aciertos":                  "Respuestas correctas totales. Indicador de desempeño efectivo.",
        "tiempo_reaccion_promedio":  "Latencia promedio de respuesta en ms. >600 ms sugiere procesamiento lento o dificultad inhibitoria.",
        "precision":                 "Porcentaje de respuestas correctas sobre el total de intentos. <60% indica déficit significativo.",
        "precisión":                 "Porcentaje de respuestas correctas sobre el total de intentos. <60% indica déficit significativo.",
        "intrusions":                "Respuestas a estímulos incorrectos (falsos positivos). Indican fallas inhibitorias.",
        "intrusiones":               "Respuestas a estímulos incorrectos (falsos positivos). Indican fallas inhibitorias.",
        "secuencias_correctas":      "Bloques o series completadas exitosamente. Refleja memoria de trabajo y planificación.",
        "nivel_maximo":              "Máximo nivel alcanzado en la tarea. Indicador de capacidad cognitiva en ese dominio.",
        "palabras_generadas":        "Cantidad de palabras producidas. <10 palabras/minuto sugiere déficit de fluidez verbal.",
    }
    for clave in sorted(tipos_metricas):
        if clave in glosario:
            guia_items.append(f"  - {clave}: {glosario[clave]}")

    if not guia_items:
        return ""

    return "\nGUÍA DE INTERPRETACIÓN DE MÉTRICAS DISPONIBLES:\n" + "\n".join(guia_items)


def construir_prompt(datos: dict[str, Any]) -> str:
    pruebas = preparar_pruebas(datos)
    total_pruebas = len(pruebas)
    pruebas_mostradas = pruebas[:MAX_PRUEBAS_PROMPT]
    pruebas_json = json.dumps(pruebas_mostradas, ensure_ascii=False, indent=2)
    bloque_metricas = _construir_bloque_metricas(pruebas_mostradas)

    nota_pruebas = ""
    if total_pruebas > MAX_PRUEBAS_PROMPT:
        omitidas = total_pruebas - MAX_PRUEBAS_PROMPT
        nota_pruebas = (
            f"\n[Nota: se muestran {MAX_PRUEBAS_PROMPT} de {total_pruebas} pruebas; "
            f"{omitidas} omitidas por límite de contexto.]"
        )

    # Calcular resumen global para contexto del modelo
    promedio_global = (
        sum(p["porcentaje_obtenido"] for p in pruebas_mostradas) / len(pruebas_mostradas)
        if pruebas_mostradas else 0
    )
    nivel_global = interpretar_nivel(promedio_global)
    dominios_comprometidos = sorted({
        p["dominio_cognitivo"]
        for p in pruebas_mostradas
        if p["nivel"] in ("BAJO", "MEDIO")
    })
    dominios_preservados = sorted({
        p["dominio_cognitivo"]
        for p in pruebas_mostradas
        if p["nivel"] == "ALTO"
    })

    # Contexto pre-calculado para orientar el razonamiento del modelo
    ctx_dominios_comp = ", ".join(dominios_comprometidos) if dominios_comprometidos else "ninguno identificado"
    ctx_dominios_pres = ", ".join(dominios_preservados) if dominios_preservados else "ninguno con nivel ALTO"

    prompt = f"""Eres un Neuropsicólogo clínico con 20 años de experiencia en evaluación cognitiva computarizada, \
especializado en neuropsicología del adulto y del adulto mayor. \
Has publicado investigaciones sobre evaluación digital de funciones cognitivas y redactas informes \
utilizados en contextos hospitalarios, forenses y académicos.

Tu tarea es redactar un INFORME NEUROPSICOLÓGICO FORMAL Y COMPLETO en español a partir de los \
datos de evaluación digital proporcionados a continuación.

════════════════════════════════════════
REGLAS ABSOLUTAS DE FORMATO — INCUMPLIRLAS INVALIDA EL INFORME:
════════════════════════════════════════
REGLA 1 — TÍTULOS: Cada sección comienza en su propia línea, con el título \
en LETRAS MAYÚSCULAS seguido OBLIGATORIAMENTE de dos puntos (:). \
Nada más en esa línea.
REGLA 2 — SIN MARCADO: NO uses asteriscos (*), almohadillas (#), guiones (-) \
como viñetas, ni ningún símbolo de formato. Solo texto plano corrido.
REGLA 3 — ORDEN ESTRICTO: Las secciones deben aparecer exactamente en este orden:

ANTECEDENTES Y CONTEXTO DE EVALUACIÓN:
RESULTADOS DE PRUEBAS:
INTERPRETACIÓN CLÍNICA:
RECOMENDACIONES Y SEGUIMIENTO:
NOTA ÉTICA Y ALCANCE:
CONCLUSIÓN:

EJEMPLO CORRECTO de inicio de sección:
INTERPRETACIÓN CLÍNICA:
El paciente mostró un perfil heterogéneo...

EJEMPLO INCORRECTO (NO hagas esto):
**Interpretación Clínica**
- El paciente mostró...

════════════════════════════════════════
DATOS DEL PACIENTE Y CONTEXTO CLÍNICO:
════════════════════════════════════════
Nombre completo: {datos["nombre_paciente"]}
Identificación/Documento: {datos.get("documento_paciente") or datos["paciente_id"]}
Edad: {datos["edad_paciente"]} años
Teléfono de contacto: {datos.get("telefono_paciente") or "No registrado"}
Diagnóstico / Antecedente clínico reportado: {datos.get("diagnostico_paciente") or "No registrado"}
Institución evaluadora: {datos.get("institucion") or "NeuroApp360"}
Profesional evaluador/a: {datos["profesional"]}
Fecha de la evaluación: {datos["fecha_evaluacion"]}

Resumen estadístico de la sesión (calculado previamente para tu referencia):
Promedio global de desempeño: {promedio_global:.1f}% — Nivel global: {nivel_global}
Dominios con rendimiento comprometido (BAJO o MEDIO): {ctx_dominios_comp}
Dominios preservados (ALTO): {ctx_dominios_pres}

════════════════════════════════════════
DATOS DE PRUEBAS APLICADAS:
════════════════════════════════════════
{pruebas_json}{nota_pruebas}
{bloque_metricas}

════════════════════════════════════════
INSTRUCCIONES DETALLADAS POR SECCIÓN:
════════════════════════════════════════

SECCIÓN 1 — ANTECEDENTES Y CONTEXTO DE EVALUACIÓN:
Redacta 2–3 oraciones describiendo: (a) el motivo probable de derivación, \
considerando el antecedente clínico registrado; (b) el contexto general de la evaluación \
(plataforma digital NeuroApp360, fecha, profesional); (c) una aclaración de que los \
resultados deben interpretarse como apoyo clínico y no como diagnóstico aislado.

SECCIÓN 2 — RESULTADOS DE PRUEBAS:
Analiza CADA prueba de forma individual en un párrafo separado. Para cada una debes:
a) Nombrar la prueba y su dominio cognitivo evaluado.
b) Reportar el puntaje exacto (porcentaje_obtenido) y el nivel (BAJO/MEDIO/ALTO).
c) Interpretar las métricas_detalladas disponibles. Ejemplo: si hay muchos errores y \
pocas omisiones, eso sugiere impulsividad más que inatención. Si el tiempo de reacción \
es alto con pocos errores, sugiere procesamiento cauteloso pero lento. Si la precisión \
es baja, indica dificultad cualitativa en la tarea más allá de la velocidad.
d) Concluir qué implica ese resultado para la función cognitiva específica evaluada.

SECCIÓN 3 — INTERPRETACIÓN CLÍNICA:
Este es el núcleo del informe. Debes:
a) Integrar los resultados por DOMINIO COGNITIVO (no por prueba individual).
b) Para cada dominio, argumentar si está PRESERVADO, LEVEMENTE COMPROMETIDO \
o SIGNIFICATIVAMENTE ALTERADO, justificando con los datos.
c) Discutir la coherencia o inconsistencia entre dominios \
(p.ej., si la atención está baja pero la memoria está bien, eso tiene implicaciones clínicas).
d) Si el antecedente clínico es relevante (depresión, ansiedad, daño neurológico), \
analizar cómo puede estar modulando el rendimiento cognitivo.
e) Evitar diagnósticos definitivos; usa frases como "los hallazgos son consistentes con", \
"se sugiere la posibilidad de", "no puede descartarse".

SECCIÓN 4 — RECOMENDACIONES Y SEGUIMIENTO:
Proporciona recomendaciones ESPECÍFICAS por dominio comprometido. Incluye:
a) Derivaciones a especialistas si aplica (neurología, fonoaudiología, psiquiatría).
b) Intervenciones cognitivas concretas (rehabilitación, estimulación, psicoeducación).
c) Evaluaciones complementarias sugeridas (laboratorio, neuroimagen, audición).
d) Plazos de seguimiento diferenciados: 3 meses si hay déficit BAJO, \
6 meses si hay déficit MEDIO, 12 meses si todo está en nivel ALTO.

SECCIÓN 5 — NOTA ÉTICA Y ALCANCE:
Redacta un párrafo indicando que el informe es de apoyo clínico, \
que no reemplaza la valoración médica integral, que debe interpretarse \
en conjunto con la historia clínica y el criterio del profesional responsable.

SECCIÓN 6 — CONCLUSIÓN:
Sintetiza en 3–5 oraciones el perfil neuropsicológico global del paciente. \
Menciona explícitamente los dominios comprometidos y preservados. \
Cierra con la fecha de expedición y la firma del profesional evaluador: {datos["profesional"]}.

════════════════════════════════════════
INICIO DEL INFORME — ESCRIBE SOLO EL INFORME, SIN COMENTARIOS PREVIOS:
════════════════════════════════════════
""".strip()

    if len(prompt) > MAX_CHARS_PROMPT:
        prompt = prompt[:MAX_CHARS_PROMPT].rstrip() + "\n[Contenido truncado por límite de contexto.]"

    return prompt


# ── Helpers para el reporte local ─────────────────────────────────────────────

def _texto_nivel(nivel: str) -> str:
    return {
        "ALTO": "dentro de parámetros funcionales adecuados",
        "MEDIO": "en rango intermedio con áreas de oportunidad",
        "BAJO": "por debajo de los parámetros esperados para la edad",
    }.get(nivel, "en rango indeterminado")


def _analizar_prueba_individual(prueba: dict[str, Any]) -> str:
    """Genera un párrafo clínico para una prueba individual, integrando métricas detalladas."""
    nombre = prueba["nombre_prueba"]
    porcentaje = prueba["porcentaje_obtenido"]
    nivel = prueba["nivel"]
    tiempo = prueba["tiempo_segundos"]
    metricas = prueba.get("metricas_detalladas") or {}
    desc_nivel = _texto_nivel(nivel)

    texto = (
        f"Prueba '{nombre}': puntuación de {porcentaje:.1f}% (nivel {nivel}), "
        f"tiempo de ejecución {tiempo} segundos. "
        f"El desempeño se ubica {desc_nivel}."
    )

    # Integrar métricas detalladas si están disponibles
    detalles_metricas: list[str] = []
    if metricas:
        if "errores" in metricas:
            detalles_metricas.append(f"errores registrados: {metricas['errores']}")
        if "omisiones" in metricas:
            detalles_metricas.append(f"omisiones: {metricas['omisiones']}")
        if "aciertos" in metricas:
            detalles_metricas.append(f"aciertos: {metricas['aciertos']}")
        if "tiempo_reaccion_promedio" in metricas:
            detalles_metricas.append(
                f"tiempo de reacción promedio: {metricas['tiempo_reaccion_promedio']} ms"
            )
        for key in ("precision", "precisión"):
            if key in metricas:
                detalles_metricas.append(f"precisión: {metricas[key]}%")
                break

    if detalles_metricas:
        texto += f" Métricas adicionales: {'; '.join(detalles_metricas)}."

    return texto


def _interpretar_dominio(dominio: str, ps: list[dict[str, Any]]) -> str:
    """Genera un párrafo clínico de interpretación para un dominio cognitivo."""
    promedio_d = sum(x["porcentaje_obtenido"] for x in ps) / len(ps)
    nivel_d = interpretar_nivel(promedio_d)
    nombres = ", ".join(x["nombre_prueba"] for x in ps)
    tiempo_total = sum(x["tiempo_segundos"] for x in ps)

    frases: dict[str, dict[str, str]] = {
        "Memoria": {
            "ALTO": (
                f"Las pruebas de {nombres} evidencian una capacidad mnemónica dentro de parámetros funcionales adecuados "
                f"(promedio {promedio_d:.1f}%). El/la paciente demuestra retención y evocación de información de manera eficiente, "
                f"sin señales de deterioro en la codificación o consolidación de la memoria."
            ),
            "MEDIO": (
                f"Las pruebas de {nombres} arrojan un desempeño intermedio en memoria (promedio {promedio_d:.1f}%). "
                f"Se observan dificultades leves en la retención a corto plazo o en la recuperación de información sin claves, "
                f"sin que esto constituya un deterioro clínicamente significativo de manera aislada."
            ),
            "BAJO": (
                f"Las pruebas de {nombres} evidencian un rendimiento mnésico por debajo de lo esperado para la edad "
                f"(promedio {promedio_d:.1f}%). Se identifican dificultades en la codificación, almacenamiento o recuperación "
                f"de información que requieren evaluación complementaria."
            ),
        },
        "Atención": {
            "ALTO": (
                f"El desempeño en {nombres} refleja una capacidad atencional sostenida adecuada (promedio {promedio_d:.1f}%). "
                f"El/la evaluado(a) mantuvo el foco durante la tarea sin signos de fatiga cognitiva prematura "
                f"ni errores por inatención significativos."
            ),
            "MEDIO": (
                f"En las pruebas de atención ({nombres}), se obtuvo un promedio de {promedio_d:.1f}%, indicando fluctuaciones "
                f"en el sostenimiento atencional. Se observan omisiones o tiempos de reacción variables que sugieren "
                f"capacidad atencional limitada bajo demanda sostenida."
            ),
            "BAJO": (
                f"Los resultados en {nombres} (promedio {promedio_d:.1f}%) señalan dificultades marcadas en la regulación "
                f"atencional. El patrón de errores y/o tiempos de reacción elevados es consistente con déficit atencional "
                f"que impacta el funcionamiento cognitivo general."
            ),
        },
        "Funciones Ejecutivas": {
            "ALTO": (
                f"Las pruebas de funciones ejecutivas ({nombres}) muestran un rendimiento adecuado (promedio {promedio_d:.1f}%). "
                f"El/la paciente demuestra capacidad de planificación, flexibilidad cognitiva e inhibición de respuestas "
                f"predominantes sin dificultades evidentes."
            ),
            "MEDIO": (
                f"En funciones ejecutivas ({nombres}), el rendimiento fue de {promedio_d:.1f}%, situándose en rango intermedio. "
                f"Se aprecian ligeras dificultades en la inhibición de respuestas o en la velocidad de alternancia entre tareas, "
                f"sin llegar a un deterioro ejecutivo significativo."
            ),
            "BAJO": (
                f"Los resultados en {nombres} (promedio {promedio_d:.1f}%) evidencian alteraciones en las funciones ejecutivas. "
                f"Se detecta compromiso en la planificación, flexibilidad cognitiva y/o control inhibitorio, "
                f"lo que puede impactar en el desempeño de actividades de vida diaria complejas."
            ),
        },
        "Lenguaje": {
            "ALTO": (
                f"Las pruebas de lenguaje ({nombres}) indican un funcionamiento lingüístico dentro de la normalidad "
                f"(promedio {promedio_d:.1f}%). La fluidez verbal, recuperación léxica y organización del discurso "
                f"se encuentran preservadas."
            ),
            "MEDIO": (
                f"En las pruebas de lenguaje ({nombres}), se obtuvo un promedio de {promedio_d:.1f}%, con rendimiento intermedio. "
                f"Se aprecian dificultades leves en la evocación léxica o en la fluidez verbal bajo condiciones de tiempo limitado."
            ),
            "BAJO": (
                f"Los resultados en {nombres} (promedio {promedio_d:.1f}%) sugieren dificultades en la producción y/o comprensión verbal. "
                f"La reducción en fluencia y el acceso léxico limitado ameritan evaluación lingüística especializada."
            ),
        },
        "Dominio no especificado": {
            "ALTO": (
                f"Las pruebas de {nombres} muestran un rendimiento adecuado (promedio {promedio_d:.1f}%), "
                f"sin alteraciones cognitivas evidentes en este dominio."
            ),
            "MEDIO": (
                f"En {nombres}, el rendimiento fue de {promedio_d:.1f}%, con un perfil intermedio que requiere monitoreo clínico."
            ),
            "BAJO": (
                f"Las pruebas de {nombres} (promedio {promedio_d:.1f}%) revelan dificultades cognitivas "
                f"que merecen seguimiento e intervención profesional."
            ),
        },
    }

    texto_dominio = frases.get(dominio, frases["Dominio no especificado"]).get(nivel_d, "")
    return (
        f"{dominio.upper()}: {texto_dominio} "
        f"Tiempo total de ejecución del dominio: {tiempo_total} segundos."
    )


def _recomendaciones_por_dominio(dominios: dict[str, list[dict[str, Any]]]) -> str:
    """Genera recomendaciones clínicas específicas según los dominios comprometidos."""
    recomendaciones: list[str] = []

    recs_bajo: dict[str, str] = {
        "Memoria": (
            "Derivar a neuropsicología clínica para evaluación comprehensiva de memoria. "
            "Considerar estrategias compensatorias (agendas, recordatorios externos). "
            "Descartar causas tratables: déficit de vitamina B12, hipotiroidismo, privación de sueño crónica. "
            "Control neuropsicológico en 3 meses."
        ),
        "Atención": (
            "Evaluar la presencia de TDAH en adultos o trastorno atencional de origen secundario. "
            "Implementar técnicas de manejo ambiental para reducir distractores. "
            "Considerar intervención cognitiva de entrenamiento atencional estructurado. "
            "Control en 3 meses o según criterio clínico."
        ),
        "Funciones Ejecutivas": (
            "Derivar a neuropsicología y/o neurología para evaluación de funciones frontales. "
            "Implementar estrategias de planificación asistida y descomposición de tareas complejas. "
            "Evaluar impacto en actividades instrumentales de la vida diaria. "
            "Control en 3 meses."
        ),
        "Lenguaje": (
            "Derivar a fonoaudiología/logopedia para evaluación formal del lenguaje. "
            "Considerar estudio de neuroimagen si existe deterioro súbito o progresivo. "
            "Evaluar la audición como posible factor contribuyente. "
            "Control en 3 meses."
        ),
        "Dominio no especificado": (
            "Derivar a especialista para evaluación cognitiva comprehensiva. "
            "Control de seguimiento en 3 meses o según criterio del profesional responsable."
        ),
    }

    recs_medio: dict[str, str] = {
        "Memoria": (
            "Implementar programa de estimulación de memoria (asociación, repetición espaciada, técnicas mnemónicas). "
            "Evaluar factores de sueño y estrés como contribuyentes. Control neuropsicológico en 6 meses."
        ),
        "Atención": (
            "Entrenamiento de atención sostenida y selectiva con apoyo profesional. "
            "Evaluar higiene del sueño y niveles de ansiedad. Control en 6 meses."
        ),
        "Funciones Ejecutivas": (
            "Técnicas de organización personal y planificación de tareas. "
            "Psicoeducación sobre funciones ejecutivas y autorregulación. Control en 6 meses."
        ),
        "Lenguaje": (
            "Ejercicios de fluidez verbal y acceso léxico. Estimulación lingüística estructurada. "
            "Control en 6 meses."
        ),
        "Dominio no especificado": (
            "Estimulación cognitiva general y monitoreo clínico. Control en 6 meses."
        ),
    }

    for dominio, ps in dominios.items():
        promedio_d = sum(x["porcentaje_obtenido"] for x in ps) / len(ps)
        nivel_d = interpretar_nivel(promedio_d)
        if nivel_d == "BAJO":
            recomendaciones.append(recs_bajo.get(dominio, recs_bajo["Dominio no especificado"]))
        elif nivel_d == "MEDIO":
            recomendaciones.append(recs_medio.get(dominio, recs_medio["Dominio no especificado"]))

    if not recomendaciones:
        return (
            "Los hallazgos actuales son alentadores y sugieren un perfil cognitivo preservado. "
            "Se recomienda mantener un estilo de vida cognitivamente activo "
            "(lectura, actividades de estimulación cognitiva y ejercicio físico regular). "
            "Se sugiere control de rutina neuropsicológica en 12 meses "
            "o ante la aparición de nuevos síntomas cognitivos."
        )

    return " ".join(recomendaciones)


def generar_reporte_local(datos: dict[str, Any]) -> str:
    """
    Genera un reporte neuropsicológico estructurado sin depender de Ollama.
    Produce texto plano compatible con el parser _splitReportSections de Flutter:
    todos los encabezados de sección son MAYÚSCULAS seguidos de (:).
    """
    from datetime import date as _date

    pruebas = preparar_pruebas(datos)
    nombre = datos["nombre_paciente"]
    edad = datos["edad_paciente"]
    documento = datos.get("documento_paciente") or "No registrado"
    telefono = datos.get("telefono_paciente") or "No registrado"
    institucion = datos.get("institucion") or "NeuroApp360"
    profesional = datos["profesional"]
    fecha_eval = datos["fecha_evaluacion"]
    diagnostico = datos.get("diagnostico_paciente") or "No registrado"
    fecha_emision = _date.today().isoformat()

    # ── Cálculos globales ──────────────────────────────────────────────────────
    promedio_global = (
        sum(p["porcentaje_obtenido"] for p in pruebas) / len(pruebas) if pruebas else 0
    )
    nivel_global = interpretar_nivel(promedio_global)
    total_alto = sum(1 for p in pruebas if p["nivel"] == "ALTO")
    total_medio = sum(1 for p in pruebas if p["nivel"] == "MEDIO")
    total_bajo = sum(1 for p in pruebas if p["nivel"] == "BAJO")

    nivel_desc = {
        "ALTO": "rendimiento cognitivo global dentro de parámetros funcionales adecuados",
        "MEDIO": "rendimiento cognitivo global en rango intermedio, con áreas de oportunidad identificadas",
        "BAJO": "rendimiento cognitivo global por debajo de los parámetros funcionales esperados, con requerimiento de intervención",
    }

    # ── Agrupación por dominio ─────────────────────────────────────────────────
    dominios: dict[str, list[dict[str, Any]]] = {}
    for p in pruebas:
        dominios.setdefault(p["dominio_cognitivo"], []).append(p)

    # ── Análisis por prueba individual ─────────────────────────────────────────
    analisis_por_prueba = [_analizar_prueba_individual(p) for p in pruebas]

    # ── Interpretación por dominio ─────────────────────────────────────────────
    interpretaciones = [_interpretar_dominio(d, ps) for d, ps in dominios.items()]

    # ── Recomendaciones específicas ────────────────────────────────────────────
    recomendacion_texto = _recomendaciones_por_dominio(dominios)

    # ── Conclusión integradora ─────────────────────────────────────────────────
    dominios_bajo = [
        d for d, ps in dominios.items()
        if interpretar_nivel(sum(x["porcentaje_obtenido"] for x in ps) / len(ps)) == "BAJO"
    ]
    dominios_medio = [
        d for d, ps in dominios.items()
        if interpretar_nivel(sum(x["porcentaje_obtenido"] for x in ps) / len(ps)) == "MEDIO"
    ]

    if dominios_bajo:
        conclusion_dominios = (
            f"Se identifican déficits significativos en los dominios de {', '.join(dominios_bajo)}, "
            f"que requieren intervención profesional especializada. "
        )
    elif dominios_medio:
        conclusion_dominios = (
            f"Se observan áreas de oportunidad en los dominios de {', '.join(dominios_medio)}, "
            f"que requieren seguimiento clínico periódico. "
        )
    else:
        conclusion_dominios = (
            "Todos los dominios evaluados se encuentran dentro de parámetros funcionales adecuados. "
        )

    # ── Ensamble final — encabezados todos en MAYÚSCULAS seguidos de (:) ──────
    partes: list[str] = [
        "DATOS DE LA EVALUACIÓN:",
        (
            f"Paciente: {nombre} — Documento/ID: {documento} — Edad: {edad} años. "
            f"Teléfono: {telefono}. Institución: {institucion}. "
            f"Antecedente clínico: {diagnostico}. "
            f"Evaluador/a: {profesional}. "
            f"Fecha de evaluación: {fecha_eval}. Fecha de emisión: {fecha_emision}."
        ),
        "",
        "ANTECEDENTES Y CONTEXTO DE EVALUACIÓN:",
        (
            f"El/la paciente {nombre}, de {edad} años de edad, fue remitido(a) para evaluación neuropsicológica "
            f"asistida por NeuroApp360. Se aplicaron {len(pruebas)} prueba(s) cognitiva(s) en la fecha indicada. "
            f"Antecedente clínico reportado: {diagnostico}. "
            f"Las conclusiones del presente documento constituyen apoyo clínico y no reemplazan "
            f"la valoración médica integral ni el criterio del profesional responsable."
        ),
        "",
        "RESUMEN CUANTITATIVO:",
        (
            f"Se evaluaron {len(pruebas)} prueba(s) cognitiva(s). La puntuación promedio global fue de "
            f"{promedio_global:.1f}%, correspondiente a nivel {nivel_global} ({nivel_desc.get(nivel_global, '')}). "
            f"Distribución de resultados — ALTO: {total_alto} prueba(s), "
            f"MEDIO: {total_medio} prueba(s), BAJO: {total_bajo} prueba(s)."
        ),
        "",
        "RESULTADOS DE PRUEBAS:",
        *analisis_por_prueba,
        "",
        "INTERPRETACIÓN CLÍNICA:",
        *interpretaciones,
        "",
        "RECOMENDACIONES Y SEGUIMIENTO:",
        recomendacion_texto,
        "",
        "NOTA ÉTICA Y ALCANCE:",
        (
            "El presente informe neuropsicológico tiene carácter de apoyo clínico y no reemplaza una valoración "
            "médica integral. Debe interpretarse en conjunto con la historia clínica completa, la entrevista clínica "
            "estructurada, la observación conductual y el criterio del profesional responsable. "
            "Las interpretaciones se basan exclusivamente en las métricas registradas durante la sesión de evaluación."
        ),
        "",
        "CONCLUSIÓN:",
        (
            f"El perfil neuropsicológico de {nombre} corresponde a un nivel de rendimiento cognitivo global {nivel_global} "
            f"(promedio {promedio_global:.1f}%). "
            + conclusion_dominios
            + "Se expide el presente informe a solicitud del profesional evaluador para los fines pertinentes. "
            + f"Firma: {profesional}."
        ),
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
        logger.warning(
            "Timeout asíncrono al generar reporte con Ollama (%.0fs); se usará el reporte local de respaldo",
            TIMEOUT_SEGUNDOS,
        )
        return generar_reporte_local(datos)
    except (httpx.ConnectError, httpx.TimeoutException, httpx.HTTPStatusError, httpx.HTTPError):
        logger.exception("Ollama no respondió; se usará el reporte local de respaldo")
        return generar_reporte_local(datos)
