# Upgrade plan

Goal: modern Flutter + packages; ship only with
data-safety checks (see `persistence-risk.md`).

## Status (2026-07-27 — batch merged to `master`)

| Item | Status |
|---|---|
| Flutter on host | **3.44.8** / Dart **3.12.2** (maintainer headless host), 3.44.0 (workstation) |
| Branch | `chore/flutter-deps-upgrade` **merged to `master` 2026-07-27**, deleted |
| SDK constraint | `^3.12.0` |
| Hive → Hive CE | Done + foundation fixtures + open/cold-open tests + **device proof** |
| Analyze | **0 errors** (deprecation infos remain) |
| Package majors | Largely bumped (see below) |
| iOS E2E | Simulator + real OBS + real-device install verified (macOS workstation) |
| Android | **Not yet built/tested** — deferred, do before store release |

## Persistence tests

```bash
flutter test test/persistence/
# regenerate committed boxes after changing foundation data:
GENERATE_HIVE_FIXTURES=1 flutter test test/persistence/generate_committed_boxes_test.dart
```

Foundation data: `test/persistence/fixtures/foundation_data.dart`  
Committed boxes: `test/persistence/fixtures/boxes/*.hive`

## Notable dependency moves

| Was | Now |
|---|---|
| hive / hive_flutter | hive_ce / hive_ce_flutter |
| qr_code_scanner | qr_code_scanner_plus |
| get_it ^7 | ^9 |
| fl_chart ^0.69 | ^1 |
| flutter_slidable ^3 | ^4 |
| smooth_page_indicator ^1 | ^2 |
| intl ^0.19 | ^0.20 |
| connectivity_plus ^6 | ^7 |
| network_info_plus ^6 | ^8 |
| package_info_plus ^8 | ^10 |
| share_plus ^10 | ^13 |
| keyboard_actions ^4.2.0 | ^4.2.1 (4.2.0 fails to compile on Flutter 3.44: `SemanticsConfiguration.isFocused` is now `bool?`; fixed upstream in 4.2.1 — surfaced on the first simulator build) |
| + webview / wakelock / image_picker / path_provider / … | current minors |

**Still watch:** `freezed` resolves to `3.2.6-dev.1` (analyzer clash with
`hive_ce_generator`). **Decision (2026-07-27):** accept the `-dev` resolve for
this batch — dependency resolution follows the dev route for now; re-check on
a future pass, expected to resolve itself as upstream releases catch up.

## Open after last session

See [`session-handoff.md`](session-handoff.md). Chat Phase 0 done; Phase 1 (native
Twitch) needs credentials. **Before store release:** Android build/test +
version/build-number bump. Upgrade branch merged to `master` 2026-07-27.

## Do not run

- `flutter run` / device E2E on headless clones (GUI-less hosts are for
  `pub get` / `analyze` / unit tests only).
