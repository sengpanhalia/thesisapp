#!/usr/bin/env bash
# Run the app with the API token + base URL baked in from dart_defines.json.
#
# One-time setup:
#   cp dart_defines.example.json dart_defines.json   # then paste the real token
#
# dart_defines.json is gitignored, so the token never enters the repository.
# --dart-define is compile-time, which is why a bare `flutter run` (or one after
# `flutter clean`) builds with an empty token and the app asks for a key; this
# passes the file every time so that cannot happen.
set -euo pipefail
cd "$(dirname "$0")"

if [ ! -f dart_defines.json ]; then
  echo "dart_defines.json is missing — copy dart_defines.example.json to it and paste the token." >&2
  exit 1
fi

exec flutter run --dart-define-from-file=dart_defines.json "$@"
