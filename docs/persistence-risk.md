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

### Device-proof procedure (agreed 2026-07-27)

1. **Backup (makes it reversible):** Xcode → Devices and Simulators → iPhone
   → OBS Blade → gear → **Download Container** (`.xcappdata` = full Documents,
   incl. classic-Hive boxes). Rollback = **Replace Container**, never a plain
   reinstall.
2. **Simulator rehearsal (zero phone risk):** run the new build on a
   simulator, quit, swap its `Documents/*.hive` with the boxes from the
   downloaded container, relaunch → verify connections, settings, theme, chat
   usernames, dashboard order, past stream/record stats. This is the
   real-data classic→CE open.
3. **Phone upgrade (only after 2 is clean):** upgrade install preserves data
   only with **same bundle ID + same signing team** as the installed app
   (different team → iOS forces delete → data loss). Install the new build
   over the existing app, open, verify, connect to OBS once.
4. **No downgrade after CE writes:** once the CE build wrote frames, going
   back to the classic build is untested — use the container backup instead.

## Red flags

- Renumbering `TypeIDs` / reusing an ID
- Removing/renaming `@HiveField` without read-compat
- Changing enum HiveField ordinals
- Registering adapters twice (manual + `Hive.registerAdapters()`)
