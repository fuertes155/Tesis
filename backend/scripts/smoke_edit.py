import json
import os
import time
import urllib.error
import urllib.request


def _base_url() -> str:
    return os.environ.get("NEUROAPP_BASE_URL", "http://127.0.0.1:8000").rstrip("/")


def _request_json(method: str, path: str, payload: dict | None = None, headers: dict | None = None):
    url = f"{_base_url()}{path}"
    data = None
    request_headers = {"Content-Type": "application/json"}
    if headers:
        request_headers.update(headers)
    if payload is not None:
        data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(url, data=data, headers=request_headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
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


def main() -> int:
    s, body = _request_json(
        "POST",
        "/api/v1/users/auth/login",
        {"username": "samuel1@gmail.com", "password": "Password123!"},
    )
    if s != 200 or not isinstance(body, dict):
        print("FAIL login", s, body)
        return 1
    token = body["access_token"]
    auth = {"Authorization": f"Bearer {token}"}

    email = f"edit{int(time.time())}@example.com"
    s, u = _request_json(
        "POST",
        "/api/v1/users/register",
        {"username": email, "password": "Password123!", "role": "doctor"},
        headers=auth,
    )
    if s != 200 or not isinstance(u, dict):
        print("FAIL create user", s, u)
        return 1

    user_id = u["id"]
    s, u2 = _request_json(
        "PUT",
        f"/api/v1/users/{user_id}",
        {"is_available": False},
        headers=auth,
    )
    if s != 200 or not isinstance(u2, dict) or u2.get("is_available") is not False:
        print("FAIL update user", s, u2)
        return 1

    s, p = _request_json(
        "POST",
        "/api/v1/patients/",
        {"name": "Paciente Prueba", "age": 20, "phone": "000", "diagnosis": "test"},
        headers=auth,
    )
    if s != 200 or not isinstance(p, dict):
        print("FAIL create patient", s, p)
        return 1
    pid = p["id"]

    s, p2 = _request_json(
        "PUT",
        f"/api/v1/patients/{pid}",
        {"name": "Paciente Editado", "age": 21},
        headers=auth,
    )
    if s != 200 or not isinstance(p2, dict) or p2.get("name") != "Paciente Editado":
        print("FAIL update patient", s, p2)
        return 1

    s, _ = _request_json("DELETE", f"/api/v1/patients/{pid}", headers=auth)
    if s != 200 or not isinstance(_, dict):
        print("FAIL delete patient", s, _)
        return 1

    print("OK edit flow")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

