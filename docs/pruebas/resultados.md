# Resultados locales de verificación

**Corte:** 6 de noviembre de 2026. Evidencia obtenida en Windows 11; es una
ejecución local de desarrollo, no una certificación ni una ejecución de CI.
Se conservan límites y fallos junto con los resultados para no convertir una
prueba incompleta en aprobación.

## Pruebas repetibles

| Área | Resultado | Evidencia y alcance |
|---|---|---|
| Backend | **209/209 pasan**; repetido dos veces durante esta revisión (9,63 s y 11,94 s) | `pytest -c backend/pytest.ini backend/tests -q`; BD temporal. Incluye seguridad JWT, sincronización/API y métricas de estudio. |
| Cobertura backend | **100 % líneas (1386/1386); 96,35 % ramas (343/356)** | `artifacts/backend-coverage.xml`, ejecución previa del 6 nov. No implica ausencia de defectos. |
| Bandit | **0 hallazgos** en severidad/confianza reportadas | `artifacts/security/bandit.json`; 2219 líneas, una regla excluida. |
| pip-audit | **0 vulnerabilidades** en dependencias del entorno QA escaneado | `artifacts/security/pip-audit.json`; no representa otros entornos ni el servidor desplegado. |
| Mutación | **45/47 detectados; 2 sobreviven (95,74 %)** | `artifacts/mutation/summary.json`; solo `backend/app/core/security.py`. Revisar los dos sobrevivientes antes de ampliar alcance. |
| Web | **8/9** combinaciones antiguas de Chrome/Edge/Firefox y 360/768/1440 px aprobaron | `artifacts/compatibility/summary.json`. La falla Firefox/360 aguardó un selector DOM que Flutter no expuso como input habilitado; el control visual sí aparece en la captura. El selector se corrigió y el script usa roles de accesibilidad. Una nueva ejecución de Firefox se interrumpió porque el proceso del navegador cayó al crear páginas por falta de recursos; no equivale a una aprobación de la corrección. |

## Resultados que requieren seguimiento

La carga local duró 120 s por escenario, con lecturas autenticadas, SQLite temporal,
un worker y un token/IP compartidos. A 10 usuarios hubo 0/591 fallos, p95 26 ms y
5,01 solicitudes/s. A 50 hubo 1760/2960 fallos (59,46 %), p95 15 ms y 24,92
solicitudes/s; a 100 hubo 4542/5742 fallos (79,10 %), p95 12 ms y 48,27
solicitudes/s. Estos escenarios **fallan** el umbral de errores ≤1 %, pese a latencias
bajas: los 429 del limitador compartido cuentan como fallos. No presentar los RPS
como capacidad de usuarios concurrentes exitosos. Evidencia: `artifacts/load/summary.json`.

ZAP activo autenticado reportó cero alertas FAIL y dos WARN: posible SQL injection
en `POST /api/v1/sessions/` y `POST /api/v1/sessions/results`, cuyas rutas dieron
404 en ese escaneo, y ausencia/invalidez de `Cross-Origin-Resource-Policy` en rutas
200. La alerta SQL no queda confirmada como inyección, pero el 404 significa que
ZAP no verificó esos handlers: revisar el esquema/rutas y repetir el escaneo contra
la API actual. Hay pruebas de regresión que envían payloads como datos literales;
no sustituyen un escaneo con cobertura válida. Evidencia: `artifacts/security/zap/`.

La prueba Flutter anterior quedó incompleta por agotamiento de memoria. Sus seis
casos de tamaño/escala sí se alcanzaron; el caso de accesibilidad en el log
`artifacts/accessibility.log` falló porque el handle de semántica no se liberó.
El test actual ya lo libera en `finally`, pero **no se obtuvo una ejecución verde
completa de Flutter** en este equipo. Android tampoco se verificó: Gradle perdió
la conexión con el daemon Kotlin durante `compileDebugKotlin`; no hay resultado
de una prueba ejecutada en emulador. Ejecutar estos dos gates en GitHub Actions,
o en una máquina con memoria disponible, y adjuntar sus logs antes de afirmar
cobertura móvil completa.

## Próximas acciones

1. Ejecutar `flutter test --coverage --reporter expanded` en CI y revisar cualquier
   fallo real tras completar la suite.
2. Ejecutar el smoke test Android en emulador API 35 en CI.
3. Corregir rutas del esquema ZAP para que el escaneo alcance endpoints existentes;
   revisar política CORP y repetir. Mantener visibles las advertencias hasta resolverlas.
4. Definir si la prueba de carga debe modelar IP/usuarios independientes o validar
   deliberadamente el límite por IP. Repetir tres veces en infraestructura objetivo
   antes de fijar capacidad.
5. Revisar los dos mutantes supervivientes y repetir navegador en un runner limpio.

Los estudios con personas siguen pendientes; consultar los protocolos de
[usabilidad](usabilidad.md) y [validación clínica](validacion_clinica.md).
No se generaron participantes ni datos clínicos ficticios.
