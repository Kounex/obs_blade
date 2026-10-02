---
name: obs-feature
description: Use when building or extending an OBS Blade feature that talks to OBS (obs-websocket requests / events, plugin vendor requests) or changes the dashboard - e.g. "add support for X plugin", "show Y from OBS", "control Z on the canvas", "new dashboard control". Runs research -> source-verified facts -> build -> journey sweep -> visual check -> independent review before the first report, so the feature lands complete instead of over several "test it again" rounds.
---

# OBS-facing feature, done in one pass

Why this exists: canvas v2 (2026-10-02) needed ~5 follow-up rounds, each
finding real bugs that were discoverable from the start - name lookups
that are canvas-scoped, events that don't exist, interactions with studio
mode / screenshots / hidden scenes, and the biggest real-world use case
(Twitch Dual Format). Tests were green throughout because the fake OBS
encoded the same wrong assumptions as the code. Don't report before
phase 6.

**Process size:** at least tier M (`sizing-the-process`) - anything
touching protocol + UI (+ persistence) is not a tier-S change, whatever
the handoff's default says.

## 1. Research the real use (before designing)

- Who uses this and how? Plugins involved, platforms (Twitch, YouTube,
  TikTok, ...), setup guides, the plugin's own UI. Write down 3-6 real
  user setups (journeys) - see `docs/dashboard-interaction-checklist.md`
  § Journeys.
- Ask what else the same OBS data is used for than the request names
  ("vertical canvas" turned out to be any size, and Twitch sends it
  through the *main* stream).

## 2. Verify facts against source, not docs

- Read `docs/obs-protocol-gotchas.md` first.
- For every request / event / vendor call the feature uses, read the
  handler in the source (obs-websocket `src/requesthandler/`, OBS
  `frontend/`, the plugin repo) - shallow clone into the scratchpad,
  delete it afterwards. Note: required / optional fields, how things are
  looked up (by name? in which canvas?), what's *not* evented, what the
  answer looks like on success and failure.
- Make `test/websocket/support/fake_obs_peer.dart` responses / rejections
  behave like that source (comment the source location for non-obvious
  behavior). A fake that agrees with the code proves nothing.
- Add new non-obvious facts to `docs/obs-protocol-gotchas.md`.

## 3. Short spec, then build

- A few lines in the changelog entry or `docs/superpowers/specs/` for
  anything bigger: journeys, the facts from 2, what's gated on what, what
  is deliberately left out and why.
- Build per `AGENTS.md`; commit per verified unit. Key state by UUID.

## 4. Journey + interaction sweep

Walk every journey from 1 through `docs/dashboard-interaction-checklist.md`
(surfaces, state changes, form factors, copy, colors, accessibility) -
from the code, with a test for each behavior that could regress. Fix what
you find before going on.

## 5. Look at it

Write / extend a spec in `tool/widget_shots/` for every state the feature
adds and every neighbor it changes, run `tool/widget_shots/run.sh`, and
open the PNGs (phone, narrow 320 pt, tablet). Fix layout / copy /
contradictions (a status next to a button that says otherwise). A MobX
"No observables detected" line in the output is a finding.

## 6. Independent review, then report

- Run the gates (`AGENTS.md` § test selection; `dart analyze` 0 errors).
- Get a fresh-context review before reporting: spawn one reviewer agent
  (this skill is the user's standing request for it) with the diff range,
  the journeys and both docs, asking for correctness bugs and user-facing
  problems - verify its findings, fix the real ones.
- Report what was built, what's verified how, what's left out and why.
- **End the report by reminding the user to run `/code-review high` in a
  fresh session** for an independent pass (see `AGENTS.md` § Definition
  of done).
- Update the changelog, `AGENTS.md` (only if a rule / map entry changed)
  and the gotchas doc.
