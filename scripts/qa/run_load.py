"""Ejecuta 10/50/100 usuarios con API/BD nueva por escenario y genera gráficas."""
import argparse
import csv
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import platform
import subprocess
import sys

from local_api import ROOT, local_api


def summarize(path):
    with path.open(encoding="utf-8") as stream:
        rows = list(csv.DictReader(stream))
    row = next(row for row in rows if row["Name"] == "Aggregated")
    requests = int(row["Request Count"])
    return {"requests": requests, "failures": int(row["Failure Count"]),
            "failure_ratio": int(row["Failure Count"]) / max(requests, 1),
            "p95_ms": float(row["95%"]), "rps": float(row["Requests/s"])}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--seconds", type=int, default=120)
    parser.add_argument("--output", type=Path, default=ROOT / "artifacts/load")
    parser.add_argument("--max-p95", type=float, default=1000)
    parser.add_argument("--max-errors", type=float, default=0.01)
    args = parser.parse_args()
    if args.seconds < 30:
        parser.error("Usa al menos 30 segundos; para la tesis se recomiendan 120 o más")
    args.output.mkdir(parents=True, exist_ok=True)
    results = []
    for users in (10, 50, 100):
        print(f"Escenario {users} usuarios, {args.seconds}s", flush=True)
        with local_api() as api:
            prefix = args.output / f"users_{users}"
            env = {**os.environ, "QA_TOKEN": api["token"],
                   "QA_PATIENT_ID": str(api["patient_id"])}
            command = [sys.executable, "-m", "locust", "-f", str(Path(__file__).with_name("locustfile.py")),
                       "--headless", "--host", api["url"], "--users", str(users),
                       "--spawn-rate", "10", "--run-time", f"{args.seconds}s",
                       "--csv", str(prefix), "--csv-full-history", "--only-summary",
                       "--html", str(prefix.with_suffix(".html")), "--stop-timeout", "5"]
            with prefix.with_suffix(".log").open("w", encoding="utf-8") as log:
                result = subprocess.run(command, env=env, stdout=log, stderr=log,
                                        timeout=args.seconds + 120)
            if not Path(f"{prefix}_stats.csv").exists():
                raise RuntimeError(f"Locust no generó estadísticas; revisar {prefix}.log")
            row = {"users": users, "exit_code": result.returncode,
                   **summarize(Path(f"{prefix}_stats.csv"))}
            row["passed"] = (row["requests"] > 0 and row["failure_ratio"] <= args.max_errors
                             and row["p95_ms"] <= args.max_p95 and result.returncode == 0)
            results.append(row)
    report = {"utc": datetime.now(timezone.utc).isoformat(), "platform": platform.platform(),
              "duration_seconds": args.seconds, "ramp_users_per_second": 10,
              "workload": "lecturas autenticadas 3 pacientes / 2 sesiones / 1 resultados; espera 1–3s",
              "limitations": "SQLite temporal pequeña, un worker, una IP/token; incluye rampa y rate limiting. No mide IA ni escrituras.",
              "thresholds": {"p95_ms": args.max_p95, "failure_ratio": args.max_errors},
              "results": results}
    (args.output / "summary.json").write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    figure, axes = plt.subplots(1, 2, figsize=(10, 4))
    for axis, metric, label in [(axes[0], "p95_ms", "Latencia p95 (ms, incluye errores)"),
                                (axes[1], "rps", "Peticiones/s (incluye errores)")]:
        axis.plot([r["users"] for r in results], [r[metric] for r in results], "o-")
        axis.set(xlabel="Usuarios concurrentes", ylabel=label, xticks=[10, 50, 100])
        axis.grid(alpha=0.3)
    figure.tight_layout()
    figure.savefig(args.output / "load.png", dpi=180)
    print(json.dumps(report, indent=2, ensure_ascii=False))
    return 0 if all(r["passed"] for r in results) else 1


if __name__ == "__main__":
    raise SystemExit(main())
