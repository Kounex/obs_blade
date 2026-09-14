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
- Native rich chat pane binds typed Twitch/YouTube rows, channel selection, replies,
  drafts and sends. Phone/tablet walkthroughs passed with synthetic stores; native
  long-press/following and Super Chat amount contrast defects are corrected.

## Current workstream

Complete advanced chat interactions and host actions. The native pane now binds
real presentation/controller code to synthetic stores. Account/setup/purchases,
free WebView hosting, moderation/user cards, pin actions, emote picking and
appearance editing remain unbound. Catalog rendering accepts explicit stores;
fixture captures do not establish downloaded badge/emote artwork.

## Integration and validation

Production navigation and persistence formats remain unchanged. Shared chat rows
have dependency injection seams plus hold-wash and amount-readability fixes. Chat stores
have targeted ownership fixes; the OBS request helper has the previously verified
custom-envelope/Studio Mode transition seam. DashboardStore remains intact.

Final native-pane gate (2026-09-14): **859 tests pass** across chat, WebSocket,
persistence, Pro and redesign (108 redesign). Targeted redesign/lab analysis is
clean; broad analysis retains **0 errors / 8 warnings / 372 infos**.

Native rich chat inspection passed on phone/tablet with continuous rendering and
explicit tail/highlight assertions. Ten pane tests cover drafts, channel changes,
reply/resize lifetime, scrolling, Pro/write access, keyboard/large text, amount
contrast and message identity during buffer trimming. A shared-row regression
covers hold termination. The last identity-only change passed the final full gate;
it changes gesture ownership, not the captured composition. Temporary simulators
were removed. See `chat-contract.md` for captures and evidence boundaries.

## Remaining major areas

1. Preserve remaining specialized chat interactions (emote picker, appearance,
   user cards/moderation, pin actions), then connect account/setup host actions.
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
