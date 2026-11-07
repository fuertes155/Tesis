"""Servidor desechable para carga/ZAP. Nunca importa main con la BD habitual."""
from contextlib import contextmanager
import os
from pathlib import Path
import secrets
import socket
import subprocess
import sys
import tempfile
import time

import httpx

ROOT = Path(__file__).resolve().parents[2]


@contextmanager
def local_api(*, bind="127.0.0.1"):
    with tempfile.TemporaryDirectory(prefix="neuroapp_qa_") as directory:
        database = Path(directory) / "qa.db"
        password = secrets.token_urlsafe(24)
        with socket.socket() as probe:
            probe.bind(("127.0.0.1", 0))
            port = probe.getsockname()[1]
        env = {**os.environ, "DATABASE_URL": f"sqlite:///{database.as_posix()}",
               "DEFAULT_ADMIN_PASSWORD": password, "SECRET_KEY": secrets.token_urlsafe(48)}
        log_path = Path(directory) / "server.log"
        with log_path.open("w", encoding="utf-8") as log:
            server = subprocess.Popen(
                [sys.executable, "-m", "uvicorn", "main:app", "--host", bind,
                 "--port", str(port), "--no-access-log"],
                cwd=ROOT / "backend", env=env, stdout=log, stderr=log,
            )
            url = f"http://127.0.0.1:{port}"
            try:
                with httpx.Client(base_url=url, timeout=3, trust_env=False) as client:
                    for _ in range(100):
                        if server.poll() is not None:
                            raise RuntimeError(log_path.read_text(encoding="utf-8"))
                        try:
                            if client.get("/readiness").status_code == 200:
                                break
                        except httpx.TransportError:
                            pass
                        time.sleep(0.2)
                    else:
                        raise RuntimeError("La API temporal no arrancó")
                    login = client.post("/api/v1/users/auth/login", json={
                        "username": "samuel@gmail.com", "password": password})
                    login.raise_for_status()
                    token = login.json()["access_token"]
                    client.headers["Authorization"] = f"Bearer {token}"
                    patient = client.post("/api/v1/patients/", json={
                        "name": "Paciente Sintético QA", "age": 70,
                        "document_id": "QA-SYNTHETIC", "has_consent": True})
                    patient.raise_for_status()
                    yield {"url": url, "port": port, "token": token,
                           "patient_id": patient.json()["id"]}
            finally:
                if sys.platform == "win32" and server.poll() is None:
                    # El launcher del venv crea un hijo en Windows; terminar solo
                    # el padre deja la API y SQLite abiertos.
                    subprocess.run(["taskkill", "/PID", str(server.pid), "/T", "/F"],
                                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False)
                elif server.poll() is None:
                    server.terminate()
                try:
                    server.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    server.kill()
                    server.wait(timeout=10)
