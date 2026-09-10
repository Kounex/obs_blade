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
prototype proposals; chat access before any OBS connection remains an explicit
open product question. This decision does not select new event integrations,
change entitlements or approve new persistence formats.
