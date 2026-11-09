#!/bin/bash
# Notarizes a signed .dmg / .pkg with an App Store Connect API key and
# staples the ticket, so Gatekeeper accepts it offline too.
#
#   notarize.sh <file> <key .p8> <key id> <issuer id>
set -euo pipefail
file=$1
key=$2
key_id=$3
issuer=$4

auth=(--key "$key" --key-id "$key_id" --issuer "$issuer")
result=$(xcrun notarytool submit "$file" "${auth[@]}" --wait --output-format json)
id=$(plutil -extract id raw - <<< "$result")
status=$(plutil -extract status raw - <<< "$result")
echo "notarization $id: $status"
if [[ $status != Accepted ]]; then
  xcrun notarytool log "$id" "${auth[@]}" >&2 || true
  exit 1
fi
xcrun stapler staple "$file"
xcrun stapler validate "$file"
