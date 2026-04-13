import json
import os
import sys
import time
import urllib.error
import urllib.request


def _base_url() -> str:
    return os.environ.get("NEUROAPP_BASE_URL", "http://127.0.0.1:8000").rstrip("/")


def _gestor_username() -> str:
    return os.environ.get("NEUROAPP_GESTOR_USERNAME", "samuel1@gmail.com")


def _gestor_password() -> str:
    return os.environ.get("NEUROAPP_GESTOR_PASSWORD", "Password123!")


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


def _login_gestor_token() -> str:
    status, body = _request_json(
        "POST",
        "/users/auth/login",
        {"username": _gestor_username(), "password": _gestor_password()},
    )
    if status != 200 or not isinstance(body, dict) or "access_token" not in body:
        raise RuntimeError(f"Login gestor failed: {status} {body}")
    return body["access_token"]


def _fetch_patients(token: str) -> list[dict]:
    auth = {"Authorization": f"Bearer {token}"}
    all_items: list[dict] = []
    skip = 0
    limit = 100
    while True:
        status, body = _request_json("GET", f"/patients/?skip={skip}&limit={limit}", headers=auth)
        if status != 200 or not isinstance(body, list):
            raise RuntimeError(f"Fetch patients failed: {status} {body}")
        if not body:
            break
        all_items.extend(body)
        skip += limit
    return all_items


def _delete_patient(token: str, patient_id: int) -> None:
    auth = {"Authorization": f"Bearer {token}"}
    last = None
    for _ in range(4):
        status, body = _request_json("DELETE", f"/patients/{patient_id}", headers=auth)
        if status in (200, 204):
            return
        last = (status, body)
        time.sleep(0.5)
    raise RuntimeError(f"Delete patient {patient_id} failed: {last[0]} {last[1]}")


def main() -> int:
    token = _login_gestor_token()
    patients = _fetch_patients(token)
    ids = [int(p["id"]) for p in patients if isinstance(p, dict) and "id" in p]
    ids = sorted(set(ids))
    print(f"Patients found: {len(ids)}")

    deleted = 0
    for pid in ids:
        try:
            _delete_patient(token, pid)
            deleted += 1
        except Exception:
            token = _login_gestor_token()
            _delete_patient(token, pid)
            deleted += 1

    remaining = _fetch_patients(token)
    print(f"Deleted: {deleted}")
    print(f"Remaining: {len(remaining)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
