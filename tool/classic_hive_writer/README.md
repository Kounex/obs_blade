# classic_hive_writer

Standalone Dart package that depends **only** on classic `hive: 2.2.3`
(no Flutter, no hive_ce). Writes the same foundation dataset as
`test/persistence/fixtures/foundation_data.dart` into on-disk `*.hive` boxes.

Those boxes are then opened by Hive CE in
`test/persistence/hive_classic_to_ce_test.dart` — proving the upgrade path
without a store build.

## Regenerate classic boxes

From this directory:

```bash
dart pub get
dart run bin/write_fixtures.dart ../../test/persistence/fixtures/classic_boxes
```

Hand-ported adapters in `lib/adapters.dart` must stay wire-compatible with
production `*.g.dart` (typeIds 0–12 and field indices).
