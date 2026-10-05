import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/stores/views/chat_history.dart';
import 'package:obs_blade/types/classes/kick/kick_chat_message.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/classes/youtube/youtube_chat_message.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';

import '../persistence/support/hive_test_harness.dart';

ChatMessageEvent twitchMessage(String id, String chatterId) => ChatMessageEvent(
  broadcasterUserId: 'b1',
  chatterUserId: chatterId,
  chatterUserLogin: 'login-$chatterId',
  chatterUserName: 'Name$chatterId',
  messageId: id,
  message: ChatMessageText(
    text: 'msg $id',
    fragments: [ChatMessageFragment(type: 'text', text: 'msg $id')],
  ),
);

YouTubeChatMessage youTubeMessage(String id, String authorId) =>
    YouTubeChatMessage(
      id: id,
      snippet: YouTubeChatMessageSnippet(
        type: YouTubeChatMessageType.textMessage,
        liveChatId: 'chat-1',
        authorChannelId: authorId,
        publishedAt: DateTime.utc(2026, 10, 5),
        hasDisplayContent: true,
        displayMessage: 'msg $id',
        textMessageDetails: YouTubeTextMessageDetails(messageText: 'msg $id'),
      ),
      authorDetails: YouTubeChatAuthorDetails(
        channelId: authorId,
        channelUrl: '',
        displayName: 'Name$authorId',
        profileImageUrl: '',
      ),
    );

KickChatMessage kickMessage(String id, int senderId) => KickChatMessage(
  id: id,
  chatroomId: 42,
  content: 'msg $id',
  createdAt: DateTime.utc(2026, 10, 5),
  sender: KickChatSender(id: senderId, username: 'user-$senderId'),
);

void main() {
  group('ChatHistoryStore', () {
    test('feed then query per platform returns chronological full models', () {
      final store = ChatHistoryStore();
      final twitch = twitchMessage('t1', 'u1');
      final youtube = youTubeMessage('y1', 'c1');
      final kick = kickMessage('k1', 7);

      store.record(
        platform: ChatHistoryPlatform.twitch,
        channelKey: 'b1',
        authorKey: 'u1',
        message: twitch,
      );
      store.record(
        platform: ChatHistoryPlatform.youtube,
        channelKey: 'Some Channel',
        authorKey: 'c1',
        message: youtube,
      );
      store.record(
        platform: ChatHistoryPlatform.kick,
        channelKey: 'some-slug',
        authorKey: '7',
        message: kick,
      );
      store.record(
        platform: ChatHistoryPlatform.twitch,
        channelKey: 'b1',
        authorKey: 'u1',
        message: twitchMessage('t2', 'u1'),
      );

      final twitchHistory = store.historyFor(
        platform: ChatHistoryPlatform.twitch,
        channelKey: 'b1',
        authorKey: 'u1',
      );
      expect(twitchHistory.map((e) => e.message), [twitch, isNotNull]);
      expect(
        twitchHistory.map((e) => (e.message as ChatMessageEvent).messageId),
        ['t1', 't2'],
      );
      expect(identical(twitchHistory.first.message, twitch), isTrue);
      expect(
        store
            .historyFor(
              platform: ChatHistoryPlatform.youtube,
              channelKey: 'Some Channel',
              authorKey: 'c1',
            )
            .single
            .message,
        same(youtube),
      );
      expect(
        store
            .historyFor(
              platform: ChatHistoryPlatform.kick,
              channelKey: 'some-slug',
              authorKey: '7',
            )
            .single
            .message,
        same(kick),
      );

      /// Wrong channel / wrong author / wrong platform: nothing.
      expect(
        store.historyFor(
          platform: ChatHistoryPlatform.twitch,
          channelKey: 'other',
          authorKey: 'u1',
        ),
        isEmpty,
      );
      expect(
        store.historyFor(
          platform: ChatHistoryPlatform.twitch,
          channelKey: 'b1',
          authorKey: 'u2',
        ),
        isEmpty,
      );
      expect(
        store.historyFor(
          platform: ChatHistoryPlatform.kick,
          channelKey: 'b1',
          authorKey: 'u1',
        ),
        isEmpty,
      );
      expect(store.length, 4);
      expect(
        store.countFor(
          platform: ChatHistoryPlatform.twitch,
          channelKey: 'b1',
          authorKey: 'u1',
        ),
        2,
      );
    });

    test('tombstone snapshot rides the entry', () {
      final store = ChatHistoryStore();
      store.record(
        platform: ChatHistoryPlatform.twitch,
        channelKey: 'b1',
        authorKey: 'u1',
        message: twitchMessage('t1', 'u1'),
        tombstone: const ChatHistoryTombstone(
          isDeleted: true,
          marker: ' -Timed out (10m)',
          actor: 'Cool_Mod',
        ),
      );

      final entry = store
          .historyFor(
            platform: ChatHistoryPlatform.twitch,
            channelKey: 'b1',
            authorKey: 'u1',
          )
          .single;
      expect(entry.tombstone.isDeleted, isTrue);
      expect(entry.tombstone.marker, ' -Timed out (10m)');
      expect(entry.tombstone.actor, 'Cool_Mod');
    });

    test('clearChannel drops only that channel', () {
      final store = ChatHistoryStore();
      store.record(
        platform: ChatHistoryPlatform.twitch,
        channelKey: 'b1',
        authorKey: 'u1',
        message: twitchMessage('t1', 'u1'),
      );
      store.record(
        platform: ChatHistoryPlatform.twitch,
        channelKey: 'b2',
        authorKey: 'u1',
        message: twitchMessage('t2', 'u1'),
      );
      store.record(
        platform: ChatHistoryPlatform.kick,
        channelKey: 'b1',
        authorKey: 'u1',
        message: kickMessage('k1', 1),
      );

      store.clearChannel(ChatHistoryPlatform.twitch, 'b1');

      expect(store.length, 2);
      expect(
        store.historyFor(
          platform: ChatHistoryPlatform.twitch,
          channelKey: 'b1',
          authorKey: 'u1',
        ),
        isEmpty,
      );
      expect(
        store.historyFor(
          platform: ChatHistoryPlatform.twitch,
          channelKey: 'b2',
          authorKey: 'u1',
        ),
        hasLength(1),
      );

      /// Same key string on another platform survives.
      expect(
        store.historyFor(
          platform: ChatHistoryPlatform.kick,
          channelKey: 'b1',
          authorKey: 'u1',
        ),
        hasLength(1),
      );
    });

    test('clearPlatform drops only that platform; clearAll empties', () {
      final store = ChatHistoryStore();
      store.record(
        platform: ChatHistoryPlatform.twitch,
        channelKey: 'b1',
        authorKey: 'u1',
        message: twitchMessage('t1', 'u1'),
      );
      store.record(
        platform: ChatHistoryPlatform.youtube,
        channelKey: 'L',
        authorKey: 'c1',
        message: youTubeMessage('y1', 'c1'),
      );

      store.clearPlatform(ChatHistoryPlatform.twitch);
      expect(store.length, 1);
      expect(
        store.historyFor(
          platform: ChatHistoryPlatform.twitch,
          channelKey: 'b1',
          authorKey: 'u1',
        ),
        isEmpty,
      );
      expect(
        store.historyFor(
          platform: ChatHistoryPlatform.youtube,
          channelKey: 'L',
          authorKey: 'c1',
        ),
        hasLength(1),
      );

      store.clearAll();
      expect(store.length, 0);
      expect(
        store.historyFor(
          platform: ChatHistoryPlatform.youtube,
          channelKey: 'L',
          authorKey: 'c1',
        ),
        isEmpty,
      );
    });

    test(
      'global FIFO eviction at the cap drops the oldest across platforms '
      'and keeps the author index consistent',
      () {
        const cap = 1000;
        final store = ChatHistoryStore(cap: cap);

        /// Platforms cycle i % 3, authors i % 50, channels i % 5: the
        /// first 1000 records (message-0 … message-999) must be gone once
        /// 2000 total are in, regardless of who recorded them.
        for (var i = 0; i < cap + 1000; i++) {
          final platform = switch (i % 3) {
            0 => ChatHistoryPlatform.twitch,
            1 => ChatHistoryPlatform.youtube,
            _ => ChatHistoryPlatform.kick,
          };
          store.record(
            platform: platform,
            channelKey: 'chan-${i % 5}',
            authorKey: 'author-${i % 50}',
            message: 'message-$i',
          );
        }

        expect(store.length, cap);

        /// The FIFO cut: entries with i < 1000 are gone, everything later
        /// retained, indexed under the right (platform, channel, author).
        /// One pass builds the expectation; then compare index contents.
        final expected = <String, Set<String>>{};
        for (var i = 1000; i < cap + 1000; i++) {
          final platform = switch (i % 3) {
            0 => ChatHistoryPlatform.twitch,
            1 => ChatHistoryPlatform.youtube,
            _ => ChatHistoryPlatform.kick,
          };
          expected
              .putIfAbsent(
                '${platform.name}|chan-${i % 5}|author-${i % 50}',
                () => <String>{},
              )
              .add('message-$i');
        }
        var actualTotal = 0;
        for (final platform in ChatHistoryPlatform.values) {
          for (var channel = 0; channel < 5; channel++) {
            for (var author = 0; author < 50; author++) {
              final entries = store.historyFor(
                platform: platform,
                channelKey: 'chan-$channel',
                authorKey: 'author-$author',
              );
              actualTotal += entries.length;
              final key = '${platform.name}|chan-$channel|author-$author';
              expect(
                entries.map((e) => e.message).toSet(),
                expected[key] ?? <String>{},
                reason: key,
              );
              expect(
                store.countFor(
                  platform: platform,
                  channelKey: 'chan-$channel',
                  authorKey: 'author-$author',
                ),
                entries.length,
              );
            }
          }
        }
        expect(actualTotal, cap);

        /// Recording one more evicts message-1000 (the oldest retained).
        store.record(
          platform: ChatHistoryPlatform.kick,
          channelKey: 'chan-0',
          authorKey: 'author-0',
          message: 'message-tail',
        );
        expect(store.length, cap);
        expect(
          store
              .historyFor(
                platform: ChatHistoryPlatform.twitch,
                channelKey: 'chan-0',
                authorKey: 'author-0',
              )
              .map((e) => e.message),
          isNot(contains('message-1000')),
        );
      },
    );
  });

  group('ChatHistoryStore cap', () {
    test('defaults to 50k when no settings box/value exists', () {
      /// This group opens no Hive box - the persisted lookup misses.
      final store = ChatHistoryStore();
      expect(store.cap, kChatHistoryCapDefault);
      expect(kChatHistoryCapDefault, 50000);
    });

    test('lowering the cap trims the oldest immediately, index included',
        () {
      /// The setter clamps to [kChatHistoryCapMin], so the trim path is
      /// exercised inside the real range (the constructor seam covers
      /// the small-number mechanics in the FIFO test above).
      final store = ChatHistoryStore(cap: 12000);
      for (var i = 0; i < 12000; i++) {
        store.record(
          platform: ChatHistoryPlatform.twitch,
          channelKey: 'chan-${i % 3}',
          authorKey: 'author-${i % 10}',
          message: 'message-$i',
        );
      }
      expect(store.length, 12000);

      store.cap = 10000;

      expect(store.cap, 10000);
      expect(store.length, 10000);

      /// Only message-2000 … message-11999 survive, still indexed per
      /// (channel, author).
      var actualTotal = 0;
      for (var channel = 0; channel < 3; channel++) {
        for (var author = 0; author < 10; author++) {
          final entries = store.historyFor(
            platform: ChatHistoryPlatform.twitch,
            channelKey: 'chan-$channel',
            authorKey: 'author-$author',
          );
          actualTotal += entries.length;
          for (final entry in entries) {
            final id = int.parse(
              (entry.message as String).substring('message-'.length),
            );
            expect(id, greaterThanOrEqualTo(2000));
            expect(id % 3, channel);
            expect(id % 10, author);
          }
        }
      }
      expect(actualTotal, 10000);
    });

    test('raising the cap un-gates growth without touching the rows', () {
      final store = ChatHistoryStore(cap: 10000);
      for (var i = 0; i < 11000; i++) {
        store.record(
          platform: ChatHistoryPlatform.kick,
          channelKey: 'slug',
          authorKey: 'author-${i % 5}',
          message: 'message-$i',
        );
      }
      expect(store.length, 10000);

      store.cap = 20000;
      expect(store.length, 10000);

      for (var i = 11000; i < 21000; i++) {
        store.record(
          platform: ChatHistoryPlatform.kick,
          channelKey: 'slug',
          authorKey: 'author-${i % 5}',
          message: 'message-$i',
        );
      }
      expect(store.length, 20000);
    });

    test('the setter clamps to the 10k … 200k range', () {
      final store = ChatHistoryStore(cap: 100);
      store.cap = 5;
      expect(store.cap, kChatHistoryCapMin);
      expect(store.length, lessThanOrEqualTo(kChatHistoryCapMin));
      store.cap = 999999;
      expect(store.cap, kChatHistoryCapMax);
      store.cap = 50000;
      expect(store.cap, 50000);
    });

    test('memory estimate matches the spike anchors', () {
      expect(chatHistoryEstimatedMb(10000), 13);
      expect(chatHistoryEstimatedMb(50000), 64);
      expect(chatHistoryEstimatedMb(100000), 128);
      expect(chatHistoryEstimatedMb(200000), 256);
    });
  });

  group('ChatHistoryStore persisted cap', () {
    late Directory tempDir;
    late HiveTestHarness harness;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('chat_history_cap_test');
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

    test('honored when set, clamped when out of range', () async {
      await Hive.box(
        HiveKeys.Settings.name,
      ).put(SettingsKeys.ChatHistoryCap.name, 120000);
      expect(ChatHistoryStore().cap, 120000);

      await Hive.box(
        HiveKeys.Settings.name,
      ).put(SettingsKeys.ChatHistoryCap.name, 5000);
      expect(ChatHistoryStore().cap, kChatHistoryCapMin);

      await Hive.box(
        HiveKeys.Settings.name,
      ).put(SettingsKeys.ChatHistoryCap.name, 999999);
      expect(ChatHistoryStore().cap, kChatHistoryCapMax);
    });

    test('falls back to the default on a missing/foreign value', () async {
      expect(ChatHistoryStore().cap, kChatHistoryCapDefault);
      await Hive.box(
        HiveKeys.Settings.name,
      ).put(SettingsKeys.ChatHistoryCap.name, 'not-an-int');
      expect(ChatHistoryStore().cap, kChatHistoryCapDefault);
    });
  });
}
