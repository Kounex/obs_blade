# 4.0 UI Iteration — State & Plan (read this first)

**Purpose of this doc:** cold-start briefing. A fresh agent (evaluator, reviewer,
or implementer) should be able to read only this file and know what exists, what is
ratified, what is open, and where every artifact lives. Keep it current — update it
whenever state moves. Last updated: 2026-09-09 (v12 mock — user-directed
polish batch on top of Gate 2b's v10 + token delta v3; implementation route
changed to live-app branch; branch landed with unbuilt-items section).

## The goal

OBS Blade 4.0 is a major-release UI/UX iteration of the whole app (Flutter,
iOS/Android, phone + tablet, 500k+ users). Target: feels like a 2026 app — fluid
motion, simplicity, clean color mapping — without regressing the tablet experience
(product requirement). The ratified direction is **"restrained Liquid Glass"**:
glass+blur only on truly floating layers (nav bars, tab bar, sheets), no
aurora/glow, ≤1 specular line per floating surface, one accent moment per screen.

## Process so far (multi-agent, gated)

1. **Phase 1 — audit** of the shipping app (tokens, motion, screenshots).
2. **Phase 2 — direction mockups** in the visual companion (v1→v7 with the user;
   restraint pass after an "AI slop" flag).
3. **Composition model** of the connected view verified against the real code.
4. **User ratified the direction** (v7).
5. **Gate 1 — two independent fresh-agent critiques** (design; a11y/implementability)
   → **v8** polish (25 items).
6. **Token delta doc** (mock→code contract).
7. **Gate 2 — three independent fresh-agent evaluations** (design verification;
   measured a11y re-audit; docs-coherence cold-read) of v8 + docs → **v9** mock +
   token delta v2 + persisted gate reports. **Gate 2b — user-run fresh
   evaluation** of v9 (12 findings: PGM/PVW precedence, full-inert reconnect,
   Transition/Config split, bars-float, measured switch/badge fixes) → **v10**
   mock + token delta v3. All rounds itemized in
   [`gate-reports.md`](gate-reports.md).
8. **v11–v12 — user-directed polish** (2026-09-09): card tint reverted to the
   v7 neutral white-5% (user-ratified; the v8–v10 cool-tint experiment dead),
   auth-failed toast's left accent bar removed (borderless, red hairline kept),
   connect-method segment de-accented (the v9 accent underline on the thumb
   read as template chrome → neutral thumb + white label, iOS-style), paywall
   hero double naming fixed (the "OBS Blade Pro" h2 dropped — the logo already
   carries the wordmark; the value line steps up as the headline).
9. **Implementation route changed (user, 2026-09-09): NO design-lab shadow
   clone.** The throwaway `tool/design_lab/` step is dropped — a parallel app
   would inevitably drift from the real one ("too many gaps"). Instead:
   implement **in the live app on a git branch** (`4.0-liquid-glass` off
   `master`, frequent rebases, unmerged until Gate 3) — real widgets/data/
   navigation on both platforms, full rollback by abandoning the branch.
   Tokens first (additive ThemeExtensions, zero visual diff), then per-screen
   migration. Details: token-delta §8.
10. **Branch implementation landed (2026-09-09, overnight autonomous wave):**
    token layer + color-group wiring (rule-8 drift fixed) + GlassBar on all
    floating bars + per-view migration of Connect, connected/Scenes, Settings,
    Statistics, Paywall — 31 commits on `4.0-liquid-glass`, pushed. Gate green
    (analyze = baseline, all test suites). Known unbuilt items — each with
    what/why/what's-needed — in **"Known unbuilt items" below** (Gate-3 input).
11. **Next:** user dogfoods the branch (phone + tablet) → tablet connected-view
    frame decision → Gate 3 (fresh review of the branch diff + on-device feel +
    tokens; findings to user first) → Phase 4 spec → merge.

## Known unbuilt items on branch `4.0-liquid-glass` (Gate-3 input)

Everything the token-delta contract calls for that the branch does **not** ship
yet, with the reason each exists and the reason it is deferred. None of these
are regressions — they are contract items the styling wave deliberately did not
absorb, or open decisions that were never ratified for build.

### A. Ratified contract items, deferred (token-delta §5)

1. **Reconnecting: blocking scrim + inert command handlers.**
   *What:* when the OBS socket drops, the connected view must put an
   input-blocking scrim over the content area and make every OBS-command
   control inert — scene tiles, transition, sliders, eye/lock/mute, chat send,
   **and the LIVE/REC pills** — to pointer *and* keyboard/assistive input
   (guarded command handlers, not pointer-events alone). A neutral "reconnect
   status" pill (single pulse on appear) anchors below the pills row. Only
   navigation (Close, navbar menu, tab bar) stays live.
   *Why it exists:* an armed green LIVE pill over a dead connection asserts
   "you're live" when you are not — the worst lie a remote can tell mid-show;
   and commands fired into a dead socket fail silently, so the UI must not
   offer them.
   *Built already:* the neutral **unknown state** for the LIVE/REC pills
   (gray dot + label, no breathe) rides the existing store observable.
   *Why deferred:* the scrim + guarded handlers are state/interaction logic
   across `DashboardStore`'s command paths, not styling — half-guarding them
   in a styling wave was the risky option.
   *Needs:* a command-dispatch guard (one choke point), the scrim widget, the
   status pill, semantics audit.

2. **Auth-failed error-card toast with "Edit password" action.**
   *What:* on OBS authentication failure, a near-opaque error card with an
   **"Edit password"** action that routes to the Connect view's Manual pane
   *and moves focus there*, plus a × dismiss; manual-dismiss only; a 1px
   red-tinted hairline on all four sides carries "error" (the v11 left-edge
   bar was killed — user: "generic template chrome"); hidden toasts leave the
   semantics tree entirely.
   *Why it exists:* today an auth failure strands the user on a generic
   message with no path to the one field that fixes it; the action turns a
   dead end into a one-tap recovery.
   *Why deferred:* it is **unbuilt functionality** (routing + focus management
   + semantics), not a restyle of an existing surface — the app has no error
   toast of this kind at all.
   *Needs:* new toast widget on the toast contract, route + focus handoff to
   the Manual pane, a11y pass on show/hide.

3. **Paywall equivalence line ("$4.17/mo" under the yearly price).**
   *What:* the mock shows the per-month equivalence on the yearly card so
   BEST VALUE is a number, not an adjective.
   *Why deferred:* the purchase gateway's `ProProduct` carries only a display
   `priceString` ("$49.99") — numeric prices are not plumbed through, and
   parsing a localized currency string is exactly the fragile path we refuse
   to take.
   *Needs:* expose numeric price through the gateway (RevenueCat
   `StoreProduct.price` / `pricePerMonth`; legacy direct-IAP
   `ProductDetails.rawPrice`), divide, format per locale.

4. **Reconnect toast off-token (motion + colors).**
   *What:* the existing reconnect toast still animates on a hardcoded
   500ms/easeOut and uses red/green borders instead of `AppMotion` + status
   tokens.
   *Why deferred:* §5 relocates reconnect status to the pill below the pills
   row (item 1) — re-tokenizing chrome that the same contract then
   repositions is rework. Resolves together with item 1.

### B. Open decisions (token-delta §6 — never ratified for build, Phase-4 owned)

5. **Chat-bar frame (§6.3).** The densest cluster in the app — engine switch,
   channel dropdown, emote picker, mod actions, send — was never modeled in
   the mock, so the branch leaves it alone. Needed before 4.0 sign-off; a
   design pass of its own in the Phase 4 spec.
6. **Data-viz color slot (§6.5).** Every statistics chart shares chrome-blue,
   which encodes nothing. The categorical slot decision (+ axis-label dedupe)
   is open, so chart colors are deliberately untouched.
7. **Tablet composition (§6.1).** Tablet layout rules (640 cap vs
   multi-column, side-by-side pairing, scene-grid breakpoints, carousels →
   grid, statistics master-detail, landscape) are unmocked and unratified.
   The branch's tablet requirement was *no regressions* — verified by the
   iPad walk — not a tablet redesign; that is the biggest Phase-4 item.

### C. Framework ceiling (documented in code, not fixable in-app today)

8. **GlassBar saturate garnish + reduced-transparency fallback.** The glass
   spec's saturation pass and the accessibility fallback for reduced
   transparency are not expressible in Flutter 3.44 — no `ImageFilter` color
   pass over the blur, no `MediaQuery` reduced-transparency flag. Documented
   in `lib/shared/design/glass_bar.dart`; revisit on an SDK bump.

## Artifact map

| What | Where |
|---|---|
| **Current mock (v12, the thing to evaluate)** | `.superpowers/brainstorm/63192-1788922769/content/all-views-v12.html` (local, gitignored; single-file HTML: 5 views × Current/Liquid Glass variants + shell). ⚠️ The content dir also holds **stale standalone mocks** (`connect-liquid-glass-v1.html`, `dashboard-liquid-glass-v2.html`, …) and older all-views versions — superseded, do not evaluate them |
| Settled screenshots (v8; recapture for v9) | `/tmp/obs_verify/v8_*.png` (ephemeral — recapture via the server, recipe in gotchas doc) |
| **Token delta (THE contract — wins all conflicts)** | `docs/redesign/2026-iteration/token-delta.md` |
| Gate reports (both rounds, itemized + dispositions) | `docs/redesign/2026-iteration/gate-reports.md` |
| Composition model (connected view) | `docs/redesign/2026-iteration/dashboard-composition.md` — one view, ordered user-reorderable element list, pairing rules, toggles. Known drift: mock's default element order puts gated elements at the bottom, code puts them at the top (spec input, gate-reports E16) |
| Current-state audit (the app as it ships) | `docs/redesign/2026-iteration-audit.md` — ⚠️ its direction paragraph is pre-restraint (historical); raw inputs: `docs/redesign/2026-iteration/{motion-audit,token-discipline,animation-opportunities}.md` |
| Existing design system (code) | `lib/shared/design/` (`app_motion.dart`, `app_status_colors.dart`, `pressable.dart`, `staggered_entrance.dart`, …) |
| Existing design system (docs) | `docs/redesign/design-system.md` |
| Mock build/polish changelog | `.superpowers/sdd/mockup-dashboard-v1-report.md` (local) |
| Mock tooling gotchas | `docs/superpowers/visual-companion-gotchas.md` — **read before serving or screenshotting mocks** (server start, port/key discovery, background-tab screenshot recipe) |

**Viewing the mock:** quick look = open the HTML file directly (`file://` works for
a static peek). Full evaluation = serve via the visual companion server (start
instructions + port/key discovery in the gotchas doc). URL shape:
`http://localhost:<port>/files/all-views-v12.html?key=<key>`. Shell: top segment
switcher (Connect / Scenes / Statistics / Settings / Paywall); per-view
**Current ↔ Liquid Glass** toggle (evaluate the Liquid Glass side); Connect/Scenes
**DEMO STATE** toggles (first-run, auth-failed — combinable; reconnecting).
Screenshotting via automation: inject the settle-override from the gotchas doc
FIRST — background-tab CSS animation throttling otherwise fakes "faded" content.

## Process rule (user-directed, standing)

**Evaluation/critique findings are triaged to the user BEFORE anything is
applied.** Present findings with a recommendation; the user approves, adjusts or
rejects; only then build. Applies to mock changes, token/contract changes, and
doc amendments that follow from findings. (Ratified 2026-09-09 after a Gate-1
finding — the cool-tint card — was applied without user review and had to be
reverted. Taste-affecting changes are the user's call, always.)

## Mock fidelity — what the mock IS and IS NOT (read before evaluating)

The mock is a **direction artifact, not a blueprint**. Implementation restyles the
app's real components (`BaseCard`, `BaseIconButton`, settings rows, scene grid…)
with the new tokens — their actual layouts, icons and sizing stay unless the
direction explicitly changes them — and the live implementation branch
(on-device, token-delta §8) is where sizing and feel get judged, not the browser.

**Authoritative (binding, evaluate hard):** color tokens & grammar; material
rules (glass only on floating layers, specular, toasts solid); motion tokens
(durations/curves/stagger); state semantics (reconnecting, auth-failed,
first-run — WHAT happens and what's interactive); composition model (which
elements exist, pairing, ordering rules).

**Illustrative (do NOT file as direction defects):** exact px sizes, icon/glyph
choice, precise spacing and layout, typography scale specifics, mock-only DOM
architecture. Pixel-level findings are acceptable only as mock-hygiene notes —
never as blockers. (Gate 2b's px-level items were useful mock hygiene but were
over-weighted; calibrate accordingly.)

## What is RATIFIED (do not re-litigate without a genuine defect)

- The restrained Liquid Glass direction itself (user-approved).
- The color grammar (token-delta §1): state colors from `AppStatusColors` (never
  the themable accent); accent = selection/brand; highlight = control states +
  transient affordances; green = streaming-live only; toasts = near-opaque solid.
- One accent moment per screen; glass only on floating layers; spring release only
  on ≥44pt targets; decorative icon tiles neutral.
- **Color groups, uniform across elements AND platforms** (user, 2026-09-09 —
  token-delta §1 rule 8): every colored element resolves to a named group token,
  identical on iOS/Android, no framework-default leaks; the group set is the
  future per-group CustomTheme surface.
- **Implementation route: live app on git branch `4.0-liquid-glass`, NO
  design-lab shadow clone** (user, 2026-09-09 — token-delta §8). Full rollback
  = abandon the branch; unmerged until Gate 3 passes.
- Composition model of the connected view (one view, many states — NOT separate
  pages per feature).
- **Token values in `token-delta.md` — that doc wins every conflict** (the mock
  can be stale; report mismatches as defects instead of averaging). Changing a
  ratified value needs measurement, not taste.

## Gate 2 outcome (summary — full itemization in gate-reports.md)

All v8 headline fixes verified in code and pixels. New findings → **v9**:
selected segment label contrast (white label + accent hairline), `textTertiary`
42→48%, `highlightText` #409CFF ratified, new `recordingText` #FF6B60, switch
off-track 32%, PGM tags → `program` + darker fill + ≥10px, ctrl-btn ghost 35%,
spring rule enforced on small icons, mod-green username fixed, toggle/checkbox
unified on highlight, paywall icon tiles neutralized + duplicate title dropped,
reconnecting rework (blocking scrim, neutral pills, toast below pills), auth
toast gains Edit-password action + dismiss, demo states combinable. Docs:
tie-breaker rule, Rosetta table (CSS var → Flutter token), migration strategy +
token-debt sequencing added as open decisions §6.8/§6.9.

## Open decisions (owned by the Phase 4 spec — token-delta §6)

Tablet composition (biggest gap), light-theme + True Dark derivation pass,
chat-bar frame, Streaming Mode, data-viz color slot, haptics tokens, scene-tile
identity, **migration strategy**, **token-debt sequencing**.

## Evaluation brief (future gates)

Fresh evaluators should: **(a)** treat the ratified list as settled law,
**(b)** verify claims by measuring (CSS values, WCAG math, file:line) — two
ratified values failed their own bar under re-measurement in Gate 2, so "trust
but verify" is literal, **(c)** hunt for NEW defects (demo states, cross-view
consistency, state combinations), **(d)** check artifact agreement (mock ↔
token-delta ↔ composition doc). Output: numbered findings with severity
(blocker / should-fix / note), exact evidence, concrete fix each.
