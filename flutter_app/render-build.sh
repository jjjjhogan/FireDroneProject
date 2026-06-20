#!/usr/bin/env bash
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.44.1}"
FLUTTER_HOME="${FLUTTER_HOME:-$PWD/.render/flutter}"
API_BASE="${FIRE_DRONE_API_BASE:-http://127.0.0.1:5000/api}"

if [[ -n "${RENDER:-}" && -z "${FIRE_DRONE_API_BASE:-}" ]]; then
  echo "FIRE_DRONE_API_BASE must be set for Render builds, for example https://firedrone-api.onrender.com/api" >&2
  exit 1
fi

if [[ ! -x "$FLUTTER_HOME/bin/flutter" ]]; then
  rm -rf "$FLUTTER_HOME"
  mkdir -p "$(dirname "$FLUTTER_HOME")"
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_HOME"
fi

export PATH="$FLUTTER_HOME/bin:$PATH"

flutter config --enable-web
flutter pub get
flutter build web --release --dart-define=FIRE_DRONE_API_BASE="$API_BASE"
