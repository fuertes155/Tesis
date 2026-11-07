"""Métricas con validación estricta de entradas, independientes de la API."""
import math
from statistics import mean


def sus_score(responses):
    if len(responses) != 10 or any(type(x) is not int or not 1 <= x <= 5 for x in responses):
        raise ValueError("SUS requiere diez respuestas enteras entre 1 y 5")
    return 2.5 * sum(x - 1 if i % 2 == 0 else 5 - x for i, x in enumerate(responses))


def agreement_metrics(baseline, retest):
    """ICC(A,1): dos vías, acuerdo absoluto, medida individual; Bland–Altman."""
    if len(baseline) != len(retest) or len(baseline) < 3:
        raise ValueError("Se requieren al menos tres pares completos")
    if any(not math.isfinite(x) for x in [*baseline, *retest]):
        raise ValueError("Los puntajes deben ser finitos")
    n, k = len(baseline), 2
    rows = [(x + y) / 2 for x, y in zip(baseline, retest)]
    columns = [mean(baseline), mean(retest)]
    grand = mean(columns)
    ms_rows = k * sum((x - grand) ** 2 for x in rows) / (n - 1)
    ms_columns = n * sum((x - grand) ** 2 for x in columns) / (k - 1)
    ms_error = sum((value - rows[i] - columns[j] + grand) ** 2
                   for i, pair in enumerate(zip(baseline, retest))
                   for j, value in enumerate(pair)) / ((n - 1) * (k - 1))
    denominator = ms_rows + (k - 1) * ms_error + k * (ms_columns - ms_error) / n
    if denominator == 0:
        raise ValueError("ICC indefinido: no hay variabilidad")
    differences = [y - x for x, y in zip(baseline, retest)]
    bias = mean(differences)
    sd = math.sqrt(sum((d - bias) ** 2 for d in differences) / (n - 1))
    return {"icc_a1": (ms_rows - ms_error) / denominator,
            "bias_retest_minus_baseline": bias,
            "agreement_lower": bias - 1.96 * sd, "agreement_upper": bias + 1.96 * sd}
