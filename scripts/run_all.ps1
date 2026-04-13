$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

Start-Process -FilePath "powershell" -ArgumentList @(
  "-NoExit",
  "-Command",
  "Set-Location -Path `"$root\backend`"; python -B -m uvicorn main:app --reload --host 127.0.0.1 --port 8000"
)

Start-Process -FilePath "powershell" -ArgumentList @(
  "-NoExit",
  "-Command",
  "Set-Location -Path `"$root`"; flutter run -d chrome --web-hostname 127.0.0.1 --web-port 55912"
)
