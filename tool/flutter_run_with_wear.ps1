# Instala el companion Wear OS (si hay reloj conectado) y lanza flutter run.
# Uso:
#   .\tool\flutter_run_with_wear.ps1
#   .\tool\flutter_run_with_wear.ps1 -d emulator-5554 --dart-define-from-file=dart_defines.json

[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$FlutterArgs
)

$ErrorActionPreference = "Stop"
$installScript = Join-Path $PSScriptRoot "install_wear_companion.ps1"

Write-Host "==> Companion Wear OS"
& $installScript
$wearExit = $LASTEXITCODE

if ($wearExit -eq 2) {
    Write-Warning "Continuando sin instalar Wear (no hay reloj conectado)."
}
elseif ($wearExit -ne 0) {
    exit $wearExit
}

Write-Host "==> Flutter run"
Push-Location (Resolve-Path (Join-Path $PSScriptRoot ".."))
try {
    if ($FlutterArgs.Count -gt 0) {
        flutter run @FlutterArgs
    }
    else {
        flutter run
    }
    exit $LASTEXITCODE
}
finally {
    Pop-Location
}
