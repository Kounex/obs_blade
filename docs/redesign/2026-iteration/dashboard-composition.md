# Connected dashboard composition — verified against code (2026-09-08)

Source: code audit for the 4.0 mockup phase. Governs mockups and the
redesign implementation. Entry: `lib/views/dashboard/dashboard.dart:155-203`
(`CustomScrollView`: `StatusAppBar` + `DashboardContent`, or
`DashboardContentStreaming` when Streaming Mode is on).

## One view, many states

The connected view is a single screen whose content is an **ordered list
of composable elements** (`DashboardElement` enum,
`lib/models/enums/dashboard_element.dart`, Hive typeId 12). Users reorder
it (Settings → Customisation → Elements Order → `ReorderableListView`,
persisted to `SettingsKeys.DashboardElementsOrder`); toggles gate some
elements. It is NOT multiple views.

## Element inventory

| Element (UI name) | Always-on? | Toggle (settings key) | Default |
|---|---|---|---|
| Scene Buttons (tile grid) | always | — | — |
| Scene Items | always | — | — |
| Scene Audio | always | — | — |
| Chat | always | — | — |
| Stats | always | — | — |
| Scene Preview | toggle | `ExposeScenePreview` | **on** |
| Studio Mode Config (checkbox + transition dropdown/ms row) | toggle* | `ExposeStudioControls` gates ONLY the checkbox; the transition row always renders with the element | off |
| Profiles / Scene Collections card | toggle | `ExposeProfile` / `ExposeSceneCollection` (either shows the card) | off |
| Controls card (streaming/recording/replay/hotkeys) | toggle | `ExposeStreamingControls` / `ExposeRecordingControls` / `ExposeReplayBufferControls` / `ExposeHotkeys` — card renders if ≥1 on | all off |
| Studio Mode Transition button | runtime | shown when `ExposeStudioControls` AND OBS studio mode active | — |

Not reorderable, part of the view: `StatusAppBar` (incl. stream/record
actions when Controls card off, Edit Scene Visibility mode),
`ReconnectToast`.

## Composition rules

- **Pairing** (`dashboard_element_layout.dart:24-95`): when `SceneItems`
  + `SceneItemsAudio` are adjacent in the order → one combined block:
  phone = tabbed ("Scene Items"/"Audio"), tablet = side-by-side cards.
  Same for `StreamChat` + `OBSStats` (phone tabs, tablet side-by-side).
  Separated members render as standalone full-width cards in list order.
- **Streaming Mode** (`StreamingMode`, default off) swaps the whole body
  to `DashboardContentStreaming` (resizable preview, horizontal 64px
  scene buttons, full-height chat); order/exposure toggles ignored.
- **Studio mode runtime state**: scene-button taps set the preview scene,
  PGM/PVW tally tags on tiles; Transition button appears.
- **Edit Scene Visibility** mode (app-bar menu): grid shows hidden scenes
  with eye badges; hidden scenes/items persist in Hive boxes.
- **Chat body** varies (platform empty states; native engine gated behind
  Pro upsell; WebView free) — the Chat element itself is always present.
- Pointer over Chat disables outer scroll (`dashboard.dart:173`).

Mockup consequence: one "Scenes" mockup in default order, ideally with an
interactive composition panel (toggles + reorder) to demonstrate states.
