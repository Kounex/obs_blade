# 4.0 UI Iteration — State & Plan (read this first)

**Purpose of this doc:** cold-start briefing. A fresh agent (evaluator, reviewer,
or implementer) should be able to read only this file and know what exists, what is
ratified, what is open, and where every artifact lives. Keep it current — update it
whenever state moves. Last updated: 2026-09-08 (Gate 2 complete, v9 mock + token
delta v2, pre-design-lab).

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
8. **Next:** Flutter design lab (`tool/design_lab/`), tablet connected-view frame,
   then Gate 3 (fresh review of lab + tokens), Phase 4 spec, implementation.

## Artifact map

| What | Where |
|---|---|
| **Current mock (v10, the thing to evaluate)** | `.superpowers/brainstorm/16464-1788892928/content/all-views-v10.html` (local, gitignored; single-file HTML: 5 views × Current/Liquid Glass variants + shell). ⚠️ The content dir also holds **stale standalone mocks** (`connect-liquid-glass-v1.html`, `dashboard-liquid-glass-v2.html`, …) — superseded, do not evaluate them |
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
`http://localhost:<port>/files/all-views-v9.html?key=<key>`. Shell: top segment
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
direction explicitly changes them — and the Flutter design lab (on-device) is
where sizing and feel get judged, not the browser.

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
