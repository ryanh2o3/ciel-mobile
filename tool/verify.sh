#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
dart analyze --fatal-infos
dart run import_lint
flutter test
