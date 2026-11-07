# Verificación de NeuroApp360

Este directorio separa pruebas ejecutables, mediciones y estudios con personas.
La evidencia local y sus límites se registran en [resultados.md](resultados.md).
El número de pruebas se obtiene de los ejecutores, no de una cifra fija de 229.
Una prueba unitaria no demuestra capacidad de carga, ausencia de vulnerabilidades
ni validez clínica, aunque la cobertura sea del 100 %.

## Preparación en Windows

Desde la raíz, PowerShell:

```powershell
python -m venv .qa-venv
.qa-venv\Scripts\python.exe -m pip install --upgrade pip
.qa-venv\Scripts\python.exe -m pip install -r backend/requirements-qa.txt
flutter pub get
```

Se usa un entorno separado para evitar conflictos con un servidor que esté abierto.
Python 3.12 y Flutter 3.35.4 son las versiones de referencia. Docker Desktop debe
estar iniciado para ZAP y mutmut. En Linux usar `.qa-venv/bin/python`.

## Ejecución

| Área | Comando desde la raíz | Evidencia |
|---|---|---|
| Unitarias, widgets, offline y accesibilidad | `flutter test --coverage --reporter expanded` | `coverage/lcov.info` y salida del ejecutor |
| API y backend | `.qa-venv\Scripts\python.exe -m pytest -c backend/pytest.ini backend/tests -q` | resumen pytest; siempre BD temporal |
| Cobertura Python con ramas | Desde `backend`: `..\.qa-venv\Scripts\python.exe -m pytest --cov=app --cov=main --cov-branch --cov-report=html --cov-report=xml` | `backend/htmlcov/`, `backend/coverage.xml` |
| Carga | `.qa-venv\Scripts\python.exe scripts/qa/run_load.py --seconds 120` | `artifacts/load/`: CSV, HTML, resumen y `load.png` |
| Bandit | `.qa-venv\Scripts\python.exe -m bandit -r backend/app backend/main.py -f json -o artifacts/security/bandit.json` | JSON; crear previamente la carpeta |
| Dependencias instaladas | `.qa-venv\Scripts\python.exe -m pip_audit --format json --output artifacts/security/pip-audit.json` | JSON con versiones realmente auditadas |
| ZAP autenticado | `.qa-venv\Scripts\python.exe scripts/qa/run_zap.py` | `artifacts/security/zap/`: JSON, HTML y código de salida |
| Mutación en Windows | `.qa-venv\Scripts\python.exe scripts/qa/run_mutation.py` | `artifacts/mutation/`: resumen y supervivientes |
| Navegadores | `flutter build web --release`, luego `.qa-venv\Scripts\python.exe scripts/qa/run_browsers.py` | `artifacts/compatibility/`: versiones, tamaños, capturas |
| Android conectado/emulado | `flutter test integration_test/compatibility_smoke_test.dart -d ID_DEL_DISPOSITIVO` | salida de la prueba real |

Para Firefox instalar primero `python -m playwright install firefox` usando el
Python QA. Chrome y Edge deben estar instalados. La prueba registra un fallo si
falta un navegador; no lo convierte en aprobación. El smoke web comprueba renderizado,
entrada y validación del login. El flujo clínico completo existente se ejecuta
por separado con `scripts/run_e2e.ps1`.

## Servicios simulados y sincronización

`test/services/offline_sync_test.dart` usa Dio y una base Sembast en memoria real.
Cubre desconexión, timeout, 408/429/5xx, errores definitivos, cancelación, caché,
reintentos concurrentes, conservación de fecha/duración/identificador, cierre de
sesión y la cola heredada. Cada caso limpia la base y las preferencias.

`PendingActionsSynchronizer` conserva los registros rechazados y los sucesores.
Un error requiere reintento o revisión; no se elimina por encontrar "400/404"
en un mensaje. Las sesiones usan `external_id` para la idempotencia del backend.
La app aún necesita una política completa para aislar cachés/colas entre distintos
usuarios y resolver conflictos manuales. Los resultados de juegos no tienen una
clave de idempotencia de servidor: una respuesta perdida tras confirmar escritura
puede duplicar un resultado. No confundir esta limitación con la protección de sesiones.

## Carga y criterios

Cada escenario crea su API y BD, autentica un profesional y ejecuta 10, 50 y 100
usuarios. Mezcla de lecturas: pacientes 3, sesiones 2, resultados 1, con espera de
1–3 s. Incluye la rampa a 10 usuarios/s. Se guardan fallos, p95, RPS y series
temporales. El umbral inicial es p95 ≤ 1000 ms y errores ≤ 1 %, configurable;
es una decisión de ingeniería que debe acordarse antes de la medición definitiva.

Los 429 cuentan como errores. El limitador actual comparte el límite por IP/ruta,
por lo que usuarios detrás de una misma IP compiten por él. Un p95 bajo con muchos
rechazos no demuestra capacidad. La BD pequeña, SQLite, un worker y lecturas no
representan generación de informes con IA, escrituras ni el despliegue final.
Para la tesis repetir al menos tres veces en el servidor objetivo, conservar
hardware, sistema, versiones, volumen de datos, configuración y dispersión.

## Seguridad y mutación

Bandit revisa `backend/app` y `main.py`; pip-audit inspecciona el entorno instalado.
Un entorno antiguo puede conservar bibliotecas retiradas de requirements: volver a
crearlo y auditarlo también. La auditoría de QA no certifica el servidor desplegado.
La migración a PyJWT requiere reinstalar `backend/requirements.txt` y reiniciar la API.
Configurar una `SECRET_KEY` larga y propia en el despliegue; no usar las claves de
desarrollo ni las credenciales de las pruebas.

ZAP se autentica contra su propia API temporal. Es un escaneo activo que puede
crear y borrar registros de esa BD. Redacta el token de los informes. Códigos:
0 sin alertas, 1 FAIL, 2 WARN, 3 fallo de ejecución. La automatización conserva el
código; no transforma advertencias en éxito. Revisar también los logs para detectar
429 o rutas rechazadas que reduzcan la cobertura autenticada del escaneo.

La mutación inicial se limita explícitamente a `app/core/security.py`; no es una
medición de todo Python ni de Dart. Se fija mutmut 3.3.1 y pytest 8 por compatibilidad.
En Linux: desde `backend`, `mutmut run --max-children 2`, `mutmut results` y
`python ../scripts/qa/export_mutation.py ../artifacts/mutation`.
El exportador cuenta solo código 1 como detección; errores de infraestructura,
timeouts, mutantes sin pruebas y no ejecutados quedan separados. El puntaje conservador
es detectados/total, sin borrar supervivientes para mejorar la cifra.

## Integración continua

- `tests.yml`: todas las pruebas descubiertas de Flutter y Python, push y PR,
  cobertura y JUnit como artefactos. No depende de un número fijo de casos.
- `security.yml`: Bandit y pip-audit en push, PR, ejecución manual y semanal;
  guarda ambos informes antes de marcar fallo.
- `extended-qa.yml`: carga, ZAP y mutación mediante ejecución manual.
- `compatibility.yml`: Chrome/Edge/Firefox en Windows y smoke Android API 35
  mediante ejecución manual.

Los workflows se activan al subirlos al repositorio y habilitar GitHub Actions.
Crear los archivos localmente no demuestra una ejecución en GitHub.

## Estudios pendientes

Seguir [usabilidad.md](usabilidad.md) y [validacion_clinica.md](validacion_clinica.md).
Las plantillas tienen únicamente encabezados. No contienen participantes ficticios
ni resultados que puedan confundirse con un estudio completado.

## Fuentes técnicas

- [Flutter: Accessibility Guideline API](https://docs.flutter.dev/ui/accessibility/accessibility-testing).
- [Locust: estadísticas CSV e historial](https://docs.locust.io/en/stable/configuration.html).
- [ZAP: API scan y códigos de salida](https://www.zaproxy.org/docs/docker/api-scan/).
- [Bandit](https://bandit.readthedocs.io/en/latest/start.html) y [pip-audit](https://github.com/pypa/pip-audit).
- [mutmut 3.3.1](https://github.com/boxed/mutmut/tree/3.3.1).
- [PyJWT: algoritmos permitidos y validación de tokens](https://pyjwt.readthedocs.io/en/stable/api.html).
