"""Escaneo activo autenticado exclusivamente contra la BD desechable creada aquí."""
import argparse
import json
import os
from pathlib import Path
import subprocess

import httpx
from local_api import ROOT, local_api


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, default=ROOT / "artifacts/security/zap")
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    # host.docker.internal permite a Docker Desktop acceder al servidor temporal.
    with local_api(bind="0.0.0.0") as api:
        target = f"http://host.docker.internal:{api['port']}"
        with httpx.Client(trust_env=False) as client:
            schema = client.get(f"{api['url']}/api/v1/openapi.json").raise_for_status().json()
        schema["servers"] = [{"url": target}]
        (args.output / "openapi.json").write_text(json.dumps(schema), encoding="utf-8")
        # El token nunca se escribe en archivos ni argumentos del proceso Docker.
        env = {**os.environ, "ZAP_AUTH_HEADER": "Authorization",
               "ZAP_AUTH_HEADER_VALUE": f"Bearer {api['token']}",
               "ZAP_AUTH_HEADER_SITE": "host.docker.internal"}
        command = ["docker", "run", "--rm", "--add-host", "host.docker.internal:host-gateway",
                   "-v", f"{args.output.resolve()}:/zap/wrk/:rw",
                   "-e", "ZAP_AUTH_HEADER", "-e", "ZAP_AUTH_HEADER_VALUE", "-e", "ZAP_AUTH_HEADER_SITE",
                   "ghcr.io/zaproxy/zaproxy:stable", "zap-api-scan.py",
                   "-t", "/zap/wrk/openapi.json", "-f", "openapi", "-T", "5",
                   "-r", "zap.html", "-J", "zap.json"]
        with (args.output / "zap.log").open("w", encoding="utf-8") as log:
            result = subprocess.run(command, env=env, stdout=log, stderr=log, timeout=1800)
        # ZAP puede incluir el header en las instancias de alertas.
        for artifact in args.output.iterdir():
            if artifact.suffix in {".html", ".json", ".log"}:
                artifact.write_text(artifact.read_text(encoding="utf-8").replace(api["token"], "[REDACTED]"),
                                    encoding="utf-8")
        (args.output / "status.json").write_text(json.dumps({"exit_code": result.returncode,
            "scope": "API temporal autenticada; sin acceso a base real",
            "passed": result.returncode == 0}), encoding="utf-8")
        print(f"ZAP exit={result.returncode}. Informes: {args.output}")
        return result.returncode


if __name__ == "__main__":
    raise SystemExit(main())
