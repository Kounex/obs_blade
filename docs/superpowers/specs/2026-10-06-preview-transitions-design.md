# Scene preview transitions — design

2026-10-06 · status: **Experiment** (branch `feature/preview-transitions`).

## Problem

User request: the dashboard scene preview cuts instantly on a scene switch,
while OBS plays the configured transition. The preview is a loop of
`GetSourceScreenshot` reads of the program **scene** (one in flight,
`DashboardStore._requestPreviewImage`), so it can never contain a
mid-transition frame - we have to play the transition ourselves.

## Facts (verified against source + OBS 32.2.2 / obs-websocket 5.7.4)

- `GetSourceScreenshot` only takes inputs and scenes
  (`RequestHandler_Sources.cpp:181`); a transition by name is "not found"
  (probe, code 600). No request screenshots the program output / a canvas.
- **`CurrentProgramSceneChanged` fires at the END of an animated
  transition**: OBS emits `SCENE_CHANGED` from `TransitionStopped`, wired to
  `transition_video_stop` (`frontend/widgets/OBSBasic_Transitions.cpp`).
  Probe, 1000 ms Swipe: `SceneTransitionStarted` +3 ms,
  `SceneTransitionVideoEnded` + `CurrentProgramSceneChanged` +1016 ms,
  `SceneTransitionEnded` +1032 ms. Cut: all within ~20 ms.
- `SceneTransitionStarted` carries only `transitionName` / `transitionUuid`
  - but of the transition really running (obs-websocket hooks every
  transition's signals, `EventHandler.cpp`), i.e. overrides included.
- **`GetCurrentProgramScene` sent at `SceneTransitionStarted` already
  returns the incoming scene** (probe; `obs_frontend_get_current_scene`
  reads the frontend's current / program scene, set before the transition
  starts).
- `GetCurrentSceneTransition.transitionSettings` leaves defaults out
  (`ObsDataToJson(..., includeDefault = false)`). Only the *current*
  transition's settings are readable at all.
- Per-scene override: `GetSceneSceneTransitionOverride` → name + duration
  (`null` = OBS default **300 ms**, `GetOverrideTransitionDuration`).
- Built-in kinds and their render math (`plugins/obs-transitions`):

| Kind | Look | Settings (default) |
|---|---|---|
| `cut_transition` | swap | - |
| `fade_transition` | lerp(a, b, t), linear t | - |
| `fade_to_color_transition` | a → color (smoothstep 0..sp), color → b (smoothstep sp..1) | `color` (0xFF000000, ABGR int), `switch_point` (50 %) |
| `swipe_transition` | one image moves over the other, `cubic_ease_in_out` | `direction` (left), `swipe_in` (false) |
| `slide_transition` | both move, `cubic_ease_in_out` | `direction` (left) |
| `wipe_transition` | luma mask threshold with softness | `luma_image` (`linear-h.png`), `luma_softness` (0.03), `luma_invert` (false) |
| `obs_stinger_transition` | video on top (a private ffmpeg source of the transition - never in a scene screenshot), scenes swap at `transition_point` | `transition_point` (ms, or frames with `tp_type` 1) |

## Decisions (user, 2026-10-06)

- On by default, Settings → Dashboard toggle.
- Luma Wipe: bundle OBS's masks (`assets/luma_wipes/`, GPL-2.0-or-later,
  app is GPLv3) + a fragment shader with OBS's math.
- Stinger: cut at the transition point.
- Unknown kinds (Move, shader plugins, ...): crossfade over the duration.

## Design

1. **Frames are tagged** with the scene they were requested for (one
   screenshot in flight, so the in-flight scene name is the tag).
2. **`PreviewTransitionTracker`** (pure Dart) decides per frame: show it,
   hold it (a transition is known to be starting but not yet resolved), or
   start a transition from the last shown frame. A scene change without a
   transition context (reconnect, collection switch, studio preview pick)
   cuts as before.
3. **Context sources:** an app switch (`setActiveSceneName`) opens one with
   the target known; `SceneTransitionStarted` names the transition and, for
   switches from elsewhere, triggers a scoped `GetCurrentProgramScene` that
   also moves `activeSceneName` to the incoming scene right away (scene
   tiles + items follow at the start of the transition like for app taps,
   instead of after it).
4. **Spec resolution** (store): kind from `availableTransitions`, settings
   from a per-name cache (fed by every `GetCurrentSceneTransition`, re-read
   at each start), duration = override duration if the override names this
   transition, else the current duration when it is the current one, else
   the last measured Started→VideoEnded time, else the current duration.
5. **Timing:** the animation starts when the first incoming frame is
   decoded and runs the full duration (the preview lags OBS by about one
   frame anyway). Stinger: cut at `startedAt + transition_point`, not
   before the first incoming frame. Hold at most 400 ms, then cut.
6. **Rendering:** `ScenePreviewImage` keeps the live `Image.memory`
   underneath and paints an overlay (old frame frozen, incoming frame live)
   with `PreviewTransitionPainter`; luma wipe via `shaders/luma_wipe.frag`.
   Reduce-motion → cut.

## Left out

- T-bar / manual transitions (no duration; would need cursor polling).
- Fade to black (program scene doesn't change - nothing to animate).
- Quick-transition durations (studio-mode buttons) unknown until measured once.
- Other canvases' previews (`CanvasViewStore` loop) - no program concept.
- Settings of a non-current transition (no request) → kind defaults.
