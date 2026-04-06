import json
import os
import sys
import time
import urllib.error
import urllib.request


def _base_url() -> str:
    return os.environ.get("NEUROAPP_BASE_URL", "http://127.0.0.1:8000").rstrip("/")


def _request_json(method: str, path: str, payload: dict | None = None) -> tuple[int, dict | str]:
    url = f"{_base_url()}{path}"
    data = None
    headers = {"Content-Type": "application/json"}
    if payload is not None:
        data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
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

    s, body = _request_json("GET", "/health")
    ok = _expect(200, s, body, "GET /health") and ok

    s, body = _request_json(
        "POST",
        "/users/auth/login",
        {"username": "samuel@gmail.com", "password": "Password123!"},
    )
    ok = _expect(200, s, body, "POST /users/auth/login (doctor seed)") and ok

    s, body = _request_json(
        "POST",
        "/users/auth/login",
        {"username": "samuel1@gmail.com", "password": "Password123!"},
    )
    ok = _expect(200, s, body, "POST /users/auth/login (gestor seed)") and ok

    email = f"smoke{int(time.time())}@example.com"
    s, body = _request_json(
        "POST",
        "/users/auth/register",
        {"username": email.upper(), "password": "Password123!", "role": "doctor"},
    )
    ok = _expect(201, s, body, "POST /users/auth/register (new)") and ok

    s, body = _request_json(
        "POST",
        "/users/auth/register",
        {"username": email.lower(), "password": "Password123!", "role": "doctor"},
    )
    ok = _expect(409, s, body, "POST /users/auth/register (duplicate)") and ok

    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())

