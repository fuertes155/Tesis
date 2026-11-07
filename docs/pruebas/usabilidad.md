# Estudio exploratorio de usabilidad

Estado: preparado; requiere reclutar participantes y aplicar el instrumento.
Responsable, institución, versión de NeuroApp, fechas y aprobaciones: completar
antes de iniciar. No presentar esta plantilla como un estudio ejecutado.

## Participantes y condiciones

Reclutar entre 5 y 10 psicólogos o médicos del perfil que usará la aplicación.
Registrar profesión y experiencia de forma agregada, usar códigos U01… y evitar
documentos, nombres de pacientes y datos identificables. Explicar la participación
voluntaria, el retiro, la finalidad, la duración y el uso de observaciones. Definir
la autorización institucional necesaria, almacenamiento, acceso y retención antes
de recoger datos. Para grabar pantalla/voz, obtener autorización específica.

Realizar las tareas con pacientes sintéticos, la misma versión y condiciones
comparables. Registrar dispositivo, tamaño de pantalla, navegador, red y si utiliza
ayudas de visión. No explicar cómo resolver cada tarea durante el intento; registrar
la ayuda cuando se solicite. La muestra pequeña descubre problemas y estima
percepción; no representa estadísticamente a todos los profesionales.

## Guion (aproximadamente 25–35 minutos)

1. Explicación y autorización de participación (5 min).
2. Iniciar sesión con las credenciales entregadas.
3. Crear un paciente sintético y localizarlo mediante búsqueda.
4. Iniciar una evaluación y completar una prueba disponible.
5. Encontrar el resultado, abrir el informe y localizar su opción de descarga.
6. Consultar el historial y explicar con sus palabras qué entiende de la evolución.
7. Cerrar sesión.
8. Aplicar SUS después del uso y antes de discutir mejoras (3–5 min).
9. Entrevista breve: principal dificultad, elemento confuso y mejora prioritaria.

Definir de antemano éxito y límite de tiempo por tarea. Registrar en
`plantillas/tasks.csv` tiempo, éxito sin ayuda, errores, ayudas y observaciones.
No reemplazar un intento fallido por otro asistido sin conservar ambos registros.

## Cuestionario y puntuación

Usar los diez ítems del [instrumento SUS publicado por Brooke, alojado por AHRQ](https://digital.ahrq.gov/sites/default/files/docs/survey/systemusabilityscale%2528sus%2529_comp%255B1%255D.pdf).
Para aplicación en español, seleccionar y citar una adaptación validada para el
contexto con el director de tesis; registrar su referencia/versión y respetar su
redacción, orden y escala. Una traducción improvisada o preguntas propias no se
deben describir como una versión validada. Este repositorio no incluye una nueva
traducción que aparente esa validación.

Escala de respuesta 1–5 con los anclajes del instrumento. En los ítems impares
restar 1; en los pares restar la respuesta a 5; sumar y multiplicar por 2,5.
El rango 0–100 no es porcentaje de éxito ni probabilidad. No completar respuestas
faltantes. Aplicar la misma versión a todos los participantes.

Copiar `plantillas/sus.csv`, diligenciar q1…q10 y ejecutar:

```powershell
.qa-venv\Scripts\python.exe scripts/qa/analyze_studies.py sus ruta/sus.csv --output artifacts/studies/sus.json
```

El script valida diez enteros 1–5 y códigos únicos, calcula puntajes individuales,
media, desviación estándar e intervalo t aproximado del 95 %. Con muestras pequeñas
reportar la incertidumbre y los problemas por tarea; no declarar aprobación solo
por superar una referencia de SUS. Los límites del intervalo t no se recortan
artificialmente a 0–100.

## Informe que debe completarse

Documentar reclutamiento y exclusiones, n efectivo, perfiles agregados, protocolo,
versión de instrumento, media/SD/IC, éxito y tiempos por tarea, citas anónimas,
problemas priorizados, correcciones y una segunda ronda si se realizaron cambios.
Separar opinión profesional sobre usabilidad de la validez de los puntajes clínicos.
