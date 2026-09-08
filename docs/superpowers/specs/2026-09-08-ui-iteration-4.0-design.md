# 4.0 UI/UX iteration — evaluation & exploration workflow

2026-09-08 · Status: approved (process design) · Output feeds a later
redesign spec + implementation plan.

## Intent

4.0 should *feel* like a 2026 app: fluid motion, simplified surfaces,
deliberate color mapping. This document designs the **workflow** for
evaluating the current UI and iterating on ideas **without touching app
code** — not the redesign itself (that gets its own spec in Phase 4).

## Ratified decisions (from brainstorming)

- **Focus:** system-wide evolution via tokens (motion, color, spacing,
  type) so every screen inherits the feel — not screen-by-screen.
- **Aesthetic direction:** Liquid Glass inspired (iOS 26-era: layered
  translucency, specular edges, content-aware blur, bouncier motion),
  evolving the existing "On Air" identity.
- **Constraints:** everything on the table — including new dependencies,
  signature color changes, and CustomTheme slot re-mapping (with
  migration designed explicitly if it happens).
- **Fidelity strategy:** animated browser mockups for breadth (cheap
  iteration), a throwaway Flutter design lab for finalists (real
  springs/scroll/blur on device). Browser → Flutter translation is ~1:1
  for tokens (hex, px, durations, cubic-bezier ↔ `Cubic()`); it degrades
  for gesture physics, platform text rendering, backdrop-blur quality —
  exactly what the lab exists to validate.

## Phase 1 — Current-state audit (read-only)

1. **Visual inventory:** `tool/visual_qa/capture_screenshots.sh` at phone
   width, then again with Settings → Force Tablet Mode (or wide sim).
   Output PNGs (`/tmp/obs_shots/`) = the "before" set + mockup structure
   reference + later visual-regression baseline.
2. **Motion & token audit:** codebase sweep (read-only advisor passes —
   `find-animation-opportunities`, `improve-animations`) for ad-hoc
   durations/curves bypassing `AppMotion`, hardcoded colors bypassing the
   theme / `AppStatusColors`, static-where-it-should-animate, and
   over-animated spots. Output: prioritized findings, no code changes.
3. **Findings digest:** `docs/redesign/2026-iteration-audit.md` —
   screenshots embedded, grouped into quick wins / systemic issues /
   "where the 2026 feel is missing".

## Phase 2 — Direction mockups (browser)

- **Surfaces:** Dashboard, Scenes, Paywall — phone width first; tablet
  variant for Dashboard (flagship composition).
- **Form:** static HTML/CSS/JS under `tool/visual_qa/mockups/`, animated
  (staggers, springs-as-overshoot-curves, transitions). Animation
  parameters written as real token names (`AppMotion.slow`,
  `emphasized` = `Cubic(0.2,0,0,1)` …) so approval = a token diff.
- **Iteration:** wide first (color mapping, surface treatment), then
  choreography. No app code touched. Mockup review happens in a browser
  tab (local mockup server offered just-in-time when the first mockup is
  ready).

## Phase 3 — Token delta + Flutter design lab

- **Token diff:** concrete proposed edits to `app_motion.dart`,
  `app_status_colors.dart` / color defaults, type scale, radii + any new
  Liquid Glass tokens (blur intensities, specular opacity, glass border
  treatment).
- **Design lab:** throwaway Flutter app in `tool/design_lab/` rendering
  the three hero surfaces with real app widgets where practical and the
  new tokens applied — run on device/simulator to judge springs, scroll
  feel, blur quality.
- **Legacy-theme toggle:** if the direction implies CustomTheme
  re-mapping, the lab shows what an existing saved theme renders like
  under the new mapping before any migration is committed to.

## Phase 4 — Redesign spec + handoff

- Ratified decisions flow into a new redesign spec under
  `docs/superpowers/specs/` (dated at writing, e.g.
  `…-liquid-glass-4.0-design.md`): token changes, per-surface changes,
  motion contracts, CustomTheme migration story (if any), rollout hard
  rules.
- That spec goes through the normal pipeline (writing-plans →
  implementation). Phase-1 screenshots serve as the visual baseline.
- Design lab is deleted or archived once the app adopts the tokens.

## Error handling / risks

- **Browser mockup oversells motion** — mitigated by Phase 3 lab gate;
  nothing ships that hasn't been felt on device.
- **Scope creep into app code during exploration** — hard rule: no edits
  under `lib/` until the Phase 4 spec is approved.
- **Mockup/lab drift** — parameters always named as app tokens; the lab
  imports the real token files where feasible rather than copying values.
- **500k-user compatibility** — CustomTheme migration (if any) is a
  first-class spec section, not an afterthought; persistence hard rules
  from `docs/persistence-risk.md` still apply to any Hive changes.
