# Current objective

Choose and prototype a first-principles interaction architecture for OBS Blade,
then integrate one verified journey. Follow `README.md` for authority and scope.

# Current state

Branch `redesign-astra`, new worktree from master
`2307081594712f1da712ac23073d1ba3f3b82311`. Earlier redesign branches/artifacts
are excluded. Original checkout and unrelated IDE edits are preserved.

Archaeology and three architecture proposals are documented. Provisional
recommendation: A, session workspace. No architecture is selected, no prototype
exists, and production UI/business logic/persistence are unchanged.

# Last verified milestone

Branch provenance, source-backed product/behavior maps and documentation checks.
Baseline tests: 738 passed across chat/WebSocket/persistence/Pro. App/test analysis:
0 errors, 8 warnings, 372 infos; full analysis additionally fails in standalone
tool packages. Details and commands: `progress.md`. No new UI has been rendered.

# Next recommended action

Resolve the product choice in `design-direction.md`; record the answer in
`decisions.md` and this handoff, then build the selected isolated fake Flutter
journey. Continue automatically after the answer.

# Important context required for that action

First slice: connect → observe program/preview → change scene and sound → recover
from interruption → disconnect, on phone and tablet. Use representative chat
content to test attention balance, without integrating accounts/purchases yet.
Inspection, preview and program are distinct intents. Command dispatch has no
caller-visible acknowledgement today; do not claim an optimistic value is confirmed.
Home/Dashboard widgets own session lifecycle and wakelock; later extract a small
coordinator/adapter while retaining DashboardStore.

# Open questions requiring user input

Default emphasis: A broad OBS operation (recommended), B monitoring/chat with
occasional intervention, or C a small repertoire of configurable actions?
This determines primary architecture, not feature removal. No preference has
been inferred from code, prior redesign work or silence.

# Relevant files and symbols

`design-direction.md`, `user-flows.md`, `business-logic-map.md`,
`current-ui-assumptions.md`; `NetworkStore.setOBSWebSocket`, `DashboardStore`,
`NetworkHelper.makeRequest`, Home/Dashboard lifecycle. Planned prototype home:
`lib/redesign/` and an independent entrypoint; neither exists yet.

# Do not accidentally change

Production entrypoints, Hive contracts, entitlement/legacy ownership, v5 protocol,
free WebView access, chat drafts/buffers, confirmation preferences, tablet support
or unrelated work in the original checkout. No new dependency or generic design
system before a proven need. Do not restart from the historical redesign branch.

# Recommended next execution

Task class: Product/UX choice and first interaction prototype.
Recommended model: Astra.
Recommended reasoning: High for resolving architecture; Medium for the approved prototype.
Reason: The organizing model affects navigation and every downstream slice;
once chosen, implementation should follow the explicit scenario and boundaries.
