# youtube_spike

Standalone Dart CLI (no Flutter) that measures the two YouTube live chat
**read paths** against a real chat, to decide the default read transport for
the native YouTube chat engine (see `docs/youtube-native-chat-audit.md`):

- **poll** — REST `liveChatMessages.list` loop honoring
  `pollingIntervalMillis` exactly (drift is logged), resuming via
  `pageToken`, stopping cleanly on `offlineAt` / `chatEndedEvent`.
  Prints calls, messages, errors and a running quota estimate
  (calls × 5 units, community-verified cost).
- **stream** — gRPC server-streaming `V3DataLiveChatMessageService.StreamList`
  on `youtube.googleapis.com:443`, API key sent as `x-goog-api-key` metadata.
  Streams can EOF after seconds; the tool resumes from the last
  `nextPageToken` with exponential backoff and logs connection lifetimes,
  EOF count and message cadence. Its quota cost is **undocumented** — that
  is what the measurement protocol below determines.

All calls are charged to the GCP project that owns the API key, so use a
throwaway/test project key.

## Setup

Prerequisites: Dart SDK ≥ 3.4, `protoc`, and the Dart protoc plugin:

```bash
apt install protobuf-compiler            # or your platform's equivalent
dart pub global activate protoc_plugin   # installs protoc-gen-dart
```

Then, from this directory:

```bash
./setup.sh      # fetches stream_list.proto + runs protoc --dart_out=grpc
dart pub get
```

`setup.sh` tries the documented proto URL first; Google currently does not
serve `stream_list.proto` as a raw file (the URL returns an HTML page), so
the script falls back to extracting the proto **verbatim from the "stream_list.proto"
section** of the official guide
(<https://developers.google.com/youtube/v3/live/streaming-live-chat>) and
verifies the result declares `proto2` + `V3DataLiveChatMessageService` +
`rpc StreamList` before generating.

The fetched proto (`proto/`) and the generated stubs (`lib/src/generated/`)
are **gitignored** — re-run `./setup.sh` after a fresh clone. If the stubs
are missing, the binary exits with a clear error telling you to run
`setup.sh`.

## Running

```bash
# Resolve video → live chat id via videos.list (1 unit, logged), run both modes:
dart run bin/youtube_spike.dart --api-key "$YT_API_KEY" --video-id <VIDEO_ID>

# Poll only, 45 minutes, chat id already known:
dart run bin/youtube_spike.dart --api-key "$YT_API_KEY" \
    --live-chat-id <CHAT_ID> --mode poll --duration-minutes 45

# Stream only:
dart run bin/youtube_spike.dart --api-key "$YT_API_KEY" \
    --video-id <VIDEO_ID> --mode stream
```

Ctrl-C finishes the current step and still prints the summary.
Pick a **busy chat** (large concurrent streamer) — EOF behavior and message
cadence only show up under real load.

## Quota measurement protocol

Client-side logs only give the poll estimate (calls × 5). The stream mode's
per-connection quota cost is undocumented, so measure it from the GCP side:

1. In Google Cloud Console, open **APIs & Services → Enabled APIs →
   YouTube Data API v3 → Quotas & System Limits** for the project that owns
   the key. Note the current-day **usage** counter (take a screenshot with a
   visible clock). Use a project with no other API traffic during the run.
2. Run stream mode for **≥ 30 minutes** on a busy chat:
   `--mode stream --duration-minutes 30` (longer is better; keep the full
   tool output — connection lifetimes and EOF count matter for the
   per-connection cost).
3. Refresh the quota page, note the new usage counter (screenshot again).
   `delta = after - before`. Subtract the 1 unit for `videos.list` if you
   used `--video-id`.
4. Compute:
   - **units per connection-hour** = `delta / (runHours × avg concurrent
     connections)` — stream mode holds one connection at a time, so this is
     `delta / runHours` unless you ran several instances.
   - **units per poll-hour** (baseline) = `pollCalls × 5 / pollRunHours`
     from a same-length `--mode poll` run; sanity-check against the
     theoretical 5 units × 720 calls/hr ≈ 3,600 units/hr at a 5 s interval.
5. Record the results in `docs/youtube-native-chat-audit.md` (quota
   section): date, chat size, run length, EOF count, delta, and the
   computed units/connection-hour vs units/poll-hour. That comparison
   gates whether in-app gRPC becomes the default read path.

## Notes

- `videos.list?part=liveStreamingDetails` costs 1 unit; a video without an
  active chat errors out as "not live".
- `liveChatMessages.list` ≈ 5 units/call (community-verified; Google removed
  the live rows from the official quota table).
- `streamList` is not in the REST discovery doc, so no `package:googleapis`
  support — this tool vendors the proto + `package:grpc`.
