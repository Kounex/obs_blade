# Current objective

Prototype the selected session workspace with first-class, user-controlled chat
focus, then integrate a verified journey. Read `README.md` for authority/scope.

# Current state

Branch `redesign-astra`, separate worktree from master
`2307081594712f1da712ac23073d1ba3f3b82311`. Historical redesign work is excluded;
the original checkout and unrelated IDE edits are preserved.

D-003 records the user's acceptance of the workspace with first-class chat.
Proposed phone OBS/Chat focus and tablet concurrent panes are in
`design-direction.md`. No runnable prototype or production changes exist.

# Last verified milestone

Source-backed archaeology and 738 passing baseline tests. App/test analysis had
0 errors, 8 warnings, 372 infos; full analysis also fails in standalone tool
packages (`progress.md`). Decision update is docs-only; code gates were not rerun.
No new UI has been rendered. Chat stores independently own transport; their
current dashboard presentation still depends on DashboardStore.

# Next recommended action

Resolve chat-only entry before fixing launch navigation. Record the answer and
continue automatically into the isolated fake Flutter workspace, with phone and
tablet validation. Do not reopen the choice between architectures A/B/C.

# Important context required for that action

Both loops belong in the first prototype: connect/scene/audio/recover/exit and
chat/read/reply/intervene/return. Preserve channel, draft, scroll anchor and
inspected scene when emphasis changes. OBS and chat readiness are separate.
Future audience activity needs a reviewable presentation; exact event sources,
alert policy and retention are not yet specified. Existing Twitch notices are
available as source evidence; do not imply every proposed event already exists.

Inspection, preview and program differ. Commands currently lack caller-visible
acknowledgements; optimistic state is not confirmed OBS state. Later migrate
Home/Dashboard lifecycle and wakelock through a small adapter/coordinator while
retaining DashboardStore. Planned code home: `lib/redesign/` plus independent
entrypoint, neither created yet.

# Open questions requiring user input

Can users open/use chat before connecting OBS? Recommend yes: source already
supports independent chat transport and this avoids tying audience interaction
to OBS setup/availability. No answer yet; do not infer approval from silence.

# Relevant files and symbols

`decisions.md` D-003, `design-direction.md`, `user-flows.md`,
`business-logic-map.md`; `TwitchChatStore.init` / `chatNotifications`,
`YouTubeChatStore.init`, `StreamChat.build`, `NetworkStore`, `DashboardStore`.

# Do not accidentally change

Production entrypoints, Hive contracts, entitlements/legacy ownership, free
WebView access, chat buffers/drafts, confirmation preferences or tablet support.
Do not lock chat permanently into a secondary panel. Focus changes must not
restart transports or become inferred broadcast stages. Keep appearance,
new dependencies and persistence translation provisional until validated.

# Recommended next execution

Task class: Resolve workspace entry semantics, then implement interaction prototype.
Recommended model: Astra for product judgment; capable implementation model afterward.
Recommended reasoning: High for entry/lifecycle boundary; Medium for approved prototype.
Reason: Independent chat entry affects the shell and session ownership; focus
interactions can then be implemented against explicit fake state and scenarios.
