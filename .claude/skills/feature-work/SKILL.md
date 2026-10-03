---
name: feature-work
description: Use for any OBS Blade feature work - building something new OR changing / fixing an existing feature - that touches OBS (obs-websocket requests / events, plugin vendor calls), the dashboard, chat (Twitch / YouTube / Kick, combined chat, activity feed, TTS), sign-ins, or other user-facing flows. E.g. "add support for X plugin", "control Z on the canvas", "the YouTube sign-in is confusing", "this sheet says not connected while I'm signed in", "rework the paywall". Clarifies the request with the user first, then runs research -> verified facts -> build -> journey sweep -> visual check -> independent review -> device check list, so the work lands as the user wants it instead of over several "test it again" rounds.
---

# Feature work, done in one pass

Why this exists: canvas v2 (2026-10-02) took ~5 follow-up rounds, and the
4.1 chat work (2026-10-03) shipped six user-visible misses past two
`/code-review high` runs (a secret in the build, a read-only YouTube
setup that dead-ended, Brand Account sign-ins without "You", a `UC…` id
shown as a name, a header sheet saying "Not connected" while signed in,
outdated console steps). None was wrong code - each was a wrong
**assumption**, encoded in the code and in its tests alike. This skill is
how assumptions get checked: ask, verify against reality, walk the
journeys. Don't report before phase 7.

**Process size:** at least tier M (`sizing-the-process`) for anything
touching protocol / platform APIs + UI (+ persistence), new or existing.

## 0. Understand the request - ask, don't assume

Before designing or fixing, make sure you build what the user means.

- Read what's there first (code, docs below, the handoff) - never ask
  what the code can tell you.
- Then ask about everything that changes the outcome and that you can't
  know: which users / platforms / setups it is for, what should happen
  in the edge states (signed out, no data, offline, tablet), what is out
  of scope, how it should look or read when that's a matter of taste.
  Use the ask-the-user tool where you have one (up to 4 questions a
  round, concrete options, your recommendation first); a short
  numbered list otherwise.
- Restate your understanding in one or two sentences ("So: X for Y, not
  Z") with the questions, so a misunderstanding surfaces now.
- Don't ask for permission on things already decided, and don't ask
  more than one round unless the answers open a real new question.

## Changing an existing feature (bug reports, rework)

Same principles, plus:

- **Reproduce with real data first.** On a maintainer machine: the
  dogfood device's app container (`devicectl device copy from
  --domain-type appDataContainer`), Settings → Logs, a live call with
  the user's own session. Find the root cause, not the symptom.
- **Name the class of the miss** (wrong state assumption, raw id as a
  name, a shared component's platform assumption, outdated external
  steps, ...) and grep for its siblings - other platforms, other entry
  points, the combined chat. Fix them together.
- Add a row to the area's checklist (below) for the new kind of miss,
  and a test that starts from the real case.

## 1. Research the real use

- Who uses this and how? Platforms, plugins, setup guides, the
  third-party UI the user goes through. Write down 3-6 real user setups
  (journeys) - the area checklist has examples.
- Ask what else the same data is used for than the request names
  ("vertical canvas" turned out to be any size; a YouTube channel can
  belong to a Brand Account).

## 2. Verify facts against the source, not memory

Per area:

| Area | Facts from | Fakes to keep honest | Checklist |
|---|---|---|---|
| OBS / dashboard | obs-websocket / OBS / plugin **source** (shallow clone into the scratchpad, delete afterwards); [`docs/obs-protocol-gotchas.md`](../../../docs/obs-protocol-gotchas.md) | `test/websocket/support/fake_obs_peer.dart` | [`docs/dashboard-interaction-checklist.md`](../../../docs/dashboard-interaction-checklist.md) |
| Chat, sign-ins, activity, TTS | the platform's official API reference + a live call or a captured real answer; the audits (`docs/youtube-native-chat-audit.md`, `docs/kick-chat-audit.md`, `docs/chatterino-comparison.md`) | `test/chat/support/fake_*`, starting from the awkward answers (missing keys, no channel, 401 / 403 / 429) | [`docs/chat-journey-checklist.md`](../../../docs/chat-journey-checklist.md) |
| Third-party consoles in copy | the **current** official docs (consoles move) | - | chat checklist § Copy |
| Pro / paywall / store | `docs/revenuecat-setup.md`, `docs/release-playbook.md` | - | - |

- For every request / endpoint: required vs optional fields, how things
  are looked up, what isn't evented, what success **and** failure answers
  look like. Make the fake behave like that (comment the source for
  non-obvious behavior). A fake that agrees with the code proves nothing.
- Write new non-obvious facts down (gotchas doc, audit, checklist).

## 3. Short spec, then build

- A few lines in the changelog entry, or `docs/superpowers/specs/` for
  anything bigger: journeys, facts from 2, what's gated on what, what's
  deliberately left out and why.
- Build per `AGENTS.md`; commit per verified unit. Failures go through
  `GeneralHelper.logFailure` (they must show up in Settings → Logs).

## 4. Journey + interaction sweep

Walk every journey from 1 through the area checklist - states, entry
points, shared components for **every** platform that uses them, form
factors, copy. From the code, with a test for each behavior that could
regress (a matrix over the states where it fits). Fix what you find
before going on.

## 5. Look at it

Write / extend a spec in `tool/widget_shots/` for every state the work
adds and every neighbor it changes, run `tool/widget_shots/run.sh`, and
open the PNGs (phone, narrow 320 pt, tablet). Fix layout / copy /
contradictions (a status next to a button that says otherwise). A MobX
"No observables detected" line in the output is a finding.

## 6. Independent review

- Run the gates (`dart tool/test_gate.dart` on the touched areas;
  `dart analyze` 0 errors).
- Get a fresh-context review: spawn one reviewer agent (this skill is
  the user's standing request for it) with the diff range, the journeys,
  the area checklist and the docs from 2, asking for correctness bugs,
  **wrong assumptions** and user-facing problems - verify its findings,
  fix the real ones.

## 7. Report, with a device check list

- What was built / changed, how each part is verified, what's left out
  and why.
- **Device check:** maintainers - put it on the dogfood device (recipe
  in `docs/private/maintainer-workflow.md`) and give the user a short
  tap list: the journeys and states the work touches, once from a fresh
  state. Store test builds (`release-beta`) only after their on-device
  OK.
- Update the changelog, the area checklist / gotchas, and `AGENTS.md`
  only if a rule or map entry changed.
- **End by reminding the user to run `/code-review high` in a fresh
  session** (see `AGENTS.md` § Definition of done) - pointing it at the
  area checklist makes it check the journeys too.
