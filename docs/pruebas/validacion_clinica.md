# Protocolo preliminar de validación clínica

Estado: propuesta para revisión del director de tesis y responsable clínico.
No se ha reclutado, evaluado ni consentido a ningún participante mediante este
trabajo de programación. No constituye una validación clínica terminada.

## Definición antes de reclutar

Precisar qué puntaje de NeuroApp se investigará, su rango, dirección, constructo,
algoritmo y versión. Congelar ese algoritmo antes de obtener la muestra; ajustar
pesos después de ver los resultados requiere una muestra de validación independiente.
Comparar dominios compatibles: un porcentaje de un juego no es automáticamente
equivalente a cognición global, MoCA o MMSE. Elegir instrumento, versión e idioma
con el profesional responsable. No mezclar MoCA y MMSE en una misma correlación.

Especificar población, ámbito, inclusión/exclusión, reclutamiento consecutivo o
procedimiento elegido, educación/edad/condiciones relevantes, manejo de pérdidas
y adaptaciones sensoriales. El tamaño muestral debe justificarse con un profesional
de estadística según la precisión deseada, correlación/ICC esperada y pérdidas;
los 5–10 usuarios de SUS no constituyen por sí mismos la muestra clínica necesaria.

Establecer hipótesis y análisis primarios antes de recolectar datos. Registrar
las decisiones y cualquier desviación posterior. Consultar la guía metodológica
[COSMIN para propiedades de medición](https://www.cosmin.nl/finding-right-tool/conducting-study-measurement-properties/)
como apoyo, atendiendo a que sus listas se desarrollaron para instrumentos de
resultados reportados por pacientes y requieren adaptación al constructo cognitivo.

## Ética y administración

Obtener la evaluación/aprobación institucional correspondiente y un consentimiento
informado revisado por el equipo responsable antes del reclutamiento. Definir cómo
se valorará la capacidad de consentir y el procedimiento aplicable cuando proceda
representación; no inferir consentimiento por usar la app. Preparar en lenguaje
comprensible objetivo, procedimientos, tiempo, molestias, voluntariedad, retiro,
confidencialidad, destinatarios de resultados y contacto del investigador/comité.
Los registros de consentimiento identificables deben mantenerse separados de los
datos analíticos codificados. Definir retención, responsables y acceso.

La administración del comparador corresponde a personal habilitado y entrenado.
Comprobar [permisos de MoCA](https://www.mocacognition.com/permission) y
[requisitos de formación/certificación](https://mocacognition.com/training-certification/)
para el uso concreto; verificar también derechos y condiciones de MMSE si se elige.
No reproducir los ítems de esas pruebas en el repositorio sin permiso.

## Diseño y recogida

1. Aplicar NeuroApp y el comparador en condiciones estandarizadas; fijar y, si
   procede, contrabalancear el orden para controlar fatiga/aprendizaje.
2. Mantener al evaluador del comparador ajeno al resultado de NeuroApp cuando sea
   viable, y documentar cualquier falta de cegamiento.
3. Reaplicar NeuroApp en un intervalo justificado y acordado previamente. Registrar
   los días reales, estabilidad clínica, intervenciones y cambios relevantes.
4. Conservar versión, dispositivo, asistencia, interrupciones, datos faltantes y
   motivos de exclusión. No excluir retrospectivamente resultados discrepantes.
5. Usar códigos C001…; copiar `plantillas/clinical.csv`. `reference_test` debe
   identificar instrumento/versión/idioma y `consent=yes` solo cuando está verificado.
   Guardar covariables en un archivo protegido separado; el CSV analítico no necesita
   nombres, documentos ni informes clínicos completos.

## Análisis preparado

```powershell
.qa-venv\Scripts\python.exe scripts/qa/analyze_studies.py clinical ruta/clinical.csv --output artifacts/studies/clinical.json
```

El script rechaza duplicados, datos no finitos, escalas mezcladas y retest previo.
Calcula Pearson con IC Fisher cuando es posible, Spearman, ICC(A,1) de acuerdo
absoluto para NeuroApp inicial/retest, sesgo y límites de Bland–Altman. Incluye un
IC bootstrap percentil del ICC, remuestreando participantes con semilla fija.
El IC y los valores p son exploratorios y pueden ser inestables con muestras pequeñas;
revisar supuestos y método con estadística antes de interpretarlos. El mínimo técnico
de tres pares del script no es un tamaño clínicamente suficiente.

Pearson/Spearman altos no prueban acuerdo, precisión diagnóstica ni sustitución del
comparador. Un desplazamiento sistemático puede conservar correlación perfecta y
reducir el acuerdo; existe una prueba unitaria específica que verifica esa diferencia.
Los límites de Bland–Altman inicial/retest están en unidades de NeuroApp. No comparar
directamente mediante esos límites puntajes de escalas distintas.

Agregar gráficas de dispersión, análisis de supuestos, IC y pérdidas al informe.
Si se desea sensibilidad/especificidad o puntos de corte diagnósticos, hace falta
otro diseño con referencia clínica adecuada, umbrales predefinidos y validación
independiente. Este protocolo no los estima ni asigna diagnósticos.

## Informe que debe completarse

Código de aprobación, versión de consentimiento, registro del protocolo, diagrama
de participantes, características agregadas, resultados con IC, pérdidas, intervalos
reales, limitaciones, efecto de práctica y conclusión limitada a población y versión
estudiadas. Conservar un registro verificable de la procedencia de cada resultado.
