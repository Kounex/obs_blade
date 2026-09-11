# OBS Blade — first-principles redesign

Current phase: session workspace selected, with first-class chat and user-controlled
focus. The isolated Flutter prototype has passed its first browser checkpoint;
scene-row interaction policy is approved (D-005). Work now moves into the
state/action contract and adapter. Production UI is unchanged.

## Baseline and authority

- Branch: `redesign-astra` (new, created 2026-09-10).
- Master base: `2307081594712f1da712ac23073d1ba3f3b82311`; matched
  `origin/master` at creation. Work in the dedicated worktree for this branch.
- Product evidence comes from master source and tests. Reuse domain behavior
  where sensible; screens, navigation, widgets and previous aesthetics are not
  requirements. No historical redesign branch is an input.
- Older files already in this directory, including `design-system.md`,
  `session-notes.md`, `audit-digest.md` and `2026-iteration*`, concern earlier
  efforts. They are historical, not design authority for this project.
- Authority: source/tests for implemented behavior → active decisions → design
  direction → session handoff → project progress. Chat is supplementary.

## Read in this order

1. This file; [session-handoff.md](session-handoff.md); [progress.md](progress.md);
   [decisions.md](decisions.md).
2. For the current task, read only the relevant documents:
   [product model](product-model.md), [intent journeys](user-flows.md),
   [behavior/source map](business-logic-map.md),
   [assumptions to challenge](current-ui-assumptions.md),
   [constraints](redesign-constraints.md), [design direction](design-direction.md).
3. Inspect relevant code; verify branch, diff and tests before relying on claims.

## Delivery approach

Explore distinct interaction architectures, choose a representative journey,
prototype with realistic fake state, inspect phone and tablet output, then define
a UI model/actions contract and adapt existing logic. Extract shared components
only after their product semantics prove useful.

Prototype: `lib/redesign/workspace/`, entrypoint `lib/main_redesign.dart`.
Run instructions, screenshots and validation: [workspace prototype](workspace-prototype.md). Production navigation will remain available during migration.
Product decisions with meaningful tradeoffs go to the user with a recommendation;
routine design/engineering work proceeds autonomously.
