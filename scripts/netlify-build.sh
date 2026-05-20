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
  flutter build web --release --base-href / -O4 --source-maps --no-wasm-dry-run --dart-define=API_BASE_URL="$API_BASE_URL"
else
  flutter build web --release --base-href / -O4 --source-maps --no-wasm-dry-run
fi

# Flutter emits a sourceMappingURL for flutter.js without shipping flutter.js.map.
# Removing that reference prevents Lighthouse from reporting a missing source map.
if [ -f build/web/flutter.js ]; then
  perl -0pi -e 's/\n?\/\/# sourceMappingURL=flutter\.js\.map\s*$//' build/web/flutter.js
fi
if [ -f build/web/flutter_bootstrap.js ]; then
  perl -0pi -e 's/\n?\/\/# sourceMappingURL=flutter\.js\.map\s*/\n/g' build/web/flutter_bootstrap.js
fi
