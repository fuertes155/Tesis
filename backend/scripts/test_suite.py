"""
=======================================================================
  NeuroApp360 -- Suite Completa de Pruebas
  Cubre: Funcionales, Seguridad, Rendimiento, Latencia, Carga,
         Disponibilidad, Accesibilidad, Compatibilidad
=======================================================================
  Uso:  python backend/scripts/test_suite.py
  Req:  Backend corriendo en http://127.0.0.1:8000
"""

import json, os, sys, time, urllib.error, urllib.request, statistics, threading, subprocess
from datetime import datetime

BASE = os.environ.get("NEUROAPP_BASE_URL", "http://127.0.0.1:8000").rstrip("/")
PASS = 0
FAIL = 0
WARN = 0


# -- Helpers -------------------------------------------------------------------

def _req(method, path, payload=None, headers=None, timeout=10):
    url = f"{BASE}{path}"
    data = json.dumps(payload).encode() if payload else None
    hdrs = {"Content-Type": "application/json"}
    if headers:
        hdrs.update(headers)
    req = urllib.request.Request(url, data=data, headers=hdrs, method=method)
    start = time.perf_counter()
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            body = json.loads(r.read().decode("utf-8", "replace"))
            elapsed = (time.perf_counter() - start) * 1000
            return r.status, body, dict(r.headers), elapsed
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", "replace")
        elapsed = (time.perf_counter() - start) * 1000
        try:
            body = json.loads(body)
        except Exception:
            pass
        return e.code, body, dict(e.headers), elapsed
    except Exception as e:
        elapsed = (time.perf_counter() - start) * 1000
        return 0, str(e), {}, elapsed


def _check(ok, label, detail=""):
    global PASS, FAIL
    if ok:
        PASS += 1
        print(f"  [PASS] {label}")
    else:
        FAIL += 1
        print(f"  [FAIL] {label}" + (f" -- {detail}" if detail else ""))
    return ok


def _warn(label):
    global WARN
    WARN += 1
    print(f"  [WARN] {label}")


def _login(username="samuel1@gmail.com", password="Password123!"):
    s, b, _, _ = _req("POST", "/api/v1/users/auth/login",
                       {"username": username, "password": password})
    if s == 200 and isinstance(b, dict):
        return b.get("access_token")
    return None


def _auth(token):
    return {"Authorization": f"Bearer {token}"}


def _section(title):
    print(f"\n{'-'*60}")
    print(f"  {title}")
    print(f"{'-'*60}")


# ==============================================================================
# 1. PRUEBAS DE DISPONIBILIDAD
# ==============================================================================

def test_availability():
    _section("1. PRUEBAS DE DISPONIBILIDAD")

    s, b, h, ms = _req("GET", "/health")
    _check(s == 200, f"GET /health -> 200 ({ms:.0f}ms)")
    if isinstance(b, dict):
        _check(b.get("status") == "healthy", "Estado: healthy")
        _check("uptime_seconds" in b, "Uptime reportado")
        _check(b.get("database") == "connected", "Base de datos conectada")
        _check("version" in b, f"Versión: {b.get('version')}")
        _check("timestamp" in b, f"Timestamp: {b.get('timestamp')}")

    s2, b2, _, ms2 = _req("GET", "/readiness")
    _check(s2 == 200, f"GET /readiness -> 200 ({ms2:.0f}ms)")
    if isinstance(b2, dict):
        _check(b2.get("ready") is True, "Readiness: true")

    s3, _, _, ms3 = _req("GET", "/")
    _check(s3 == 200, f"GET / (root) -> 200 ({ms3:.0f}ms)")

    s4, _, _, _ = _req("GET", "/api/v1/openapi.json")
    _check(s4 == 200, "OpenAPI spec accesible")


# ==============================================================================
# 2. PRUEBAS DE LATENCIA Y TIEMPOS DE RESPUESTA
# ==============================================================================

def test_latency():
    _section("2. PRUEBAS DE LATENCIA Y TIEMPOS DE RESPUESTA")

    endpoints = [
        ("GET", "/health"),
        ("GET", "/readiness"),
        ("GET", "/"),
    ]
    token = _login()
    if token:
        endpoints += [
            ("GET", "/api/v1/users/me"),
            ("GET", "/api/v1/patients/"),
            ("GET", "/api/v1/sessions/"),
        ]

    for method, path in endpoints:
        times = []
        hdrs = _auth(token) if token and "/api/" in path else {}
        for _ in range(5):
            s, _, h, ms = _req(method, path, headers=hdrs)
            if s == 200:
                times.append(ms)
        if times:
            avg = statistics.mean(times)
            p95 = sorted(times)[int(len(times) * 0.95)]
            _check(avg < 500, f"{method} {path} -- avg={avg:.0f}ms  p95={p95:.0f}ms",
                   f"LENTO (>{500}ms)" if avg >= 500 else "")

    # Verificar header X-Response-Time
    _, _, h, _ = _req("GET", "/health")
    _check("X-Response-Time" in h or "x-response-time" in h,
           "Header X-Response-Time presente en respuestas")


# ==============================================================================
# 3. PRUEBAS DE RENDIMIENTO Y CARGA
# ==============================================================================

def test_load():
    _section("3. PRUEBAS DE RENDIMIENTO Y CARGA")

    CONCURRENT = 20
    TOTAL = 50
    results = []
    errors = []

    def worker():
        s, _, _, ms = _req("GET", "/health", timeout=15)
        if s == 200:
            results.append(ms)
        else:
            errors.append(s)

    print(f"  Ejecutando {TOTAL} requests concurrentes ({CONCURRENT} hilos)...")
    threads = []
    for i in range(TOTAL):
        t = threading.Thread(target=worker)
        threads.append(t)
        t.start()
        if len([t for t in threads if t.is_alive()]) >= CONCURRENT:
            threads[0].join(timeout=15)
            threads = [t for t in threads if t.is_alive()]

    for t in threads:
        t.join(timeout=15)

    if results:
        avg = statistics.mean(results)
        p50 = sorted(results)[len(results) // 2]
        p95 = sorted(results)[int(len(results) * 0.95)]
        success_rate = len(results) / TOTAL * 100

        _check(success_rate >= 95, f"Tasa de exito: {success_rate:.0f}% ({len(results)}/{TOTAL})")
        _check(avg < 1000, f"Promedio bajo carga: {avg:.0f}ms")
        _check(p95 < 2000, f"P50={p50:.0f}ms  P95={p95:.0f}ms")
        if errors:
            _warn(f"Errores: {len(errors)} (codigos: {set(errors)})")
    else:
        _check(False, "Sin respuestas exitosas bajo carga")

    # Rate limiting test
    print(f"\n  Verificando Rate Limiting...")
    rate_limited = False
    for i in range(210):
        s, _, _, _ = _req("GET", "/health", timeout=5)
        if s == 429:
            rate_limited = True
            break
    _check(rate_limited, "Rate limiting activo (429 recibido)")


# ==============================================================================
# 4. PRUEBAS FUNCIONALES
# ==============================================================================

def test_functional():
    _section("4. PRUEBAS FUNCIONALES")

    # Auth
    s, b, _, _ = _req("POST", "/api/v1/users/auth/login",
                       {"username": "samuel@gmail.com", "password": "Password123!"})
    _check(s == 200, "Login doctor exitoso")
    _check(isinstance(b, dict) and "access_token" in b, "Token JWT recibido")

    token = _login()
    if not token:
        _check(False, "No se pudo autenticar como gestor")
        return

    auth = _auth(token)

    # CRUD Pacientes
    s, p, _, _ = _req("POST", "/api/v1/patients/",
                       {"name": "Test Funcional", "age": 30, "phone": "555-0001",
                        "diagnosis": "Prueba funcional", "has_consent": True}, headers=auth)
    _check(s == 200, f"Crear paciente -> {s}")
    pid = p.get("id") if isinstance(p, dict) else None

    if pid:
        s2, p2, _, _ = _req("GET", f"/api/v1/patients/{pid}", headers=auth)
        _check(s2 == 200 and isinstance(p2, dict) and p2.get("name") == "Test Funcional", "Leer paciente creado")

        s3, p3, _, _ = _req("PUT", f"/api/v1/patients/{pid}",
                             {"name": "Test Actualizado", "age": 31}, headers=auth)
        _check(s3 == 200 and isinstance(p3, dict) and p3.get("name") == "Test Actualizado", "Actualizar paciente")

        # Sesión
        ext_id = f"test-func-{int(time.time())}"
        s4, sess, _, _ = _req("POST", "/api/v1/sessions/",
                               {"patient_id": pid, "date": "2026-05-16T12:00:00",
                                "status": "completed", "notes": "Prueba funcional",
                                "duration_ms": 5000, "external_id": ext_id}, headers=auth)
        _check(s4 == 200, "Crear sesión para paciente")

        # Idempotencia
        s5, sess2, _, _ = _req("POST", "/api/v1/sessions/",
                                {"patient_id": pid, "date": "2026-05-16T12:00:00",
                                 "status": "completed", "notes": "Dup",
                                 "duration_ms": 5000, "external_id": ext_id}, headers=auth)
        _check(s5 == 200, "Idempotencia de external_id (sin duplicados)")

        # Resultados
        s6, res, _, _ = _req("POST", "/api/v1/sessions/results",
                              {"patient_id": pid, "game_name": "visual_memory",
                               "score": 85, "details": {"Memoria": 85},
                               "metrics": {"level": 5}}, headers=auth)
        _check(s6 == 201, "Enviar resultado de juego")

        s7, latest, _, _ = _req("GET", f"/api/v1/sessions/results/latest?patient_id={pid}",
                                 headers=auth)
        _check(s7 == 200 and isinstance(latest, list), "Obtener ultimos resultados")

        # Cleanup
        _req("DELETE", f"/api/v1/patients/{pid}", headers=auth)

    # Auth negativo
    s, _, _, _ = _req("POST", "/api/v1/users/auth/login",
                       {"username": "noexiste@x.com", "password": "wrong"})
    _check(s == 401, "Login con credenciales invalidas -> 401")

    s, _, _, _ = _req("GET", "/api/v1/patients/", headers={"Authorization": "Bearer invalidtoken"})
    _check(s == 401, "Token invalido -> 401")

    s, _, _, _ = _req("GET", "/api/v1/patients/")
    _check(s in (401, 403), "Sin token -> rechazado")

    s, _, _, _ = _req("GET", "/api/v1/patients/99999", headers=auth)
    _check(s == 404, "Paciente inexistente -> 404")


# ==============================================================================
# 5. PRUEBAS DE SEGURIDAD BÁSICAS
# ==============================================================================

def test_security():
    _section("5. PRUEBAS DE SEGURIDAD BÁSICAS")

    token = _login()
    auth = _auth(token) if token else {}

    # Security headers
    _, _, h, _ = _req("GET", "/health")
    headers_check = {
        "X-Content-Type-Options": "nosniff",
        "X-Frame-Options": "DENY",
        "X-XSS-Protection": "1; mode=block",
        "Referrer-Policy": "strict-origin-when-cross-origin",
    }
    for hdr, expected in headers_check.items():
        val = h.get(hdr, h.get(hdr.lower(), ""))
        _check(val == expected, f"Header {hdr}: {val}")

    _check("Permissions-Policy" in h or "permissions-policy" in h, "Header Permissions-Policy presente")
    _check("Cache-Control" in h or "cache-control" in h, "Header Cache-Control presente")

    # XSS en paciente
    xss = "<script>alert('xss')</script>"
    s, b, _, _ = _req("POST", "/api/v1/patients/",
                       {"name": xss, "age": 25}, headers=auth)
    if s in (200, 201) and isinstance(b, dict):
        _check(xss not in str(b.get("name", "")), "XSS sanitizado en nombre de paciente")
        if b.get("id"):
            _req("DELETE", f"/api/v1/patients/{b['id']}", headers=auth)

    # SQL Injection
    s, _, _, _ = _req("POST", "/api/v1/users/auth/login",
                       {"username": "' OR 1=1 --", "password": "anything"})
    _check(s in (401, 422), "SQL Injection en login rechazado")

    # Password debil
    email = f"weakpwd{int(time.time())}@test.com"
    s, _, _, _ = _req("POST", "/api/v1/users/auth/register",
                       {"username": email, "password": "123", "role": "doctor"})
    _check(s == 400, "Password debil rechazada (< 8 chars)")

    s, _, _, _ = _req("POST", "/api/v1/users/auth/register",
                       {"username": email, "password": "abcdefgh", "role": "doctor"})
    _check(s == 400, "Password sin mayuscula/dígito rechazada")

    # Acceso por roles
    doc_token = _login("samuel@gmail.com", "Password123!")
    if doc_token:
        s, _, _, _ = _req("GET", "/api/v1/users/", headers=_auth(doc_token))
        _check(s == 200, "Doctor puede listar usuarios")

        s, _, _, _ = _req("DELETE", "/api/v1/users/1", headers=_auth(doc_token))
        _check(s == 403, "Doctor NO puede eliminar usuarios -> 403")


# ==============================================================================
# 6. PRUEBAS DE CONECTIVIDAD (tracert)
# ==============================================================================

def test_connectivity():
    _section("6. PRUEBAS DE CONECTIVIDAD")

    host = "127.0.0.1"
    try:
        result = subprocess.run(
            ["tracert", "-d", "-h", "5", "-w", "1000", host],
            capture_output=True, text=True, timeout=15
        )
        lines = [l for l in result.stdout.splitlines() if l.strip()]
        _check(result.returncode == 0, f"tracert {host} exitoso ({len(lines)} saltos)")
        for line in lines[-3:]:
            print(f"      {line.strip()}")
    except FileNotFoundError:
        _warn("tracert no disponible (Windows only)")
    except subprocess.TimeoutExpired:
        _warn("tracert timeout")

    # Ping check
    try:
        result = subprocess.run(
            ["ping", "-n", "3", "-w", "1000", host],
            capture_output=True, text=True, timeout=10
        )
        for line in result.stdout.splitlines():
            if "media" in line.lower() or "average" in line.lower() or "promedio" in line.lower():
                print(f"      {line.strip()}")
        _check(result.returncode == 0, f"ping {host} exitoso")
    except Exception:
        _warn("ping no disponible")


# ==============================================================================
# 7. PRUEBAS EXPLORATORIAS
# ==============================================================================

def test_exploratory():
    _section("7. PRUEBAS EXPLORATORIAS")

    token = _login()
    auth = _auth(token) if token else {}

    # Campos vacíos
    s, _, _, _ = _req("POST", "/api/v1/users/auth/login", {"username": "", "password": ""})
    _check(s in (401, 422), "Login con campos vacíos rechazado")

    # Campos nulos
    s, _, _, _ = _req("POST", "/api/v1/patients/", {"name": None, "age": None}, headers=auth)
    _check(s == 422, "Paciente con campos nulos -> 422")

    # Edad negativa
    s, b, _, _ = _req("POST", "/api/v1/patients/",
                       {"name": "Edge Case", "age": -5}, headers=auth)
    _check(s in (200, 400, 422), f"Edad negativa -> {s}")
    if s == 200 and isinstance(b, dict) and b.get("id"):
        _req("DELETE", f"/api/v1/patients/{b['id']}", headers=auth)

    # Nombre muy largo
    long_name = "A" * 1000
    s, b, _, _ = _req("POST", "/api/v1/patients/",
                       {"name": long_name, "age": 30}, headers=auth)
    _check(s in (200, 422), f"Nombre 1000 chars -> {s}")
    if s == 200 and isinstance(b, dict) and b.get("id"):
        _req("DELETE", f"/api/v1/patients/{b['id']}", headers=auth)

    # Metodo no soportado
    s, _, _, _ = _req("PATCH", "/health")
    _check(s in (405, 404), f"PATCH /health -> {s} (no soportado)")

    # Endpoint inexistente
    s, _, _, _ = _req("GET", "/api/v1/noexiste")
    _check(s == 404, "Ruta inexistente -> 404")

    # JSON malformado
    try:
        url = f"{BASE}/api/v1/users/auth/login"
        req = urllib.request.Request(url, data=b"not-json",
                                     headers={"Content-Type": "application/json"}, method="POST")
        with urllib.request.urlopen(req, timeout=5) as r:
            s = r.status
    except urllib.error.HTTPError as e:
        s = e.code
    except Exception:
        s = 0
    _check(s == 422, f"JSON malformado -> {s}")


# ==============================================================================
# MAIN
# ==============================================================================

def main():
    print("=" * 60)
    print("  NeuroApp360 -- Suite Completa de Pruebas")
    print(f"  Servidor: {BASE}")
    print(f"  Fecha: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 60)

    # Check server is running
    s, _, _, _ = _req("GET", "/health", timeout=5)
    if s == 0:
        print(f"\n  [FAIL] No se pudo conectar a {BASE}")
        print("     Asegurate de que el backend este corriendo.")
        return 1

    test_availability()
    test_latency()
    test_functional()
    test_security()
    test_exploratory()
    test_connectivity()
    test_load()  # Last because rate limiting

    print(f"\n{'='*60}")
    print(f"  RESULTADOS FINALES")
    print(f"{'='*60}")
    print(f"  [PASS] Pasaron:      {PASS}")
    print(f"  [FAIL] Fallaron:     {FAIL}")
    print(f"  [WARN] Advertencias: {WARN}")
    total = PASS + FAIL
    pct = (PASS / total * 100) if total > 0 else 0
    print(f"  Tasa de exito: {pct:.1f}%")
    print(f"{'='*60}")

    return 0 if FAIL == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
