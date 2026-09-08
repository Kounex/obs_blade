# Motion audit — 2026-09 audit input

Output of the `improve-animations` advisor pass (standard effort), scoped to
the existing animation/motion code: `lib/shared/design/`, `lib/shared/animator/`,
`AnimatedTheme`, `AnimatedSwitcher`, and `AnimationController` usages across
`lib/`. Read-only: no source was modified and no `plans/` directory was
created — this wave's hard rule limits writes to the two audit docs, so the
top findings carry plan-grade detail inline below instead of separate plan
files.

## Recon

- **Stack**: Flutter, MobX + GetIt. No motion libraries — everything is
  hand-rolled (design-system.md forbids Lottie/Rive): `AnimationController`,
  `AnimatedSwitcher`, implicit animated widgets, one `fl_chart` draw-in.
- **Motion tokens** (`lib/shared/design/app_motion.dart`): `instant` 80ms /
  `fast` 150ms / `medium` 250ms / `slow` 400ms / `dramatic` 700ms;
  `staggerStep` 30ms, `staggerMax` 12; curves `standard` easeOutCubic,
  `emphasized` Cubic(0.2, 0, 0, 1), `spring` easeOutBack, `exit` easeInCubic.
  Token adoption is already broad; the findings below are the holdouts.
- **Personality**: crisp broadcast utility. Cohesion findings are judged
  against that, not against a playful-consumer bar.
- **Frequency map**: dashboard controls (scene buttons, mute, sliders,
  tabs) = tens-to-hundreds/day; chat timeline = 100+/day; dialogs, sheets,
  toasts, refresh = occasional; connect/purchase/intro = rare.
- **Settled decisions (not findings)**: scene-button selection fill bound to
  the real OBS transition duration (design-system.md:24); tab-switch 200ms
  fade+scale around the IndexedStack (`lib/tab_base.dart:191-263`, documented
  navigator-preservation tradeoff); `FullOverlay` spring scale 0.96→1.0 and
  250ms timing ("keep timing", design-system.md:101); modal dialogs stay
  centered. The `Fader` build side-effect the design doc flagged is already
  fixed (timers moved to `initState`, `lib/shared/animator/fader.dart:42-56`).

## Findings

Ordered by leverage (impact ÷ effort). Every finding was re-read and
confirmed at its cited file:line.

| # | Severity | Category | Location | Finding | Fix summary |
| --- | --- | --- | --- | --- | --- |
| 1 | HIGH | Physicality / easing | `lib/shared/animator/full_overlay.dart:44-47` | The overlay's blur and opacity tweens use `Curves.easeIn` on **entrance**. Ease-in starts slow at exactly the moment the user is watching; this widget caps every connect/purchase flow, so the sluggish head on the curve is felt app-wide at the highest-emotion moments. | Change both `CurvedAnimation`s to `curve: AppMotion.standard` (easeOutCubic) with `reverseCurve: Curves.easeInCubic` (`AppMotion.exit`) so exits accelerate away. Keep the 0.96→1.0 `AppMotion.spring` scale and the 250ms duration — both are the settled design contract. |
| 2 | HIGH | Easing & duration | `lib/views/dashboard/widgets/dashboard_content/studio_mode_transition_button.dart:37-53` | Dashboard chrome animating with `Curves.easeInQuad` (twice) at an ad-hoc 200ms. Ease-in on entering UI plus an off-token duration. | Use `duration: AppMotion.medium` (250ms), `curve: AppMotion.standard`, `reverseCurve: AppMotion.exit` on both the fade and the `SizeTransition`. (200ms exists as a sanctioned value only for the tab-switch contract.) |
| 3 | HIGH | Correctness (build side-effect) | `lib/views/home/widgets/refresher_app_bar/scroll_refresh_icon.dart:71-84` | `build()` fires haptics (`HapticFeedback.lightImpact()`), mutates the store (`homeStore.setRefreshable(...)`), and drives `_animController.forward()/animateTo()`. Same defect class the design system already fixed in `Fader`; rebuilds can re-trigger haptics and restart animation state. | Move the threshold-crossing logic out of `build()` into `didUpdateWidget` (or a scroll-listener callback), so haptics/store writes/controller drives happen exactly once per crossing, never per frame. |
| 4 | MEDIUM | Accessibility | all of `lib/` (zero matches for `disableAnimations` / `accessibleNavigation`) | No reduced-motion handling anywhere. Perpetual motion (`StatusDot` pulse, `SupportSkeleton` breathing), entrances (`StaggeredEntrance`, tab switch), and the chart draw-in all ignore `MediaQuery.disableAnimations`. | Add a single seam — e.g. an `AppMotion.reduceMotion(context)` helper or a `disableAnimations` check inside `StaggeredEntrance`/`StatusDot`/`SupportSkeleton`/`StatsChart` — that drops movement (rise/scale/pulse/draw) but keeps opacity/color feedback. Gentler, not zero. |
| 5 | MEDIUM | Easing & duration | `lib/views/dashboard/widgets/reconnect_toast.dart:34-55` | Both toast controllers run ad-hoc 500ms with `Curves.easeOut` — over the 300ms UI budget and off-token for an occasional toast. | `duration: AppMotion.medium` (250ms) or `AppMotion.slow` (400ms) with `AppMotion.standard`; the slide `Offset(0, -0.1)` and symmetric reverse are already correct — keep. |
| 6 | MEDIUM | Easing | `lib/tab_base.dart:169-171` | Re-tap scroll-to-top uses `Curves.easeIn` — eases *into* the destination, so the list decelerates into view late. | `curve: AppMotion.standard` (or `Curves.easeOutCubic`); 250ms happens to equal `AppMotion.medium` — use the token. |
| 7 | MEDIUM | Easing & duration | `lib/shared/animator/fader.dart:15-17` | Defaults are `Curves.linear` at an ad-hoc 200ms; linear on an entrance reads mechanical. Used by `ModalHandler.showFullscreen` (modal_handler.dart:33). | Default to `duration: AppMotion.fast` (150ms) / `curve: AppMotion.standard`. |
| 8 | MEDIUM | Easing & duration | `lib/shared/general/flutter_modified/translucent_sliver_app_bar.dart:1165-1168` | Scroll-linked title fade runs 500ms — over budget for a scroll-coupled element. Curve `Cubic(0.2, 0, 0, 1)` is already `AppMotion.emphasized`. | `duration: AppMotion.medium`, `curve: AppMotion.emphasized`. Fork file — keep the diff minimal. |
| 9 | MEDIUM | Performance | `lib/views/dashboard/widgets/dashboard_content/scene_content/audio_inputs/audio_slider.dart:145-163` | The live dB fill is an `AnimatedContainer` animating **width** (layout property) at 50ms — effectively a layout pass per meter update, per input. | Swap to a full-width fill clipped by `FractionallySizedBox`/`Align(widthFactor:)` or a `Transform.scaleX` (alignment: centerLeft) so the meter animates on the compositor. The 200ms `AnimatedPositioned` peak tick (:168-185) is the same class at lower cost — fix together if touched. |
| 10 | LOW | Interruptibility | `lib/shared/animator/order_button.dart:49-62, 74-87` | The sort toggle blocks re-triggering while animating (`!isAnimating` guard) instead of retargeting mid-motion; two chained controllers + reset-in-`then` is fragile (both `onTap` and `didUpdateWidget` drive the same controllers). | Acceptable as-is at this frequency; if touched, collapse to one controller driven solely by `didUpdateWidget(order)` so a rapid double-tap reverses from the current value. |
| 11 | LOW | Cohesion & tokens | `lib/shared/animator/selectable_box.dart:25-26, 68` | Ad-hoc defaults (300ms fill / 50ms border). The fill duration is intentionally overridden by scene buttons with the OBS transition duration (settled — don't touch that call site); only the **defaults** are off-token. | Default `boxAnimation` → `AppMotion.medium` (250ms), border → `AppMotion.instant` (80ms). |
| 12 | LOW | Cohesion & tokens | scattered | Residual ad-hoc durations beside the token scale: 500ms (reconnect toast, translucent app bar), 450ms (`animated_result_icon.dart:44` `_kDrawDuration` — deliberate, between `slow` and `dramatic`; keep but document), 4000ms (`status_dot.dart:38` perpetual loop — outside the token scale by nature). | Consolidate 500ms call sites onto tokens (findings 5/8); leave 450ms/4000ms with a comment pointing at `AppMotion`. |

## Missed opportunities (additive)

Deferred to the companion doc — see
`docs/redesign/2026-iteration/animation-opportunities.md`. Top four: (1)
`Pressable` adoption on the five remaining bare-`GestureDetector` taps;
(2) entrance/exit for the chat pause chip; (3) staggered copy after the
Pro-unlock glyph draw; (4) a feedback confirmation after hotkey trigger.

## Plan-grade detail for the top 3 (executor-ready, since `plans/` is out of scope this wave)

**Fix 1 — FullOverlay entrance curve.**
File `lib/shared/animator/full_overlay.dart`. Current, lines 44-47:

```dart
_blur = Tween<double>(begin: 0.0, end: 9.0)
    .animate(CurvedAnimation(curve: Curves.easeIn, parent: _controller));
_opacity = Tween<double>(begin: 0.0, end: 1.0)
    .animate(CurvedAnimation(curve: Curves.easeIn, parent: _controller));
```

Target: both `CurvedAnimation`s become
`CurvedAnimation(parent: _controller, curve: AppMotion.standard, reverseCurve: AppMotion.exit)`.
`AppMotion` is already imported (:7). Do not touch `_scale` (:48-49),
`animationDuration`, or `_closeTimer`. Feel check: run a connect flow; the
overlay should arrive decisively (fast head, soft settle) and leave with a
slightly accelerating fade. Spam-connect must not restart the entrance.

**Fix 2 — StudioModeTransitionButton curves/duration.**
File `lib/views/dashboard/widgets/dashboard_content/studio_mode_transition_button.dart`.
Current: `duration: const Duration(milliseconds: 200)` (:37),
`Curves.easeInQuad` (:44, :51), `reverseCurve: Curves.easeOutQuad` (:46, :52).
Target: `duration: AppMotion.medium`; fade and size curves
`curve: AppMotion.standard, reverseCurve: AppMotion.exit`; drop the
`Interval(0.4, 1.0, ...)` fade lag (the delayed fade is what makes the button
feel late). Add the design import if absent. Feel check: toggle studio mode;
the Transition button should grow and fade together, immediately.

**Fix 3 — ScrollRefreshIcon build side-effects.**
File `lib/views/home/widgets/refresher_app_bar/scroll_refresh_icon.dart:71-84`.
Move both threshold-crossing blocks (haptic + `setRefreshable` +
`_animController` drives) into `didUpdateWidget(ScrollRefreshIcon oldWidget)`
guarded on `oldWidget.currentBarHeight != widget.currentBarHeight`, or onto
the scroll listener that owns `currentBarHeight`. `build()` must become
pure. Mechanical check: `flutter analyze` clean. Feel check: pull-to-refresh
repeatedly — exactly one haptic per crossing, no double-fires when the app
bar rebuilds for unrelated reasons.

## Verification notes

- No code was changed in this pass; nothing to run. Implementers of the
  fixes above should run `flutter analyze` plus the suite directory for the
  touched area (per AGENTS.md test-selection), and feel-check at 10%
  animation scale on a real device for Fixes 1–3.
- Feel could not be judged from code alone for: the `Fader` linear→easeOut
  swap inside `showFullscreen` (finding 7) and the audio-meter refactor
  (finding 9). Both carry feel-check steps above rather than guesses.
