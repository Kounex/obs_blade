# Persistence risk (Hive → Hive CE)

Live installs hold years of local data. **Wrong typeIds or field indices =
silent/corrupt reads for hundreds of thousands of users.**

## Invariants (do not change casually)

- Box names: `HiveKeys` (`lib/types/enums/hive_keys.dart`)
- Type IDs: `TypeIDs` (`lib/models/type_ids.dart`) — **0–12**
- `@HiveField` indices on every model/enum under `lib/models/`
- Adapter registration in `main.dart` `_initializeHive` (manual list kept;
  `lib/hive_registrar.g.dart` is also generated — do not dual-register)

## Hive CE migration (done on upgrade branch)

- Deps: `hive_ce`, `hive_ce_flutter`, `hive_ce_generator`
- Imports: `package:hive_ce/hive.dart`, `package:hive_ce_flutter/hive_flutter.dart`
- Kept `@HiveType` / `@HiveField` (no `GenerateAdapters` yet)
- Regenerated adapters; **field index sets + typeIds match** pre-migration
  fixtures in `docs/fixtures/pre-hive-ce-adapters/*.fixture`
- Unit guard: `test/persistence/` (foundation seed, cold reopen, CE boxes,
  classic→CE open)
- Regenerate CE boxes: `GENERATE_HIVE_FIXTURES=1 flutter test test/persistence/generate_committed_boxes_test.dart`
- Classic writer: `tool/classic_hive_writer/` → `fixtures/classic_boxes/`
  (see `docs/hive-ce-source-audit.md`)

## Before any store release

- Classic→CE fixture open is covered in CI/local tests; still do a **device**
  open of a long-lived install before shipping. Analyze alone is not enough.
- Resume context for the next agent: [`session-handoff.md`](session-handoff.md).

## Red flags

- Renumbering `TypeIDs` / reusing an ID
- Removing/renaming `@HiveField` without read-compat
- Changing enum HiveField ordinals
- Registering adapters twice (manual + `Hive.registerAdapters()`)
