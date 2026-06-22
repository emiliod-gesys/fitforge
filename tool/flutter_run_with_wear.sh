#!/usr/bin/env bash
# Instala Wear companion (si hay reloj) y ejecuta flutter run.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INSTALL="$ROOT/tool/install_wear_companion.sh"

echo "==> Companion Wear OS"
set +e
bash "$INSTALL"
WEAR_EXIT=$?
set -e

if [[ $WEAR_EXIT -eq 2 ]]; then
  echo "Continuando sin instalar Wear (no hay reloj conectado)."
elif [[ $WEAR_EXIT -ne 0 ]]; then
  exit $WEAR_EXIT
fi

echo "==> Flutter run"
cd "$ROOT"
flutter run "$@"
