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

First isolated workspace prototype is runnable and visually inspected. Resolve
scene-row tap policy before making it the production interaction contract; then
define UI state/actions and session ownership for integration.

## Integration and validation

Production UI, stores, protocol and persistence remain unchanged. Prototype code
is in `lib/redesign/workspace/`, with independent `lib/main_redesign.dart`.
There is no production adapter or stored focus preference yet.

Verified 2026-09-11: web build, clean targeted analysis, 764-test full gate,
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

1. Resolve scene-row action policy and refine the prototype from product feedback.
2. Explicit UI state/actions, session ownership, command result strategy and adapter.
3. Integrated first slice with handshake/reconnect/targeting regressions.
4. Stream/record and advanced production tools; complete discovery/QR flows.
5. Chat/accounts/capabilities, live health/history, settings/customization,
   entitlement/purchases and data management.
6. Proven shared tokens/components, preference translation, accessibility,
   large-screen/device validation and staged production migration.

## Known debt and blockers

See `current-ui-assumptions.md` for inherited command acknowledgement, retry,
grouped-source, history and deletion gaps. They remain unfixed and must not be
mistaken for requirements. Scene-row behavior awaits user input before integration.
Native device/accessibility validation remains outstanding. Other phases are planned.
Private-doc mirror verification timed out on the original checkout; no private data was changed or
used to establish this design direction.
