"""mutmut en Linux aislado; solo copia código/pruebas, sin .env ni datos reales."""
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

from local_api import ROOT


def main():
    output = ROOT / "artifacts/mutation"
    output.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="source_", dir=output) as directory:
        stage = Path(directory)
        for name in ("app", "tests"):
            shutil.copytree(ROOT / "backend" / name, stage / name,
                            ignore=shutil.ignore_patterns("__pycache__", "*.pyc"))
        for name in ("main.py", "pytest.ini", "setup.cfg", "requirements.txt"):
            shutil.copy2(ROOT / "backend" / name, stage / name)
        shutil.copy2(Path(__file__).with_name("export_mutation.py"), stage / "export_mutation.py")
        # Evita copiar/configurar plugins de pytest ajenos al proyecto.
        runner = '''import subprocess, sys
from pathlib import Path
subprocess.run([sys.executable, '-m', 'pip', 'install', '-r', 'requirements.txt', 'mutmut==3.3.1'], check=True)
baseline = subprocess.run([sys.executable, '-m', 'pytest', '-q'])
if baseline.returncode:
    raise SystemExit(baseline.returncode)
run = subprocess.run(['mutmut', 'run', '--max-children', '2'])
with Path('/out/results.txt').open('w') as log:
    subprocess.run(['mutmut', 'results'], stdout=log, stderr=log)
summary = subprocess.run([sys.executable, 'export_mutation.py', '/out'])
raise SystemExit(run.returncode or summary.returncode)
'''
        (stage / "container_runner.py").write_text(runner, encoding="utf-8")
        with (output / "mutation.log").open("w", encoding="utf-8") as log:
            result = subprocess.run(["docker", "run", "--rm", "--cpus", "2",
                "-v", f"{stage.resolve()}:/work:rw", "-v", f"{output.resolve()}:/out:rw",
                "-w", "/work", "python:3.12-slim", "python", "container_runner.py"],
                stdout=log, stderr=log, timeout=1500)
        print(f"mutmut exit={result.returncode}; informes en {output}")
        return result.returncode


if __name__ == "__main__":
    raise SystemExit(main())
