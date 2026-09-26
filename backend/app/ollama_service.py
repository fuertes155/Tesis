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
MAX_TOKENS_REPORTE = int(os.getenv("OLLAMA_NUM_PREDICT", "1300"))        # informe clínico (~520 palabras)
MAX_PRUEBAS_PROMPT = int(os.getenv("OLLAMA_MAX_PRUEBAS_PROMPT", "6"))
MAX_CHARS_PROMPT = int(os.getenv("OLLAMA_MAX_PROMPT_CHARS", "6000"))
MAX_PALABRAS_REPORTE = 520

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
        "items_to_remember": "estímulos por serie en el último nivel",
        "prompt": "consigna de fluidez (categoría semántica o letra)",
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

    prompt = f"""Actúa como neuropsicólogo clínico con experiencia en evaluación cognitiva del adulto. \
Redacta en español un INFORME NEUROPSICOLÓGICO de tamizaje (máximo {MAX_PALABRAS_REPORTE} palabras) \
a partir de los datos de una evaluación digital.

FORMATO OBLIGATORIO:
Usa exactamente estas secciones y en este orden. Cada título va solo en su línea, en MAYÚSCULAS y terminado en dos puntos.
Texto plano: sin asteriscos, almohadillas, guiones ni viñetas. Tercera persona, registro clínico formal, sin relleno.

MOTIVO DE EVALUACIÓN:
Una o dos oraciones: paciente, profesional solicitante, antecedente y número de pruebas.
INSTRUMENTOS APLICADOS:
Una línea por prueba con el formato "Nombre de la prueba: qué función cognitiva explora."
OBSERVACIONES DE LA EJECUCIÓN:
Una línea por prueba con métricas, formato "Nombre de la prueba: lectura clínica" (velocidad, variabilidad, impulsividad, errores de interferencia, producción verbal).
INTERPRETACIÓN CLÍNICA POR DOMINIO:
Una línea por dominio con el formato "Dominio: Rendimiento <nivel> (<puntaje>%). <interpretación con terminología neuropsicológica>".
IMPRESIÓN CLÍNICA:
Un párrafo: índice global, patrón del perfil (focal, heterogéneo o global), relación con la edad y el antecedente. \
Usa calificadores ("compatible con", "sugiere", "no puede descartarse"); nunca diagnósticos definitivos.
IMPRESIÓN DIAGNÓSTICA:
Líneas "Categoría: ...", "Equivalencia DSM-5: ..." (si aplica), "Fundamento: ..." y "Confirmación: ...". \
Criterios (Petersen 2004 y DSM-5): todos los dominios ALTO = funcionamiento normal; índice global >= 70% sin dominios BAJO \
y un solo dominio MEDIO = dentro de lo esperado con dificultad aislada; índice 41-69% o algún dominio BAJO = deterioro cognitivo leve probable \
(subtipo amnésico o no amnésico, de dominio único o múltiple); índice <= 40% con dos o más dominios BAJO = deterioro \
cognitivo mayor probable; un solo dominio explorado = indeterminada. Siempre como impresión presuntiva de tamizaje.
RECOMENDACIONES:
Una línea por dominio BAJO o MEDIO ("Dominio: recomendación concreta"), estudios complementarios si hay nivel BAJO \
y una última línea "Reevaluación neuropsicológica sugerida en N meses." (3 si hay BAJO, 6 si hay MEDIO, 12 si todo es ALTO).
LIMITACIONES:
Una o dos oraciones: tamizaje computarizado, sin baremos por edad ni escolaridad.

DATOS DEL PACIENTE:
Nombre completo: {datos["nombre_paciente"]}
Edad: {datos["edad_paciente"]} años (0 significa no registrada)
Antecedente clínico: {datos.get("diagnostico_paciente") or "No registrado"}
Profesional evaluador/a: {datos["profesional"]}
Fecha de la evaluación: {datos["fecha_evaluacion"]}
Índice global: {promedio_global:.1f}% ({nivel_global})
Dominios comprometidos (BAJO o MEDIO): {", ".join(dominios_comprometidos) or "ninguno"}
Dominios preservados (ALTO): {", ".join(dominios_preservados) or "ninguno"}
Escala: BAJO 0-40%, MEDIO 41-69%, ALTO 70-100%.

PRUEBAS APLICADAS:
{pruebas_json}{nota_pruebas}
{bloque_metricas}

Escribe solo el informe, sin preámbulos ni despedidas.
""".strip()

    if len(prompt) > MAX_CHARS_PROMPT:
        prompt = prompt[:MAX_CHARS_PROMPT].rstrip() + "\n[Contenido truncado por límite de contexto.]"

    return prompt


# ── Reporte local (sin Ollama) ─────────────────────────────────────────────────
# Redactado con criterio neuropsicológico: motivo, instrumentos, observaciones de
# la ejecución, interpretación por dominio, impresión clínica, recomendaciones y
# limitaciones. Cada encabezado va en MAYÚSCULAS seguido de (:) para el parser de
# Flutter. Las líneas "Etiqueta: texto" se muestran como filas etiquetadas.

_MESES_CONTROL = {"BAJO": 3, "MEDIO": 6, "ALTO": 12}

_DESCRIPTOR_NIVEL = {
    "ALTO": "dentro de lo esperado",
    "MEDIO": "rango limítrofe",
    "BAJO": "por debajo de lo esperado",
}

_MESES = (
    "enero", "febrero", "marzo", "abril", "mayo", "junio", "julio",
    "agosto", "septiembre", "octubre", "noviembre", "diciembre",
)

_INSTRUMENTOS: dict[str, str] = {
    "Memoria": (
        "reconocimiento de estímulos visoespaciales con carga creciente; explora memoria "
        "de trabajo visoespacial y recuerdo inmediato."
    ),
    "Atención": (
        "tiempo de reacción ante estímulos visuales; explora vigilancia, velocidad de "
        "procesamiento e impulsividad."
    ),
    "Funciones Ejecutivas": (
        "paradigma de interferencia color-palabra; explora control inhibitorio y "
        "atención selectiva."
    ),
    "Lenguaje": (
        "evocación de palabras en 60 s ante consigna semántica o fonológica; explora "
        "acceso léxico y estrategias de búsqueda verbal."
    ),
    "Dominio no especificado": "tarea cognitiva computarizada.",
}

_INTERPRETACION: dict[str, dict[str, str]] = {
    "Memoria": {
        "ALTO": "La codificación y el recuerdo inmediato de información visoespacial se encuentran preservados.",
        "MEDIO": (
            "Sugiere dificultades leves en la codificación o en la recuperación de información "
            "visoespacial, sin alcanzar un compromiso clínicamente significativo."
        ),
        "BAJO": (
            "Compatible con compromiso de la memoria de trabajo visoespacial y del recuerdo inmediato; "
            "debe precisarse si afecta la codificación, la consolidación o la evocación."
        ),
    },
    "Atención": {
        "ALTO": "Capacidad de vigilancia y velocidad de respuesta conservadas, sin indicadores de fatigabilidad.",
        "MEDIO": (
            "Sugiere fluctuaciones en la atención sostenida o un enlentecimiento leve de la "
            "velocidad de procesamiento."
        ),
        "BAJO": (
            "Compatible con compromiso de la atención sostenida, con posible repercusión sobre "
            "los dominios que dependen de los recursos atencionales."
        ),
    },
    "Funciones Ejecutivas": {
        "ALTO": "Control inhibitorio y resistencia a la interferencia preservados.",
        "MEDIO": "Sugiere dificultad leve para inhibir respuestas automáticas bajo condiciones de interferencia.",
        "BAJO": (
            "Compatible con disfunción ejecutiva, con compromiso del control inhibitorio y de la "
            "flexibilidad cognitiva, hallazgo habitualmente asociado a circuitos frontosubcorticales."
        ),
    },
    "Lenguaje": {
        "ALTO": "Acceso léxico y organización de la búsqueda verbal preservados.",
        "MEDIO": "Sugiere leve reducción en la eficiencia del acceso léxico o de las estrategias de búsqueda verbal.",
        "BAJO": (
            "Compatible con compromiso de la fluidez verbal; conviene diferenciar un origen "
            "lingüístico (acceso léxico-semántico) de uno ejecutivo (estrategias de búsqueda)."
        ),
    },
    "Dominio no especificado": {
        "ALTO": "Sin alteraciones relevantes en la tarea aplicada.",
        "MEDIO": "Rendimiento limítrofe que amerita seguimiento.",
        "BAJO": "Dificultades clínicamente relevantes que ameritan evaluación ampliada.",
    },
}

_RECOMENDACION: dict[str, dict[str, str]] = {
    "BAJO": {
        "Memoria": (
            "evaluación ampliada de memoria verbal y visual con pruebas estandarizadas "
            "(p. ej., RAVLT, Figura de Rey) y estrategias compensatorias externas."
        ),
        "Atención": (
            "valoración neurológica o psiquiátrica para descartar causas secundarias "
            "(sueño, fármacos, TDAH) y entrenamiento atencional estructurado."
        ),
        "Funciones Ejecutivas": (
            "evaluación ejecutiva ampliada (p. ej., TMT A/B, WCST) y rehabilitación centrada "
            "en planificación y autorregulación."
        ),
        "Lenguaje": (
            "valoración por fonoaudiología con exploración formal de denominación, comprensión "
            "y repetición."
        ),
        "Dominio no especificado": "evaluación neuropsicológica ampliada.",
    },
    "MEDIO": {
        "Memoria": "estimulación cognitiva con estrategias de codificación profunda y repetición espaciada.",
        "Atención": "entrenamiento de atención sostenida y revisión de higiene del sueño y niveles de estrés.",
        "Funciones Ejecutivas": "estrategias de organización y planificación (agenda estructurada, fraccionamiento de tareas).",
        "Lenguaje": "ejercicios de fluidez verbal semántica y fonológica.",
        "Dominio no especificado": "estimulación cognitiva y monitoreo periódico.",
    },
}

# Palabras clave del antecedente -> consideración clínica para la impresión.
_ANTECEDENTES: tuple[tuple[tuple[str, ...], str], ...] = (
    (("depres",), "El antecedente de depresión puede afectar la atención y la memoria; debe considerarse el componente afectivo en la interpretación."),
    (("ansied",), "La ansiedad puede interferir con la atención y el control inhibitorio; conviene valorar su efecto sobre el desempeño."),
    (("tdah", "déficit de atención", "deficit de atencion", "hiperactiv"), "Los hallazgos deben interpretarse a la luz del antecedente de TDAH."),
    (("tce", "traumatismo", "trauma craneo", "trauma cráneo"), "El antecedente de traumatismo craneoencefálico es relevante para interpretar las dificultades atencionales y ejecutivas."),
    (("acv", "ictus", "cerebrovascular", "infarto cerebral"), "El antecedente cerebrovascular obliga a correlacionar los hallazgos con la localización y extensión de la lesión."),
    (("alzheimer", "demencia", "deterioro cognitivo"), "Dado el antecedente, se recomienda comparar con evaluaciones previas para estimar la evolución del perfil."),
    (("parkinson",), "La enfermedad de Parkinson se asocia a enlentecimiento y disfunción ejecutiva, aspectos a considerar en la interpretación."),
    (("epilep",), "La epilepsia y su tratamiento farmacológico pueden influir en la atención y la memoria."),
)

_AFECTIVOS = ("depres", "ansied")


def _numero(valor: Any) -> float | None:
    try:
        return float(valor)
    except (TypeError, ValueError):
        return None


def _metrica(metricas: dict[str, Any], *claves: str) -> float | None:
    """Primer valor numérico presente entre las claves dadas (0 cuenta como valor)."""
    for clave in claves:
        if metricas.get(clave) is not None:
            return _numero(metricas[clave])
    return None


def _formatear_fecha(valor: Any) -> str:
    texto = str(valor)
    try:
        anio, mes, dia = (int(x) for x in texto[:10].split("-"))
        return f"{dia} de {_MESES[mes - 1]} de {anio}"
    except (ValueError, IndexError):
        return texto


def _plural(n: int, singular: str, plural: str) -> str:
    return singular if n == 1 else plural


def _observacion_prueba(prueba: dict[str, Any]) -> str | None:
    """Lectura clínica de las métricas de proceso de una prueba."""
    m = prueba.get("metricas_detalladas") or {}
    dominio = prueba["dominio_cognitivo"]
    partes: list[str] = []

    if dominio == "Atención":
        media = _metrica(m, "avg_ms", "tiempo_reaccion_promedio")
        mejor = _metrica(m, "best_ms")
        anticipadas = _metrica(m, "too_early")
        if media:
            if media < 400:
                velocidad = "velocidad de respuesta ágil"
            elif media < 550:
                velocidad = "velocidad de respuesta dentro de lo esperado"
            elif media < 750:
                velocidad = "velocidad de respuesta levemente enlentecida"
            else:
                velocidad = "velocidad de respuesta enlentecida"
            partes.append(f"tiempo de reacción medio de {media:.0f} ms ({velocidad})")
            if mejor and media > 0 and (media - mejor) / media > 0.4:
                partes.append(
                    "variabilidad intraindividual elevada entre ensayos, sugestiva de fluctuaciones atencionales"
                )
        if anticipadas is not None:
            if anticipadas > 0:
                n = int(anticipadas)
                partes.append(
                    f"{n} {_plural(n, 'respuesta anticipatoria', 'respuestas anticipatorias')}, "
                    "indicador de impulsividad o de dificultad para inhibir la respuesta"
                )
            else:
                partes.append("sin respuestas anticipatorias")

    elif dominio == "Funciones Ejecutivas":
        aciertos = _metrica(m, "correct", "aciertos")
        errores = _metrica(m, "wrong", "errores")
        media = _metrica(m, "avg_ms")
        if aciertos is not None and errores is not None and aciertos + errores > 0:
            precision = aciertos * 100 / (aciertos + errores)
            texto = f"{precision:.0f}% de aciertos en ensayos de interferencia ({int(errores)} {_plural(int(errores), 'error', 'errores')})"
            if precision < 70:
                texto += ", con errores de interferencia frecuentes"
            partes.append(texto)
        if media:
            partes.append(
                f"tiempo medio de respuesta de {media:.0f} ms"
                + (", enlentecido bajo interferencia" if media > 1500 else "")
            )

    elif dominio == "Memoria":
        nivel = _metrica(m, "level", "nivel_maximo")
        elementos = _metrica(m, "items_to_remember")
        seleccion = _metrica(m, "avg_selection_ms")
        if nivel:
            texto = f"alcanzó el nivel {nivel:.0f} de la tarea"
            if elementos:
                texto += f" (series de {elementos:.0f} estímulos)"
            partes.append(texto)
        if seleccion:
            partes.append(
                f"tiempo medio de selección de {seleccion:.0f} ms"
                + (", compatible con un estilo de respuesta lento" if seleccion > 2000 else "")
            )

    elif dominio == "Lenguaje":
        palabras = _metrica(m, "count", "palabras_generadas")
        consigna = str(m.get("prompt") or "").strip()
        duracion = _metrica(m, "duration_s") or 60
        if palabras is not None:
            fonologica = consigna.lower().startswith("letra")
            tipo = "fonológica" if fonologica else "semántica"
            detalle = f" ({consigna.lower()})" if consigna else ""
            texto = f"produjo {palabras:.0f} palabras en {duracion:.0f} s en la condición {tipo}{detalle}"
            por_minuto = palabras * 60 / duracion if duracion else palabras
            if por_minuto < (8 if fonologica else 12):
                texto += ", producción reducida"
            partes.append(texto)

    if not partes:
        return None
    texto = "; ".join(partes)
    return f"{prueba['nombre_prueba']}: {texto[:1].upper()}{texto[1:]}."


def _consideracion_antecedente(diagnostico: str | None) -> str | None:
    if not diagnostico:
        return None
    d = diagnostico.lower()
    for claves, texto in _ANTECEDENTES:
        if any(c in d for c in claves):
            return texto
    return f"Los hallazgos deben correlacionarse con el antecedente clínico reportado ({diagnostico})."


def _impresion_diagnostica(
    nivel_por_dominio: dict[str, str],
    promedio_global: float,
    edad: int,
) -> tuple[str, list[str]]:
    """
    Clasificación diagnóstica presuntiva según el índice global y los dominios afectados.

    Sigue los criterios de deterioro cognitivo leve de Petersen (2004) y su equivalencia
    con los trastornos neurocognitivos del DSM-5. Es una impresión de tamizaje: la
    confirmación exige evaluación estandarizada y valoración de la funcionalidad.

    Devuelve (tipo, líneas); tipo es uno de: "normal", "aislado", "dcl", "mayor",
    "indeterminada" o "menor".
    """
    afectados = [d for d, nv in nivel_por_dominio.items() if nv != "ALTO"]
    bajos = [d for d, nv in nivel_por_dominio.items() if nv == "BAJO"]
    total = len(nivel_por_dominio)
    nivel_global = interpretar_nivel(promedio_global)

    def lista(dominios_: list[str]) -> str:
        return _unir([d.lower() for d in dominios_])

    fundamento = f"Índice global de {promedio_global:.1f}% ({nivel_global})"
    if afectados:
        fundamento += (
            f" con {len(afectados)} de {total} {_plural(total, 'dominio', 'dominios')} en rango "
            f"limítrofe o bajo ({lista(afectados)})."
        )
    else:
        fundamento += f" con {_plural(total, 'el dominio explorado', f'los {total} dominios explorados')} dentro de lo esperado."
    confirmacion = (
        "Confirmación: Impresión presuntiva de tamizaje; requiere evaluación neuropsicológica "
        "estandarizada y valoración de la funcionalidad antes de establecer un diagnóstico definitivo."
    )

    equivalencia: str | None = None
    if total == 1:
        tipo = "indeterminada"
        categoria = (
            "Indeterminada. Con un solo dominio explorado no es posible establecer una categoría "
            "diagnóstica; se requiere completar el protocolo integral."
        )
    elif 0 < edad < 18:
        tipo = "menor"
        categoria = (
            f"Dificultades cognitivas específicas en {lista(afectados)}. Las categorías de deterioro "
            "cognitivo del adulto no aplican a esta edad."
            if afectados
            else "Funcionamiento cognitivo dentro de lo esperado para la tarea."
        )
    elif not afectados:
        tipo = "normal"
        categoria = "Funcionamiento cognitivo normal. Sin evidencia de deterioro cognitivo."
    elif not bajos and promedio_global >= 70 and len(afectados) == 1:
        tipo = "aislado"
        categoria = (
            f"Funcionamiento cognitivo dentro de lo esperado, con rendimiento limítrofe aislado en "
            f"{lista(afectados)}. No cumple criterios de deterioro cognitivo."
        )
    elif promedio_global <= 40 and len(bajos) >= 2:
        tipo = "mayor"
        categoria = "Deterioro cognitivo mayor probable."
        equivalencia = (
            "Equivalencia DSM-5: Compatible con trastorno neurocognitivo mayor, sujeto a confirmar "
            "la pérdida de autonomía en las actividades de la vida diaria."
        )
    else:
        tipo = "dcl"
        amnesico = "Memoria" in afectados
        subtipo = (
            f"{'amnésico' if amnesico else 'no amnésico'} de "
            f"{'dominio múltiple' if len(afectados) > 1 else 'dominio único'}"
        )
        categoria = f"Deterioro cognitivo leve (DCL) probable, subtipo {subtipo}."
        equivalencia = (
            "Equivalencia DSM-5: Compatible con trastorno neurocognitivo leve, siempre que se "
            "conserve la autonomía en las actividades de la vida diaria."
        )

    lineas = [f"Categoría: {categoria}"]
    if equivalencia:
        lineas.append(equivalencia)
    lineas.append(f"Fundamento: {fundamento} Criterios de referencia: Petersen (2004) y DSM-5.")
    lineas.append(confirmacion)
    return tipo, lineas


def generar_reporte_local(datos: dict[str, Any]) -> str:
    """
    Genera el informe neuropsicológico sin depender de Ollama.
    Produce texto plano compatible con el parser _splitReportSections de Flutter.
    """
    pruebas = preparar_pruebas(datos)
    nombre = datos["nombre_paciente"]
    edad = int(_numero(datos.get("edad_paciente")) or 0)
    profesional = datos["profesional"]
    diagnostico = (datos.get("diagnostico_paciente") or "").strip() or None

    promedio_global = _promedio(pruebas)
    nivel_global = interpretar_nivel(promedio_global)
    n = len(pruebas)

    dominios = _agrupar_por_dominio(pruebas)
    nivel_por_dominio = {d: interpretar_nivel(_promedio(ps)) for d, ps in dominios.items()}
    bajo = [d for d, nv in nivel_por_dominio.items() if nv == "BAJO"]
    medio = [d for d, nv in nivel_por_dominio.items() if nv == "MEDIO"]
    alto = [d for d, nv in nivel_por_dominio.items() if nv == "ALTO"]

    def lista(dominios_: list[str]) -> str:
        return _unir([d.lower() for d in dominios_])

    # ── Motivo ────────────────────────────────────────────────────────────────
    motivo = (
        f"Evaluación neuropsicológica de tamizaje de {nombre}"
        + (f", de {edad} años" if edad > 0 else "")
        + f", solicitada por {profesional} para caracterizar su funcionamiento cognitivo"
        + (f" en el contexto del antecedente de {diagnostico.lower()}" if diagnostico else "")
        + f". Se aplicaron {n} {_plural(n, 'prueba', 'pruebas')} de la batería digital NeuroApp360"
        + f" el {_formatear_fecha(datos['fecha_evaluacion'])}."
    )

    # ── Instrumentos ──────────────────────────────────────────────────────────
    instrumentos = [
        f"{p['nombre_prueba']}: "
        + _INSTRUMENTOS.get(p["dominio_cognitivo"], _INSTRUMENTOS["Dominio no especificado"])[:1].upper()
        + _INSTRUMENTOS.get(p["dominio_cognitivo"], _INSTRUMENTOS["Dominio no especificado"])[1:]
        for p in pruebas
    ]

    # ── Observaciones de la ejecución ─────────────────────────────────────────
    observaciones = [o for o in (_observacion_prueba(p) for p in pruebas) if o]

    # ── Interpretación por dominio ────────────────────────────────────────────
    interpretacion = []
    for d, ps in dominios.items():
        promedio = _promedio(ps)
        nivel = nivel_por_dominio[d]
        textos = _INTERPRETACION.get(d, _INTERPRETACION["Dominio no especificado"])
        descriptor = "en rango limítrofe" if nivel == "MEDIO" else _DESCRIPTOR_NIVEL[nivel]
        interpretacion.append(f"{d}: Rendimiento {descriptor} ({promedio:.1f}%). {textos[nivel]}")

    # ── Impresión clínica ─────────────────────────────────────────────────────
    impresion = [
        f"El índice de rendimiento global fue de {promedio_global:.1f}%, correspondiente a un "
        f"nivel {nivel_global} ({_DESCRIPTOR_NIVEL[nivel_global]})."
    ]
    if len(dominios) == 1:
        unico = next(iter(dominios))
        impresion.append(
            f"Solo se exploró el dominio de {unico.lower()}, por lo que los hallazgos no permiten "
            "caracterizar el perfil cognitivo global."
        )
    elif not bajo and not medio:
        impresion.append("El perfil cognitivo es homogéneo y se encuentra dentro de lo esperado en todos los dominios explorados.")
    elif alto:
        rasgos = []
        if bajo:
            rasgos.append(f"compromiso en {lista(bajo)}")
        if medio:
            rasgos.append(f"rendimiento limítrofe en {lista(medio)}")
        rasgos.append(f"preservación de {lista(alto)}")
        impresion.append(
            f"Se observa un perfil heterogéneo: {', '.join(rasgos[:-1])} y {rasgos[-1]}. "
            "Este patrón orienta a dificultades focales más que a un compromiso cognitivo global."
        )
    else:
        impresion.append(
            f"Se observa afectación en todos los dominios explorados ({lista(bajo + medio)}), "
            "patrón que sugiere un compromiso cognitivo de carácter más global."
        )

    atencion = nivel_por_dominio.get("Atención")
    otros_afectados = [d for d in bajo + medio if d != "Atención"]
    if atencion in ("BAJO", "MEDIO") and otros_afectados:
        impresion.append(
            "Dado el compromiso atencional, el menor rendimiento en otros dominios podría estar "
            "parcialmente mediado por una reducción de los recursos atencionales."
        )
    if nivel_por_dominio.get("Memoria") == "BAJO" and edad >= 60:
        impresion.append(
            f"En el contexto de la edad ({edad} años), el compromiso mnésico amerita descartar un "
            "deterioro cognitivo leve de tipo amnésico."
        )
    consideracion = _consideracion_antecedente(diagnostico)
    if consideracion:
        impresion.append(consideracion)

    # ── Impresión diagnóstica ─────────────────────────────────────────────────
    tipo_diagnostico, diagnostica = _impresion_diagnostica(nivel_por_dominio, promedio_global, edad)

    # ── Recomendaciones ───────────────────────────────────────────────────────
    recomendaciones: list[str] = []
    for d in bajo + medio:
        recs = _RECOMENDACION[nivel_por_dominio[d]]
        texto = recs.get(d, recs["Dominio no especificado"])
        recomendaciones.append(f"{d}: {texto[:1].upper()}{texto[1:]}")
    if bajo:
        recomendaciones.append(
            "Estudios complementarios: Valoración neurológica y, según criterio clínico, neuroimagen "
            "estructural (RM cerebral) y laboratorio (vitamina B12, función tiroidea)."
        )
    if tipo_diagnostico == "mayor":
        recomendaciones.append(
            "Valoración funcional: Escalas de actividades básicas e instrumentales (Barthel, Lawton y Brody) "
            "y entrevista con un informante para confirmar la pérdida de autonomía."
        )
    elif tipo_diagnostico == "dcl":
        recomendaciones.append(
            "Valoración funcional: Escala de Lawton y Brody para confirmar que se conserva la autonomía "
            "en las actividades instrumentales, criterio necesario para el DCL."
        )
    if diagnostico and any(a in diagnostico.lower() for a in _AFECTIVOS):
        recomendaciones.append(
            "Salud mental: Abordaje de los factores emocionales que puedan interferir con el rendimiento cognitivo."
        )
    if len(dominios) == 1:
        recomendaciones.append(
            "Exploración complementaria: Aplicar el protocolo integral para caracterizar el perfil cognitivo completo."
        )
    if not bajo and not medio:
        recomendaciones.append(
            "Factores protectores: Mantener actividad cognitiva, física y social de forma regular."
        )
    peor = "BAJO" if bajo else ("MEDIO" if medio else "ALTO")
    recomendaciones.append(f"Reevaluación neuropsicológica sugerida en {_MESES_CONTROL[peor]} meses.")

    # ── Limitaciones ──────────────────────────────────────────────────────────
    limitaciones = (
        "Tamizaje computarizado: los puntajes no están baremados por edad ni escolaridad y no "
        "sustituyen una evaluación neuropsicológica estandarizada."
    )
    if edad <= 0:
        limitaciones += " La edad no fue registrada, por lo que la interpretación no pudo ajustarse a este factor."
    limitaciones += (
        " El desempeño pudo verse influido por fatiga, motivación o familiaridad con dispositivos digitales."
    )

    partes: list[str] = [
        "MOTIVO DE EVALUACIÓN:",
        motivo,
        "",
        "INSTRUMENTOS APLICADOS:",
        *instrumentos,
    ]
    if observaciones:
        partes += ["", "OBSERVACIONES DE LA EJECUCIÓN:", *observaciones]
    partes += [
        "",
        "INTERPRETACIÓN CLÍNICA POR DOMINIO:",
        *interpretacion,
        "",
        "IMPRESIÓN CLÍNICA:",
        " ".join(impresion),
        "",
        "IMPRESIÓN DIAGNÓSTICA:",
        *diagnostica,
        "",
        "RECOMENDACIONES:",
        *recomendaciones,
        "",
        "LIMITACIONES:",
        limitaciones,
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
