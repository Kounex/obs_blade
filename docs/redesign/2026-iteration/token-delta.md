# 4.0 Token Delta — "Liquid Glass, restrained"

Status: **ratified direction, pre-implementation** · v3 after the user-run
independent evaluation of v9 (12 findings, all accepted — see
[`gate-reports.md`](gate-reports.md) § Gate 2b). Earlier rounds: v2 after Gate 2,
v1 after Gate 1. Sources: mock `all-views-v10.html` (visual companion),
[`dashboard-composition.md`](dashboard-composition.md),
[`../2026-iteration-audit.md`](../2026-iteration-audit.md).

This doc is the contract between the mockups and `lib/shared/design/`. **Tie-breaker:
this doc wins.** If the mock contradicts a value here, the mock is stale — report it
as a defect, don't average them. Every value was cross-checked against current code
and measured (WCAG relative luminance) where contrast matters. **Tints compose:**
when a tinted element sits on a tinted surface, measure text against the full
composite stack, not the base.

---

## 1. Ratified grammar (the rules everything else follows)

1. **State colors come from `AppStatusColors`, never from the themable accent.**
   Program/tally, recording, live — constant across custom themes. *Why:* under a
   blue custom accent, an accent-derived active-scene ring renders blue while the
   PGM tag on the same tile stays red — a broken tally signal on the most
   state-critical element in the app. Small text *in* a status color may use the
   brightened `…Text` derivative (§2.3) — the constant base stays; the derivative
   is the same precedent as `accentText`.
2. **Accent = selection & brand moments.** Active tab/segment ink, selected state
   of navigation controls, the one accent CTA per screen. Selected labels on
   lightened thumbs use **white text + accent hairline** (raw accent text on a
   light thumb measured 2.8:1).
3. **Highlight = interactive control states + transient affordances.** Switch/slider
   on-states, scanner/viewfinder arming, links, nav-back, focus. It never encodes
   *semantic* state (live/rec/program/reachable) — control on/off is not semantic
   state.
4. **Glass + blur only on truly floating layers** (nav bars, tab bar, sheets) —
   and floating means **overlaying the scroll viewport with matching content
   insets**, so content visibly scrolls beneath the blur (a bar laid out as a
   sibling above clipped content demonstrates nothing). **Toasts are the
   exception: near-opaque solid** (glass over glass reads muddy; matches the
   GlassBar fallback path). Two toast morphologies, written down so a third isn't
   invented: **error card** (full-width, action + dismiss, persists) and
   **status pill** (centered, transient). Content cards are solid. No aurora,
   no glow.
5. **One accent moment per screen.** Everything else is ghost/secondary. Decorative
   icon tiles are neutral (white 7% + dim glyph) — they don't spend the accent.
6. **Spring (overshoot) release only on targets ≥ 44pt.** Small icons get the
   standard curve — overshoot on a 17px glyph reads as jitter, not physics.
   Open for the spec: sub-44pt *composite* controls (checkbox rows, help "?",
   mini-segments) — flagged by the builder, decision with the tablet pass.
7. **Semantic-color disambiguation, written down:** green = streaming live, with
   exactly two broadcast-convention exceptions: **audio meters** (rendered as a
   gradient, `.hot` warning-colored — never a flat fill that could read as
   "live") and the **PVW preview tally** (preview=green / program=red is
   broadcast language; **program wins when program and preview are the same
   scene** — mirrors the shipping if/else in `scene_button.dart`). Reachable/
   online = neutral dot. Platform badge *icons* keep platform colors (Twitch mod
   sword etc.); username *text* never uses `live`. Red = recording/program
   (constant) and brand accent (themable) — distinguished by token, never mixed
   on one element. Favorite/star-on = named `favorite` token (#FFD60A), not a
   hardcoded hex.

## 2. Color tokens

### 2.1 New: three-level text emphasis (`AppTextColors` ThemeExtension)

| Token | CSS var | Value (dark) | Measured | Use |
|---|---|---|---|---|
| `textPrimary` | `--text` | white 92% | ~14:1 | titles, row labels, values, tile labels |
| `textSecondary` | `--text-dim` | white 55% | 5.8:1 | body copy ≤15px, subtitles, addresses, stat keys, settings values |
| `textTertiary` | `--text-faint` | white **48%** | 4.8:1 | section labels, footnotes, axis labels, version |
| `textOrnament` | `--text-ornament` | white 30% | ~2.6:1 | pure decoration only — never the sole carrier of meaning |

Gate 2 correction: 42% measured 3.98:1 (the v1 table's "~4.5:1" was wrong) → 48%.
**Light themes: derive, don't invert** — same roles as black-alpha levels
(≈60% / 45% / 38%), verified in the light-theme pass (§6).

### 2.2 New/extended semantic colors (`AppStatusColors`)

- **`program`** (#FF453A base) — on-air/program tally: active scene tile ring +
  tint, **PGM tag** (references `program`, not `rec`), scene-button fill during
  transitions. Constant across themes. The PGM tag fill darkens ~15% (≈#D93B32,
  implemented as `color-mix(85% program, black)` with a static fallback) when
  carrying white text; tag text ≥10px.
- **`favorite`** (#FFD60A) — star/favorite-on. Named so it stops being a
  hardcoded hex; constant like the other signal colors.
- Existing `live`/`recording`/`warning` unchanged; `reachable` renders as a
  **neutral dot** (the green `--reachable` var was removed from the mock —
  nothing consumes it).

### 2.3 Derived text variants (the `…Text` family — same lerp pattern each)

| Token | CSS var | Value (dark) | Measured | Use |
|---|---|---|---|---|
| `accentText` | `--accent-text` | #FF5A66 | 5.6:1 card, 4.7:1 on 15% accent tint | accent as *text*: selected labels on cards, ghost-CTA labels, badges. **Lint-level rule: accent as text ⇒ `accentText`, everywhere** |
| `highlightText` | `--highlight-text` | **#409CFF** | 6.0:1 | links, nav-back, chat usernames, Close pill, stream chip |
| `recordingText` | `--rec-text` | #FF6B60 | 5.2:1 on 15% rec tint | red status text on same-hue tints (REC pill, rec chip, offline badge) |

**Nested-tint rule (Gate 2b):** a tinted badge on a tinted card must be measured
against the composite — the BEST VALUE badge (accentText on 15% accent tint)
failed at 4.19:1 once the hero card's own 5% accent tint was composited; its
tint drops to **8%** (4.59:1). All three `…Text` variants lerp toward white for
dark surfaces / toward black for light surfaces.

### 2.4 Filled-CTA label contract

White on #FF4654 = 3.36:1 at any weight. Rule: **filled accent CTAs use 17pt/700
labels** — 17pt bold qualifies as WCAG large text (3:1 bar, passes). Caveat:
this means Flutter logical pixels (`fontSize: 17, FontWeight.w700` ≈ 17pt);
CSS-equivalent 17px (=12.75pt) does NOT qualify — the design lab must confirm
the rendered size reads as intended.

### 2.5 Card color — deliberate identity decision

Current app card: `#101823` (navy-leaning). **Decision: keep the cool tint.**
Liquid card base `#181D26` (solid, derived from the theme's card slot — not a
white-alpha overlay, not a constant). Custom themes keep their card identity;
glass/text levels derive relative to it (same pattern as
`StylingHelper.lightenDarkenColor`).

### 2.6 Non-text (3:1) values

- Ghost-button border: white **35%** (18% measured 1.8:1).
- Switch off-track: white **35%** (v3 correction: 32% measured **2.90:1** over
  #181D26 — fails; 35% = 3.21:1. 14% and 22% before that.)
- Favorite/star off-state: white **35%**.
- Card hairlines stay decorative (exempt).
- Chat input border: 12% white = 1.44:1 — **the field's identifiability must not
  rest on placeholder text alone**; raise to ~35% or add a fill (Phase 4 spec).

## 3. Glass tokens (`AppGlass` ThemeExtension)

Replaces the two loose constants in `StylingHelper` (`opacity_blurry` 0.75,
`sigma_blurry` 10):

| Token | Value | Note |
|---|---|---|
| `barColor` | derived: `(appBarColor ?? primary)` at 72–75% alpha | **must derive from the theme's `appBarColorHex`/`tabBarColorHex` slots** |
| `sigma` | 10–12 | matches the existing contract; σ20 doubles kernel cost for no visible gain |
| `saturate` | 1.15–1.3, **iOS-only garnish** | second compose pass; skip on Android |
| `specular` | 1px top gradient line, peak white ≤28% → 0% | placement rule: on the edge facing the content; 22–28% ratified because the line is the **sole glass signal on True Dark / opaque-fallback surfaces** |

**Bars float.** Nav bars and tab bar overlay the scroll viewport (content insets
compensate), so blur always has content beneath it. **Shared navbar min-height
(55pt content height)** regardless of whether action slots are populated — an
empty slot must not collapse the bar.

**`GlassBar` is a single widget** — all floating bars go through it so fallbacks
are one code path:
- Android + chat element in WebView mode → drop `BackdropFilter` to 0.9-alpha
  solid (platform view + live blur over the same region is a known jank path).
- True Dark scaffold (#000): blur contributes nothing; bar = specular + alpha only.
- Reduced-transparency accessibility setting → solid.

## 4. Motion tokens (`AppMotion` — mostly 1:1 already)

Current `app_motion.dart` values map directly (80/150/250/400/700ms, stagger 30ms ×
max 12, easeOutCubic / emphasized Cubic(0.2,0,0,1) / easeOutBack / easeInCubic).
Deltas:

1. **`AppMotion.ambient`** (3s) — new; infinite ambient loops (LIVE-dot breathe).
   Always gated, never load-bearing.
2. **`Pressable` gains a `scale` parameter** (0.85–0.97 range; fixed 0.97 today)
   and enforces rule 1.6.
3. **`StaggeredEntrance` gains optional `scaleFrom` (0.985)** — mock entrances are
   rise **+** 2% scale settle; current widget is rise-only.
4. **Pane switches: 12px rise + fade at `medium` + `emphasized`** (toasts/hints
   keep `standard`). Final curve feel is confirmed on-device in the design lab.

### Reduced-motion seam — built from zero (nothing exists in `lib/` today)

One helper: `AppMotion.reduce(context)` → `MediaQuery.of(context).disableAnimations`
(responds to iOS Reduce Motion / Android animator-off; **no new persisted key**).
Mapping:

| Animation | Reduced behavior |
|---|---|
| `Pressable` scale | drop scale, keep instant opacity flash |
| `StaggeredEntrance` | skip delay+duration, render at final value |
| LIVE-dot breathe (ambient) | **stop entirely**; single 300ms pulse on state change only |
| Theme/mode crossfades | ≤50ms hard swap |
| Seg-thumb/ink slides, chevrons | keep (user-initiated), shorten to `fast` |
| `AnimatedSize`/max-height reveals | fade-only, no layout motion |
| Toast slide-in | fade-only |
| Celebration (`dramatic`) | suppress |
| Scene-button fill (OBS transition duration) | **keep** — conveys real state |

## 5. State & interaction contracts

- **Reconnecting (connected view):** input-blocking scrim over the content area
  — and "blocking" is total for **OBS-command controls**: scene tiles,
  transition, sliders, eye/lock/mute, chat send, **and the LIVE/REC pills**
  are inert to pointer *and* keyboard/assistive input (`inert`/semantics +
  guarded command handlers, not pointer-events alone). LIVE/REC pills switch
  to a **neutral unknown state** (gray dot + label, no breathe) — an armed
  green pill must not assert "you're live" over a dead connection, and a
  neutral pill must not accept commands. Reconnect status pill anchored
  **below** the pills row, neutral dot (single pulse on appear). Only
  navigation stays live: Close, navbar menu, tab bar. (Dimmed sub-AA text
  under a blocking scrim is acceptable disabled treatment.)
- **Auth-failed (connect):** error-card toast with **"Edit password"** action
  (routes to Manual pane **and moves focus there**) + × dismiss; manual-dismiss
  only. Hidden toasts leave the focus/semantics tree entirely
  (`Visibility`/`Offstage` semantics — opacity 0 + pointer-events none still
  exposes them). Toast actions honor the 44pt target contract.
- **Hit-slop contract:** visual glyph sizes stay small, but every icon control
  gets a 44×44 minimum hit area (`BaseIconButton` gains a hard floor); buttons,
  pills and tappable rows get **44pt min-height via padding**. Scene-item
  eye/lock and audio mute are the live-production mis-tap cluster this protects.
- **Flutter risk notes (budget these):** gradient↔solid crossfades need
  `DecorationTween`/Stack+opacity, not `AnimatedContainer`; `BackdropFilter`
  can't be faded (opacity-animated parent); `AnimatedSize` inside the
  dashboard's `CustomScrollView` slivers is a jank risk — prefer
  `AnimatedCrossFade`.

## 6. Open decisions (owned by the Phase 4 spec, NOT yet ratified)

1. **Tablet** (product requirement, currently unmocked — one connected-view
   tablet frame is the follow-up): 640 cap vs multi-column; side-by-side pairing
   rules (min card width, gutter, Force Tablet Mode <700px); scene-grid column
   breakpoint; carousels → grid/wrap; statistics master-detail; landscape;
   2-column stagger order; navigation stays `CupertinoTabBar` (say so
   explicitly). **Depends on composition fidelity:** elements must stay
   independently reorderable (the v9 mock's merged Transition/Config element
   would have constrained this — fixed in v10).
2. **Light theme + True Dark pass** — derive all white-alpha levels relative to
   the active scaffold/brightness; one light-theme screenshot review before ship.
3. **Chat bar frame** — densest cluster in the app (engine switch, emote picker,
   mod actions, send) is not modeled; needed before sign-off.
4. **Streaming Mode** — swaps the entire connected-view body; unseen by this
   direction so far.
5. **Data-viz color slot** — all statistics charts share chrome-blue (encodes
   nothing); categorical slot decision + axis-label dedupe.
6. **Haptics tokens** — `Pressable.haptic` exists; no token-level mapping yet.
7. **Scene tiles** — wall of identical squares + 8-tile orphan row (3/3/2);
   per-scene color chips vs (later) live thumbnails.
8. **Migration strategy** (in NO doc before Gate 2): per-screen vs flag-gated vs
   one cutover; restyle `BaseCard`/`StylingHelper` in place vs fork; screen
   migration order.
9. **Token-debt sequencing**: the audit's ~211 hardcoded colors / 87 radii / 41
   durations must resolve against theme slots — prerequisite wave, part of 4.0
   scope, or separate ownership?

## 7. CSS var → Flutter token map (the Rosetta table)

| Mock CSS var | Flutter token | Where |
|---|---|---|
| `--text` / `--text-dim` / `--text-faint` / `--text-ornament` | `AppTextColors.textPrimary/.textSecondary/.textTertiary/.textOrnament` | new ThemeExtension |
| `--accent` / `--accent-text` | `CustomTheme.accentColorHex` slot / `AppTextColors.accentText` (lerp) | existing slot + new |
| `--highlight` / `--highlight-text` | `CustomTheme.highlightColorHex` slot / `AppTextColors.highlightText` (lerp) | existing slot + new |
| `--program` / `--rec` / `--rec-text` / `--live` / `--warn` / `--favorite` | `AppStatusColors.program/.recording/.recordingText/.live/.warning/.favorite` | extension + new fields |
| liquid card `#181D26` | derived from `CustomTheme.cardColorHex` | existing slot |
| glass bar/σ/saturate/specular | `AppGlass.*` | new ThemeExtension |
| `--d-*` / `--c-*` durations & curves | `AppMotion.*` | existing (1:1) |
| breathe 3s | `AppMotion.ambient` | new |

## 8. Verification path

Phase 3b stands up `tool/design_lab/` — a runnable Flutter sandbox rendering these
tokens as real components (GlassBar over scrolling content, Pressable variants,
StaggeredEntrance, calm chips, sliders, pills, reconnecting/auth states) for
on-device feel (springs, blur, scroll, reduced-motion). Gate 3 is a fresh-session
review of this doc + the lab against the mock before any app code changes.
