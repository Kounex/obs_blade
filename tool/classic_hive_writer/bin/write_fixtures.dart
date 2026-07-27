import 'dart:io';

import 'package:classic_hive_writer/adapters.dart';
import 'package:classic_hive_writer/foundation.dart';
import 'package:classic_hive_writer/models.dart';
import 'package:hive/hive.dart';

/// Writes foundation boxes with **classic hive 2.2.3** only.
///
/// Usage (from repo root):
///   dart run --define=out=...  (or)
///   cd tool/classic_hive_writer && dart run bin/write_fixtures.dart [outDir]
Future<void> main(List<String> args) async {
  final outDir = Directory(
    args.isNotEmpty
        ? args.first
        : '../../test/persistence/fixtures/classic_boxes',
  );

  if (outDir.existsSync()) {
    outDir.deleteSync(recursive: true);
  }
  outDir.createSync(recursive: true);

  Hive.init(outDir.absolute.path);
  registerAllClassicAdapters();

  final data = ClassicFoundationData();

  Future<void> fill<T>(String name, List<T> items) async {
    final box = await Hive.openBox<T>(name);
    await box.clear();
    await box.addAll(items);
    await box.flush();
    await box.close();
  }

  await fill(BoxNames.savedConnections, data.connections);
  await fill(BoxNames.pastStreamData, data.pastStreams);
  await fill(BoxNames.pastRecordData, data.pastRecords);
  await fill(BoxNames.customTheme, data.themes);
  await fill(BoxNames.hiddenScene, data.hiddenScenes);
  await fill(BoxNames.hiddenSceneItem, data.hiddenSceneItems);
  await fill(BoxNames.appLog, data.appLogs);
  await fill(BoxNames.purchasedTip, data.purchasedTips);
  await fill(BoxNames.hotkey, data.hotkeys);

  final settings = await Hive.openBox(BoxNames.settings);
  await settings.clear();
  await settings.putAll(data.settings);
  await settings.flush();
  await settings.close();

  await Hive.close();

  final files = outDir
      .listSync()
      .whereType<File>()
      .map((f) => f.uri.pathSegments.last)
      .where((n) => n.endsWith('.hive'))
      .toList()
    ..sort();

  stdout.writeln(
      'classic hive 2.2.3 wrote ${files.length} boxes → ${outDir.absolute.path}');
  for (final f in files) {
    stdout.writeln('  $f');
  }
}
