# Plan-Defect Checklist + Pre-Dispatch Verification Pass

Process hardening for SDD (subagent-driven-development) waves, distilled
from the ratified defect log in `.superpowers/sdd/progress.md`. Evidence
base: 9 plan amendments + 2 review-caught fixes across 17 tasks (three
waves, 2026-08-04 → 2026-08-07). Two findings drove this doc:

- **~2/3 of all amendments share one root cause:** plan-authored test code
  written against unverified assumptions about existing code (fixtures,
  helper behavior, span shapes, Dart/codegen semantics).
- **The rest** are codegen artifact omissions, doc-claim drift, and one
  vacuous-assert test — all preventable with explicit checks.

Nothing defective reached `master` in any wave; the per-task review net
held. This doc exists to cut the amendment round-trips (~1/task), not to
fix a quality escape.

## 1. Pre-dispatch plan-verification pass (do this every wave)

After the plan is approved (and after any later amendment), **before the
Task 1 brief is dispatched**, run ONE read-only verifier subagent with a
falsification brief. Cost: one ~10-minute dispatch. Yield so far: would
have caught ~4 of 4 amendment-class defects in the deleted-content wave.

Verifier checklist (paste into the dispatch prompt, plan path filled in):

1. **Every claim about existing code:** for each fixture, helper,
   producer, symbol, or line ref the plan's code touches, open the file
   and verify the plan's assumed shape is the real shape (field names,
   split/tokenize behavior, visibility, statics, types).
2. **Every new or modified test:** can each assert actually fail? Does
   the harness make it testable (attached nodes, real state transitions)?
   Flag any assert that passes vacuously under the plan's own setup.
3. **Codegen:** does the task touch `@freezed` / MobX-annotated classes?
   If yes, the plan must contain the full artifact list (see §3) — one
   `build_runner` run AFTER all annotated edits, `.g.dart` in the commit
   file list.
4. **Doc claims:** any test count, line count, pixel value, or behavior
   statement the plan puts into changelog/handoff/AGENTS.md — spot-check
   against the code it will describe.
5. **Commit lists:** every file the task will create or modify (incl.
   generated files) appears in the task's commit step.

Output: ratified findings → amend the plan (one `docs(plan)` commit per
finding cluster), re-extract affected task briefs, THEN dispatch Task 1.

## 2. Defect-class checklist (the hall of fame)

Append every newly ratified defect class here at wave wrap-up. Plan
authors and reviewers: treat these as named probes, not vibes.

**Plan code vs. existing code (the dominant class — verify, don't recall):**

- Fixture/payload shapes: existing test fixtures must gain new required
  DTO fields (deleted-content Task 1: `message_delete` frame lacked
  `user_name`, 809bffe).
- Producer behavior: tokenizers/splitters eat delimiters — assert against
  the real output shape (deleted-content Task 2: `_textSpans` splits on
  spaces, so a `'Hello '` span never exists; lookup `'Hello'`, f6e6fe3).
- Dart semantics: `static` members don't cross mixin/class aliases —
  reference the literal or the owning declaration (lifecycle Task 2:
  `kMaxMessages`, bd7a09c).
- Codegen'd types: freezed hides `runtimeType` (private impl classes) —
  use `isA<T>()` in tests, never `runtimeType` (lifecycle Task 2).
- Completeness: plan code that introduces a type reference must list the
  import (lifecycle Task 6: window itemBuilder cast, c4a7644).

**Test design (vacuity — invisible to compiles and RED-checks):**

- **Mutation tests: positive-before, negative-after.** Assert the state
  is present immediately BEFORE the mutation, then absent after
  (deleted-content Task 1 review: wipe assert ran after a `/clear` that
  had already emptied the state → vacuous, fixed e8183f3).
- **Harness realism:** framework state must exist for the assert to mean
  anything — a bare `FocusNode` never attached to a widget can never
  have focus (emote-picker Task 5, a31d5f6).
- **Fixture logic:** fixtures must satisfy the production invariants the
  test relies on (emote-picker Task 2: newer-fetch emote not owned by
  its userId, 14d2671).

**Codegen artifacts (see §3):** MobX action retypes and freezed edits
need a regen AFTER all annotated source edits, and the `.g.dart` belongs
in the commit (deleted-content Task 1, 809bffe).

**Doc claims:** numbers and behavior statements in changelog/handoff/
specs drift from the code — spot-check before committing (emote-picker
Task 7: changelog said 44pt cells, shipped is 56pt, caught pre-dispatch
1728d7a; lifecycle spec's "deduped by messageId" fact error, swept in
1b9eca4).

## 3. Codegen artifact checklist (auto-include when annotations touched)

If a task modifies any file containing `@freezed`, `@observable`,
`@action`, or a `part '*.g.dart'` directive it semantically changes:

1. Make ALL annotated source edits first.
2. Run `FLUTTER_ROOT="$HOME/.dotfiles/flutter/sdk" bash flutterw pub run
   build_runner build --delete-conflicting-outputs` ONCE, after the last
   annotated edit.
3. Stage every regenerated `.g.dart` in the task's commit (the commit
   file list in the plan must name it).
4. Then run the gates (tests + analyze) — not before.

## 4. Wiring

- **Plan-author prompts** (writing-plans / brainstorm→plan handoff):
  paste §2 + §3 as "named constraints — verify each against the repo
  before writing code that depends on it".
- **Verifier dispatch** (§1): paste the 5-item checklist.
- **Reviewer prompts** (per-task + final): paste §2 as named probes; add
  "for every empty/null/absent assert after a mutation, confirm the
  positive state was asserted or structurally guaranteed just before".
- **Wave wrap-up:** append any newly ratified defect class to §2, one
  line each, with the commit ref. If a class stops recurring (caught
  reliably pre-dispatch for two waves), mark it dormant rather than
  deleting it.
