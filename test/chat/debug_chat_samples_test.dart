import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/stores/views/twitch_badges.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/debug_chat_samples.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_twitch_services.dart';

void main() {
  group('debugChatSamples', () {
    test('covers the gif, power-up, and shared-chat sample shapes', () {
      final samples = debugChatSamples();

      expect(samples, hasLength(3));
      expect(samples[0].event.message.fragments[1].type, 'gif');
      expect(samples[0].event.message.fragments[1].gif, isNotNull);
      expect(
        samples[1].event.messageType,
        'power_ups_gigantified_emote',
      );
      expect(samples[2].event.sourceBroadcasterUserName, isNotNull);
      expect(samples[2].event.sourceBroadcasterUserId, isNotNull);
    });

    test('message ids are unique across calls', () {
      final first = debugChatSamples();
      final second = debugChatSamples();

      expect(
        first[0].event.messageId,
        isNot(second[0].event.messageId),
      );
    });
  });

  group('TwitchChatStore.debugInjectMessage', () {
    late Directory tempDir;
    late HiveTestHarness harness;
    late TwitchChatStore store;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('debug_inject_test');
      harness = HiveTestHarness(tempDir);
      await harness.init();
      store = TwitchChatStore(
        authService: FakeTwitchAuthService(),
        eventSubFactory: (_, __, ___, ____, _____, ______, _______, ________) =>
            FakeTwitchEventSubService(),
        badgeStoreResolver: () =>
            TwitchBadgeStore(service: FakeTwitchBadgeService()),
      );
    });

    tearDown(() async {
      await store.dispose();
      await harness.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('appends the sample, stamping channel and arrival time', () {
      store.selectedChannelId = 'chan-1';
      final sample = debugChatSamples()[2].event;

      store.debugInjectMessage(sample);

      expect(store.messages, hasLength(1));
      final injected = store.messages.single;
      expect(injected.messageId, sample.messageId);
      expect(injected.broadcasterUserId, 'chan-1');
      expect(injected.receivedAt, isNotNull);
      expect(injected.sourceBroadcasterUserName, isNotNull);
    });
  });
}
