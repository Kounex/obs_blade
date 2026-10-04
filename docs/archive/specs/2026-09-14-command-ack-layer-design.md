# Command-ack layer — mini-design (2026-09-14)

Astra adoption, phase 2 (audit defect #3). Tier **M**: implementer subagent +
end reviewer; this doc is the plan. Predecessor: harvest phase 1 + defect fixes
#5/#6 (landed on `4.0-liquid-glass`).

## Defect being fixed

`NetworkHelper.makeRequest` returns `void` — fire-and-forget. Failures are
log-only; optimistic DashboardStore state (scene selection etc.) is never
rolled back or re-synced. Astra's proven rule: **never assign from an ack —
re-read confirmed state**; revision counters let events beat stale reads.

## User-ratified decisions

| Decision | Answer |
|---|---|
| Timing/branch | Feature branch `command-ack-layer` off `4.0-liquid-glass` (Gate 3 diff stays frozen; merges into 4.0 when gated) |
| Failure UX | Toast on **definitive** failure only (explicit `requestStatus.result == false` or hard timeout ~10s) + re-read + log. Storm dedup (same kind within a short window / mass failure on disconnect → one aggregate toast). **Settings kill-switch** (persisted, default on) → off = log-only. Slow-but-eventually-successful acks never toast. |
| Wave scope | Mechanism + **all** DashboardStore mutations. Special rule for continuous controls (volume slider): ticks stay fire-and-forget (unawaited, today's UX unchanged), `onChangeEnd` commits via the acked path; failed commit → re-read + toast. Socket order guarantees the final write wins over in-flight ticks. |
| Merge gate | Fake-peer protocol tests (loopback OBS v5 peer that deterministically rejects/delays/drops acks — astra `test/redesign/support/obs_peer.dart` pattern) + unit/widget gates + **real-OBS smoke run by the agent** via `tool/obs_local` (`obs_test_env.sh` + a ws_smoke-style script; password read from local OBS config per `docs/local-obs-e2e.md`) + user dogfood after. |

## Mechanism

- `NetworkHelper.makeRequest(...)` gains an awaitable path: a static
  `_pendingByUUID` map of completers, keyed by requestId (symmetric to the
  existing `_requestBodyByUUID`). The central response handler
  (`lib/stores/shared/network.dart` dispatch) completes them. Generous
  timeout (~10s) → treated as failure. Disconnect fails all pending with an
  aggregated notice.
- Typed failure: OBS `requestStatus` code + comment → exception/`Result`.
- `makeBatchRequest`: per-request statuses surfaced the same way
  (v5 batches carry per-request results).
- On failed mutation: issue the matching `Get*` re-read; existing response
  handlers apply the confirmed state (self-healing).
- Failure surfacing: an observable/stream on DashboardStore → dashboard toast
  widget. Dedup window + settings toggle per the ratified Failure UX row.

### Call-site adoption order (all mutations, this wave)

1. Scene program/preview switch (the defect-evidenced optimistic write).
2. Studio-mode transition — starts sending the real
   `TriggerStudioModeTransition` (harvested enum) — fixes defect #2's wrong
   request type as part of adoption.
3. Source visibility toggles, audio mute.
4. Volume/sync-offset sliders: acked commit on `onChangeEnd` only.
5. Stream/record start/stop/save-replay controls.
6. Polling reads (`GetStats` etc.) stay fire-and-forget.

## Non-goals

- No revision-counter projection (that's phase 3, port item 1 — this wave
  re-reads instead).
- No UI redesign; toast uses existing design-system idioms.
- No changes to connect/handshake path beyond the response dispatch hook.

## Verification

- New fake-peer tests in `test/websocket/` (ack success, rejection, timeout,
  disconnect-mid-flight, batch partial failure, slider-commit failure).
- Existing suites must stay green: `test/chat/ test/websocket/
  test/persistence/ test/pro/ test/statistics/ test/settings/` + analyze at
  the 472-issue baseline.
- Real-OBS smoke (agent-run): `tool/obs_local/obs_test_env.sh start` → script
  exercises acked mutations incl. a deterministic rejection → `stop`.
- User dogfoods the branch against their real OBS before merge into 4.0.

## Risks

- Every request in the app flows through this path — regressions are global.
  Mitigation: fake-peer suite + real-OBS smoke + dogfood gate; call-site
  adoption in the listed order with per-unit commits.
- Response-handler wiring must complete completers for ALL responses,
  including ones with error statuses and ones for requests that timed out
  (late acks are dropped, not misrouted).
