# Current objective

Complete the first session-workspace slice, keeping OBS and first-class chat
independent. The next integration areas are scoped OBS source/audio controls and
real chat capability/account/entitlement state.

# Current state

Branch `redesign-astra`, based directly on master
`2307081594712f1da712ac23073d1ba3f3b82311`. Original checkout/IDE edits are separate.
D-003–004 select adjustable OBS/chat focus and independent chat availability.
D-005 records the user's approved tap-to-inspect / explicit Preview-Send policy.
D-006 defines confirmed scene state and isolated connection-attempt ownership.

`lib/main_redesign.dart` is the fully simulated browser/native prototype.
`lib/main_redesign_obs.dart` is a native-only scene integration lab. It reuses
NetworkStore/NetworkHelper without production bootstrap, Hive, DI or accounts.
OBS scenes and scoped source visibility are real; chat/activity remain simulated.
Audio controls are still hidden pending actual input discovery. The new source
inspector needs native recapture alongside the coming audio controls. Production UI remains
unchanged; this is not a complete production workspace replacement.

# Last verified milestone

2026-09-11: iPhone and iPad native walkthroughs passed with production WebSocket
transport against a synthetic peer. They exercised inspection, explicit Preview
and Take, confirmed output, and retained draft/reply after OBS disconnect. Visual
inspection removed an accidentally retained fake microphone from the live browser.
Screenshots/limits: `live-obs-lab.md`. Both temporary simulators were removed.
Subsequent source milestone: 65 redesign/WebSocket tests pass, including seven
source targeting/event/hierarchy tests; targeted analysis clean.
Earlier scene gate: 784 tests passed (46 redesign); targeted analysis clean. Broad
analysis retains baseline 0 errors / 8 warnings / 372 infos. An inherited restore
test binding issue was fixed in a separate test-only commit. See `progress.md`.

# Next recommended action

Integrate actual audio input discovery, mute/volume and per-input outcomes, then
run the native source/audio composition checkpoint. Keep chat a first-class
parallel contract: readiness, Pro, account/scopes and channel state must remain
independent of OBS. Do not reopen A/B/C or the approved scene-row policy.

# Important context required for that action

Read `workspace-contract.md` and `live-obs-lab.md`. The correlated request client
never retries mutations or treats acknowledgements as observed state. Scene events
win over older snapshots; collection changes suspend reads/commands. Take uses
TriggerStudioModeTransition. Scene order follows master's descending sceneIndex.
Each connection attempt owns a separate NetworkStore; cancelled handshake
completion cannot touch a newer session. No automatic reconnect policy is added.

The live model inherits local fake chat/focus as a transitional lab binding, not
as a production chat adapter. Keep DashboardStore intact. Production lifecycle,
history, preference translation, wakelock and actual chat gates remain to integrate.
Grouped source targets use parentGroupName + item ID; displayed scene name alone
is insufficient. Audio must address actual input identity, never a fixed microphone.

# Open questions requiring user input

None currently. The user's latest substantive answer approved our recommendation.

# Relevant files and symbols

`lib/redesign/obs/`, `lib/redesign/workspace/`, `test/redesign/`;
`integration_test/workspace_scene_lab_test.dart`; `business-logic-map.md`;
NetworkStore, DashboardStore, TwitchChatStore, YouTubeChatStore, ProStore.

# Do not accidentally change

Production entrypoints, Hive contracts, entitlements/legacy ownership, free WebView
access, confirmation preferences or tablet support. Never connect services because
focus changes. Do not claim synthetic-peer tests establish installed OBS or chat API
behavior. Use synthetic data and temporary simulators for automated validation.

# Recommended next execution

Task class: Scoped source/audio integration and real-chat presentation contract.
Recommended model: Astra for unresolved boundaries; capable implementation model afterward.
Recommended reasoning: High for grouped targets/lifetime; Medium for approved implementation.
Reason: New scene command/ownership seams are established. Preserve source scope,
independent chat state and production policies during expansion. The implementation
sub-agent previously exhausted quota; avoid re-dispatch until capacity is available.
