# Current objective

Carry the selected session workspace with first-class chat from a verified fake
prototype into a clean UI contract and production adapter.

# Current state

Branch `redesign-astra`, separate worktree from master
`2307081594712f1da712ac23073d1ba3f3b82311`. Historical redesign work is excluded;
original checkout and its unrelated IDE edits remain separate.

D-003 selects the workspace with adjustable chat focus; D-004 permits chat before
OBS connection. The Flutter prototype runs from `lib/main_redesign.dart` using
in-memory state only. Production UI, accounts and persistence are untouched.

# Last verified milestone

2026-09-11: release web build; clean targeted analysis; 764-test full gate;
26-test redesign recheck after accessibility refinements. Browser-inspected
phone OBS/chat, tablet emphasis/together, reconnect and simulated password repair.
Saved screenshots and limitations: `workspace-prototype.md`. Native platform
behavior and real OBS/chat integration remain unverified.

# Next recommended action

D-005 records the approved tap-to-inspect / explicit command policy. Continue into
the explicit presentation contract and adapter. Do not reopen A/B/C architecture.
Prototype run steps are in `workspace-prototype.md`; local preview uses port 49160.
Check whether the server is still running before presenting its URL.

# Important context required for that action

Prototype uses tap-to-inspect plus labelled Preview/Send controls and a persistent
Take dock. Phone opens focused details; a wide OBS pane shows scenes and details
alongside chat. Focus and resize preserve draft/reply/scroll controller; together
layout returns to the last explicit phone focus. OBS/chat readiness is independent.

The fixture serializes OBS commands; production needs scoped pending state.
NetworkHelper currently exposes no acknowledgement future, and optimistic scene
values are not confirmed OBS output. Home/Dashboard widgets own session lifecycle
and wakelock. Keep DashboardStore; define a small coordinator/adapter seam.
Existing Take sends SetCurrentProgramScene: verify actual studio-transition
semantics before integration. Source groups/IDs, accounts, entitlement, manual
entry, QR/discovery and real event feeds are not covered by the tiny fake fixture.

# Open questions requiring user input

None currently. The user approved the recommended scene-row policy on 2026-09-11.

# Relevant files and symbols

`design-direction.md`, `workspace-prototype.md`, `business-logic-map.md`;
`lib/redesign/workspace/{workspace_model,workspace_app,obs_panel,chat_panel}.dart`;
`test/redesign/`; `NetworkStore`, `DashboardStore`, `TwitchChatStore`,
`YouTubeChatStore`, `StreamChat`.

# Do not accidentally change

Production entrypoints, Hive contracts, entitlements/legacy ownership, free
WebView access, chat buffers/drafts, confirmation preferences or tablet support.
Do not assume simulated sends/events/Take are production functionality. Do not
reconnect services merely because emphasis changes. Use synthetic data only.

# Recommended next execution

Task class: Consequential adapter architecture and approved implementation.
Recommended model: Astra.
Recommended reasoning: High for contract/lifecycle; Medium for approved implementation.
Reason: Confirmed-versus-optimistic state and widget-owned session lifetime are
real integration gaps. The implementation sub-agent hit its usage limit during
refinement; avoid re-dispatching until capacity is available and keep process small.
