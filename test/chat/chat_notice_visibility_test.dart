import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_notice_visibility.dart';

import '../persistence/support/hive_test_harness.dart';

void main() {
  group('chatNoticeCategory', () {
    test('maps known notice types into toggle categories', () {
      expect(chatNoticeCategory('sub_gift'), ChatNoticeCategory.subs);
      expect(chatNoticeCategory('shared_chat_resub'), ChatNoticeCategory.subs);
      expect(chatNoticeCategory('watch_streak'), ChatNoticeCategory.streaks);
      expect(chatNoticeCategory('raid'), ChatNoticeCategory.raids);
      expect(
        chatNoticeCategory('announcement'),
        ChatNoticeCategory.announcements,
      );
      expect(chatNoticeCategory('bits_badge_tier'), ChatNoticeCategory.bitsBadge);
      expect(chatNoticeCategory('charity_donation'), ChatNoticeCategory.charity);
      expect(chatNoticeCategory('modiversary'), ChatNoticeCategory.modiversary);
      expect(chatNoticeCategory('something_new'), ChatNoticeCategory.other);
    });
  });

  group('isChatNoticeTypeVisible', () {
    late Directory tempDir;
    late HiveTestHarness harness;
    Box settingsBox() => Hive.box(HiveKeys.Settings.name);

    setUp(() async {
      tempDir =
          await Directory.systemTemp.createTemp('chat_notice_visibility_test');
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
      expect(isChatNoticeTypeVisible(box, 'sub_gift'), isTrue);
      box.put(SettingsKeys.TwitchChatNoticeSubs.name, false);
      expect(isChatNoticeTypeVisible(box, 'sub_gift'), isFalse);
      expect(isChatNoticeTypeVisible(box, 'watch_streak'), isTrue);
      box.put(SettingsKeys.TwitchChatNoticeStreaks.name, false);
      expect(isChatNoticeTypeVisible(box, 'watch_streak'), isFalse);
    });

    test('first-message chrome defaults on and can be disabled', () {
      final box = settingsBox();
      expect(isChatFirstMessageVisible(box), isTrue);
      box.put(SettingsKeys.TwitchChatNoticeFirstMessage.name, false);
      expect(isChatFirstMessageVisible(box), isFalse);
    });
  });
}
