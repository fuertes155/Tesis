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
ESTILO DE ESCRITURA REQUERIDO:
════════════════════════════════════════
Redacta en TERCERA PERSONA impersonal y voz formal clínica.
Usa terminología neuropsicológica precisa:
  Correcto: "dominio mnésico", "funciones ejecutivas frontales", "control inhibitorio",
            "velocidad de procesamiento", "capacidad atencional sostenida",
            "fluencia verbal semántica", "flexibilidad cognitiva", "codificación mnésica".
  Incorrecto: "el paciente recordó bien", "se portó bien", "le fue mal".
Cuantifica siempre con los datos: menciona puntajes exactos y métricas específicas.
Evita diagnósticos definitivos; usa calificadores clínicos:
  "los hallazgos son consistentes con", "no puede descartarse", "sugiere la posibilidad de",
  "compatible con", "en el contexto de la presente evaluación".

════════════════════════════════════════
INSTRUCCIONES DETALLADAS POR SECCIÓN:
════════════════════════════════════════

SECCIÓN 1 — ANTECEDENTES Y CONTEXTO DE EVALUACIÓN:
Redacta 3 oraciones en tono formal. Incluye: (a) el motivo clínico de derivación \
inferido del antecedente registrado; (b) descripción del contexto evaluativo \
(plataforma NeuroApp360, profesional a cargo, fecha); \
(c) declaración de que los hallazgos constituyen apoyo clínico y no diagnóstico definitivo.

SECCIÓN 2 — RESULTADOS DE PRUEBAS:
Un párrafo por cada prueba aplicada. Para cada una:
a) Identificar la prueba y el dominio cognitivo que evalúa.
b) Citar el puntaje exacto (porcentaje_obtenido) y el nivel clasificatorio.
c) Interpretar las métricas_detalladas clínicamente:
   Muchos errores + pocas omisiones → patrón impulsivo más que inatento.
   Tiempo de reacción alto + pocos errores → procesamiento cauteloso y lento.
   Precisión baja + errores altos → dificultad cualitativa en la tarea.
   Pocas omisiones + tiempo bajo → ejecución eficiente y sostenida.
d) Cerrar el párrafo con una oración que traduzca el dato al proceso cognitivo subyacente.

SECCIÓN 3 — INTERPRETACIÓN CLÍNICA:
Es el núcleo clínico del informe. Debes:
a) Organizar la discusión POR DOMINIO COGNITIVO, no por prueba.
b) Clasificar cada dominio como PRESERVADO, LEVEMENTE COMPROMETIDO \
o SIGNIFICATIVAMENTE ALTERADO, con justificación cuantitativa.
c) Analizar la coherencia del perfil: si la atención está comprometida \
pero la memoria está preservada, discutir las implicaciones clínicas diferenciales.
d) Relacionar los hallazgos con el antecedente clínico reportado \
(ej.: la depresión puede generar pseudodemencia; la ansiedad eleva la impulsividad).
e) Usar calificadores clínicos apropiados en lugar de diagnósticos definitivos.

SECCIÓN 4 — RECOMENDACIONES Y SEGUIMIENTO:
Recomendaciones concretas y jerarquizadas por dominio comprometido:
a) Derivaciones a especialistas con justificación (neurología, psiquiatría, fonoaudiología).
b) Intervenciones específicas: rehabilitación cognitiva, psicoeducación, adaptaciones funcionales.
c) Estudios complementarios si se justifican: neuroimagen, laboratorio, evaluación auditiva.
d) Plazos diferenciados: seguimiento en 3 meses si nivel BAJO, \
6 meses si nivel MEDIO, 12 meses si todo en nivel ALTO.

SECCIÓN 5 — NOTA ÉTICA Y ALCANCE:
Párrafo formal que explicite: el informe es de apoyo clínico y no reemplaza \
la valoración médica integral, debe contextualizarse en la historia clínica \
completa y el juicio profesional del evaluador responsable.

SECCIÓN 6 — CONCLUSIÓN:
3–5 oraciones que sinteticen el perfil neuropsicológico global. \
Mencionar dominios comprometidos y preservados con sus puntajes. \
Cerrar con fecha de expedición y firma: {datos["profesional"]}.

════════════════════════════════════════
INICIO DEL INFORME — ESCRIBE SOLO EL INFORME, SIN PREÁMBULOS:
════════════════════════════════════════
""".strip()

    if len(prompt) > MAX_CHARS_PROMPT:
        prompt = prompt[:MAX_CHARS_PROMPT].rstrip() + "\n[Contenido truncado por límite de contexto.]"

    return prompt


# ── Helpers para el reporte local ─────────────────────────────────────────────

def _calificacion_clinica(nivel: str) -> str:
    """Devuelve la calificación clínica formal según el nivel de rendimiento."""
    return {
        "ALTO": "dentro de parámetros normativos funcionales",
        "MEDIO": "en rango limítrofe con compromiso funcional leve",
        "BAJO": "significativamente por debajo de los parámetros normativos esperados para la edad cronológica",
    }.get(nivel, "en rango indeterminado")


def _interpretar_metrica_individual(nombre_metrica: str, valor: Any, total_aciertos: int | None = None) -> str:
    """Traduce una métrica específica en lenguaje clínico interpretativo."""
    try:
        v = float(valor)
    except (TypeError, ValueError):
        return ""

    if nombre_metrica == "errores":
        if v == 0:
            return "sin errores de comisión registrados, lo que indica una ejecución precisa"
        if v <= 2:
            return f"{int(v)} error(es) de comisión, dentro de límites aceptables"
        if v <= 5:
            return f"{int(v)} errores de comisión, indicativos de dificultades en la precisión de respuesta"
        return f"{int(v)} errores de comisión, patrón consistente con compromiso significativo del proceso evaluado"

    if nombre_metrica == "omisiones":
        if v == 0:
            return "sin omisiones, lo que refleja sostenimiento atencional adecuado"
        if v <= 3:
            return f"{int(v)} omisión(es), sugiriendo leves fluctuaciones en la vigilancia"
        return f"{int(v)} omisiones, patrón indicativo de déficit en la atención sostenida o procesamiento lento"

    if nombre_metrica == "aciertos":
        ref = total_aciertos or v
        pct = (v / ref * 100) if ref > 0 else 0
        if pct >= 80:
            return f"{int(v)} respuestas correctas ({pct:.0f}%), reflejando eficacia en la recuperación de información"
        if pct >= 60:
            return f"{int(v)} respuestas correctas ({pct:.0f}%), con rendimiento moderado"
        return f"{int(v)} respuestas correctas ({pct:.0f}%), evidenciando dificultades marcadas en la ejecución"

    if nombre_metrica == "tiempo_reaccion_promedio":
        if v < 350:
            return f"latencia promedio de respuesta de {int(v)} ms, compatible con velocidad de procesamiento ágil"
        if v < 600:
            return f"latencia promedio de {int(v)} ms, dentro de rangos normativos de velocidad de procesamiento"
        if v < 900:
            return f"latencia promedio de {int(v)} ms, sugestiva de enlentecimiento en la velocidad de procesamiento cognitivo"
        return f"latencia promedio de {int(v)} ms, compatible con enlentecimiento cognitivo de grado moderado a severo"

    if nombre_metrica in ("precision", "precisión"):
        if v >= 85:
            return f"índice de precisión del {v:.1f}%, preservado dentro de parámetros normativos"
        if v >= 65:
            return f"índice de precisión del {v:.1f}%, en rango limítrofe"
        return f"índice de precisión del {v:.1f}%, evidenciando comprometida calidad de respuesta"

    return ""


def _analizar_prueba_individual(prueba: dict[str, Any]) -> str:
    """Genera un párrafo clínico formal para una prueba individual con interpretación cuantitativa."""
    nombre = prueba["nombre_prueba"]
    dominio = prueba["dominio_cognitivo"]
    porcentaje = prueba["porcentaje_obtenido"]
    nivel = prueba["nivel"]
    tiempo = prueba["tiempo_segundos"]
    metricas = prueba.get("metricas_detalladas") or {}
    calificacion = _calificacion_clinica(nivel)

    # Párrafo principal
    texto = (
        f"La prueba de {nombre} (dominio: {dominio}) arrojó un puntaje de {porcentaje:.1f}%, "
        f"clasificado como nivel {nivel}. El rendimiento observado se ubica {calificacion}, "
        f"con un tiempo total de ejecución de {tiempo} segundos."
    )

    # Interpretación clínica de métricas detalladas
    interpretaciones_metricas: list[str] = []
    total_aciertos = metricas.get("aciertos")
    for clave, valor in metricas.items():
        interp = _interpretar_metrica_individual(clave, valor, total_aciertos)
        if interp:
            interpretaciones_metricas.append(interp)

    if interpretaciones_metricas:
        texto += (
            f" El análisis de las métricas de ejecución revela: "
            + "; ".join(interpretaciones_metricas)
            + "."
        )

    # Calificación clínica final por nivel
    if nivel == "BAJO":
        texto += (
            f" Estos hallazgos son clínicamente significativos y sugieren la presencia de "
            f"alteraciones en los procesos cognitivos subyacentes al dominio de {dominio}, "
            f"requiriendo evaluación complementaria."
        )
    elif nivel == "MEDIO":
        texto += (
            f" El perfil observado es compatible con funcionamiento cognitivo limítrofe en el "
            f"dominio de {dominio}, ameritando seguimiento y posible intervención preventiva."
        )
    else:
        texto += (
            f" Los procesos cognitivos correspondientes al dominio de {dominio} "
            f"se encuentran funcionales y preservados."
        )

    return texto


def _interpretar_dominio(dominio: str, ps: list[dict[str, Any]]) -> str:
    """Genera interpretación clínica profesional de un dominio cognitivo con lenguaje neuropsicológico formal."""
    promedio_d = sum(x["porcentaje_obtenido"] for x in ps) / len(ps)
    nivel_d = interpretar_nivel(promedio_d)
    nombres = ", ".join(x["nombre_prueba"] for x in ps)
    tiempo_total = sum(x["tiempo_segundos"] for x in ps)
    n_pruebas = len(ps)
    plural = "s" if n_pruebas > 1 else ""

    frases: dict[str, dict[str, str]] = {
        "Memoria": {
            "ALTO": (
                f"La evaluación del dominio mnésico mediante la{plural} prueba{plural} de {nombres} "
                f"evidencia un funcionamiento mnemónico dentro de los parámetros normativos esperados "
                f"(puntuación media del dominio: {promedio_d:.1f}%). "
                f"Los procesos de codificación, almacenamiento y recuperación de la información "
                f"se encuentran conservados, sin indicadores de compromiso en la consolidación mnésica "
                f"a corto ni a largo plazo. El rendimiento es consistente con una memoria funcional preservada."
            ),
            "MEDIO": (
                f"La exploración del dominio mnésico a través de la{plural} prueba{plural} de {nombres} "
                f"revela un rendimiento en rango limítrofe (puntuación media: {promedio_d:.1f}%). "
                f"Se aprecian dificultades leves en alguna de las fases del proceso mnésico —codificación, "
                f"consolidación o evocación—, que, si bien no alcanzan criterios de deterioro clínicamente "
                f"significativo de forma aislada, merecen seguimiento sistemático dado su potencial evolución."
            ),
            "BAJO": (
                f"Los hallazgos en el dominio mnésico, evaluado mediante la{plural} prueba{plural} de {nombres}, "
                f"revelan un rendimiento significativamente por debajo de los parámetros normativos para la edad "
                f"(puntuación media: {promedio_d:.1f}%). "
                f"El perfil obtenido es compatible con alteraciones en uno o más componentes del proceso mnésico: "
                f"dificultades en la codificación de nueva información, en su consolidación a corto plazo "
                f"o en los mecanismos de recuperación libre y/o con claves. "
                f"Estos hallazgos revisten relevancia clínica y justifican la derivación para evaluación especializada."
            ),
        },
        "Atención": {
            "ALTO": (
                f"La exploración de los procesos atencionales mediante la{plural} prueba{plural} de {nombres} "
                f"demuestra una capacidad atencional sostenida y selectiva funcionalmente preservada "
                f"(puntuación media: {promedio_d:.1f}%). "
                f"No se evidenciaron fluctuaciones relevantes en la vigilancia, ni patrones de inatención, "
                f"impulsividad o fatiga cognitiva prematura durante la ejecución de las tareas. "
                f"La velocidad de procesamiento y la regulación atencional se encuentran dentro de rangos normativos."
            ),
            "MEDIO": (
                f"La valoración del dominio atencional mediante la{plural} prueba{plural} de {nombres} "
                f"revela un rendimiento en rango limítrofe (puntuación media: {promedio_d:.1f}%), "
                f"con fluctuaciones en el sostenimiento del foco atencional bajo demanda continua. "
                f"Se identifican omisiones y/o variabilidad en los tiempos de reacción compatibles con "
                f"dificultades en la atención sostenida, sin que esto constituya un déficit atencional "
                f"primario de grado severo en el contexto de la presente evaluación."
            ),
            "BAJO": (
                f"La evaluación del dominio atencional mediante la{plural} prueba{plural} de {nombres} "
                f"evidencia dificultades marcadas en la regulación y el sostenimiento del proceso atencional "
                f"(puntuación media: {promedio_d:.1f}%). "
                f"El patrón de errores de comisión, omisiones y/o latencias de respuesta elevadas observado "
                f"es clínicamente consistente con compromiso significativo de los sistemas atencionales, "
                f"con impacto probable en el funcionamiento cognitivo global y en las actividades de la vida diaria."
            ),
        },
        "Funciones Ejecutivas": {
            "ALTO": (
                f"La valoración de las funciones ejecutivas mediante la{plural} prueba{plural} de {nombres} "
                f"evidencia un funcionamiento ejecutivo preservado dentro de parámetros normativos "
                f"(puntuación media: {promedio_d:.1f}%). "
                f"Se constata integridad en los procesos de planificación, flexibilidad cognitiva, "
                f"control inhibitorio y autorregulación conductual. "
                f"No se identificaron dificultades en la alternancia de sets cognitivos ni en la "
                f"inhibición de respuestas prepotentes."
            ),
            "MEDIO": (
                f"La exploración de las funciones ejecutivas mediante la{plural} prueba{plural} de {nombres} "
                f"sitúa el rendimiento en un rango limítrofe (puntuación media: {promedio_d:.1f}%). "
                f"Se aprecian dificultades leves en alguno de los componentes ejecutivos, "
                f"particularmente en el control inhibitorio, la velocidad de alternancia entre conjuntos "
                f"cognitivos o la planificación bajo presión temporal, sin configurar un compromiso ejecutivo "
                f"de grado clínicamente severo en el momento de la evaluación."
            ),
            "BAJO": (
                f"Los resultados en el dominio de funciones ejecutivas, obtenidos mediante la{plural} "
                f"prueba{plural} de {nombres}, revelan compromiso significativo del funcionamiento ejecutivo "
                f"(puntuación media: {promedio_d:.1f}%). "
                f"Se evidencia alteración en los procesos de control inhibitorio, planificación "
                f"y/o flexibilidad cognitiva, lo que puede traducirse en dificultades para la gestión "
                f"autónoma de actividades complejas de la vida cotidiana. "
                f"El perfil ejecutivo obtenido amerita evaluación neurológica complementaria."
            ),
        },
        "Lenguaje": {
            "ALTO": (
                f"La evaluación del dominio lingüístico mediante la{plural} prueba{plural} de {nombres} "
                f"evidencia un funcionamiento verbal dentro de los parámetros normativos "
                f"(puntuación media: {promedio_d:.1f}%). "
                f"La fluencia verbal, el acceso léxico y la organización del discurso "
                f"se encuentran conservados. No se identificaron anomias, parafasias "
                f"ni dificultades en la comprensión verbal."
            ),
            "MEDIO": (
                f"La valoración del dominio lingüístico mediante la{plural} prueba{plural} de {nombres} "
                f"sitúa el rendimiento en rango limítrofe (puntuación media: {promedio_d:.1f}%). "
                f"Se aprecian dificultades leves en la evocación léxica bajo condiciones de tiempo "
                f"limitado o restricciones semánticas/fonológicas, sin constituir un compromiso "
                f"lingüístico primario de grado significativo."
            ),
            "BAJO": (
                f"Los hallazgos en el dominio del lenguaje, valorados mediante la{plural} prueba{plural} "
                f"de {nombres}, evidencian dificultades clínicamente significativas en la producción "
                f"y/o comprensión verbal (puntuación media: {promedio_d:.1f}%). "
                f"La reducción marcada en la fluencia verbal, el acceso léxico limitado "
                f"y/o las dificultades en la organización discursiva justifican la derivación "
                f"a valoración fonoaudiológica especializada y, de ser pertinente, estudio de neuroimagen."
            ),
        },
        "Dominio no especificado": {
            "ALTO": (
                f"La evaluación mediante la{plural} prueba{plural} de {nombres} "
                f"no evidencia alteraciones cognitivas en este dominio (puntuación media: {promedio_d:.1f}%), "
                f"con un rendimiento dentro de parámetros funcionales adecuados."
            ),
            "MEDIO": (
                f"La prueba{plural} de {nombres} arrojó un rendimiento en rango limítrofe "
                f"(puntuación media: {promedio_d:.1f}%), requiriendo monitoreo clínico periódico "
                f"para evaluar su evolución."
            ),
            "BAJO": (
                f"Los resultados de la{plural} prueba{plural} de {nombres} "
                f"(puntuación media: {promedio_d:.1f}%) revelan dificultades cognitivas clínicamente relevantes "
                f"que justifican intervención y seguimiento profesional especializado."
            ),
        },
    }

    texto_dominio = frases.get(dominio, frases["Dominio no especificado"]).get(nivel_d, "")
    return (
        f"{dominio.upper()}: "
        + texto_dominio
        + f" Tiempo total de ejecución en este dominio: {tiempo_total} segundos."
    )


def _recomendaciones_por_dominio(dominios: dict[str, list[dict[str, Any]]]) -> str:
    """Genera recomendaciones clínicas formales y específicas por dominio comprometido."""
    recomendaciones: list[str] = []

    recs_bajo: dict[str, str] = {
        "Memoria": (
            "En virtud del compromiso mnésico evidenciado, se recomienda derivación a neuropsicología "
            "clínica para evaluación comprehensiva de los procesos de memoria mediante baterías "
            "neuropsicológicas estandarizadas (p. ej., RAVLT, WMS-IV o equivalentes). "
            "Se sugiere descartar etiologías reversibles: déficit de vitamina B12, hipotiroidismo, "
            "síndrome de apnea del sueño y factores farmacológicos. "
            "La implementación de estrategias compensatorias (sistemas de recordatorio externos, "
            "técnicas de codificación semántica y repetición espaciada) es aconsejable "
            "como medida de soporte funcional. Control neuropsicológico en un plazo de 3 meses."
        ),
        "Atención": (
            "Dado el compromiso atencional identificado, se recomienda valoración psiquiátrica "
            "y/o neurológica orientada a descartar trastorno por déficit de atención e hiperactividad "
            "en el adulto (TDAH), trastorno del sueño o condiciones médicas subyacentes. "
            "Se sugiere implementar intervención cognitiva estructurada de entrenamiento atencional "
            "(Attention Process Training o equivalente) y adaptaciones en el entorno para minimizar "
            "la carga cognitiva. Control en 3 meses o según criterio del especialista."
        ),
        "Funciones Ejecutivas": (
            "El compromiso ejecutivo evidenciado justifica derivación a neuropsicología clínica "
            "y consulta neurológica para descartar patología frontal o subcortical. "
            "Se recomienda evaluación del impacto funcional en actividades instrumentales de la vida diaria "
            "(AIVD) mediante escalas validadas (p. ej., DAD o IADL). "
            "La intervención debe incluir entrenamiento en planificación asistida, "
            "descomposición de tareas complejas y psicoeducación en autorregulación. "
            "Control de seguimiento en 3 meses."
        ),
        "Lenguaje": (
            "Las dificultades lingüísticas identificadas ameritan derivación a fonoaudiología "
            "para evaluación formal mediante protocolos estandarizados "
            "(p. ej., Boston Diagnostic Aphasia Examination o equivalente). "
            "De existir deterioro de instauración aguda o progresiva, se recomienda "
            "estudio de neuroimagen estructural (RM cerebral). "
            "Evaluar la función auditiva como factor contribuyente. "
            "Control multidisciplinario en 3 meses."
        ),
        "Dominio no especificado": (
            "Los resultados obtenidos justifican derivación a neuropsicología clínica "
            "para evaluación cognitiva comprehensiva mediante batería neuropsicológica completa. "
            "Control de seguimiento en 3 meses o según criterio del profesional responsable."
        ),
    }

    recs_medio: dict[str, str] = {
        "Memoria": (
            "El rendimiento mnésico limítrofe identificado sugiere la implementación de un "
            "programa estructurado de estimulación cognitiva orientado a memoria, "
            "con énfasis en técnicas de codificación profunda, repetición espaciada y "
            "uso de estrategias mnemónicas (método loci, encadenamiento semántico). "
            "Se recomienda evaluar la calidad del sueño y los niveles de estrés como "
            "factores moduladores. Control neuropsicológico en 6 meses."
        ),
        "Atención": (
            "El perfil atencional limítrofe observado aconseja intervención preventiva "
            "mediante entrenamiento de atención sostenida y selectiva con apoyo profesional. "
            "Se recomienda evaluación de la higiene del sueño, niveles de ansiedad "
            "y hábitos de uso de tecnología como variables moduladoras. "
            "Control neuropsicológico en 6 meses."
        ),
        "Funciones Ejecutivas": (
            "El rendimiento ejecutivo limítrofe identificado sugiere la implementación de "
            "estrategias de organización y planificación personal (agendas estructuradas, "
            "técnicas de priorización y gestión del tiempo), complementadas con "
            "psicoeducación sobre el funcionamiento ejecutivo y estrategias de autorregulación. "
            "Control en 6 meses."
        ),
        "Lenguaje": (
            "Las dificultades leves en el dominio lingüístico aconsejan la práctica sistemática "
            "de ejercicios de fluencia verbal (categorías semánticas y fonológicas) "
            "y estimulación del acceso léxico. "
            "Si los síntomas persisten o progresan, derivar a fonoaudiología. "
            "Control en 6 meses."
        ),
        "Dominio no especificado": (
            "Se recomienda estimulación cognitiva multidominio y monitoreo clínico periódico. "
            "Control neuropsicológico en 6 meses."
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
