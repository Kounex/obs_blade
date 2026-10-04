# WebSocket connection audit (2026-07-25)

## Verdict

OBS WebSocket **`rpcVersion` is still `1`**. Auth algorithm unchanged. There is
no proven “protocol rewrite” that alone explains “can’t connect.”

User reports mix:

- **Environment:** Windows Firewall / Public network, WebSocket disabled, port
  conflicts (e.g. DroidCam on 4455).
- **App gaps:** short handshake timeout, auth always sent, errors collapsed to
  generic “Couldn’t connect,” domain default `wss://`, stream listener lifecycle.

Upstream: [obs-websocket protocol](https://github.com/obsproject/obs-websocket/blob/master/docs/generated/protocol.md).

## Handshake (correct behavior)

1. TCP upgrade → OBS sends **Hello** (`op` 0), optional `authentication` object.
2. App sends **Identify** (`op` 1): `rpcVersion`, `eventSubscriptions`, and
   **`authentication` only if Hello required it**.
3. OBS sends **Identified** (`op` 2) or closes with a 400x code.

## App gaps → remediation status

| Gap | Status |
|---|---|
| Identify always includes `authentication` | **Fixed** — conditional on Hello |
| 3s timeout → false `UnknownReason` | **Fixed** — `kObsHandshakeTimeout` 10s + stages |
| Completer race `onDone` / Identified | **Fixed** — complete only if `!isCompleted` |
| Generic failure overlay | **Fixed** — `ConnectionAttemptResult.userMessage` |
| Domain default `wss://` | **Fixed** — default `ws://`; `websocketUri` builder |
| `watchOBSStream` closes socket; uncanceled listens | **Fixed** — owned pumps + cancel on dispose |
| Reconnect skips re-binding pump | **Fixed** — `handleStream` after success |
| QR only `obsws://` | **Fixed** — also `obswss://` via `Uri.parse` |

## Environment (not fixed in code)

- Enable WebSocket Server in OBS Tools → WebSocket Server Settings.
- Use password from **Show Connect Info**.
- Allow OBS through firewall; Private network profile on Windows.
- Same LAN / subnet; Local Network permission on iOS.

## Related code

- [`lib/utils/authentication_helper.dart`](../lib/utils/authentication_helper.dart)
- [`lib/stores/shared/network.dart`](../lib/stores/shared/network.dart)
- [`lib/utils/network_helper.dart`](../lib/utils/network_helper.dart)
- [`lib/types/classes/connection_attempt_result.dart`](../lib/types/classes/connection_attempt_result.dart)
- Architecture overview: [`obs-websocket-architecture.md`](obs-websocket-architecture.md)
