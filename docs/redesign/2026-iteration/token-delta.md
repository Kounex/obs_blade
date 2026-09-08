# 4.0 Token Delta — "Liquid Glass, restrained"

Status: **ratified direction, pre-implementation** · v2 after Gate 2 verification
(three independent evaluators; their measured corrections are folded in below).
Sources: mock `all-views-v9.html` (visual companion; v9 = post-Gate-2 polish),
[`dashboard-composition.md`](dashboard-composition.md),
[`../2026-iteration-audit.md`](../2026-iteration-audit.md),
[`gate-reports.md`](gate-reports.md) (both critique rounds, itemized).

This doc is the contract between the mockups and `lib/shared/design/`. **Tie-breaker:
this doc wins.** If the mock contradicts a value here, the mock is stale — report it
as a defect, don't average them. Every value was cross-checked against current code
and measured (WCAG relative luminance) where contrast matters.

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
   on-states, links, nav-back, focus. It never encodes *semantic* state
   (live/rec/program/reachable) — control on/off is not semantic state.
4. **Glass + blur only on truly floating layers** (nav bars, tab bar, sheets).
   **Toasts are the exception: near-opaque solid** (glass over glass reads muddy;
   matches the GlassBar fallback path). Two toast morphologies, written down so a
   third isn't invented: **error card** (full-width, action + dismiss, persists)
   and **status pill** (centered, transient). Content cards are solid. No aurora,
   no glow.
5. **One accent moment per screen.** Everything else is ghost/secondary. Decorative
   icon tiles are neutral (white 7% + dim glyph) — they don't spend the accent.
6. **Spring (overshoot) release only on targets ≥ 44pt.** Small icons get the
   standard curve — overshoot on a 17px glyph reads as jitter, not physics.
7. **Semantic-color disambiguation, written down:** green = streaming live *only*
   (exception: audio level meters — hardware convention, and they're a gradient,
   not a flat fill). Reachable/online = neutral dot. Platform badge *icons* keep
   platform colors (Twitch mod sword etc.); username *text* never uses `live`.
   Red = recording/program (constant) and brand accent (themable) — distinguished
   by token, never mixed on one element.

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

### 2.2 New semantic color: `program`

`AppStatusColors` gains `program` (#FF453A base, same family as `recording`) —
the on-air/program tally. Consumers: active scene tile ring + tint, **PGM tag**
(references `program`, not `rec`), scene-button fill during transitions. Constant
across themes (broadcast convention). The PGM tag fill darkens ~15% (≈#D93B32)
when carrying white text (9–10px measured 3.4:1 → ~4.6:1); tag text ≥10px.

### 2.3 Derived text variants (the `…Text` family — same lerp pattern each)

| Token | CSS var | Value (dark) | Measured | Use |
|---|---|---|---|---|
| `accentText` | `--accent-text` | #FF5A66 | 5.6:1 card, 4.7:1 on 15% accent tint | accent as *text*: selected labels on cards, ghost-CTA labels, badges |
| `highlightText` | `--highlight-text` | **#409CFF** | 6.0:1 | links, nav-back, chat usernames, Close pill, stream chip |
| `recordingText` | `--rec-text` | #FF6B60 | 5.2:1 on 15% rec tint | red status text on same-hue tints (REC pill, rec chip, offline badge) |

Gate 2 correction: v1 ratified `highlightText` #7EB8FF while the mock shipped
#409CFF — #409CFF wins (passes AA, closer to platform blue; #7EB8FF's 8.2:1 was
over-bright for the role). All three lerp toward white for dark surfaces / toward
black for light surfaces.

### 2.4 Filled-CTA label contract

White on #FF4654 = 3.36:1 at any weight. Rule: **filled accent CTAs use 17pt/700
labels** — 17pt bold qualifies as WCAG large text (3:1 bar, passes). Caveat from
Gate 2: this means Flutter logical pixels (`fontSize: 17, FontWeight.w700` ≈ 17pt);
CSS-equivalent 17px (=12.75pt) does NOT qualify — the design lab must confirm the
rendered size reads as intended.

### 2.5 Card color — deliberate identity decision

Current app card: `#101823` (navy-leaning). **Decision: keep the cool tint.**
Liquid card base `#181D26`, derived from the theme's card slot (not a constant) —
custom themes keep their card identity; glass/text levels derive relative to it
(same pattern as `StylingHelper.lightenDarkenColor`).

### 2.6 Non-text (3:1) values

- Ghost-button border: white **35%** (18% measured 1.8:1).
- Switch off-track: white **32%** (22% measured 2.05:1; 14% before that).
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
| `specular` | 1px top gradient line, peak white ≤28% → 0% | Gate 2 amendment (v1 said ≤10%): 22–28% is ratified because the line is the **sole glass signal on True Dark / opaque-fallback surfaces**; placement rule: on the edge facing the content |

**`GlassBar` is a single widget** — all floating bars go through it so fallbacks are
one code path:
- Android + chat element in WebView mode → drop `BackdropFilter` to 0.9-alpha solid
  (platform view + live blur over the same region is a known jank path).
- True Dark scaffold (#000): blur contributes nothing; bar = specular + alpha only.
- Reduced-transparency accessibility setting → solid.

## 4. Motion tokens (`AppMotion` — mostly 1:1 already)

Current `app_motion.dart` values map directly (80/150/250/400/700ms, stagger 30ms ×
max 12, easeOutCubic / emphasized Cubic(0.2,0,0,1) / easeOutBack / easeInCubic).
Deltas:

1. **`AppMotion.ambient`** (3s) — new; infinite ambient loops (LIVE-dot breathe).
   Always gated, never load-bearing.
2. **`Pressable` gains a `scale` parameter** (0.85–0.97 range; fixed 0.97 today) and
   enforces rule 1.6: `spring` release only when the target's longest side ≥ 44pt,
   else `standard`.
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
  (taps blocked; dimmed sub-AA text is acceptable disabled treatment) +
  reconnect status pill anchored **below** the LIVE/REC pills row, neutral dot
  (single pulse on appear). LIVE/REC pills switch to a **neutral unknown state**
  (gray dot + label, no breathe) — an armed green LIVE pill must not keep
  asserting "you're live" over a dead connection. Navbar/tab bar stay live
  (Close remains reachable).
- **Auth-failed (connect):** error-card toast with an **"Edit password" action**
  (routes to the Manual pane) + × dismiss; manual-dismiss only (errors persist).
- **Hit-slop contract:** visual glyph sizes stay small, but every icon control
  gets a 44×44 minimum hit area (`BaseIconButton` gains a hard floor); buttons,
  pills and tappable rows get **44pt min-height via padding** (saved-card ghost
  40px, transition btn 35px, LIVE/REC pills 30px, Close pill 30px all flagged).
  Scene-item eye/lock and audio mute are the live-production mis-tap cluster
  this protects.
- **Flutter risk notes (budget these):** gradient↔solid crossfades need
  `DecorationTween`/Stack+opacity, not `AnimatedContainer`; `BackdropFilter` can't
  be faded (opacity-animated parent); `AnimatedSize` inside the dashboard's
  `CustomScrollView` slivers is a jank risk — prefer `AnimatedCrossFade`.

## 6. Open decisions (owned by the Phase 4 spec, NOT yet ratified)

1. **Tablet** (product requirement, currently unmocked — one connected-view tablet
   frame is the follow-up): 640 cap vs multi-column; side-by-side pairing rules
   (min card width, gutter, Force Tablet Mode <700px); scene-grid column breakpoint;
   carousels → grid/wrap; statistics master-detail; landscape; 2-column stagger
   order; navigation stays `CupertinoTabBar` (say so explicitly).
2. **Light theme + True Dark pass** — derive all white-alpha levels relative to the
   active scaffold/brightness; one light-theme screenshot review before ship.
3. **Chat bar frame** — densest cluster in the app (engine switch, emote picker,
   mod actions, send) is not modeled; needed before sign-off.
4. **Streaming Mode** — swaps the entire connected-view body; unseen by this
   direction so far.
5. **Data-viz color slot** — all statistics charts share chrome-blue (encodes
   nothing); categorical slot decision + axis-label dedupe (a 1-minute session
   renders "18:59 18:59 19:00 19:00").
6. **Haptics tokens** — `Pressable.haptic` exists; no token-level mapping yet.
7. **Scene tiles** — wall of identical squares + 8-tile orphan row (3/3/2) is
   visible in the mock; per-scene color chips vs (later) live thumbnails.
8. **Migration strategy** (Gate 2 addition — currently in NO doc): per-screen vs
   flag-gated vs one cutover; restyle `BaseCard`/`StylingHelper` in place
   (instantly affects every screen) vs fork; screen migration order.
9. **Token-debt sequencing** (Gate 2 addition): the audit's ~211 hardcoded colors /
   87 radii / 41 durations must resolve against theme slots — is that sweep a 4.0
   prerequisite wave, part of 4.0 scope, or separate ownership?

## 7. CSS var → Flutter token map (the Rosetta table — Gate 2 addition)

| Mock CSS var | Flutter token | Where |
|---|---|---|
| `--text` / `--text-dim` / `--text-faint` / `--text-ornament` | `AppTextColors.textPrimary/.textSecondary/.textTertiary/.textOrnament` | new ThemeExtension |
| `--accent` / `--accent-text` | `CustomTheme.accentColorHex` slot / `AppTextColors.accentText` (lerp) | existing slot + new |
| `--highlight` / `--highlight-text` | `CustomTheme.highlightColorHex` slot / `AppTextColors.highlightText` (lerp) | existing slot + new |
| `--program` / `--rec` / `--rec-text` / `--live` / `--warn` | `AppStatusColors.program/.recording/.recordingText/.live/.warning` | extension + new fields |
| liquid card `#181D26` | derived from `CustomTheme.cardColorHex` | existing slot |
| glass bar/σ/saturate/specular | `AppGlass.*` | new ThemeExtension |
| `--d-*` / `--c-*` durations & curves | `AppMotion.*` | existing (1:1) |
| breathe 3s | `AppMotion.ambient` | new |

## 8. Verification path

Phase 3b stands up `tool/design_lab/` — a runnable Flutter sandbox rendering these
tokens as real components (GlassBar, Pressable variants, StaggeredEntrance, calm
chips, sliders, pills, reconnecting/auth states) for on-device feel (springs, blur,
scroll, reduced-motion). Gate 3 is a fresh-session review of this doc + the lab
against the mock before any app code changes.
