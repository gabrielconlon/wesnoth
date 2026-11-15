#!/usr/bin/env bash
# Archive Wesnoth for iOS, export a signed .ipa, upload to TestFlight.
# Mirrors the shared release.sh pattern (team 3ED9V77D6W, Admin API key, build number = commit count)
# Run after build_ios_deps.sh.
#   projectfiles/Xcode/ios/release.sh [--no-upload]
set -euo pipefail
cd "$(dirname "$0")/.."

API_KEY_ID=FMX4FN3K62
API_ISSUER_ID=69a6de80-535b-47e3-e053-5b8c7c11a4d1
KEY_PATH="$HOME/.appstoreconnect/private_keys/AuthKey_${API_KEY_ID}.p8"
TEAM=3ED9V77D6W
BUNDLE_ID=com.gabrielconlon.wesnoth
UPLOAD=1; [[ "${1:-}" == "--no-upload" ]] && UPLOAD=0

BUILD_NUMBER="$(git rev-list --count HEAD)"
AUTH=(-allowProvisioningUpdates -authenticationKeyPath "$KEY_PATH"
      -authenticationKeyID "$API_KEY_ID" -authenticationKeyIssuerID "$API_ISSUER_ID")
ARCHIVE=build-ios/Wesnoth.xcarchive
EXPORT_DIR=build-ios/export

echo "==> Wesnoth $(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Info-iOS.plist) ($BUILD_NUMBER)"
cp Info-iOS.plist build-ios-Info.plist.bak 2>/dev/null || true
trap 'mv -f build-ios-Info.plist.bak Info-iOS.plist 2>/dev/null || true' EXIT
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" Info-iOS.plist

rm -rf "$ARCHIVE" "$EXPORT_DIR"
xcodebuild archive \
  -project "The Battle for Wesnoth.xcodeproj" \
  -scheme "The Battle for Wesnoth" \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -derivedDataPath build-ios \
  -archivePath "$ARCHIVE" \
  -IDEBuildingContinueBuildingAfterErrors=YES \
  "${AUTH[@]}" \
  DEVELOPMENT_TEAM="$TEAM" \
  PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID"

EXPORT_PLIST="$(mktemp -t wesnoth-export).plist"
cat > "$EXPORT_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>method</key><string>app-store-connect</string>
  <key>destination</key><string>export</string>
  <key>teamID</key><string>${TEAM}</string>
  <key>signingStyle</key><string>automatic</string>
  <key>manageAppVersionAndBuildNumber</key><false/>
</dict></plist>
EOF
xcodebuild -exportArchive -archivePath "$ARCHIVE" -exportOptionsPlist "$EXPORT_PLIST" \
  -exportPath "$EXPORT_DIR" "${AUTH[@]}"
IPA="$(ls "$EXPORT_DIR"/*.ipa | head -1)"
echo "==> Exported $IPA"
[[ "$UPLOAD" -eq 0 ]] && exit 0

echo "==> Validating"
xcrun altool --validate-app --file "$IPA" --type ios --apiKey "$API_KEY_ID" --apiIssuer "$API_ISSUER_ID"
echo "==> Uploading to TestFlight"
xcrun altool --upload-app --file "$IPA" --type ios --apiKey "$API_KEY_ID" --apiIssuer "$API_ISSUER_ID"
echo "==> Uploaded build $BUILD_NUMBER."
