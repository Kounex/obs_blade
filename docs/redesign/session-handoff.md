# Current objective

Complete the first session-workspace slice with independent OBS and first-class
chat. OBS scene/source/audio controls run in the native lab. Real chat access,
composition/actions and typed timeline seams exist; bind them into the workspace.

# Current state

Branch `redesign-astra`, master base
`2307081594712f1da712ac23073d1ba3f3b82311`. Original checkout/IDE edits are separate.
D-003–004: adjustable OBS/chat focus and independent chat availability.
D-005: tap to inspect, explicit Preview/Send, persistent Take.
D-006: confirmed OBS state and isolated connection attempts.
D-007: conversation-owned composition and typed native chat payloads.

`main_redesign.dart` is simulated. `main_redesign_obs.dart` binds actual OBS
scenes, grouped source visibility and input mute/volume without production
bootstrap, Hive or accounts. Chat in both UIs remains simulated.
`ChatComposerController` injects Pro/Twitch/YouTube stores, observes access and rich
timeline data, owns drafts/replies, and guards channel/send actions. It does not
initialize or dispose those stores. UI/account/setup/WebView binding is unfinished.
Production navigation/UI and persistence formats are unchanged.

# Last verified milestone

Chat adapter: **848 full-gate tests pass** (98 redesign), including 18 new contract
cases for ownership, gate changes, payloads, notices/tombstones and authorization.
Targeted redesign/lab analysis is clean; see `progress.md`.
Earlier native phone/tablet Pro/read-only and OBS scene/source/audio walkthroughs
passed with synthetic peers; captures inspected, temporary simulators removed.
Browser semantics interception remains a preview limitation (`chat-contract.md`).

# Next recommended action

Bind a real native chat pane using `ChatComposerController` and `ChatTimeline`.
Pass typed entries into specialized message rendering; do not convert them into
`WorkspaceMessage` strings or reuse the fake model as production state. Preserve
emotes, badge/appearance settings, reply IDs, notices, pins, tombstones and
per-action moderation capabilities. Inject dependencies where existing renderers
currently use GetIt. Wire channel picker and composer to the tested controller;
keep account/setup/purchase/WebView intents explicit until host actions exist.
Then validate phone/tablet composition with deterministic rich store fixtures,
before enabling account initialization or connecting real APIs in a lab host.

# Important context required for that action

Read `chat-contract.md`, `workspace-contract.md`, `live-obs-lab.md` and the behavior
map. Store send races and YouTube label/video buffer invalidation are fixed.
Twitch `isSwitchingChannel` prevents showing old rows under a new channel header.
Workspace actions recheck Pro/readiness; no automatic message retries.
Twitch permission renewal retains same-user drafts. YouTube has no stable account
ID in its persisted model, so drafts conservatively reset across signed-in status
changes. No credentials or display names may substitute for account identity.
Focus/OBS disconnect must not initialize, dispose or reset chat services.

# Open questions requiring user input

None currently. The approved workspace and scene-row architecture remain active.

# Relevant files and symbols

`lib/redesign/chat/`, `lib/redesign/workspace/`, `lib/redesign/obs/`;
`test/redesign/chat_composer_controller_test.dart`, `chat_timeline_test.dart`;
`lib/views/dashboard/widgets/obs_widgets/stream_chat/` native renderers and input;
`integration_test/workspace_scene_lab_test.dart`; `business-logic-map.md`.

# Do not accidentally change

Production entrypoints/navigation, Hive contracts, entitlements, free WebView,
confirmation preferences or tablet support. Keep DashboardStore intact. Do not
claim synthetic peer/store tests establish installed OBS or real chat API behavior.
Use synthetic data and temporary simulators for automated validation.

# Recommended next execution

Task class: Bind approved native chat presentation to the workspace.
Recommended model: Capable implementation model; Astra for unresolved identity/lifecycle boundaries.
Recommended reasoning: Medium; High only if a consequential ownership boundary remains unresolved.
Reason: Access, send/channel ownership and typed data seams are tested. Remaining
work is UI binding and preservation of specialized renderer dependencies. A prior
implementation sub-agent exhausted quota; avoid re-dispatch without available capacity.
