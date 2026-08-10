#!/usr/bin/env bash
set -euo pipefail

: "${IOS_DISTRIBUTION_CERTIFICATE_BASE64:?IOS_DISTRIBUTION_CERTIFICATE_BASE64 is required}"
: "${IOS_DISTRIBUTION_CERTIFICATE_PASSWORD:?IOS_DISTRIBUTION_CERTIFICATE_PASSWORD is required}"
: "${IOS_PROVISIONING_PROFILE_BASE64:?IOS_PROVISIONING_PROFILE_BASE64 is required}"
: "${KEYCHAIN_PASSWORD:?KEYCHAIN_PASSWORD is required}"

KEYCHAIN_PATH="$RUNNER_TEMP/app-signing.keychain-db"
CERT_PATH="$RUNNER_TEMP/build_certificate.p12"
PROFILE_PATH="$RUNNER_TEMP/build_pp.mobileprovision"

echo "$IOS_DISTRIBUTION_CERTIFICATE_BASE64" | base64 --decode >"$CERT_PATH"
echo "$IOS_PROVISIONING_PROFILE_BASE64" | base64 --decode >"$PROFILE_PATH"

security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security import "$CERT_PATH" -P "$IOS_DISTRIBUTION_CERTIFICATE_PASSWORD" -A -t cert -f pkcs12 \
  -k "$KEYCHAIN_PATH"
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
security list-keychain -d user -s "$KEYCHAIN_PATH"

mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
PROFILE_UUID="$(/usr/libexec/PlistBuddy -c 'Print UUID' /dev/stdin <<<"$(security cms -D -i "$PROFILE_PATH")")"
cp "$PROFILE_PATH" ~/Library/MobileDevice/Provisioning\ Profiles/"$PROFILE_UUID.mobileprovision"

echo "iOS signing configurado (profile $PROFILE_UUID)"
