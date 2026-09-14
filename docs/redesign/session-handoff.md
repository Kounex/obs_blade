# Current objective

Complete the first session-workspace slice with independent OBS and first-class
chat. The native rich pane is bound; preserve advanced chat interactions and then
connect account/setup host actions.

# Current state

Branch `redesign-astra`, master base
`2307081594712f1da712ac23073d1ba3f3b82311`. Original checkout/IDE edits are separate.
D-003–004: adjustable OBS/chat focus and independent chat availability.
D-005–006: inspect separately from confirmed scene commands; isolated OBS attempts.
D-007: conversation-owned composition and typed native chat data.

`main_redesign.dart` is simulated. `main_redesign_obs.dart` binds OBS scenes,
grouped source visibility and input mute/volume; its chat remains simulated.
`main_redesign_chat.dart` binds `ChatComposerController`, `WorkspaceChatPane` and
`WorkspaceChatTimeline` to synthetic chat stores and a temporary settings box.
It renders specialized Twitch/YouTube rows and supports channel drafts, actual
reply IDs, guarded sends, pause/return-live and readiness/Pro gates. No saved
account, purchase, production setting or chat API is initialized by this lab.
Production navigation and Hive formats remain unchanged. Shared rows now accept
explicit catalog stores and have small hold-wash/amount-readability fixes.

# Last verified milestone

Native phone/tablet rich-chat walkthroughs passed; captures in `chat-contract.md`.
The native loop found and fixed long-press scroll ownership and hold-wash defects.
YouTube amount contrast improved from 2.66:1 to 13.58:1 in the workspace theme.
Ten pane tests pass, including draft/focus/resize ownership, Pro/write gates,
keyboard/large text and buffer trimming during a hold. A recycled list position
must not retarget an action; rows now carry conversation/message identity.
Final gate (2026-09-14): **859 tests pass** (108 redesign). Targeted analysis is
clean; broad analysis retains 0 errors / 8 warnings / 372 infos. Temporary
simulators were removed. The final identity-only change passed the full gate;
no visual composition changed after the native captures.

# Next recommended action

Bind emote picking and appearance controls before account/setup hosting. Read the existing `chat_emote_picker.dart` and native options surface for
behavior; inject settings/catalog dependencies instead of global lookups. Keep
picker edits owned by their original conversation: a sheet opened before a
channel/account change must not overwrite the new draft. Preserve capability
renewal, third-party visibility, draft cancellation and compose continuation.
After that, bind user cards/moderation and pin actions through explicit host
intents, then account/setup and free WebView hosting. Do not flatten typed messages
into fake `WorkspaceMessage` data or turn the fake OBS model into production state.

# Important context required for that action

Store send races and YouTube video-buffer invalidation are fixed. Twitch drafts
survive same-user permission renewal; logout creates a new in-memory identity
for scroll/reveal ownership. YouTube has no stable persisted account ID, so drafts
reset conservatively across signed-in status changes. No credentials or display
names may substitute for identity. Focus/OBS changes never own chat services.
Notice rails/mention-color continuation, pin actions, emote picker, appearance
editing, user cards and moderation are not yet fully bound. Catalog dependencies
exist, but fixture screenshots do not establish downloaded artwork behavior.

# Open questions requiring user input

None currently. Continue within the approved workspace and scene-row architecture.

# Relevant files and symbols

`lib/redesign/chat/`, `lib/redesign/workspace/`, `lib/redesign/obs/`;
`test/redesign/workspace_chat_pane_test.dart`; `integration_test/workspace_chat_lab_test.dart`;
`lib/views/dashboard/widgets/obs_widgets/stream_chat/`;
`chat-contract.md`, `business-logic-map.md`, `progress.md`.

# Do not accidentally change

Production entrypoints/navigation, Hive contracts, entitlements, free WebView,
confirmation preferences or tablet support. Keep DashboardStore intact. Synthetic
fixtures do not establish installed OBS, real chat API or Android runtime behavior.
Browser-preview semantics interception and full accessibility validation remain open.

# Recommended next execution

Task class: Preserve specialized chat interactions in the approved native pane.
Recommended model: Capable implementation model; Astra for unresolved ownership boundaries.
Recommended reasoning: Medium; High only for consequential lifecycle uncertainty.
Reason: Presentation and typed state/action seams are now proven. Next work adapts
existing emote/options behavior with conversation ownership and explicit dependencies.
A prior implementation sub-agent exhausted quota; avoid re-dispatch without capacity.
