import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/enums/chat_engine.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';

import '../persistence/support/hive_test_harness.dart';

void main() {
  group('ChatEngine', () {
    test('has a label per engine', () {
      expect(ChatEngine.webView.text, 'WebView');
      expect(ChatEngine.native.text, 'Native');
    });

    test('native engine is available for Twitch only', () {
      expect(nativeChatAvailableFor(ChatType.Twitch), isTrue);
      expect(nativeChatAvailableFor(ChatType.YouTube), isFalse);
      expect(nativeChatAvailableFor(ChatType.Owncast), isFalse);
    });
  });

  group('SelectedChatEngine persistence', () {
    late Directory tempDir;
    late HiveTestHarness harness;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('chat_engine_test');
      harness = HiveTestHarness(tempDir);
      await harness.init();
      await Hive.openBox(HiveKeys.Settings.name);
    });

    tearDown(() async {
      await harness.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('missing key falls back to the WebView default at read time', () {
      expect(
        Hive.box(HiveKeys.Settings.name).get(
              SettingsKeys.SelectedChatEngine.name,
              defaultValue: ChatEngine.webView,
            ),
        ChatEngine.webView,
      );
    });

    test('round-trips through the Settings box and survives a cold open',
        () async {
      final settings = Hive.box(HiveKeys.Settings.name);
      await settings.put(
          SettingsKeys.SelectedChatEngine.name, ChatEngine.native);
      expect(settings.get(SettingsKeys.SelectedChatEngine.name),
          ChatEngine.native);

      await harness.reopenFromDisk();

      expect(
        Hive.box(HiveKeys.Settings.name)
            .get(SettingsKeys.SelectedChatEngine.name),
        ChatEngine.native,
      );
    });
  });
}
