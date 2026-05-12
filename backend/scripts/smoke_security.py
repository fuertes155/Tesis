import json
import os
import sys
import time
import urllib.error
import urllib.request

def _base_url() -> str:
    return os.environ.get("NEUROAPP_BASE_URL", "http://127.0.0.1:8000").rstrip("/")

def _request_json(
    method: str,
    path: str,
    payload: dict | None = None,
    headers: dict | None = None,
) -> tuple[int, dict | str]:
    url = f"{_base_url()}{path}"
    data = None
    request_headers = {"Content-Type": "application/json"}
    if headers:
        request_headers.update(headers)
    if payload is not None:
        data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=data,
        headers=request_headers,
        method=method,
    )
    try:
        with urllib.request.urlopen(req, timeout=6) as resp:
            raw = resp.read()
            text = raw.decode("utf-8", errors="replace")
            try:
                return resp.status, json.loads(text)
            except Exception:
                return resp.status, text
    except urllib.error.HTTPError as e:
        raw = e.read()
        text = raw.decode("utf-8", errors="replace")
        try:
            return e.code, json.loads(text)
        except Exception:
            return e.code, text
    except Exception as e:
        return 0, str(e)

def _expect(status: int, got_status: int, got_body: dict | str, label: str) -> bool:
    ok = got_status == status
    prefix = "OK" if ok else "FAIL"
    print(f"{prefix} {label} -> {got_status}")
    if not ok:
        print(got_body)
    return ok

def main() -> int:
    ok = True

    # 1. Autenticar como doctor para obtener token
    print("Iniciando pruebas de seguridad (XSS)...")
    s, body = _request_json(
        "POST",
        "/api/v1/users/auth/login",
        {"username": "samuel@gmail.com", "password": "Password123!"},
    )
    if s != 200 or not isinstance(body, dict):
        print(f"FAIL Login inicial para pruebas XSS. Status: {s}, Body: {body}")
        return 1
    
    token = body.get("access_token")
    auth = {"Authorization": f"Bearer {token}"}

    # 2. XSS Test: Crear Paciente con payload en el nombre
    xss_payload = "<script>alert('XSS')</script>Paciente"
    s, body = _request_json(
        "POST",
        "/api/v1/patients/",
        {
            "name": xss_payload,
            "age": 30,
            "gender": "Masculino",
            "phone": "555-XSS",
            "diagnosis": "Test XSS"
        },
        headers=auth
    )
    
    # Check if backend sanitizes or rejects it.
    # A robust API might sanitize and return 201 with cleaned name, or reject with 400.
    # Let's just log what it does.
    if s in (200, 201):
        if isinstance(body, dict) and body.get("name") == xss_payload:
            print("VULNERABLE: El backend aceptó el payload XSS en el nombre del paciente sin sanitizar.")
            ok = False
        else:
            name_val = body.get('name') if isinstance(body, dict) else body
            print(f"SAFE: El paciente fue creado pero el nombre fue sanitizado: {name_val}")
            # Limpiar paciente
            if isinstance(body, dict) and "id" in body:
                _request_json("DELETE", f"/api/v1/patients/{body['id']}", headers=auth)
    elif s == 400 or s == 422:
        print("SAFE: El backend rechazó correctamente el payload XSS en el paciente.")
    else:
        print(f"FAIL unexpected status {s} en creación de paciente XSS")
        ok = False

    # 3. XSS Test: Crear sesión de evaluación con payload en las notas
    s, p_body = _request_json(
        "POST",
        "/api/v1/patients/",
        {
            "name": "Paciente Seguro",
            "age": 30,
            "gender": "Masculino",
            "phone": "555-123",
            "diagnosis": "Test"
        },
        headers=auth
    )
    if s in (200, 201) and isinstance(p_body, dict):
        patient_id = p_body.get("id")
        
        xss_notes = "<img src='x' onerror='alert(1)'>"
        s2, s_body = _request_json(
            "POST",
            "/api/v1/sessions/",
            {
                "patient_id": patient_id,
                "date": "2026-05-11T12:00:00",
                "status": "Completada",
                "notes": xss_notes,
                "duration_ms": 1000,
                "external_id": f"xss-{int(time.time())}"
            },
            headers=auth
        )
        
        if s2 in (200, 201):
            if isinstance(s_body, dict) and s_body.get("notes") == xss_notes:
                print("VULNERABLE: El backend aceptó el payload XSS en las notas de la sesión sin sanitizar.")
                ok = False
            else:
                print(f"SAFE: La sesión fue creada pero las notas fueron sanitizadas.")
        elif s2 == 400 or s2 == 422:
            print("SAFE: El backend rechazó correctamente el payload XSS en las notas de la sesión.")
        
        # Limpiar
        _request_json("DELETE", f"/api/v1/patients/{patient_id}", headers=auth)
    
    if ok:
        print("Todas las pruebas de seguridad XSS pasaron satisfactoriamente.")
    else:
        print("Se encontraron vulnerabilidades XSS.")
        
    return 0 if ok else 1

if __name__ == "__main__":
    raise SystemExit(main())
