# Current objective

Complete the first session-workspace slice, keeping OBS and first-class chat
independent. OBS scene/source/audio controls and synthetic chat access states are implemented
in the lab. Next is real chat channel/send ownership and rich-message binding.

# Current state

Branch `redesign-astra`, based directly on master
`2307081594712f1da712ac23073d1ba3f3b82311`. Original checkout/IDE edits are separate.
D-003–004 select adjustable OBS/chat focus and independent chat availability.
D-005 records the user's approved tap-to-inspect / explicit Preview-Send policy.
D-006 defines confirmed scene state and isolated connection-attempt ownership.

`lib/main_redesign.dart` is the fully simulated browser/native prototype.
`lib/main_redesign_obs.dart` is a native-only scene integration lab. It reuses
NetworkStore/NetworkHelper without production bootstrap, Hive, DI or accounts.
OBS scenes, scoped source visibility and actual input mute/volume are real;
chat/activity remain simulated. Both source/audio native checkpoints pass.
`ChatAccess` and `projectChatAccess` map actual store access facts without service
initialization. The lab uses synthetic snapshots for its gate/read-only states;
account/setup/purchase/WebView navigation is not wired.
Production UI remains unchanged; this is not a complete workspace replacement.

# Last verified milestone

**818 tests passed** after chat access work (80 redesign); targeted analysis and
web build pass. Native phone/tablet Pro and read-only states were inspected on
2026-09-12, retaining reply/draft; temporary simulators removed. Browser semantics
interception is a preview limitation, documented in `chat-contract.md`.
The earlier source/audio native checkpoint remains:
2026-09-11: **801 tests passed** (chat, WebSocket, persistence, Pro and redesign;
63 redesign tests). Targeted analysis clean. Native iPhone/iPad walkthroughs pass
against a synthetic peer using production WebSocket transport. They exercise
inspection, Preview/Take, grouped visibility, input mute/volume, quick audio from
chat and draft/reply retention after disconnect. Screenshots inspected; pinned
phone Back to scenes and removed duplicate tablet Disconnect. Both temporary
simulators removed. See `live-obs-lab.md`. Broad analysis retains baseline
0 errors / 8 warnings / 372 infos from the previous scene checkpoint.

# Next recommended action

Fix the channel/send ownership regressions, then bind real chat actions and rich
messages. The access projection and native visual checkpoint are complete.
New regression probes are in the existing Twitch/YouTube store test files; the
source fix is the next unit, separate from the chat access UI checkpoint.
Readiness, Pro, account/scopes and channel state must remain independent of OBS.
Audit pending sends versus channel switches before binding user actions; existing
Twitch send resolves its destination after awaiting token refresh, and YouTube
appends its completed send to the active message list. Prevent cross-channel
command/result ownership in the adapter. Do not reopen the approved architecture
or scene-row policy.

# Important context required for that action

Read `chat-contract.md`, `workspace-contract.md` and `live-obs-lab.md`. The correlated request client
never retries mutations or treats acknowledgements as observed state. Scene events
win over older snapshots; collection changes suspend reads/commands. Take uses
TriggerStudioModeTransition. Scene order follows master's descending sceneIndex.
Each connection attempt owns a separate NetworkStore; cancelled handshake
completion cannot touch a newer session. No automatic reconnect policy is added.

The live model inherits local fake chat/focus as a transitional lab binding, not
as a production chat adapter. Keep DashboardStore intact. Production lifecycle,
history, preference translation, wakelock and actual chat gates remain to integrate.
Grouped source targets use parentGroupName + item ID; displayed scene name alone
is insufficient. Audio uses actual input names; read failures disable controls. The UI shows
reported gain above unity without mutating it and sends volume only on release.

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

Task class: Real-chat presentation contract and safe store adapter.
Recommended model: Astra for unresolved boundaries; capable implementation model afterward.
Recommended reasoning: High for channel/send lifetime; Medium for approved implementation.
Reason: New scene command/ownership seams are established. Preserve source scope,
independent chat state and production policies during expansion. The implementation
sub-agent previously exhausted quota; avoid re-dispatch until capacity is available.
