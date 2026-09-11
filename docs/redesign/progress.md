# Project progress

## Completed

- New `redesign-astra` worktree created directly from current master; base and
  historical-work boundary recorded. Original checkout's IDE edits preserved.
- Source archaeology of connection/session/control, chat, history, persistence,
  settings and entitlements; widget-owned policies and integration risks mapped.
- Canonical project documents established; three materially different interaction
  architectures evaluated. User selected the session workspace with first-class,
  user-controlled chat focus (D-003).

## Current workstream

D-005 approves the inspected scene-row policy. D-006 defines confirmed scene state
and session ownership. An isolated native lab now binds scene inspection,
Preview/Take and direct Send to the existing WebSocket transport. Native iPhone
and iPad walkthroughs passed against a synthetic peer; real chat and OBS
source/audio controls remain unintegrated.

## Integration and validation

Production UI, stores and persistence remain unchanged. The request enum adds the
official Studio Mode transition request; custom request envelopes bypass the
legacy request-context cache. Existing request callers are unchanged. Prototype code
is in `lib/redesign/workspace/`, with independent `lib/main_redesign.dart`.
The native lab entrypoint is `lib/main_redesign_obs.dart`; confirmed scene/session
adapters live in `lib/redesign/obs/`. This is a partial integration, with simulated
chat and no stored focus preference. See `live-obs-lab.md` and `workspace-contract.md`.

Verified 2026-09-11 after the scene adapter:

- **784 tests passed**: chat, WebSocket, persistence, Pro and redesign (46 redesign).
- Simulated browser prototype rebuilt successfully after the shared UI changes.
- iPhone and iPad native walkthroughs passed against a synthetic WebSocket peer;
  screenshots inspected and the unsupported microphone fixture removed.
- Targeted analysis of both lab entrypoints, redesign code/tests and the native
  walkthrough: **no issues**. Broad `lib test` analysis remains at the baseline
  **0 errors, 8 warnings, 372 infos**.
- The first full run exposed an inherited test setup gap in explicit Pro restore:
  the delayed dialog read a GlobalKey before binding initialization. A separate
  test-only commit initializes the binding and waits for that callback; all 63 Pro
  tests and the final full gate pass. Production purchase behavior is unchanged.

Earlier fake-prototype checkpoint (same date): web build, clean targeted analysis, 764-test full gate,
26-test redesign recheck after accessibility refinements, and phone/tablet
browser inspection. Scenarios, screenshots and exact limitations are in
`workspace-prototype.md`. The fake prototype is not an integrated vertical slice.

Verified 2026-09-10 against unchanged master app/test sources, using Flutter
3.47.2 / Dart 3.13.2:

- `flutter test test/chat/ test/websocket/ test/persistence/ test/pro/`:
  **738 passed**.
- `flutter analyze`: nonzero, 1,264 baseline diagnostics. All 764 errors are
  under standalone `tool/` packages, including unresolved package imports and
  generated YouTube spike types in this fresh worktree.
- `flutter analyze --no-pub lib test`: **0 errors, 8 warnings, 372 infos**;
  nonzero exit. Existing unused declarations/imports and lints remain; this is
  not a clean analyzer gate. No unrelated cleanup was performed.
- Canonical documentation links and explicit source paths resolve; no private
  paths/addresses in the new documents; `git diff --check` passes.

## Remaining major areas

1. Expand scoped source/audio targets and the real-chat presentation contract.
2. Connect real chat with independent readiness, entitlement/account/scopes and
   channel state; preserve free WebView availability.
3. Complete first slice: production lifecycle/preferences, grouped-source/audio
   targeting, real chat entitlement/account gates and reconnect regressions.
4. Stream/record and advanced production tools; complete discovery/QR flows.
5. Chat/accounts/capabilities, live health/history, settings/customization,
   entitlement/purchases and data management.
6. Proven shared tokens/components, preference translation, accessibility,
   large-screen/device validation and staged production migration.

## Known debt and blockers

See `current-ui-assumptions.md` for inherited command acknowledgement, retry,
grouped-source, history and deletion gaps. They remain unfixed and must not be
mistaken for requirements. Scene-row behavior is approved; no product question currently blocks integration.
Native phone/tablet layout checks passed against a synthetic peer. Android,
installed OBS, real chat APIs and accessibility validation remain outstanding. Other phases are planned.
Private-doc mirror verification timed out on the original checkout; no private data was changed or
used to establish this design direction.
