# Project progress

## Completed

- Clean `redesign-astra` worktree from master; base recorded, original IDE edits
  preserved. Product archaeology and canonical project documentation established.
- Three interaction architectures evaluated; session workspace selected with
  adjustable OBS/chat emphasis and independent chat entry (D-003–004).
- Fake phone/tablet prototype visually checked; scene policy approved (D-005).
- Native OBS lab binds confirmed scenes/Preview/Take, grouped source visibility
  and input mute/volume. Native phone/tablet checks passed with a synthetic peer.
- Chat access/read-only/Pro states visually checked on native phone/tablet.
- Store send ownership fixed; YouTube replaced/removed video buffers retired.
- Chat composition/action adapter and typed timeline projection implemented.
  Draft/reply ownership, entitlement/readiness guards, channel serialization and
  native message metadata are tested. D-007 records the lifetime policy.

## Current workstream

Bind real chat UI and host actions into the session workspace. The new controller
accepts initialized stores and observes actual messages/access state. The visible
labs still use synthetic chat. Login/setup/purchases, free WebView hosting,
rich rendering, moderation and appearance/catalog dependencies need UI binding.

## Integration and validation

Production navigation/UI and persistence formats remain unchanged. Chat stores
have targeted ownership fixes; the OBS request helper has the previously verified
custom-envelope/Studio Mode transition seam. DashboardStore remains intact.

Final chat adapter gate (2026-09-12): **848 tests pass** across chat, WebSocket,
persistence, Pro and redesign (98 redesign).
Targeted analysis of redesign code/tests, both lab entrypoints and the native
walkthrough is clean. Broad analysis retains
0 errors / 8 warnings / 372 infos. An inherited Pro test timing failure was fixed
separately by waiting for the entitlement stream listener; purchase behavior is
unchanged.

Earlier visual evidence remains current: native phone/tablet source/audio and
chat gate/read-only walkthroughs, plus fake browser prototype captures. No UI
composition changed in the latest store/adapter units, so visual checks were not
repeated. Details: `chat-contract.md`, `live-obs-lab.md`, `workspace-prototype.md`.

## Remaining major areas

1. Bind specialized chat rendering, channel picker and composer; validate rich
   deterministic states on phone/tablet, then connect account/setup host actions.
2. Complete first slice: production session lifecycle/preferences/history,
   advanced source/audio controls and reconnect/accessibility regressions.
3. Stream/record and advanced production tools; discovery/QR and saved connections.
4. Chat accounts/capabilities, live health/history, settings/customization,
   entitlements/purchases and data management.
5. Extract proven shared tokens/components, translate preferences and complete
   Android/large-screen/device validation before staged production migration.

## Known debt and blockers

- No product question currently blocks implementation. The approved architecture
  and scene-row policy should not be reopened accidentally.
- Browser semantics interception remains a preview limitation; native checks pass.
- Installed OBS, real chat APIs, Android runtime and full accessibility validation
  remain outstanding. Synthetic fixtures do not establish those integrations.
- YouTube lacks stable persisted account identity; its new drafts reset across
  signed-in status changes. Preserving them through same-account reauthorization
  requires a verified identity seam, not a display-title comparison.
- Other inherited gaps remain in `current-ui-assumptions.md`; do not treat them
  as requirements. Root-wide analysis has unrelated standalone-tool package errors.
- Private-doc mirror verification timed out in the original checkout. No private
  data was changed or used to establish this direction.
