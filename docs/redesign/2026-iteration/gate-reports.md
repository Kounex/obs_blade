# Gate Reports — 4.0 UI Iteration critiques, itemized

Both evaluation rounds, condensed but itemized, so future evaluators can verify
fixes without re-deriving findings from conversation history. Full reasoning lives
in session wire logs; the mock's own changelog is in
`.superpowers/sdd/mockup-dashboard-v1-report.md` (local).

Severity legend: **P0/blocker** = must fix before tokens/lab · **P1/should-fix** ·
**P2/note** = later or spec-input.

---

## Gate 1 (2026-09-08) — two fresh agents vs mock v7

### Agent A — senior product designer

| # | Sev | Finding | Disposition |
|---|---|---|---|
| A1 | P0 | Selected-state color contradicts itself (red on nav/segments, blue on toggles/sliders) — real rule unwritten | Grammar ratified: accent=selection/brand, highlight=control states+transient, state=AppStatusColors (token-delta §1) |
| A2 | P0 | Connect default pane has no Connect CTA; up to 5 red moments on screen | v8: armed CTA in Autodiscover pane; saved-card buttons ghost |
| A3 | P0 | CustomTheme behavior undefined (shipped feature) | token-delta §2.5/§3 derive-from-slots; light pass = open decision |
| A4 | P0 | PGM tally red (#FF453A) vs accent red (#FF4654) — two hexes, one job | `program` token; tile + tag both reference it (v9) |
| A5 | P0 | Tablet completely unmocked | Open decision §6.1; tablet frame planned |
| A6 | P0 | Missing states: first-run, connect failure, reconnecting, chat empty states, empty statistics | v8 demo states (first-run, auth-failed, reconnecting); rest → spec |
| A7 | P1 | 2026-ness: frosted 2021 recipe; needs content-responsive glass, real pane motion, one display-type moment per view | Pane 12px rise ratified; rest → design-lab feel pass |
| A8 | P1 | text-faint 30% = 2.8:1 carries structural labels; 11px-label tic | v8: faint 42% → v9: 48% (measured) |
| A9 | P1 | Slop inventory: paywall bolt squircle, italic sincerity line, "What's Next" filler card, "Aa" glyph, ↑↓ glyph, text-glyph chrome | v8: all fixed (real logo, 3 benefits, Auto/QR/Manual labels) |
| A10 | P1 | Liquid card deleted the navy identity (#101823 → generic neutral gray) | v8: cool #181D26, ratified deliberate (§2.5) |
| A11 | P1 | LIVE/REC pills: idle timer noise; live state a hairline | v8: dot+label idle, tinted-fill live |
| A12 | P1 | Spring on 17px icons = jitter; reduced-motion seam only "proposed" | Rule 6 (≥44pt); seam spec'd in token-delta §4; v9 enforces in mock |
| A13 | P1 | Green overloaded (live/reachable/mod/meters) | Rule 7: green=live only (+meter exception), reachable neutral, badge icons exempt |
| A14 | P1 | Statistics nested From/To pills; full-second timestamps | v8: one-line `18:59 → 19:00 · 20 Aug` |
| A15 | P2 | Scenes content padding 24 vs 16 elsewhere | Deferred to spec |
| A16 | P2 | Scene tiles: wall of identical squares; 8-tile orphan row | Open decision §6.7 |
| A17 | P2 | Streaming Mode + Edit Scene Visibility unmodeled | Open decision §6.4 |
| A18 | P2 | No haptics tokens | Open decision §6.6 |
| A19 | P2 | Light theme / True Dark unmodeled (glass-on-black problem) | Open decision §6.2; specular justification updated |
| A20 | P2 | Paywall yearly: ring+tint+badge+CTA = 4 accent uses | v8: ring dropped, badge kept |
| A21 | P2 | Mock data ("lul", 2022) — sanitize before store use | Note for release |

### Agent B — staff design engineer (a11y + Flutter implementability)

| # | Sev | Finding | Disposition |
|---|---|---|---|
| B1 | blocker | text-dim 45% = 4.36:1 fails AA everywhere | v8: 55% (verified 5.8:1, Gate 2 ✅) |
| B2 | blocker | text-faint 30% = 2.6–2.7:1 on meaningful labels | v8: 42% → v9: 48% |
| B3 | should-fix | accent as text on cards 4.15:1; BEST VALUE 3.52:1 | `accentText` #FF5A66 (verified ✅) |
| B4 | should-fix | #0A84FF links 3.7–4.4:1 on cards/tints | `highlightText` (v9: #409CFF ratified) |
| B5 | blocker | White 15/600 on #FF4654 CTA = 3.36:1 | 17pt/700 contract (§2.4, Flutter-pt caveat from Gate 2) |
| B6 | should-fix | Ghost border 18% = 1.79:1; switch off 14% = 1.57:1; star off 20% = 1.9:1 | 35% / 32% (v9) / 35% |
| B7 | blocker | Sub-44pt icon controls on live-production UI (eye/lock 34px, mute, edit 28px) | Hit-slop contract (§5) |
| B8 | should-fix | Slider knob 20px / 5px track | v8: 28px knob + hit-slop note |
| B9 | note | Chat bar not modeled | Open decision §6.3 |
| B10 | blocker | No reduced-motion seam in `lib/` | token-delta §4 mapping table (MediaQuery.disableAnimations, no new key) |
| B11 | should-fix | σ20+saturate vs existing σ10 contract; saturate = 2nd pass | token-delta §3: σ10–12, saturate iOS-only |
| B12 | should-fix | Tab-bar blur over chat WebView = Android jank path | GlassBar single-widget fallback (§3) |
| B13 | should-fix | accent/status red mixing breaks tally under custom themes | Rule 1 + `program` token |
| B14 | blocker | Mock dark-only; light custom themes break every token | Derivation rule + open decision §6.2 |
| B15 | note | True Dark / reduce-smearing shift contrast ~15% | Derive relative to active scaffold (§3) |
| B16 | note | 8 tablet decisions undefined | Open decision §6.1 |
| B17 | should-fix | AnimatedSize in dashboard CustomScrollView = jank risk | §5 risk notes (AnimatedCrossFade) |
| B18 | should-fix | BackdropFilter can't fade; gradient↔solid needs DecorationTween | §5 risk notes |

---

## Gate 2 (2026-09-08) — three fresh agents vs mock v8 + docs

### Agent C — design verification

Verified fixed: armed CTA/ghost cards, program tile, LIVE/REC pills, paywall
(logo/3 benefits/no ring), one-line timestamps, segment labels, cool cards,
blur σ12, knob 28px, pane rise, dim ladder, switch 22%, star 35%, CTA 17/700.

| # | Sev | Finding | Disposition |
|---|---|---|---|
| C1 | blocker | Selected "Auto" segment label ≈2.8:1 (raw accent on light thumb) | v9: white label + accent hairline |
| C2 | should-fix | REC-armed red text ≈4.0:1 (accentText fix not extended to status red) | `recordingText` #FF6B60 (v9) |
| C3 | should-fix | highlightText: mock #409CFF vs doc #7EB8FF | #409CFF ratified (§2.3) |
| C4 | should-fix | Scenes ctrl-btn kept 18% ghost border | v9: 35% |
| C5 | should-fix | Mod username spends live-green | v9: badge-icon-only green (rule 7) |
| C6 | should-fix | Studio Mode checkbox accent vs switches highlight | v9: highlight (rule 3) |
| C7 | should-fix | Paywall benefit icons keep red tiles | v9: neutralized (rule 5) |
| C8 | should-fix | Auth toast: no action, no dismiss | v9: "Edit password" + ×, persists |
| C9 | note | Reconnecting: blue status dot, toast overlaps pills, pills not dimmed, input live | v9 rework + §5 contract |
| C10 | note | Toasts solid vs grammar says glass; two morphologies undocumented | Rule 4 amended (toasts solid; taxonomy written) |
| C11 | note | Notes promise active-tile "marker dot" never rendered | v9: struck |
| C12 | note | PGM tags reference --rec not --program | v9: --program |
| C13 | note | Raw accent as selected-label text (hygiene; passes today) | accentText lint rule (§2.3) |
| C14 | note | Paywall "OBS Blade Pro" twice | v9: navbar title dropped |
| C15 | note | Tile label off-token 75% + no truncation | v9: textPrimary + ellipsis |
| C16 | note | Chart x-axis label duplication | Open decision §6.5 |
| C17 | note | First-run/auth-failed mutually exclusive in demo JS | v9: combinable |
| C18 | note | True Dark row lacks help "?" | v9: added |
| C19 | note | Specular placement arbitrary (navbar bottom vs tabbar) | Rule: edge facing content (§3) |

### Agent D — a11y/motion re-audit (measured)

Verification table: text-dim 55% ✅ 5.79:1 · text-faint 42% ❌ **3.98:1** → v9 48% ·
CTA 17/700 ⚠️ passes only as Flutter-pt (contract caveat added) · accentText ✅
5.56/4.72 · highlightText ❌ doc/mock conflict → #409CFF · ghost 35% ✅ 3.2 ·
switch 22% ❌ **2.05:1** → v9 32% · star 35% ✅ · knob 28px/blur σ12 ✅.

New: D1 textTertiary 42% blocker (→48%) · D2 segment label blocker (→white) ·
D3 highlightText conflict · D4 status-red-on-tint 3.8–4.3:1 in 4 places
(→recordingText + highlightText on stream chip) · D5 reconnecting interactive-dim
2.7:1 (→scrim contract §5) · D6 ctrl-btn 18% (→35%) · D7 PGM tag 3.41:1 + --rec
(→--program, darker fill, ≥10px) · D8 sub-44pt buttons/pills/rows (→44pt
min-height contract §5) · D9 specular 22–28% vs ≤10% (→≤28% ratified w/
justification) · D10 paneIn standard vs emphasized (→emphasized v9) · D11 raw
accent-as-text hygiene · D12 toast semantics gaps (→v9 + §5). Cool card #181D26
introduced **no** regressions (slightly darker than scaffold).

### Agent E — docs coherence (cold-read test)

| # | Sev | Finding | Disposition |
|---|---|---|---|
| E1 | should-fix | Gate-1 reports not persisted anywhere | This file |
| E2 | should-fix | Server start script + port/key discovery undocumented | gotchas doc updated |
| E3 | should-fix | Settle-override misses `.s-el` (Scenes composed elements) | gotchas doc updated |
| E4 | should-fix | No tie-breaker when mock violates ratified tokens | token-delta header: "this doc wins" |
| E5 | note | Screenshot recapture path is manual | Accepted (documented recipe) |
| E6 | note | Phase-1 raw inputs not in artifact map | state-and-plan map updated |
| E7 | note | Stale standalone mocks share content dir | state-and-plan note added |
| E8 | blocker | highlightText doc↔mock conflict (dup of D3) | #409CFF ratified |
| E9 | should-fix | Specular 22–28% vs ≤10% (dup of D9) | ≤28% ratified |
| E10 | should-fix | Spring ≥44pt claimed but not in mock CSS | v9 enforces |
| E11 | should-fix | Green-live violated by mod username (dup of C5) | v9 |
| E12 | should-fix | "Highlight never state" vs persistent control on-states | Rule 3 amended (control state ≠ semantic state) |
| E13 | note | Pane curve doc/mock mismatch (dup of D10) | v9 emphasized |
| E14 | note | PGM tag --rec (dup of C12) | v9 |
| E15 | note | Dead --reachable var invites re-litigation | v9: removed |
| E16 | note | Mock default element order ≠ code default (gated elements top vs bottom) | Composition-doc note needed (spec input) |
| E17 | note | Audit's direction paragraph is pre-restraint ("bouncier") | Mark as historical in audit |
| E18 | blocker | No migration strategy in any doc | Open decision §6.8 |
| E19 | should-fix | No CSS-var→Flutter-token mapping | §7 Rosetta table |
| E20 | should-fix | Token-debt sweep (211 colors…) unowned/unsequenced | Open decision §6.9 |
| E21 | note | New token homes (files) unstated | Phase 4 spec |
| E22 | note | 8-tile orphan row: open decision or oversight? | Confirmed open decision §6.7 |
