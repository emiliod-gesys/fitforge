#!/usr/bin/env bash
# Instala el companion Wear OS en relojes conectados por ADB.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ANDROID_DIR="$ROOT/android"
GRADLEW="$ANDROID_DIR/gradlew"

resolve_java_home() {
  if [[ -n "${JAVA_HOME:-}" && -x "$JAVA_HOME/bin/java" ]]; then
    echo "$JAVA_HOME"
    return
  fi
  for candidate in \
    "$HOME/Applications/Android Studio.app/Contents/jbr" \
    "/Applications/Android Studio.app/Contents/jbr" \
    "/usr/lib/jvm/java-17-openjdk" \
    "/usr/lib/jvm/java-17"; do
    if [[ -x "$candidate/bin/java" ]]; then
      echo "$candidate"
      return
    fi
  done
  echo "No se encontró JDK 17+. Define JAVA_HOME." >&2
  exit 1
}

resolve_android_sdk() {
  if [[ -f "$ANDROID_DIR/local.properties" ]]; then
    local sdk
    sdk="$(grep '^sdk.dir=' "$ANDROID_DIR/local.properties" | cut -d= -f2- | tr '\\' '/')"
    if [[ -d "$sdk" ]]; then
      echo "$sdk"
      return
    fi
  fi
  if [[ -n "${ANDROID_HOME:-}" && -d "$ANDROID_HOME" ]]; then
    echo "$ANDROID_HOME"
    return
  fi
  echo "No se encontró Android SDK." >&2
  exit 1
}

is_wear_device() {
  local adb="$1" serial="$2"
  local characteristics fingerprint model
  characteristics="$("$adb" -s "$serial" shell getprop ro.build.characteristics 2>/dev/null | tr -d '\r')"
  fingerprint="$("$adb" -s "$serial" shell getprop ro.build.fingerprint 2>/dev/null | tr -d '\r')"
  model="$("$adb" -s "$serial" shell getprop ro.product.model 2>/dev/null | tr -d '\r')"
  [[ "$characteristics" == *watch* || "$fingerprint" == *wear* || "$fingerprint" == *watch* || "$model" == *wear* || "$model" == *watch* ]]
}

export JAVA_HOME="$(resolve_java_home)"
SDK="$(resolve_android_sdk)"
ADB="$SDK/platform-tools/adb"

if [[ ! -x "$GRADLEW" ]]; then
  echo "No existe android/gradlew. Ejecuta: flutter build apk --debug" >&2
  exit 1
fi

mapfile -t SERIALS < <("$ADB" devices | awk 'NR>1 && $2=="device" {print $1}')
if [[ ${#SERIALS[@]} -eq 0 ]]; then
  echo "No hay dispositivos ADB conectados." >&2
  exit 1
fi

WEAR_SERIALS=()
for serial in "${SERIALS[@]}"; do
  if is_wear_device "$ADB" "$serial"; then
    WEAR_SERIALS+=("$serial")
  fi
done

if [[ ${#WEAR_SERIALS[@]} -eq 0 ]]; then
  echo "No se detectó ningún reloj Wear OS. Conecta un emulador Wear emparejado." >&2
  exit 2
fi

echo "Compilando companion Wear OS..."
(cd "$ANDROID_DIR" && "$GRADLEW" :wear:assembleDebug --no-daemon)

APK=""
for candidate in \
  "$ROOT/build/wear/outputs/apk/debug/wear-debug.apk" \
  "$ROOT/android/wear/build/outputs/apk/debug/wear-debug.apk"; do
  if [[ -f "$candidate" ]]; then
    APK="$candidate"
    break
  fi
done

if [[ -z "$APK" ]]; then
  echo "No se encontró wear-debug.apk" >&2
  exit 1
fi

for serial in "${WEAR_SERIALS[@]}"; do
  echo "Instalando en reloj $serial..."
  "$ADB" -s "$serial" install -r "$APK"
done

echo "Companion Wear OS instalado."
