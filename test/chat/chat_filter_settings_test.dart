import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/dialogs/mod_action_sheet.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_appearance.dart';

import '../persistence/support/hive_test_harness.dart';

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  Box box() => Hive.box(HiveKeys.Settings.name);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('chat_filter_test');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);
  });

  tearDown(() async {
    await harness.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('ChatFilterSettings', () {
    test('ignored users are always hidden', () async {
      await box().put(SettingsKeys.ChatIgnoredUsers.name, 'spammer');
      final filters = ChatFilterSettings.of(box());
      expect(filters.hides(['Spammer'], 'hi'), isTrue);
      expect(filters.hides(['viewer'], 'hi'), isFalse);
    });

    test('mute words hide by default, censor in replace mode', () async {
      await box().put(SettingsKeys.ChatMuteWords.name, 'spoiler');
      var filters = ChatFilterSettings.of(box());
      expect(filters.hides(['viewer'], 'big spoiler'), isTrue);
      expect(filters.display('big spoiler'), 'big spoiler');

      await box().put(SettingsKeys.ChatMuteReplace.name, true);
      filters = ChatFilterSettings.of(box());
      expect(filters.hides(['viewer'], 'big spoiler'), isFalse);
      expect(filters.display('big spoiler'), 'big ***');
    });
  });

  testWidgets('message sheet toggles the ignore list', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showMessageActionSheet(
                context,
                authorName: 'Viewer',
                messageText: 'hi',
                userListName: 'viewer',
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Highlight viewer'), findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(find.text('Ignore viewer'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();

    expect(box().get(SettingsKeys.ChatIgnoredUsers.name), 'viewer');
    expect(find.text('Hiding messages from viewer'), findsOneWidget);
  });
}
