# Instala el companion Wear OS en relojes/emuladores conectados por ADB.
# Uso: .\tool\install_wear_companion.ps1

[CmdletBinding()]
param(
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"

function Get-RepoRoot {
    return (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}

function Resolve-JavaHome {
    $candidates = @(
        $env:JAVA_HOME,
        "$env:LOCALAPPDATA\Programs\Android Studio\jbr",
        "${env:ProgramFiles}\Android\Android Studio\jbr",
        "${env:ProgramFiles(x86)}\Android\Android Studio\jbr"
    ) | Where-Object { $_ -and (Test-Path (Join-Path $_ "bin\java.exe")) }

    if ($candidates.Count -eq 0) {
        throw "No se encontró JDK 17+. Instala Android Studio o define JAVA_HOME."
    }

    return $candidates[0]
}

function Resolve-AndroidSdk {
    $repoRoot = Get-RepoRoot
    $localProps = Join-Path $repoRoot "android\local.properties"

    if (Test-Path $localProps) {
        foreach ($line in Get-Content $localProps) {
            if ($line -match '^sdk\.dir=(.+)$') {
                $sdk = $Matches[1].Replace('/', '\').Replace('\\', '\')
                if (Test-Path $sdk) { return $sdk }
            }
        }
    }

    if ($env:ANDROID_HOME -and (Test-Path $env:ANDROID_HOME)) {
        return $env:ANDROID_HOME
    }

    $defaultSdk = Join-Path $env:LOCALAPPDATA "Android\Sdk"
    if (Test-Path $defaultSdk) { return $defaultSdk }

    throw "No se encontró Android SDK. Ejecuta flutter doctor o define ANDROID_HOME."
}

function Get-AdbPath {
    param([string]$AndroidSdk)
    $adb = Join-Path $AndroidSdk "platform-tools\adb.exe"
    if (-not (Test-Path $adb)) {
        throw "adb no encontrado en $adb"
    }
    return $adb
}

function Get-ConnectedDeviceSerials {
    param([string]$Adb)
    $lines = & $Adb devices | Select-Object -Skip 1
    $serials = @()
    foreach ($line in $lines) {
        if ($line -match '^(\S+)\s+device$') {
            $serials += $Matches[1]
        }
    }
    return $serials
}

function Test-WearDevice {
    param(
        [string]$Adb,
        [string]$Serial
    )

    $characteristics = (& $Adb -s $Serial shell getprop ro.build.characteristics 2>$null).Trim()
    if ($characteristics -match 'watch') { return $true }

    $fingerprint = (& $Adb -s $Serial shell getprop ro.build.fingerprint 2>$null).Trim()
    if ($fingerprint -match 'wear|watch|sdk_gwear') { return $true }

    $model = (& $Adb -s $Serial shell getprop ro.product.model 2>$null).Trim()
    if ($model -match 'wear|watch') { return $true }

    return $false
}

function Find-WearApk {
    param([string]$RepoRoot)

    $paths = @(
        Join-Path $RepoRoot "build\wear\outputs\apk\debug\wear-debug.apk",
        Join-Path $RepoRoot "android\wear\build\outputs\apk\debug\wear-debug.apk"
    )

    foreach ($path in $paths) {
        if (Test-Path $path) { return $path }
    }

    return $null
}

$repoRoot = Get-RepoRoot
$androidDir = Join-Path $repoRoot "android"
$gradlew = Join-Path $androidDir "gradlew.bat"

if (-not (Test-Path $gradlew)) {
    throw "No existe android\gradlew.bat. Ejecuta primero: flutter pub get; flutter build apk --debug"
}

$env:JAVA_HOME = Resolve-JavaHome
$androidSdk = Resolve-AndroidSdk
$adb = Get-AdbPath -AndroidSdk $androidSdk

Write-Host "JAVA_HOME=$($env:JAVA_HOME)"
Write-Host "Android SDK=$androidSdk"

$serials = Get-ConnectedDeviceSerials -Adb $adb
if ($serials.Count -eq 0) {
    throw "No hay dispositivos ADB conectados."
}

$wearSerials = @($serials | Where-Object { Test-WearDevice -Adb $adb -Serial $_ })
if ($wearSerials.Count -eq 0) {
    Write-Warning "No se detectó ningún reloj Wear OS."
    Write-Warning "Dispositivos conectados: $($serials -join ', ')"
    Write-Warning "Inicia un emulador Wear emparejado (Android Studio > Device Manager > Wear) y vuelve a ejecutar este script."
    exit 2
}

if (-not $SkipBuild) {
    Write-Host "Compilando companion Wear OS..."
    Push-Location $androidDir
    try {
        & .\gradlew.bat :wear:assembleDebug --no-daemon
        if ($LASTEXITCODE -ne 0) {
            throw "Falló la compilación del módulo :wear"
        }
    }
    finally {
        Pop-Location
    }
}

$apk = Find-WearApk -RepoRoot $repoRoot
if (-not $apk) {
    throw "No se encontró wear-debug.apk. Revisa la compilación del módulo :wear."
}

Write-Host "APK: $apk"

foreach ($serial in $wearSerials) {
    Write-Host "Instalando en reloj $serial..."
    & $adb -s $serial install -r $apk
    if ($LASTEXITCODE -ne 0) {
        throw "Falló adb install en $serial"
    }
}

Write-Host "Companion Wear OS instalado en: $($wearSerials -join ', ')"
