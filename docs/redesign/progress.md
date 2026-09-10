# Project progress

## Completed

- New `redesign-astra` worktree created directly from current master; base and
  historical-work boundary recorded. Original checkout's IDE edits preserved.
- Source archaeology of connection/session/control, chat, history, persistence,
  settings and entitlements; widget-owned policies and integration risks mapped.
- Canonical project documents established; three materially different interaction
  architectures evaluated with a provisional recommendation.

## Current workstream

Select the default operating emphasis: session workspace, activity focus or
personal control surface. The choice is described in `design-direction.md`.
First slice: connect, understand program/preview, change scene/sound, recover, exit.

## Integration and validation

Production UI, stores, protocol and persistence remain unchanged. There is no
new runnable prototype or adapter yet. Source review is complete for initial
prioritization, not an exhaustive audit of every existing capability.

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

No simulator/real OBS/browser visual validation has been performed for the new
direction; a new interface does not yet exist to validate.

## Remaining major areas

1. Chosen architecture: fake phone/tablet prototype, visual critique and refinement.
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
mistaken for requirements. Primary architecture awaits a product choice; other
phases are planned, not blocked by a technical failure. Private-doc mirror
verification timed out on the original checkout; no private data was changed or
used to establish this design direction.
