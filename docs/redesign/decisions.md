# Redesign decisions

## D-001 Clean master baseline and historical-work boundary

Status: active

Decision: Start `redesign-astra` from master
`2307081594712f1da712ac23073d1ba3f3b82311`, in a separate worktree. Do not
inspect, merge, cherry-pick or borrow from earlier redesign branches. Historical
design documents inherited from master do not bind this new direction.

Reason: Explicit user instruction, 2026-09-10. The original checkout contains
unrelated IDE changes and must remain intact.

Alternatives considered: Continue the earlier redesign; switch the dirty
checkout. Both rejected in favor of clean provenance and preserving user work.

Consequences: Master is the behavioral baseline even where it already contains
older UI work. Record changes to valuable behavior explicitly; do not attempt to
reconstruct a pre-master application. Future agents must verify the branch first.

## D-002 Isolated journeys before migration

Status: active

Decision: Archaeology does not modify production UI. Prototype one end-to-end
journey in an isolated development entrypoint with fake state, validate it
visually on phone and tablet, then define presentation state/actions and an
adapter to existing domain logic. Preserve production entrypoints until each
replacement has passed behavioral checks.

Reason: The user authorized substantial UX change while requiring valuable
behavior to survive and business logic to be reused sensibly.

Alternatives considered: Restyle existing widgets in place; replace all screens
at once; introduce a generic component library first. These would constrain
exploration or propagate unverified decisions.

Consequences: No new UI library or global theme replacement at project start.
Use existing MobX/GetIt/domain code behind adapters when integration begins.
Persistence, purchase identifiers and protocol formats remain stable unless a
separate reviewed migration makes change necessary.

## D-003 Session workspace with first-class chat

Status: active

Decision: Select the session workspace architecture. Chat is a first-class use
case whose prominence users can control, rather than a permanently secondary
dashboard section. Preserve access to comprehensive OBS operation in either
focus. Audience activity is a future design input alongside conversation.

Reason: User accepted the session workspace on 2026-09-10, explicitly qualifying
that specialized native chat and its future expansion must receive first-class
attention when wanted by the user. Code already gives chat independent transport
state, but currently locates its presentation inside the OBS dashboard.

Alternatives considered: A permanently scene-dominant workspace; replacing the
workspace with task stages; making users configure a personal action surface.
The chosen architecture keeps stable session context and allows attention to
change without requiring a different product structure.

Consequences: The first prototype must exercise a real chat interaction loop
with fake state, not merely show sample messages beside OBS controls. Preserve
conversation/draft/scroll state across focus changes. Exact focus controls are
prototype proposals; independent chat entry is subsequently resolved by D-004. This decision does not select new event integrations,
change entitlements or approve new persistence formats.

## D-004 Independent chat availability within the workspace

Status: active

Decision: Proceed with the recommended chat-only entry path. The workspace can
host chat before OBS is connected and retain it through OBS interruption or
explicit disconnect. OBS and chat have separate readiness and lifetimes.

Reason: After the recommendation and its entry-path tradeoff were presented,
the user directed the agent to continue. This is the lead agent's recommended
implementation choice under that direction, not an inferred change to account
or entitlement requirements. Chat stores already own independent transport.

Alternatives considered: Require an OBS connection to open chat; maintain a
separate chat application. The former unnecessarily couples availability; the
latter duplicates context/navigation for the same audience interaction.

Consequences: The fake prototype includes chat-only entry and OBS reconnection
while chat remains usable. Preserve existing platform/account/entitlement gates
when integrating. Background execution guarantees, new event subscriptions and
multiple simultaneous OBS sessions are not introduced by this decision.

## D-005 Separate scene inspection from output commands

Status: active

Decision: Retain tap-to-inspect on scene rows, with labelled Preview / Send live
actions and the persistent Take control. On narrow panes inspection opens focused
details; wide panes can show the scene browser and inspector together.

Reason: The user accepted the recommendation ("your recommendation!", 2026-09-11)
after reviewing the prototype choice. Inspecting sources should not also change
the audience's output. Labelled actions keep the execution intent visible.

Alternatives considered: Master's whole-row execution with a separate inspection
action. It provides a larger execution target, but couples browsing to commands.

Consequences: This deliberately changes master's scene-row tap policy. Preserve
large accessible command targets; inspection remains local state. Program and
preview badges must represent OBS-confirmed values, never the inspected row or
an optimistic command target. Proceed into the state/action contract and adapter.

## D-006 Confirmed scene projection and isolated session ownership

Status: active

Decision: Give the isolated live lab a session owner with one NetworkStore per
connection attempt and a bounded scene projection. Correlate replies by request
ID/type, keep confirmed values separate from commands, and use OBS's dedicated
Studio Mode transition request for Take. Scope serialization to scene-output
operations; later audio/source operations need independent resource scopes.

Reason: Source archaeology found widget-owned session lifetime, optimistic scene
writes and a send-only request helper. Pane/focus changes must not inherit those
lifetimes. Official v5 documentation identifies the dedicated transition request
as the equivalent of OBS's Studio Mode Transition button. These are engineering
choices implementing D-003–005, not additional user approvals.

Alternatives considered: Reuse optimistic DashboardStore scene values as truth;
replace/split DashboardStore; rewrite WebSocket transport. The bounded projection
reuses NetworkStore, NetworkHelper and existing protocol types while preserving
the production monolith and its history/control behavior for later integration.

Consequences: The native development entrypoint can exercise real scene commands
without production bootstrap, Hive or accounts. Chat remains explicitly simulated
there. A cancelled handshake cannot own a later session. Reconnect/command failure
must not automatically repeat output mutations. Production routing, preference
translation, full DashboardStore lifecycle and real chat integration are still
required before replacing the shipping workspace. See `workspace-contract.md`.
