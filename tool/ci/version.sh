#!/usr/bin/env bash
# Calcula versão de release sem editar pubspec.yaml manualmente.
# BUILD_NUMBER: número monotônico do CI (github.run_number).
# BUILD_NAME: major.minor do pubspec + patch = BUILD_NUMBER.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

BUILD_NUMBER="${BUILD_NUMBER:-${GITHUB_RUN_NUMBER:-1}}"
VERSION_LINE="$(grep '^version:' pubspec.yaml | awk '{print $2}')"
BASE="${VERSION_LINE%%+*}"
MAJOR="$(echo "$BASE" | cut -d. -f1)"
MINOR="$(echo "$BASE" | cut -d. -f2)"

if [[ -z "$MAJOR" || -z "$MINOR" ]]; then
  echo "Não foi possível ler major.minor de pubspec.yaml (version: $VERSION_LINE)" >&2
  exit 1
fi

BUILD_NAME="${MAJOR}.${MINOR}.${BUILD_NUMBER}"

echo "BUILD_NUMBER=${BUILD_NUMBER}"
echo "BUILD_NAME=${BUILD_NAME}"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  {
    echo "build_number=${BUILD_NUMBER}"
    echo "build_name=${BUILD_NAME}"
  } >>"$GITHUB_OUTPUT"
fi
