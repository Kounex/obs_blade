# 4.0 UI Polish Wave — Full-App Audit & Fix Map (2026-09-21)

**Scope:** whole-app UI consistency audit over all 274 files under `lib/views/` +
`lib/shared/` (10 parallel area audits), followed by one fix wave the user
approved wholesale ("go through all you found, should streamline the UI, trust
you on all"). ~120 verified findings → **76 commits** on `4.0-liquid-glass`
(`e07b81d2^..d86347cc`). This doc is the findings→fixes map and Gate-3 input.

**User calibrations ratified during the wave (do not reopen):**

1. **Green for online/reachable/connected is wanted** — saved-card Online pill,
   chat "connected" state keep green. Only framework swatches
   (`Colors.greenAccent`, `CupertinoColors.activeGreen`) were replaced with the
   tokens (`AppStatusColors.reachable` / `.live`), hue kept. Don't gatekeep.
2. **Hit-target fixes must be invisible** — visual size/padding of an element
   never changes; reach 44pt via transparent hit padding, un-clamped
   `BaseIconButton`, or `HitTestBehavior.translucent`. If a fix would bloat the
   element, skip it (drag-strip 44pt skipped for exactly this reason).
3. New **`destructive` / `destructiveText`** slots on `AppStatusColors` (+ an
   `info` slot) are the canonical error/action reds; `unreachable` is for
   reachability states only.
4. Chat brand-text fixes landed now (accent grammar); the **brand-fill
   strategy is deferred** to the Phase-4 chat-bar frame.
5. Paywall hero keeps the bolt glyph + "OBS Blade Pro" headline (the v12
   wordmark change was deliberately not ratified).

## A wave — shell + shared kit (24 commits)

**A1 — theme wiring + functional bugs**

- `filter_list.dart` self-comparison bug (always-true filter check) fixed.
- `routing_helper.dart` brace misplacement fixed.
- Dialog padding swap bug fixed; settings switcher key collision fixed;
  theme-name validation now renders (was computed but never shown).
- `AppStatusColors` gained `destructive`, `destructiveText`, `info`; all
  error-red call sites unified off `colorScheme.error` / raw `Colors.red*`.
- `cupertinoOverrideTheme.primaryColor` fixed (Cupertino chrome picked the
  wrong accent on Material 3 themes).
- `textSelection` handles → `highlight` slot; `bodySmall` captions →
  `textSecondary` slot; dead `de_DE` locale entries swept.
- Tab switch motion moved to tokens; theme crossfade on `AppMotion.slow` with
  reduced-motion gate.

**A2 — shared kit hygiene**

- `press_flash` dispose-after-deactivate crash fixed (red test → green).
- `BaseButton` ghost variant honors an explicit `color:`.
- `BaseIconButton` spring derivation (press physics from motion tokens).
- `AppGlass` applied in `ModalHandler` (sheets join the floating-chrome family).
- `StatusDot` ambient mode + `pulsing` flag; dead code/params removed;
  `TagBox` pill; kit-wide token hygiene.

## B wave — per-area polish (parallel agents, 26 commits landed here)

**B1 — navigation chrome.** Both sub-page nav-bar wrappers migrated to
`GlassBar` (55pt + specular hairline, blur on floating layers only — matches
the ratified "restrained Liquid Glass" rule).

**B2 — chat.** Sheet chrome family: drag handles, pane-to-pane transitions,
accent CTA grammar; device-code dialogs (tile contrast, auth-state morph,
green token); `highlightText` for chat links/CTAs; status-change pulse;
caption section style; **neutral Mod chip** (static role badges don't spend
the highlight); **LIVE viewer count on `CountUpText`** (white count, tweened
on poll) next to a `LIVE · ` label.

**B3 — dashboard.** Streaming cockpit gets unified floating chrome; health
pill is stale-aware + count-up; audio slider peak-hold meter tick + motion
tokens; `AnimatedCrossFade` reveals + staggered entrances on scene
items/audio lists; transition picker on `BaseDropdown`; toasts anchor below
the full status app bar; invisible 44pt hit floors (eye/filter/mute/Close);
`scene_content_mobile` raw-accent tab indicator fixed; dead `media_inputs`
stub + `visibility_edit_toggle` deleted.

**B4 — home/intro/pro.** Connect button morphs (and disables while
connecting); saved connections capped at the 640 content column; QR scan
haptic on success; refresh pill spins while autodiscovery runs; intro tour
icons on `DecorativeIconTile`, worm dots neutral; pro paywall:
reduced-motion-gated confetti, staged entrances, squircle hero, GlassBar
insets, per-card pricing stagger.

**B5 — statistics/settings.** 44pt hit floors restored (pagination, order
rows); filter fields on raised-card decoration; ON/OFF chip intrinsic width;
chart reduced-motion draw-in + hairline scrub guide; stat detail responsive +
count-up grid + nav-bar star; logs press grammar + `BaseResult` empty state;
support dialog: inline store error with retry, count-up tip total,
ambient-gated skeleton; theme editor: caption-above-card sections, named
color channels, theme-name validation; **tap-to-copy version stamp** in
About.

**Gate fix.** `AdaptiveDialogAction` destructive style now falls back to
`AppStatusColors.standard` when the extension isn't registered (test themes);
add-chat-sheet LIVE-chip assertions updated for the CountUpText split.

## Test debt paid in-wave

- add_chat_sheet: LIVE chip assertions now target the keyed chip's label +
  count descendants (the single `LIVE · N` RichText is gone by design).
- Statistics view test kept green (unrelated flake in one parallel full-suite
  run did not reproduce serially).

## Known leftovers (Gate-3 input)

- `BaseDropdown` hint slot doesn't exist yet (transition picker works around).
- Scene-preview **drag strip can't reach 44pt invisibly** — skipped per
  calibration 2.
- Carousel dots are not unified across intro/paywall (both neutral now;
  different geometries).
- Vendored app bar still 56pt (GlassBar wrappers are 55pt + hairline).
- Digit-roll (odometer) treatment and the chat-bar brand-fill frame are
  **Phase-4** items by decision.
- Follow-up sweep (landed as `refactor(chat): wave follow-ups`): reduce gate
  inside `chatImageFadeIn`; dead `kChatViewerCountColor` removed; last
  `.unreachable`-as-destructive leftovers moved to the destructive slots;
  add-chat lock/check icons on `highlightText`.

## Machine note (this box)

`/tmp` is a 3.8G tmpfs. A full `flutter test` leaves `flutter_tools.*` dirs
behind; if it fills up, the kernel compiler fails with "Free up space" and
the tool **hangs silently** instead of exiting. `rm -rf /tmp/flutter_tools.*`
between runs if a test run wedges.
