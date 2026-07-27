# Upgrade plan

Goal: modern Flutter + packages on `chore/flutter-deps-upgrade`; ship only with
data-safety checks (see `persistence-risk.md`).

## Status (2026-07-25)

| Item | Status |
|---|---|
| Flutter on host | **3.44.8** / Dart **3.12.2** (`~/flutter`) |
| Branch | `chore/flutter-deps-upgrade` |
| SDK constraint | `^3.12.0` |
| Hive → Hive CE | Done + foundation fixtures + open/cold-open tests |
| Analyze | **0 errors** (deprecation infos remain) |
| Package majors | Largely bumped (see below) |

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
| + webview / wakelock / image_picker / path_provider / … | current minors |

**Still watch:** `freezed` resolves to `3.2.6-dev.1` (analyzer clash with `hive_ce_generator`).

## Open after last session

See [`session-handoff.md`](session-handoff.md). Chat Phase 0 done; Phase 1 (native
Twitch) needs credentials. All upgrade-branch work still local/uncommitted.

## Do not run

- `flutter run` / device E2E on this NAS host.
