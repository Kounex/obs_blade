#!/usr/bin/env bash
# Fetches Google's published stream_list.proto and generates the Dart
# gRPC stubs into lib/src/generated/ (gitignored — re-run this script to
# regenerate).
#
# Prerequisites:
#   protoc          (e.g. apt install protobuf-compiler)
#   protoc-gen-dart (dart pub global activate protoc_plugin)
set -euo pipefail
cd "$(dirname "$0")"

PROTO_DIR=proto
PROTO_FILE="$PROTO_DIR/stream_list.proto"
OUT_DIR=lib/src/generated
GUIDE_URL="https://developers.google.com/youtube/v3/live/streaming-live-chat"

# --- tool checks -------------------------------------------------------------
if ! command -v protoc >/dev/null 2>&1; then
  echo "error: protoc not found in PATH." >&2
  echo "       install it first, e.g.: apt install protobuf-compiler" >&2
  exit 1
fi

export PATH="$PATH:$HOME/.pub-cache/bin"
if ! command -v protoc-gen-dart >/dev/null 2>&1; then
  echo "error: protoc-gen-dart not found." >&2
  echo "       run: dart pub global activate protoc_plugin" >&2
  exit 1
fi

# --- verify helper -----------------------------------------------------------
# A genuine stream_list.proto declares proto2 syntax and the service name.
verify_proto() {
  grep -q 'syntax = "proto2"' "$1" \
    && grep -q 'V3DataLiveChatMessageService' "$1" \
    && grep -q 'rpc StreamList' "$1"
}

# --- fetch the proto ---------------------------------------------------------
# Google does not publish stream_list.proto as a raw file (the documented URL
# returns an HTML 404 page). It is embedded verbatim in the streaming guide's
# "stream_list.proto" section, so we extract that code block. The direct URLs
# are still tried first in case Google starts publishing the raw file again.
mkdir -p "$PROTO_DIR" "$OUT_DIR"
: > "$PROTO_FILE"

for url in \
  "https://developers.google.com/youtube/v3/live/stream_list.proto" \
  "https://developers.google.com/youtube/v3/live/docs/liveChatMessages/stream_list.proto"; do
  echo "trying $url"
  if curl -fsSL --max-time 30 -o "$PROTO_FILE" "$url" && verify_proto "$PROTO_FILE"; then
    break
  fi
  : > "$PROTO_FILE"
done

if ! verify_proto "$PROTO_FILE"; then
  if ! command -v python3 >/dev/null 2>&1; then
    echo "error: raw proto URL did not serve a proto file, and python3 is" >&2
    echo "       not available to extract it from the guide page ($GUIDE_URL)." >&2
    exit 1
  fi
  echo "extracting embedded proto from $GUIDE_URL"
  curl -fsSL --max-time 30 -o "$PROTO_DIR/streaming-live-chat.html" "$GUIDE_URL"
  python3 - "$PROTO_DIR/streaming-live-chat.html" "$PROTO_FILE" <<'PY'
import html, re, sys
src = open(sys.argv[1], encoding="utf-8").read()
i = src.index('id="stream_listproto"')
j = src.index("<devsite-code>", i)
k = src.index("</devsite-code>", j)
code = re.search(r"<code[^>]*>(.*?)</code>", src[j:k], re.S).group(1)
open(sys.argv[2], "w").write(html.unescape(re.sub(r"<[^>]+>", "", code)))
PY
fi

if ! verify_proto "$PROTO_FILE"; then
  echo "error: fetched file does not look like stream_list.proto" >&2
  echo "       (missing proto2 syntax / V3DataLiveChatMessageService / StreamList)." >&2
  exit 1
fi
echo "proto OK: $PROTO_FILE"

# Google's published proto references google.protobuf.Duration but omits the
# import; insert it so protoc accepts the file.
if grep -q 'google\.protobuf\.Duration' "$PROTO_FILE" \
  && ! grep -q 'google/protobuf/duration.proto' "$PROTO_FILE"; then
  echo "patching in missing duration.proto import"
  sed -i 's|^package youtube\.api\.v3;|package youtube.api.v3;\n\nimport "google/protobuf/duration.proto";|' \
    "$PROTO_FILE"
fi

# --- generate ----------------------------------------------------------------
protoc --dart_out=grpc:"$OUT_DIR" --proto_path="$PROTO_DIR" stream_list.proto
echo "generated Dart stubs in $OUT_DIR/"
echo "next: dart pub get && dart run bin/youtube_spike.dart --help"
