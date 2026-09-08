# 4.0 Token Delta — "Liquid Glass, restrained"

Status: **ratified direction, pre-implementation** · Sources: mock `all-views-v8.html`
(visual companion, v8 = post-critique polish), two independent fresh-agent critiques
(design + UX/a11y/implementability), [`dashboard-composition.md`](dashboard-composition.md),
[`../2026-iteration-audit.md`](../2026-iteration-audit.md).

This doc is the contract between the mockups and `lib/shared/design/`. Every value
here was cross-checked against the current code; where current code already matches,
it says so — the delta is smaller than it looks.

---

## 1. Ratified grammar (the rules everything else follows)

1. **State colors come from `AppStatusColors`, never from the themable accent.**
   Program/tally, recording, live, reachable — constant across custom themes.
   *Why:* under a blue custom accent, an accent-derived active-scene ring renders
   blue while the PGM tag on the same tile stays red — a broken tally signal on the
   most state-critical element in the app. The active-scene treatment keys off
   status red ("program"), not accent.
2. **Accent = selection & brand moments.** Active tab/segment ink, selected state
   of navigation controls, the one accent CTA per screen (Connect, yearly plan).
3. **Highlight = transient affordances.** Links, nav-back, focus/hover — never state.
4. **Glass + blur only on truly floating layers** (nav bars, tab bar, sheets,
   toasts). Content cards are solid. At most one specular (1px top gradient line)
   per floating surface. No aurora, no glow.
5. **One accent moment per screen.** Everything else is ghost/secondary.
6. **Spring (overshoot) release only on targets ≥ 44pt.** Small icons get the
   standard curve — overshoot on a 17px glyph reads as jitter, not physics.
7. **Semantic-color disambiguation is written down, not vibes:** green = streaming
   live *only*; reachable/online is a neutral dot; red = recording/program *and*
   brand accent — distinguished by context (chips/tags vs. buttons) and by token
   (`AppStatusColors` vs. accent slot).

## 2. Color tokens

### 2.1 New: three-level text emphasis (`AppTextColors` ThemeExtension)

The current system has only ad-hoc greys. The mock uses three levels; critique
measured them against WCAG AA on scaffold `#212123` and liquid cards:

| Token | Value (dark) | Ratio on scaffold | Use |
|---|---|---|---|
| `textPrimary` | white 92% | ~14:1 | titles, row labels, values |
| `textSecondary` | white **55%** | ~5.9:1 | body copy ≤15px, subtitles, addresses, stat keys, settings values, paywall sub |
| `textTertiary` | white **42%** | ~4.5:1 | section labels, footnotes, axis labels, version |
| `textOrnament` | white 30% | ~2.6:1 | pure decoration only — never the sole carrier of meaning |

The mock's original 45%/30% levels measured 4.36:1 / 2.6:1 — both fail AA for the
roles they played. **Light themes: derive, don't invert** — same roles as black-alpha
levels (≈60% / 45% / 33%), verified in the light-theme pass (§6).

### 2.2 New semantic color: `program`

`AppStatusColors` gains `program` (#FF453A, same family as `recording`) — the
on-air/program tally. Used by: active scene tile ring, PGM tag, scene-button fill
during transitions. Constant across themes (broadcast convention, not brand).

### 2.3 Derived accent/highlight text variants

| Token | Value (dark) | Why |
|---|---|---|
| `accentText` | #FF5A66 | accent #FF4654 as *text* on cards = 4.15:1, fails AA; this reaches ~4.9:1. Selected labels, ghost-CTA labels, badges |
| `highlightText` | #7EB8FF | raw #0A84FF as link text measured 3.7–4.4:1 on cards/glass/tints; this reaches ~5.5:1. Links, nav-back, chat usernames, Close pill |

Both are `lerp`-functions of the active accent/highlight slots in light themes
(brighten toward white for dark surfaces, darken for light).

### 2.4 Filled-CTA label contract

White 15px/600 on #FF4654 = 3.36:1 (fails; 15px is not WCAG "large text").
Rule: **filled accent CTAs use 17px/700 labels** (qualifies as large text, 3:1 bar,
3.36 passes) — or a darkened label scrim. Mock uses 17/700.

### 2.5 Card color — deliberate identity decision

Current app card: `#101823` (navy-leaning). The restraint pass had drifted to
neutral white-5%-on-gray (generic). **Decision: keep the cool tint.** Liquid card
base ≈ `#181D26` (mock value), i.e. derived from the theme's card slot, not a
constant — custom themes keep their card identity; the glass/text levels derive
relative to it (same pattern as `StylingHelper.lightenDarkenColor`).

### 2.6 Non-text (3:1) corrections

- Ghost-button border: white 18% → **35%** (was 1.79:1, the Monthly/Lifetime CTAs'
  only affordance).
- Switch off-track: white 14% → **22%** (or +hairline).
- Favorite/star off-state: white 20% → **35%** (it's a toggle, off must be visible).
- Card hairlines stay decorative (exempt).

## 3. Glass tokens (`AppGlass` ThemeExtension)

Replaces the two loose constants in `StylingHelper` (`opacity_blurry` 0.75,
`sigma_blurry` 10):

| Token | Value | Note |
|---|---|---|
| `barColor` | derived: `(appBarColor ?? primary)` at 72–75% alpha | **must derive from the theme's `appBarColorHex`/`tabBarColorHex` slots** — the mock's hardcoded near-black ignores custom themes |
| `sigma` | **10–12** | the mock's σ20 doubles kernel cost for no visible gain at bar sizes; matches the existing contract |
| `saturate` | 1.15–1.3, **iOS-only garnish** | second compose pass; skip on Android |
| `specular` | 1px top gradient line, white ≤10% → 0% | cheap `Container`+`LinearGradient`, no filter |

**`GlassBar` is a single widget** — all floating bars go through it so fallbacks are
one code path:
- Android + chat element in WebView mode → drop `BackdropFilter` to 0.9-alpha solid
  (platform view + live blur over the same region is a known jank path).
- True Dark scaffold (#000): blur contributes nothing; bar = specular + alpha only.
- Reduced-motion / accessibility transparency settings → solid.

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
4. **Pane switches (segment/tab body swaps): 12px rise + fade at `medium` +
   `emphasized`** — the mock's opacity-only crossfade was flagged as timid; this is
   the difference between "web mockup" and "native".

### Reduced-motion seam — built from zero (nothing exists in `lib/` today)

One helper: `AppMotion.reduce(context)` → `MediaQuery.of(context).disableAnimations`
(responds to iOS Reduce Motion / Android animator-off; **no new persisted key**).
Mapping:

| Animation | Reduced behavior |
|---|---|
| `Pressable` scale | drop scale, keep instant opacity flash (state feedback stays) |
| `StaggeredEntrance` | skip delay+duration, render at final value |
| LIVE-dot breathe (ambient) | **stop entirely**; single 300ms pulse on state change only |
| Theme/mode crossfades | ≤50ms hard swap |
| Seg-thumb/ink slides, chevrons | keep (user-initiated), shorten to `fast` |
| `AnimatedSize`/max-height reveals | fade-only, no layout motion |
| Celebration (`dramatic`) | suppress |
| Scene-button fill (OBS transition duration) | **keep** — conveys real state, not decoration |

## 5. Flutter risk notes (budget these)

- **Gradient↔solid background crossfades** can't be done by `AnimatedContainer` —
  needs `DecorationTween` with explicit begin/end or Stack+opacity.
- **`BackdropFilter` can't be faded** — wrap in an opacity-animated parent.
- **`AnimatedSize` inside the dashboard's `CustomScrollView` slivers is a jank
  risk** — prefer `AnimatedCrossFade` there; test on-device early (design lab).
- **Hit-slop contract:** visual glyph sizes stay small, but every icon control gets
  a 44×44 minimum hit area (`BaseIconButton` gains a hard floor). Scene-item
  eye/lock and audio mute are the live-production mis-tap cluster this protects.

## 6. Open decisions (answered in the Phase 4 spec, NOT yet ratified)

1. **Tablet** (product requirement, currently unmocked — one connected-view tablet
   frame is the follow-up):
   - keep `kBaseConstrainedMaxWidth` 640 (centered column) or multi-column?
   - side-by-side pairing: min card width, gutter, behavior under Force Tablet Mode
     at <700px;
   - scene-grid column breakpoint / max tile size;
   - carousels (saved connections, paywall benefits) → grid/wrap on tablet;
   - statistics: master-detail on tablet?
   - landscape composition; stagger order in 2-column layouts (row-major?);
   - navigation stays `CupertinoTabBar` both form factors (say so explicitly).
2. **Light theme + True Dark pass** — derive all white-alpha levels relative to the
   active scaffold/brightness; one light-theme screenshot review before ship.
3. **Chat bar frame** — densest cluster in the app (engine switch, emote picker,
   mod actions, send) is not modeled; needed before sign-off.
4. **Streaming Mode** — swaps the entire connected-view body; unseen by this
   direction so far.
5. **Data-viz color slot** — all statistics charts share chrome-blue, which encodes
   nothing; decide whether charts get a dedicated categorical slot.
6. **Haptics tokens** — `Pressable.haptic` exists; no token-level mapping
   (which actions get impact vs. selection) yet.
7. **Scene tiles** — wall of identical squares; consider per-scene color chips or
   (later) live thumbnails; check 7/9-scene grid orphan rows.

## 7. Verification path

Phase 3b stands up `tool/design_lab/` — a runnable Flutter sandbox rendering these
tokens as real components (GlassBar, Pressable variants, StaggeredEntrance, calm
chips, sliders, pills) for on-device feel (springs, blur, scroll). Gate 2 is a
fresh-session review of this doc + the lab against `all-views-v8.html` before any
app code changes.
