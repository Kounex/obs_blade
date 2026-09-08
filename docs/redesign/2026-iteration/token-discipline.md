# Token discipline sweep — 2026-09 audit input

## Hardcoded colors (outside lib/shared/design)
- Total: 211 (excl. Colors.transparent)
- Hotspots:
  - 28 — lib/views/dashboard/widgets/obs_widgets/stream_chat/chat_notice_chrome.dart
  - 14 — lib/views/dashboard/widgets/obs_widgets/stream_chat/youtube_chat_message_row.dart
  - 11 — lib/views/dashboard/widgets/obs_widgets/stream_chat/chat_message_display.dart
  - 9 — lib/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_window.dart
  - 8 — lib/views/statistics/statistic_detail/statistic_detail.dart
  - 6 — lib/views/statistics/widgets/stats_entry/stats_entry.dart
  - 6 — lib/views/settings/custom_theme/widgets/color_picker/color_picker.dart
  - 6 — lib/views/dashboard/widgets/dashboard_content/scene_preview/scene_preview.dart
  - 5 — lib/views/dashboard/widgets/obs_widgets/stream_chat/dialogs/channel_mod_sheet.dart
  - 4 — lib/views/dashboard/widgets/status_app_bar/on_air_status_cluster.dart
  - 4 — lib/views/dashboard/widgets/obs_widgets/stream_chat/youtube_setup_sheet.dart
  - 4 — lib/views/dashboard/widgets/obs_widgets/stream_chat/dialogs/mod_action_sheet.dart
  - 4 — lib/views/dashboard/widgets/dashboard_content/scene_buttons/scene_button.dart
  - 4 — lib/views/dashboard/widgets/dashboard_content/exposed_controls/recording_controls.dart
  - 4 — lib/shared/general/base/card.dart

## Ad-hoc durations
- Total: 41 Duration(milliseconds…) outside app_motion.dart

## Ad-hoc curves
- Total: 16 Curves.* outside app_motion.dart

## Ad-hoc radii
- Total: 87 BorderRadius.* outside lib/shared/design
