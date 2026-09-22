import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/kick_chat_notice_visibility.dart';

import '../persistence/support/hive_test_harness.dart';

void main() {
  group('kickChatNoticeCategory', () {
    test('classifies by id prefix; clear and unknown ids are null', () {
      expect(
        kickChatNoticeCategory('system-sub-1'),
        KickChatNoticeCategory.subsAndGifts,
      );
      expect(
        kickChatNoticeCategory('system-gift-1'),
        KickChatNoticeCategory.subsAndGifts,
      );
      expect(
        kickChatNoticeCategory('system-host-1'),
        KickChatNoticeCategory.hosts,
      );
      expect(kickChatNoticeCategory('system-clear-1'), isNull);
      expect(kickChatNoticeCategory('regular-message-id'), isNull);
    });
  });

  group('isKickChatNoticeVisible', () {
    late Directory tempDir;
    late HiveTestHarness harness;
    Box settingsBox() => Hive.box(HiveKeys.Settings.name);

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'kick_chat_notice_visibility_test',
      );
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

    test('defaults to visible and respects category toggles', () {
      final box = settingsBox();
      expect(isKickChatNoticeVisible(box, 'system-sub-1'), isTrue);
      box.put(SettingsKeys.KickChatNoticeSubs.name, false);
      expect(isKickChatNoticeVisible(box, 'system-sub-1'), isFalse);
      expect(isKickChatNoticeVisible(box, 'system-gift-1'), isFalse);
      expect(isKickChatNoticeVisible(box, 'system-host-1'), isTrue);
      box.put(SettingsKeys.KickChatNoticeHosts.name, false);
      expect(isKickChatNoticeVisible(box, 'system-host-1'), isFalse);
    });

    test('/clear and unrecognized ids are always visible', () {
      final box = settingsBox();
      box.put(SettingsKeys.KickChatNoticeSubs.name, false);
      box.put(SettingsKeys.KickChatNoticeHosts.name, false);
      expect(isKickChatNoticeVisible(box, 'system-clear-1'), isTrue);
      expect(isKickChatNoticeVisible(box, 'regular-message-id'), isTrue);
    });
  });
}
