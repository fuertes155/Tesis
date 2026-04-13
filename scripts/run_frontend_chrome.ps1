$ErrorActionPreference = "Stop"
Set-Location -Path (Split-Path -Parent $PSScriptRoot)
flutter run -d chrome --web-hostname 127.0.0.1 --web-port 55912
