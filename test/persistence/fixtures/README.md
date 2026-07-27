# Hive persistence fixtures

## Foundation data

`foundation_data.dart` builds a large, self-explanatory dataset for every
persisted model / settings key. Names and values are readable on their own
(e.g. connection `Living Room PC` → host `192.168.1.50`).

## Committed boxes (Hive CE)

`boxes/*.hive` are on-disk Hive files generated from that foundation data
using Hive CE on this branch.

Regenerate after changing models or foundation data:

```bash
GENERATE_HIVE_FIXTURES=1 flutter test test/persistence/generate_committed_boxes_test.dart
```

Cold-open coverage (no seed in the test):

```bash
flutter test test/persistence/hive_committed_fixtures_test.dart
```

## Classic → CE boxes (upgrade proof)

`classic_boxes/*.hive` are written by **classic hive 2.2.3 only**
(`tool/classic_hive_writer/`), then opened under Hive CE:

```bash
cd tool/classic_hive_writer && dart pub get
dart run bin/write_fixtures.dart ../../test/persistence/fixtures/classic_boxes

flutter test test/persistence/hive_classic_to_ce_test.dart
```

Keep classic writer adapters wire-compatible with production `*.g.dart`
(typeIds 0–12 + field indices). Foundation counts/key rows should stay in
sync with `foundation_data.dart`.

## Full suite

```bash
flutter test test/persistence/
```
