#!/bin/bash
# Builds Sure (with the home screen widget) as an IPA for SideStore/iloader.
# Run on a Mac from the mobile/ folder:  bash ios/build_sideload_ipa.sh
#
# The IPA is ad-hoc signed only so the App Group entitlement is embedded;
# SideStore/iloader re-sign it with your Apple ID when installing.
set -euo pipefail

cd "$(dirname "$0")/.."
OUT="build/sideload"
APP="build/ios/iphoneos/Runner.app"

echo "==> Building Flutter app (unsigned)"
flutter pub get
# pubspec.yaml only has a dev placeholder version (upstream CI sets the real one),
# so give the sideload build a real version and an always-increasing build number.
flutter build ios --release --no-codesign \
  --build-name "${SIDELOAD_BUILD_NAME:-0.7.6}" \
  --build-number "${SIDELOAD_BUILD_NUMBER:-$(date -u +%Y%m%d%H)}"

if [ ! -d "$APP/PlugIns/SureWidget.appex" ]; then
  echo "!! SureWidget.appex is missing from the app. Check that the SureWidget"
  echo "!! target exists and is embedded in Runner (see WIDGET_SETUP.md)."
  exit 1
fi

echo "==> Ad-hoc signing with entitlements"
find "$APP/Frameworks" -maxdepth 1 \( -name '*.framework' -o -name '*.dylib' \) -print0 2>/dev/null |
  while IFS= read -r -d '' item; do
    codesign -f -s - "$item"
  done
codesign -f -s - --entitlements ios/SureWidget/SureWidget.entitlements "$APP/PlugIns/SureWidget.appex"
codesign -f -s - --entitlements ios/Runner/Runner.entitlements "$APP"

echo "==> Packaging IPA"
rm -rf "$OUT"
mkdir -p "$OUT/Payload"
cp -R "$APP" "$OUT/Payload/"
(cd "$OUT" && zip -qry Sure-with-widget.ipa Payload)
rm -rf "$OUT/Payload"

echo "==> Done: $(pwd)/$OUT/Sure-with-widget.ipa"
