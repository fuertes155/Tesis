$ErrorActionPreference = "Stop"
Set-Location -Path (Join-Path (Split-Path -Parent $PSScriptRoot) "backend")
python -B -m uvicorn main:app --reload --host 127.0.0.1 --port 8000
