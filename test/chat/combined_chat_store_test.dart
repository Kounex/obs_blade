import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/models/kick_auth.dart';
import 'package:obs_blade/models/twitch_auth.dart';
import 'package:obs_blade/models/youtube_auth.dart';
import 'package:obs_blade/stores/views/combined_chat.dart';
import 'package:obs_blade/stores/views/kick_chat.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';
import 'package:obs_blade/stores/views/youtube_chat.dart';
import 'package:obs_blade/types/classes/kick/kick_channel.dart';
import 'package:obs_blade/types/classes/kick/kick_chat_message.dart';
import 'package:obs_blade/types/classes/youtube/youtube_chat_message.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/kick/kick_auth_service.dart';
import 'package:obs_blade/utils/youtube/youtube_auth_service.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_kick_services.dart';
import 'support/fake_twitch_services.dart';
import 'support/fake_youtube_services.dart';

CombinedItem item(ChatType platform, String id, int? second) => CombinedItem(
  platform: platform,
  payload: id,
  at: second == null ? null : DateTime.utc(2026, 9, 24, 12, 0, second),
  key: '${platform.name}:$id',
);

YouTubeChatMessage ytMessage(String id, DateTime at) => YouTubeChatMessage(
  id: id,
  snippet: YouTubeChatMessageSnippet(
    type: YouTubeChatMessageType.textMessage,
    publishedAt: at,
    authorChannelId: 'chan-1',
    displayMessage: 'text $id',
    textMessageDetails: YouTubeTextMessageDetails(messageText: 'text $id'),
  ),
  authorDetails: const YouTubeChatAuthorDetails(
    channelId: 'chan-1',
    displayName: 'User',
  ),
);

KickChatMessage kickMessage(String id, DateTime at) =>
    KickChatMessage(id: id, content: 'kick $id', createdAt: at);

Future<void> until(bool Function() condition) async {
  for (var i = 0; i < 1000 && !condition(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
}

void main() {
  group('mergeCombinedStreams', () {
    test('interleaves streams by time', () {
      final merged = mergeCombinedStreams([
        [item(ChatType.Twitch, 't1', 1), item(ChatType.Twitch, 't2', 4)],
        [item(ChatType.Kick, 'k1', 2), item(ChatType.Kick, 'k2', 3)],
      ]);
      expect(merged.map((i) => i.payload), ['t1', 'k1', 'k2', 't2']);
    });

    test('a stream never reorders itself, even with skewed times', () {
      /// t2 claims an earlier time than t1 (clock skew) - it still stays
      /// behind t1.
      final merged = mergeCombinedStreams([
        [item(ChatType.Twitch, 't1', 5), item(ChatType.Twitch, 't2', 1)],
        [item(ChatType.Kick, 'k1', 3)],
      ]);
      expect(merged.map((i) => i.payload), ['k1', 't1', 't2']);
    });

    test('undated items stay right after their predecessor', () {
      final merged = mergeCombinedStreams([
        [item(ChatType.Twitch, 't1', 1), item(ChatType.Twitch, 'notice', null)],
        [item(ChatType.Kick, 'k1', 2)],
      ]);
      expect(merged.map((i) => i.payload), ['t1', 'notice', 'k1']);
    });

    test('ties keep stream order', () {
      final merged = mergeCombinedStreams([
        [item(ChatType.Twitch, 't1', 1)],
        [item(ChatType.YouTube, 'y1', 1)],
        [item(ChatType.Kick, 'k1', 1)],
      ]);
      expect(merged.map((i) => i.payload), ['t1', 'y1', 'k1']);
    });
  });

  group('CombinedChatStore', () {
    late Directory tempDir;
    late HiveTestHarness harness;
    late TwitchChatStore twitch;
    late YouTubeChatStore youTube;
    late KickChatStore kick;
    late FakeKickChannelService kickChannels;
    late CombinedChatStore store;

    Box settingsBox() => Hive.box(HiveKeys.Settings.name);

    KickChannelInfo kickInfo(String slug, int userId, int chatroomId) =>
        KickChannelInfo(
          id: chatroomId + 100,
          userId: userId,
          slug: slug,
          chatroom: KickChatroom(id: chatroomId),
        );

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('combined_store_test');
      harness = HiveTestHarness(tempDir);
      await harness.init();
      await Hive.openBox(HiveKeys.Settings.name);
      await Hive.openBox<TwitchAuth>(HiveKeys.TwitchAuth.name);
      await Hive.openBox<YouTubeAuth>(HiveKeys.YouTubeAuth.name);
      await Hive.openBox<KickAuth>(HiveKeys.KickAuth.name);

      /// Added channels: Kick 'aaa', YouTube entry 'A' (a video) — both
      /// selected before the combo, so restore has something to put back.
      await settingsBox().put(SettingsKeys.KickUsernames.name, ['aaa']);
      await settingsBox().put(SettingsKeys.YouTubeApiKey.name, 'api-key');
      await settingsBox().put(
        SettingsKeys.YouTubeUsernames.name,
        <String, String>{'A': 'video-a-001'},
      );
      await settingsBox().put(SettingsKeys.SelectedKickUsername.name, 'aaa');
      await settingsBox().put(
        SettingsKeys.SelectedYouTubeNativeChannelId.name,
        'A',
      );

      /// Signed in on Kick ('kicker', verified) and YouTube (own UC id).
      await Hive.box<KickAuth>(HiveKeys.KickAuth.name).put(
        KickAuth.kBoxKey,
        KickAuth(
          accessToken: 'a',
          refreshToken: 'r',
          expiresAtMs: DateTime.now().millisecondsSinceEpoch + 3600000,
          scopes: kKickChatScopes,
          userId: 9001,
          username: 'kicker',
          channelSlug: 'kicker',
        ),
      );
      await Hive.box<YouTubeAuth>(HiveKeys.YouTubeAuth.name).put(
        YouTubeAuth.kBoxKey,
        YouTubeAuth(
          accessToken: 'a',
          refreshToken: 'r',
          expiresAtMs: DateTime.now().millisecondsSinceEpoch + 3600000,
          scopes: kYouTubeChatScopes,
          channelTitle: 'My Channel',
          channelId: 'UCownchannel000000000000',
        ),
      );

      kickChannels = FakeKickChannelService();
      kickChannels.channels['aaa'] = kickInfo('aaa', 1, 42);
      kickChannels.channels['kicker'] = kickInfo('kicker', 9001, 90);
      kick = KickChatStore(
        channelService: kickChannels,
        authService: FakeKickAuthService(),
        apiService: FakeKickApiService(),
        isProResolver: () => true,
        pusherFactory: ({required onEvent, required onStateChanged}) =>
            FakeKickPusherService(
              onEvent: onEvent,
              onStateChanged: onStateChanged,
            ),
        emoteStoreResolver: () => throw StateError('no emotes'),
        kickEmoteStoreResolver: () => throw StateError('no emotes'),
      );
      youTube = YouTubeChatStore(
        authService: FakeYouTubeAuthService(),
        chatService: FakeYouTubeLiveChatService(),
        liveResolver: FakeYouTubeLiveResolver(),

        /// A real (tiny) wait: the own channel has no live stream, so the
        /// store keeps re-checking - an instant sleeper would spin that
        /// loop on microtasks and starve timers and Hive I/O.
        sleep: (_) => Future<void>.delayed(const Duration(milliseconds: 1)),
        isProResolver: () => true,
      );

      /// Signed out: Twitch contributes no source here (its login needs
      /// the device flow - covered by its own store tests).
      twitch = TwitchChatStore(
        authService: FakeTwitchAuthService(),
        isProResolver: () => true,
        eventSubFactory:
            (
              _,
              __,
              ___,
              ____,
              _____,
              ______,
              _______,
              ________,
              _________,
              __________,
            ) => FakeTwitchEventSubService(),
        ircSidecarFactory: (_) => FakeSilentIrcSidecar(),
      );
      await kick.init();
      await youTube.init();

      store = CombinedChatStore(
        twitchStore: () => twitch,
        youTubeStore: () => youTube,
        kickStore: () => kick,
      );
    });

    tearDown(() async {
      await store.deactivate();
      await kick.dispose();
      await youTube.dispose();
      await twitch.dispose();
      await harness.close();
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('"My chats" lists the signed-in own channels only', () {
      expect(store.mySources.map((s) => s.platform), [
        ChatType.YouTube,
        ChatType.Kick,
      ]);
      expect(store.mySources.last.key, 'kicker');
      expect(store.mySources.first.label, 'My Channel');
    });

    test('a switched-off platform leaves the sources and persists', () async {
      await store.setPlatformEnabled(ChatType.Kick, false);

      expect(store.mySources.map((s) => s.platform), [ChatType.YouTube]);
      expect(store.availableSources.length, 2);
      expect(settingsBox().get(SettingsKeys.MyChatsDisabledPlatforms.name), [
        'Kick',
      ]);
    });

    test('activate points each store at the own channel; deactivate '
        'restores the previous selection', () async {
      /// Before: the added channels are what the stores show.
      expect(kick.selectedChannelSlug, 'aaa');
      expect(youTube.selectedChannelLabel, 'A');

      await store.activate();

      expect(store.active, isTrue);
      expect(kick.selectedChannelSlug, 'kicker');
      expect(youTube.selectedChannelLabel, kYouTubeOwnChannelLabel);

      await store.deactivate();

      expect(store.active, isFalse);
      expect(kick.selectedChannelSlug, 'aaa');
      expect(youTube.selectedChannelLabel, 'A');
    });

    test('follows the persisted chat type (bindToChatType)', () async {
      store.bindToChatType();
      expect(store.active, isFalse);

      await settingsBox().put(
        SettingsKeys.SelectedChatType.name,
        ChatType.Combined,
      );
      await until(() => kick.selectedChannelSlug == 'kicker');
      expect(store.active, isTrue);

      await settingsBox().put(
        SettingsKeys.SelectedChatType.name,
        ChatType.Kick,
      );
      await until(() => kick.selectedChannelSlug == 'aaa');
      expect(store.active, isFalse);
      await store.dispose();
    });

    test(
      'the restore point survives a restart while Combined is active',
      () async {
        await store.activate();
        expect(kick.selectedChannelSlug, 'kicker');
        expect(settingsBox().get(SettingsKeys.CombinedChatRestore.name), {
          'YouTube': 'A',
          'Kick': 'aaa',
        });

        /// A fresh store (next launch) that never activated still knows
        /// what to put back once the user leaves Combined.
        final next = CombinedChatStore(
          twitchStore: () => twitch,
          youTubeStore: () => youTube,
          kickStore: () => kick,
        );
        await next.deactivate();

        expect(kick.selectedChannelSlug, 'aaa');
        expect(youTube.selectedChannelLabel, 'A');
        expect(
          settingsBox().get(SettingsKeys.CombinedChatRestore.name),
          isNull,
        );
      },
    );

    test('leaving mid-activation stops selecting and restores', () async {
      /// Deactivate before the first select resolves: no source may be
      /// selected after the restore ran.
      final activating = store.activate();
      await store.deactivate();
      await activating;

      expect(store.active, isFalse);
      expect(kick.selectedChannelSlug, 'aaa');
    });

    test('activate twice keeps the original restore point', () async {
      await store.activate();
      await store.activate();
      await store.deactivate();

      expect(kick.selectedChannelSlug, 'aaa');
    });

    test(
      'timeline interleaves the stores by time with platform tags',
      () async {
        await store.activate();
        await until(
          () => kick.chatConnection == KickChatConnectionState.connected,
        );
        kick.messages
          ..clear()
          ..addAll([
            kickMessage('k1', DateTime.utc(2026, 9, 24, 12, 0, 1)),
            kickMessage('k2', DateTime.utc(2026, 9, 24, 12, 0, 3)),
          ]);
        youTube.messages
          ..clear()
          ..add(ytMessage('y1', DateTime.utc(2026, 9, 24, 12, 0, 2)));

        expect(store.timeline.map((i) => i.key), [
          'kick:k1',
          'youtube:y1',
          'kick:k2',
        ]);
        expect(store.timeline[1].platform, ChatType.YouTube);
      },
    );

    test('status maps each source', () async {
      await store.activate();
      await until(
        () => kick.chatConnection == KickChatConnectionState.connected,
      );

      expect(store.sourceStatus[ChatType.Kick], CombinedSourceStatus.live);

      /// The fake resolver finds no live stream for the own channel.
      await until(() => youTube.awaitingLiveStream);
      expect(
        store.sourceStatus[ChatType.YouTube],
        CombinedSourceStatus.offline,
      );
    });
  });
}
