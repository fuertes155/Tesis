<#
  Prueba de extremo a extremo (E2E) de NeuroApp360 en Chrome.

  1. Levanta un backend de PRUEBAS en el puerto 8001 con una BD temporal
     (tus datos reales de backend/data no se tocan).
  2. Carga los datos de partida (scripts/e2e_semilla.py).
  3. Descarga chromedriver para tu versión de Chrome si hace falta.
  4. Ejecuta integration_test/flujo_completo_test.dart con `flutter drive`.
  5. Apaga todo y borra la BD temporal.

  Uso (desde la raíz del proyecto):
    .\scripts\run_e2e.ps1            # navegador oculto
    .\scripts\run_e2e.ps1 -Visible   # para ver la prueba en Chrome
#>
param([int]$Puerto = 8001, [switch]$Visible)
$ErrorActionPreference = 'Stop'

$raiz = Split-Path -Parent $PSScriptRoot
$backend = Join-Path $raiz 'backend'
$python = Join-Path $backend 'venv\Scripts\python.exe'
$tmp = Join-Path $env:TEMP ("neuroapp_e2e_" + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path $tmp | Out-Null
$bd = Join-Path $tmp 'e2e.db'

function Get-ChromeDriver {
    $version = (Get-ItemProperty 'HKCU:\Software\Google\Chrome\BLBeacon').version
    $mayor = $version.Split('.')[0]
    $destino = Join-Path $env:LOCALAPPDATA "NeuroApp360\chromedriver\$mayor"
    $exe = Join-Path $destino 'chromedriver-win64\chromedriver.exe'
    if (-not (Test-Path $exe)) {
        Write-Host "Descargando chromedriver para Chrome $mayor..."
        $ultima = (Invoke-RestMethod "https://googlechromelabs.github.io/chrome-for-testing/LATEST_RELEASE_$mayor").Trim()
        $zip = Join-Path $tmp 'chromedriver.zip'
        Invoke-WebRequest "https://storage.googleapis.com/chrome-for-testing-public/$ultima/win64/chromedriver-win64.zip" -OutFile $zip
        New-Item -ItemType Directory -Force -Path $destino | Out-Null
        Expand-Archive $zip -DestinationPath $destino -Force
    }
    return $exe
}

$procesoApi = $null
$procesoDriver = $null
$peticionesSemilla = 0
$codigo = 1
try {
    # 1. Backend de pruebas (variables solo para este proceso hijo)
    $env:DATABASE_URL = "sqlite:///$($bd -replace '\\', '/')"
    $env:DEFAULT_ADMIN_PASSWORD = 'Password123!'
    $procesoApi = Start-Process $python -ArgumentList '-B', '-m', 'uvicorn', 'main:app', '--host', '127.0.0.1', '--port', $Puerto `
        -WorkingDirectory $backend -PassThru -WindowStyle Hidden `
        -RedirectStandardOutput (Join-Path $tmp 'backend.log') -RedirectStandardError (Join-Path $tmp 'backend.err')
    Remove-Item Env:DATABASE_URL, Env:DEFAULT_ADMIN_PASSWORD

    $listo = $false
    for ($i = 0; $i -lt 40 -and -not $listo; $i++) {
        try { Invoke-RestMethod "http://127.0.0.1:$Puerto/health" -TimeoutSec 2 | Out-Null; $listo = $true }
        catch { Start-Sleep -Milliseconds 500 }
    }
    if (-not $listo) { throw "El backend de pruebas no arrancó. Revisa $tmp\backend.err" }
    Write-Host "Backend de pruebas listo en http://127.0.0.1:$Puerto (BD temporal: $bd)"

    # 2. Datos de partida
    & $python -I (Join-Path $PSScriptRoot 'e2e_semilla.py') "http://127.0.0.1:$Puerto" $bd
    if ($LASTEXITCODE -ne 0) { throw 'Falló la carga de datos de partida' }
    $peticionesSemilla = @(Get-Content (Join-Path $tmp 'backend.log') |
        Where-Object { $_ -match '"(GET|POST|PUT|DELETE) ' }).Count

    # 3. chromedriver
    $procesoDriver = Start-Process (Get-ChromeDriver) -ArgumentList '--port=4444' -PassThru -WindowStyle Hidden

    # 4. Prueba E2E
    Push-Location $raiz
    $ErrorActionPreference = 'Continue'  # flutter escribe avisos por stderr
    try {
        flutter drive `
            --driver=test_driver/integration_test.dart `
            --target=integration_test/flujo_completo_test.dart `
            -d web-server `
            --browser-name=chrome `
            $(if ($Visible) { '--no-headless' } else { '--headless' }) `
            "--dart-define=API_BASE_URL=http://127.0.0.1:$Puerto" `
            "--dart-define=REPORTE_API_BASE_URL=http://127.0.0.1:$Puerto" 2>&1 |
            Tee-Object -Variable salida | Out-Host
        # Se decide también por lo que reporta la propia prueba, no solo por el código
        # de salida de `flutter drive` (en web no siempre refleja un fallo).
        $texto = ($salida | Out-String)
        $fallo = $texto -match 'Some tests failed|Test failed|Failure Details|Failure in method|\[E\]'
        $codigo = if ($LASTEXITCODE -ne 0 -or $fallo) { 1 } else { 0 }
    }
    finally {
        $ErrorActionPreference = 'Stop'
        Pop-Location
    }
}
finally {
    foreach ($p in @($procesoDriver, $procesoApi)) {
        if ($p -and -not $p.HasExited) { Stop-Process -Id $p.Id -Force }
    }
    Start-Sleep -Milliseconds 500
    # Evidencia: lo que la app hizo realmente contra el backend (sin contar la semilla).
    $log = Join-Path $tmp 'backend.log'
    if (Test-Path $log) {
        $peticiones = Get-Content $log | Where-Object { $_ -match '"(GET|POST|PUT|DELETE) ' } |
            Select-Object -Skip $peticionesSemilla
        $contar = { param($patron) @($peticiones | Where-Object { $_ -match $patron }).Count }
        Write-Host "`nActividad de la app en el backend de pruebas:"
        Write-Host ("  Resultados de juegos guardados: {0}" -f (& $contar 'POST /api/v1/sessions/results'))
        Write-Host ("  Informes generados:             {0}" -f (& $contar 'POST /evaluacion/generar-reporte'))
    }
    if ($codigo -eq 0) {
        Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
    } else {
        Write-Host "Logs del backend de pruebas conservados en: $tmp"
    }
}

if ($codigo -eq 0) { Write-Host "`nE2E APROBADA" -ForegroundColor Green } else { Write-Host "`nE2E FALLIDA (código $codigo)" -ForegroundColor Red }
exit $codigo
