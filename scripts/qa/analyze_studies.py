"""Analiza CSV reales sin completar ni inventar observaciones faltantes."""
import argparse
import csv
from datetime import datetime, timezone
import json
import math
from pathlib import Path
import statistics
import sys

from local_api import ROOT
sys.path.insert(0, str(ROOT / "backend"))
from app.validation.study_metrics import agreement_metrics, sus_score


def read_rows(path):
    with path.open(encoding="utf-8-sig", newline="") as stream:
        rows = list(csv.DictReader(stream))
    if not rows:
        raise ValueError("El CSV solo contiene el encabezado; aún no hay participantes")
    ids = [r["participant_id"].strip() for r in rows]
    if any(not value for value in ids) or len(set(ids)) != len(ids):
        raise ValueError("Los códigos deben ser únicos y no vacíos")
    return rows


def analyze_sus(rows):
    from scipy.stats import t
    scores = [sus_score([int(r[f"q{i}"]) for i in range(1, 11)]) for r in rows]
    n = len(scores)
    average = statistics.mean(scores)
    sd = statistics.stdev(scores) if n > 1 else None
    margin = float(t.ppf(0.975, n - 1)) * sd / math.sqrt(n) if sd is not None else None
    return {"n": n, "mean": average, "sd": sd,
            "mean_ci95_t": [average - margin, average + margin] if margin is not None else None,
            "scores": dict(zip([r["participant_id"] for r in rows], scores)),
            "note": "SUS 0–100 no es un porcentaje. IC t aproximado; muestra pequeña exploratoria."}


def analyze_clinical(rows):
    import numpy as np
    from scipy.stats import pearsonr, spearmanr
    if len(rows) < 3:
        raise ValueError("Se requieren al menos tres pares; esto no sustituye el cálculo muestral")
    if len({r["reference_test"] for r in rows}) != 1:
        raise ValueError("Separar MoCA/MMSE y versiones; no mezclar escalas en un análisis")
    if any(r["consent"].strip().lower() != "yes" for r in rows):
        raise ValueError("Solo analizar participantes con consentimiento registrado como yes")
    baseline = [float(r["neuroapp_baseline"]) for r in rows]
    retest = [float(r["neuroapp_retest"]) for r in rows]
    reference = [float(r["reference_score"]) for r in rows]
    intervals = [float(r["days_between"]) for r in rows]
    if any(not math.isfinite(x) for x in baseline + retest + reference + intervals):
        raise ValueError("No se admiten NaN/inf ni valores faltantes")
    if any(x <= 0 for x in intervals):
        raise ValueError("El retest debe ser posterior a la evaluación inicial")
    if any(len(set(values)) < 2 for values in (baseline, reference)):
        raise ValueError("Correlación indefinida con puntajes constantes")
    pearson = pearsonr(baseline, reference)
    spearman = spearmanr(baseline, reference)
    # Bootstrap por participante, conserva el emparejamiento y registra degenerados.
    rng = np.random.default_rng(360)
    iccs = []
    for _ in range(2000):
        indices = rng.integers(0, len(rows), len(rows))
        try:
            iccs.append(agreement_metrics([baseline[i] for i in indices], [retest[i] for i in indices])["icc_a1"])
        except ValueError:
            pass
    interval = pearson.confidence_interval() if len(rows) > 3 else None
    return {"n": len(rows), "reference_test": rows[0]["reference_test"],
            "pearson_r": float(pearson.statistic), "pearson_p": float(pearson.pvalue),
            "pearson_ci95_fisher": [float(interval.low), float(interval.high)] if interval else None,
            "spearman_rho": float(spearman.statistic), "spearman_p_asymptotic": float(spearman.pvalue),
            **agreement_metrics(baseline, retest),
            "icc_ci95_bootstrap_percentile": np.quantile(iccs, [0.025, 0.975]).tolist() if iccs else None,
            "bootstrap_valid": len(iccs), "bootstrap_repetitions": 2000, "bootstrap_seed": 360,
            "days_between_range": [min(intervals), max(intervals)],
            "note": "Exploratorio; IC bootstrap inestable en muestras pequeñas. Correlación no equivale a acuerdo ni valida un diagnóstico."}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("kind", choices=["sus", "clinical"])
    parser.add_argument("csv", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    try:
        rows = read_rows(args.csv)
        result = analyze_sus(rows) if args.kind == "sus" else analyze_clinical(rows)
    except (ValueError, KeyError) as error:
        parser.error(str(error))
    result["utc"] = datetime.now(timezone.utc).isoformat()
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2, ensure_ascii=False, allow_nan=False), encoding="utf-8")
    print(f"Análisis guardado en {args.output}")


if __name__ == "__main__":
    main()
