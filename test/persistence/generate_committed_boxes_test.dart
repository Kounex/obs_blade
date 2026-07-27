import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'fixtures/foundation_data.dart';
import 'support/hive_test_harness.dart';

/// Regenerates committed on-disk Hive boxes used by cold-open tests.
///
/// Only runs when explicitly requested so normal `flutter test` does not
/// rewrite binary fixtures:
///   GENERATE_HIVE_FIXTURES=1 flutter test test/persistence/generate_committed_boxes_test.dart
void main() {
  final shouldGenerate = Platform.environment['GENERATE_HIVE_FIXTURES'] == '1';

  test('write foundation data into test/persistence/fixtures/boxes', () async {
    if (!shouldGenerate) {
      // ignore: avoid_print
      print('Skipping fixture generation (set GENERATE_HIVE_FIXTURES=1 to run).');
      return;
    }

    final outDir = Directory('test/persistence/fixtures/boxes');
    if (outDir.existsSync()) {
      outDir.deleteSync(recursive: true);
    }
    outDir.createSync(recursive: true);

    final harness = HiveTestHarness(outDir);
    await harness.init();
    await harness.seed(HiveFoundationData());
    await harness.close();

    final files = outDir
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .where((n) => n.endsWith('.hive'))
        .toList()
      ..sort();

    expect(files, isNotEmpty);
    expect(files, contains('saved-connections.hive'));
    expect(files, contains('past-stream-data.hive'));
    expect(files, contains('settings.hive'));
  });
}
