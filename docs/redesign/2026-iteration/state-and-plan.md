# 4.0 UI Iteration — State & Plan (read this first)

**Purpose of this doc:** cold-start briefing. A fresh agent (evaluator, reviewer,
or implementer) should be able to read only this file and know what exists, what is
ratified, what is open, and where every artifact lives. Keep it current — update it
whenever state moves. Last updated: 2026-09-08 (v8 mock + token delta ratified,
pre-design-lab).

## The goal

OBS Blade 4.0 is a major-release UI/UX iteration of the whole app (Flutter,
iOS/Android, phone + tablet, 500k+ users). Target: feels like a 2026 app — fluid
motion, simplicity, clean color mapping — without regressing the tablet experience
(product requirement). The ratified direction is **"restrained Liquid Glass"**:
glass+blur only on truly floating layers (nav bars, tab bar, sheets, toasts), no
aurora/glow, ≤1 specular line per floating surface, one accent moment per screen.

## Process so far (multi-agent, gated)

1. **Phase 1 — audit** of the shipping app (tokens, motion, screenshots).
2. **Phase 2 — direction mockups** in the visual companion (browser mockups,
   iterated v1→v7 with the user; restraint pass after an "AI slop" flag).
3. **Composition model** of the connected view verified against the real code.
4. **User ratified the direction** (v7).
5. **Gate 1 — two independent fresh-agent critiques** (senior product designer;
   UX/a11y/Flutter-implementability). Found 6 P0s + contrast failures + slop
   inventory.
6. **Polish pass → mock v8** applying all 25 critique items.
7. **Token delta doc** written (the mock→code contract), committed.
8. **Next: Gate 2** — independent evaluation of v8 (this is where we are).
   Then: Flutter design lab, tablet frame, Phase 4 spec, implementation.

## Artifact map

| What | Where |
|---|---|
| **Current mock (v8, the thing to evaluate)** | `.superpowers/brainstorm/16464-1788892928/content/all-views-v8.html` (local, gitignored; single-file HTML, contains both "Current" and "Liquid Glass" variants of 5 views + shell) |
| Settled screenshots of v8 (Liquid Glass mode) | `/tmp/obs_verify/v8_{connect,scenes,statistics,settings,paywall}.png` (ephemeral — recapture via the server if gone) |
| **Token delta (the contract)** | `docs/redesign/2026-iteration/token-delta.md` — ratified grammar, token values, reduced-motion seam, open decisions |
| Composition model (connected view) | `docs/redesign/2026-iteration/dashboard-composition.md` — one view, ordered user-reorderable element list, pairing rules, toggles |
| Current-state audit (the app as it ships) | `docs/redesign/2026-iteration-audit.md` |
| Existing design system (code) | `lib/shared/design/` (`app_motion.dart`, `app_status_colors.dart`, `pressable.dart`, `staggered_entrance.dart`, …) |
| Existing design system (docs) | `docs/redesign/design-system.md` |
| Mock build/polish changelog | `.superpowers/sdd/mockup-dashboard-v1-report.md` (local) |
| Mock tooling gotchas | `docs/superpowers/visual-companion-gotchas.md` — **read before screenshotting or serving mocks** |

**Viewing the mock:** served by the visual companion server (see gotchas doc for
start/restart). URL shape: `http://localhost:<port>/files/all-views-v8.html?key=<key>`.
The shell has a top segment switcher (Connect / Scenes / Statistics / Settings /
Paywall), each view has a **Current ↔ Liquid Glass** toggle (evaluate the Liquid
Glass side), and Connect/Scenes have **DEMO STATE** toggles (first-run, auth-failed,
reconnecting). When screenshotting via automation, inject the settle-override from
the gotchas doc first — background-tab CSS animation throttling otherwise fakes
"faded" screenshots.

## What is RATIFIED (do not re-litigate without a genuine defect)

- The restrained Liquid Glass direction itself (user-approved).
- The color grammar: **state colors from `AppStatusColors`, never the themable
  accent**; accent = selection/brand; highlight = transient affordances.
- One accent moment per screen; glass only on floating layers; spring release only
  on ≥44pt targets.
- Composition model of the connected view (one view, many states — NOT separate
  pages per feature).
- Token values in `token-delta.md` (came out of measured WCAG failures; changing
  them needs measurement, not taste).

## Gate 1 findings → what v8 changed (so evaluators don't re-report)

- Red grammar contradiction fixed: new `program` token; active scene tile + PGM tag
  both status-red; reachable dots neutral (green = live only).
- Contrast: text-dim 45→55%, text-faint 30→42%, new `accentText` #FF5A66 /
  `highlightText` #7EB8FF, ghost borders 35%, switch off-track 22%, star off 35%,
  filled-CTA labels 17/700.
- Connect: armed Connect CTA in the Autodiscover pane (the one accent moment);
  saved-card buttons demoted to ghost; segment glyphs → Auto/QR/Manual labels;
  new demo states (first-run, auth-failed).
- Scenes: LIVE/REC pills = dot+label idle / tinted-fill live; reconnecting demo.
- Paywall: real `base_logo.png` (bolt squircle removed), 3 benefits (filler cut),
  free-line de-italicized, yearly ring removed (badge kept).
- Statistics: one-line timestamps (`18:59 → 19:00 · 20 Aug`).
- Surfaces: cool-tinted cards (#181D26, deliberate identity decision), blur σ20→12,
  slider knob 20→28px, pane entrances 12px rise.

## Open decisions (owned by the Phase 4 spec — from token-delta §6)

Tablet composition (8 listed questions — biggest gap), light-theme + True Dark
derivation pass, chat-bar frame, Streaming Mode, data-viz color slot, haptics
tokens, scene-tile identity (color chips vs. thumbnails).

## Evaluation brief (Gate 2)

Fresh evaluators should: **(a)** treat the ratified list above as settled law,
**(b)** verify v8 actually implements the Gate-1 fixes correctly (trust but
verify — measure, don't assume), **(c)** hunt for NEW defects the first round
missed, especially across the new demo states and cross-view consistency,
**(d)** check the three artifacts (mock ↔ token-delta ↔ composition doc) agree.
Output: numbered findings with severity (blocker / should-fix / note), exact
evidence (CSS value / file:line / screenshot region), and a concrete fix each.
