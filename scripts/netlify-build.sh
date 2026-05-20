#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  FLUTTER_HOME="${NETLIFY_BUILD_BASE:-$HOME}/flutter"
  if [ ! -d "$FLUTTER_HOME/bin" ]; then
    git clone https://github.com/flutter/flutter.git --branch stable --depth 1 "$FLUTTER_HOME"
  fi
  export PATH="$FLUTTER_HOME/bin:$PATH"
fi

flutter config --enable-web
flutter pub get

if [ -n "${API_BASE_URL:-}" ]; then
  flutter build web --release --base-href / --dart-define=API_BASE_URL="$API_BASE_URL"
else
  flutter build web --release --base-href /
fi
