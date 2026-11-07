"""Exporta metadatos de mutmut 3.3.1 sin confundir timeout/error con detección."""
from collections import Counter
import json
from pathlib import Path
import sys


def main():
    output = Path(sys.argv[1])
    output.mkdir(parents=True, exist_ok=True)
    statuses = Counter()
    mutants = {}
    for path in Path("mutants").rglob("*.meta"):
        data = json.loads(path.read_text())
        for name, code in data["exit_code_by_key"].items():
            status = ("killed" if code == 1 else "survived" if code == 0 else
                      "no_tests" if code in (5, 33) else "not_checked" if code is None
                      else "error_or_timeout")
            statuses[status] += 1
            mutants[name] = {"status": status, "exit_code": code}
    total = sum(statuses.values())
    summary = {"scope": "app/core/security.py", "total": total, "statuses": dict(statuses),
               "score_killed_over_total": statuses["killed"] / total if total else None,
               "mutants": mutants}
    (output / "summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    print(json.dumps({k: v for k, v in summary.items() if k != "mutants"}, indent=2))
    return 0 if total and statuses["killed"] == total else 1


if __name__ == "__main__":
    raise SystemExit(main())
