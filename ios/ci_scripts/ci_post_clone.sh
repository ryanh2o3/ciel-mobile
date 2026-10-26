#!/bin/sh
set -eu

# Xcode Cloud runs this before resolving packages or evaluating the scheme.
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
cd "$SCRIPT_DIR/../.."

# Match the local SDK; optionally override in the Xcode Cloud environment.
FLUTTER_VERSION="${FLUTTER_VERSION:-3.47.2}"
FLUTTER_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/ciel-flutter.XXXXXX")"
export FLUTTER_ROOT
git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_ROOT"
export PATH="$FLUTTER_ROOT/bin:$PATH"

flutter --version
flutter precache --ios
flutter pub get

if ! command -v pod >/dev/null 2>&1; then
  HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods
fi

# Generate cloud-local Flutter settings and Swift package integration before
# Runner's Prepare Flutter Framework pre-action reads FLUTTER_ROOT.
flutter build ios --config-only --release --no-codesign
cd ios
pod install
