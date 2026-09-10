# Business logic and migration seams

Paths are relative to repository root. Symbols are preferred over fragile line
numbers. Reviewed from the master base in [README](README.md), 2026-09-10.
Generated `.g.dart` files establish serialization/reactivity but are not edit seams.

## Domain and infrastructure

| Behavior | Source and symbols | Migration implication |
|---|---|---|
| DI / persistence initialization | `lib/main.dart`: `_initializeStores`, `_initializeHive`; `lib/models/type_ids.dart`; `lib/types/enums/{hive_keys,settings_keys}.dart` | Keep registrations, box strings, field IDs and enum adapters stable. Isolated fake entrypoint must not open production data. |
| Endpoint acquisition | `lib/stores/views/home.dart`: `HomeStore`, `ConnectMode`, `updateAutodiscoverConnections`; `lib/utils/network_helper.dart`: `getAvailableOBSIPs`, URI helpers | Recompose discovery/QR/manual/saved choices; retain endpoint validation and ws/wss behavior. |
| Handshake / session | `lib/stores/shared/network.dart`: `NetworkStore.setOBSWebSocket`, `closeSession`, message pump; `lib/types/classes/connection_attempt_result.dart` | Session exists before identified; expose explicit readiness/failure. Preserve auth, timeout and close-code distinctions. |
| OBS synchronization / retry | `lib/stores/views/dashboard.dart`: `DashboardStore.initialRequests`, `_checkOBSConnection`, OBS event/response handling | Preserve one owner, reconnect refresh, collection-change suspension and lifecycle cleanup. Keep the intentional store monolith. |
| Commands / response routing | `lib/utils/network_helper.dart`: `makeRequest`, `makeBatchRequest`; `DashboardStore._obsRequestSucceeded` | Calls return void; failed responses are logged. No existing caller acknowledgement contract. Do not infer success from dispatch. |
| History sampling | `DashboardStore._manageStreamDataInit`, `_manageRecordDataInit`, finish methods and stats-response handling; `lib/models/{past_stream_data,past_record_data}.dart` | Observed telemetry, reconnect stitching and short-session removal require semantic regression checks. |
| Chat transport / capabilities | `lib/stores/views/{twitch_chat,youtube_chat}.dart`: `init`, `connectChat`, `selectChannel`, `sendChatMessage`, moderation actions | Preserve channel buffers, OAuth capability checks, poll cancellation, send failure and event reconciliation. Stores do not enforce the presentation Pro gate. |
| Engine availability | `lib/models/enums/chat_engine.dart`: `nativeChatAvailableFor` | Platform support is separate from entitlement and account readiness. |
| Entitlement | `lib/stores/pro_store.dart`: `ProStore.isPro`, `init`, buy/restore; `lib/utils/pro_ids.dart`; `test/pro/custom_theme_unlock_test.dart` | Preserve RC truth/offline mirror, legacy restore and Blacksmith custom-theme ownership. Store approval/pricing is not verified by source comments. |

## Product policy currently inside presentation

| Location | Actual product behavior to extract/preserve | Incidental presentation |
|---|---|---|
| `lib/views/home/home.dart`: `HomeView.initState` | Discovery refresh, connect results, authentication recovery, successful-session transition | Route identity, overlays and save-prompt placement |
| `lib/views/home/widgets/connect_box/quick_connect/qr_scan.dart`: `_connectionFromQR` | Parse OBS Connect Info endpoint/password, camera permission and scan completion | Scanner route, delayed dismissal and feedback layout |
| `lib/views/dashboard/dashboard.dart`: lifecycle | Store initialization/reset, wakelock, unsaved-connection prompt, terminated-session handling, screenshot response, disposal | Widget mount as session owner; tab/column arrangement |
| `lib/views/dashboard/widgets/dashboard_content/scene_buttons/scene_button.dart` | Program/preview command target, optimistic local selection, local hide editing | Tile shape, animation and tap multiplexing |
| `lib/views/dashboard/widgets/dashboard_content/studio_mode_transition_button.dart` | Current code sets program optimistically and sends `SetCurrentProgramScene` | Label must not be assumed to prove a dedicated OBS studio-transition operation |
| `lib/views/dashboard/widgets/dashboard_content/scene_content/scene_items/scene_item_tile.dart` | Source-enable command uses parent group when applicable | Tile and trailing action layout |
| `lib/views/dashboard/widgets/dashboard_content/scene_content/audio_inputs/audio_slider.dart` | Mute, volume, sync offset requests | Slider arrangement, dialogs and icon placement |
| `lib/views/dashboard/services/record_stream.dart`: `RecordStreamService` | Independent start/stop stream/record confirmation preferences and commands | Modal choice |
| `lib/views/dashboard/widgets/status_app_bar/general_actions.dart` | Replay, virtual camera and screenshot operations | Overflow-menu grouping |
| `lib/views/dashboard/widgets/obs_widgets/stream_chat/stream_chat.dart` | Engine/URL dispatch, WebView reuse, readiness mapping, draft/focus, account and Pro gate presentation | Hard-coded gesture bounds, panel location and dialog composition |
| `lib/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_input.dart`: `_submit` | Trim/reject empty, serialize submissions, keep failed draft, clear on success | Input container styling |
| `lib/views/dashboard/widgets/obs_widgets/stream_chat/native_twitch_chat_view.dart` | Pause autoscroll, return live, message actions/reveals | Pixel threshold and message composition |
| `lib/views/statistics/statistics.dart`: `_sortPastStatsData`, `_filterPastStatsData` | Filtering/sorting policy presently lives in widget | Separate latest sections; reset on rebuild |
| `lib/views/statistics/statistic_detail/statistic_detail.dart` | Name/favorite/delete writes | Detail route and edit dialogs |
| `lib/views/settings/settings.dart` | Immediate settings writes and route-dependent wakelock update | Section grouping and control type |
| `lib/views/settings/data_management/data_management.dart`: `deleteAllUserDataPreservingEntitlements` | Destructive data operations and retained purchase flags | Navigation back to introduction after reset |
| `lib/tab_base.dart` | Back-stack retention and Android back handling | Tab count, nested routes, retap-to-root behavior |

Confirm exact widget paths with `rg --files` before edits; narrow seams can move as
the project progresses. UI components should receive state and intents, not read
arbitrary GetIt services or Hive boxes themselves.

## Validation evidence and gaps

- `test/websocket/handshake_helpers_test.dart`: auth hash, subscriptions, URI,
  result messages and close codes. This does not verify full reconnect lifecycle
  or command acknowledgements.
- `test/persistence/hive_classic_to_ce_test.dart` and
  `test/persistence/hive_committed_fixtures_test.dart`: persistence compatibility.
- `test/chat/`: transport, input, moderation, emotes and reconciliation cases.
  Examples: `automod_queue_sheet_test.dart`, `channel_bans_sheet_test.dart`,
  `twitch_chat_store_test.dart`.
- `test/pro/`: entitlements, paywall, restore, custom-theme access and deletion
  preserving purchase flags. Delete-all tests do not establish all-box coverage.

Before integration, add focused contract tests for explicit readiness, stale
state, program/preview targets, grouped-source commands and ownership on exit.
Prototype simulations must distinguish dispatch from confirmation even before
the production command interface can supply acknowledgements.
