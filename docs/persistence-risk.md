# Persistence risk (Hive → Hive CE)

Live installs hold years of local data. **Wrong typeIds or field indices =
silent/corrupt reads for hundreds of thousands of users.**

## Invariants (do not change casually)

- Box names: `HiveKeys` (`lib/types/enums/hive_keys.dart`)
- Type IDs: `TypeIDs` (`lib/models/type_ids.dart`) — **0–16**
- `@HiveField` indices on every model/enum under `lib/models/`
- Adapter registration in `main.dart` `_initializeHive` (manual list kept;
  `lib/hive_registrar.g.dart` is also generated — do not dual-register)

## Hive CE migration — shipped 2026-07, device-verified

The classic-Hive → Hive CE migration shipped 2026-07 and was verified on a
real long-lived install (read + write proven); the regenerated adapters'
field index sets + typeIds were checked against pre-migration fixtures and
match. Audit evidence:
[`archive/hive-ce-source-audit.md`](archive/hive-ce-source-audit.md).

- Deps: `hive_ce`, `hive_ce_flutter`, `hive_ce_generator`; kept `@HiveType` /
  `@HiveField` (no `GenerateAdapters` yet)
- Unit guard: `test/persistence/` (foundation seed, cold reopen, CE boxes,
  classic→CE open)
- Regenerate CE boxes: `GENERATE_HIVE_FIXTURES=1 flutter test test/persistence/generate_committed_boxes_test.dart`
- Classic writer: `tool/classic_hive_writer/` → `fixtures/classic_boxes/`
- Caveat: **debug builds crash on cold launch from the home screen** (null
  registrar → first plugin `register` SIGSEGV,
  [flutter#149214](https://github.com/flutter/flutter/issues/149214)) — use
  **profile/release** builds for on-device testing.

## Red flags

- Renumbering `TypeIDs` / reusing an ID
- Removing/renaming `@HiveField` without read-compat
- Changing enum HiveField ordinals
- Registering adapters twice (manual + `Hive.registerAdapters()`)
