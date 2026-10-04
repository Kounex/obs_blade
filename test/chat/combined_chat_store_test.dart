import 'dart:async';
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
import 'package:obs_blade/types/classes/combined/combined_combo.dart';
import 'package:obs_blade/types/classes/kick/kick_channel.dart';
import 'package:obs_blade/types/classes/kick/kick_chat_message.dart';
import 'package:obs_blade/types/classes/twitch/twitch_channel_ref.dart';
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

  /// Reading the sources creates the platform stores, and a created
  /// store starts its own chat - nothing may read them while Combined
  /// isn't the chat on screen (it is created at app start).
  test('bound while another chat type is selected, the platform stores '
      'are never touched', () async {
    final tempDir = await Directory.systemTemp.createTemp('combined_bind');
    final harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);
    await Hive.box(
      HiveKeys.Settings.name,
    ).put(SettingsKeys.SelectedChatType.name, ChatType.Twitch);
    final touched = <ChatType>[];
    Never touch(ChatType type) {
      touched.add(type);
      throw StateError('${type.name} store created');
    }

    final store = CombinedChatStore(
      twitchStore: () => touch(ChatType.Twitch),
      youTubeStore: () => touch(ChatType.YouTube),
      kickStore: () => touch(ChatType.Kick),
    );
    store.bindToChatType();
    await Hive.box(
      HiveKeys.Settings.name,
    ).put(SettingsKeys.SelectedChatType.name, ChatType.Kick);
    await Future<void>.delayed(Duration.zero);

    expect(touched, isEmpty);
    await store.dispose();
    await harness.close();
    tempDir.deleteSync(recursive: true);
  });

  group('CombinedChatStore', () {
    late Directory tempDir;
    late HiveTestHarness harness;
    late TwitchChatStore twitch;
    late YouTubeChatStore youTube;
    late KickChatStore kick;
    late FakeKickChannelService kickChannels;
    late FakeKickApiService kickApi;
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
        apiService: kickApi = FakeKickApiService(),
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

    test('coming back while the restore still runs keeps the original '
        'selections as the restore point', () async {
      /// Signed in on Twitch, watching an added channel; its switches
      /// really await (EventSub), unlike Kick / YouTube.
      final eventSub = FakeTwitchEventSubService();
      await twitch.dispose();
      twitch = TwitchChatStore(
        authService: FakeTwitchAuthService(),
        isProResolver: () => true,
        channelService: FakeTwitchChannelService(),
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
            ) => eventSub,
        ircSidecarFactory: (_) => FakeSilentIrcSidecar(),
      );
      await twitch.startLogin();
      await twitch.addChannel(
        TwitchChannelRef(
          id: 'chan-1',
          login: 'chan1',
          displayName: 'Chan 1',
          addedAt: DateTime.utc(2026, 10, 2),
        ),
      );
      expect(twitch.selectedChannelId, 'chan-1');

      await store.activate();
      expect(twitch.selectedChannelId, isNull);
      expect(kick.selectedChannelSlug, 'kicker');

      /// Leave: the Twitch restore hangs on its EventSub switch ...
      final gate = Completer<void>();
      eventSub.onSwitchChannel = (_) => gate.future;
      final leaving = store.deactivate();
      await pumpEventQueue();

      /// ... and the user comes back before it finished — with Twitch
      /// switched off in "My chats", so the activation reaches YouTube /
      /// Kick while their restores still wait behind Twitch's.
      await store.setPlatformEnabled(ChatType.Twitch, false);
      final back = store.activate();
      await pumpEventQueue();
      gate.complete();
      await Future.wait([leaving, back]);
      eventSub.onSwitchChannel = null;

      /// The stale restore loop stopped: Combined shows the combo.
      expect(store.active, isTrue);
      expect(kick.selectedChannelSlug, 'kicker');
      expect(youTube.selectedChannelLabel, kYouTubeOwnChannelLabel);

      await store.deactivate();
      expect(twitch.selectedChannelId, 'chan-1');
      expect(kick.selectedChannelSlug, 'aaa');
      expect(youTube.selectedChannelLabel, 'A');
    });

    test('leaving mid-activation stops selecting and restores', () async {
      /// Deactivate before the first select resolves: no source may be
      /// selected after the restore ran.
      final activating = store.activate();
      await store.deactivate();
      await activating;

      expect(store.active, isFalse);
      expect(kick.selectedChannelSlug, 'aaa');
    });

    test('a saved combo of other channels registers them on their '
        'platforms and becomes the active sources', () async {
      kickChannels.channels['xqc'] = kickInfo('xqc', 676, 77);
      final combo = CombinedCombo(
        id: 'c1',
        youTube: const CombinedYouTubeSource(label: 'xQc', value: '@xqcow'),
        kickSlug: 'xqc',
      );

      /// Before: neither channel is in its platform's list.
      expect(kick.channels, isNot(contains('xqc')));
      expect(youTube.channels.map((c) => c.label), isNot(contains('xQc')));

      await store.activate();
      await store.saveCombo(combo);

      expect(kick.channels, contains('xqc'));
      expect(youTube.channels.map((c) => c.label), contains('xQc'));
      expect(store.selectedComboId, 'c1');
      expect(store.activeSources.map((s) => s.key), ['xQc', 'xqc']);
      expect(kick.selectedChannelSlug, 'xqc');
      expect(youTube.selectedChannelLabel, 'xQc');
      expect(settingsBox().get(SettingsKeys.SelectedCombinedCombo.name), 'c1');

      /// Leaving Combined still restores the pre-combo selections, not the
      /// "My chats" ones picked in between.
      await store.deactivate();
      expect(kick.selectedChannelSlug, 'aaa');
      expect(youTube.selectedChannelLabel, 'A');
    });

    test('a saved combo with the own YouTube channel opens "You" and adds '
        'no copy to the channel list', () async {
      /// What the builder saves for the own pick: title + channel id
      final combo = CombinedCombo(
        id: 'c-own',
        youTube: const CombinedYouTubeSource(
          label: 'My Channel',
          value: 'UCownchannel000000000000',
          own: true,
        ),
        kickSlug: 'aaa',
      );

      await store.activate();
      await store.saveCombo(combo);

      expect(youTube.channels.map((c) => c.label), ['A']);
      final source = store.activeSources.firstWhere(
        (s) => s.platform == ChatType.YouTube,
      );
      expect(source.key, kYouTubeOwnChannelLabel);
      expect(source.label, 'My Channel');
      expect(source.unavailable, isFalse);
      expect(youTube.selectedChannelLabel, kYouTubeOwnChannelLabel);
      expect(youTube.isViewingOwnChannel, isTrue);

      /// Signed out, the own source can't be shown (it is never an entry)
      /// - the fix is a sign-in
      await youTube.logout();
      final signedOut = store
          .sourcesOf(combo)
          .firstWhere((s) => s.platform == ChatType.YouTube);
      expect(signedOut.unavailable, isTrue);
      expect(signedOut.needsSignIn, isTrue);

      /// ... and using the combo doesn't add it to the list either
      await store.activate();
      expect(youTube.channels.map((c) => c.label), ['A']);
    });

    test('a copy an older build added for a combo goes once the own channel '
        'is known; its selection and restore point move to "You"', () async {
      await youTube.dispose();
      await settingsBox().put(
        SettingsKeys.YouTubeUsernames.name,
        <String, String>{
          'A': 'video-a-001',
          'My Channel': 'UCownchannel000000000000',

          /// Same title, someone else's channel: stays
          'Other': 'UCotherchannel0000000000',
        },
      );
      await settingsBox().put(
        SettingsKeys.SelectedYouTubeNativeChannelId.name,
        'My Channel',
      );
      await settingsBox().put(SettingsKeys.CombinedChatCombos.name, [
        const CombinedCombo(
          id: 'c-own',
          youTube: CombinedYouTubeSource(
            label: 'My Channel',
            value: 'UCownchannel000000000000',
          ),
        ).toJson(),
      ]);
      youTube = YouTubeChatStore(
        authService: FakeYouTubeAuthService(),
        chatService: FakeYouTubeLiveChatService(),
        liveResolver: FakeYouTubeLiveResolver(),
        sleep: (_) => Future<void>.delayed(const Duration(milliseconds: 1)),
        isProResolver: () => true,
      );
      await youTube.init();

      expect(
        Map.of(
          settingsBox().get(SettingsKeys.YouTubeUsernames.name) as Map,
        ).keys,
        unorderedEquals(['A', 'Other']),
      );
      expect(
        youTube.channels.map((c) => c.label),
        unorderedEquals(['A', 'Other']),
      );
      expect(youTube.selectedChannelLabel, kYouTubeOwnChannelLabel);
    });

    test('a combo channel removed from the YouTube list comes back when '
        'the combo is used', () async {
      final combo = CombinedCombo(
        id: 'c1',
        youTube: const CombinedYouTubeSource(label: 'xQc', value: '@xqcow'),
        kickSlug: 'aaa',
      );
      await store.activate();
      await store.saveCombo(combo);
      expect(youTube.channels.map((c) => c.label), contains('xQc'));

      /// Removed from the list (the delete-combo copy says channels stay
      /// in their lists - so users treat them as separate)
      await store.deactivate();
      await settingsBox().put(
        SettingsKeys.YouTubeUsernames.name,
        <String, String>{'A': 'video-a-001'},
      );
      youTube.reloadChannels();

      await store.activate();
      final source = store.activeSources.firstWhere(
        (s) => s.platform == ChatType.YouTube,
      );
      expect(source.unavailable, isFalse);
      expect(youTube.channels.map((c) => c.label), contains('xQc'));
      expect(youTube.selectedChannelLabel, 'xQc');
    });

    test('the cleanup keeps a copy the WebView engine has selected, and '
        'marks the combo source as own', () async {
      await youTube.dispose();
      await settingsBox().put(
        SettingsKeys.YouTubeUsernames.name,
        <String, String>{
          'A': 'video-a-001',
          'My Channel': 'UCownchannel000000000000',
        },
      );
      await settingsBox().put(
        SettingsKeys.SelectedYouTubeUsername.name,
        'My Channel',
      );
      await settingsBox().put(SettingsKeys.CombinedChatCombos.name, [
        const CombinedCombo(
          id: 'c-own',
          youTube: CombinedYouTubeSource(
            label: 'My Channel',
            value: 'UCownchannel000000000000',
          ),
        ).toJson(),
      ]);
      youTube = YouTubeChatStore(
        authService: FakeYouTubeAuthService(),
        chatService: FakeYouTubeLiveChatService(),
        liveResolver: FakeYouTubeLiveResolver(),
        sleep: (_) => Future<void>.delayed(const Duration(milliseconds: 1)),
        isProResolver: () => true,
      );
      await youTube.init();

      expect(
        youTube.channels.map((c) => c.label),
        unorderedEquals(['A', 'My Channel']),
      );
      expect(
        parseCombinedCombos(
          settingsBox().get(SettingsKeys.CombinedChatCombos.name),
        ).single.youTube!.own,
        isTrue,
      );
    });

    test('a manually added own channel without a combo stays', () {
      final own = youTube.ownChannel!;
      expect(
        ownYouTubeComboCopies(
          {'My Channel': 'UCownchannel000000000000'},
          const [],
          own,
        ),
        isEmpty,
      );
      expect(
        ownYouTubeComboCopies(
          {'Renamed': 'UCownchannel000000000000'},
          const [
            CombinedCombo(
              id: 'c',
              youTube: CombinedYouTubeSource(
                label: 'Renamed',
                value: 'UCownchannel000000000000',
              ),
            ),
          ],
          own,
        ),
        isEmpty,
        reason: 'not under the channel title',
      );
    });

    test('combos persist and reload in a fresh store', () async {
      await store.saveCombo(
        const CombinedCombo(id: 'c1', name: 'Co-stream', kickSlug: 'aaa'),
      );

      final next = CombinedChatStore(
        twitchStore: () => twitch,
        youTubeStore: () => youTube,
        kickStore: () => kick,
      );
      await next.selectCombo('c1');

      expect(next.combos.single.displayName, 'Co-stream');
      expect(next.selectedComboId, 'c1');
    });

    test('deleting the shown combo falls back to My chats', () async {
      await store.saveCombo(const CombinedCombo(id: 'c1', kickSlug: 'aaa'));
      expect(store.selectedComboId, 'c1');

      await store.deleteCombo('c1');

      expect(store.combos, isEmpty);
      expect(store.selectedComboId, kMyChatsComboId);
      expect(store.activeSources.map((s) => s.platform), [
        ChatType.YouTube,
        ChatType.Kick,
      ]);

      /// The channel stays in the Kick list.
      expect(kick.channels, contains('aaa'));
    });

    test('a Twitch source while signed out is kept but unavailable', () async {
      await store.saveCombo(
        CombinedCombo(
          id: 'c1',
          twitch: TwitchChannelRef(
            id: '42',
            login: 'someone',
            displayName: 'Someone',
            addedAt: DateTime.utc(2026),
          ),
          kickSlug: 'aaa',
        ),
      );

      final twitchSource = store.activeSources.first;
      expect(twitchSource.platform, ChatType.Twitch);
      expect(twitchSource.unavailable, isTrue);
      expect(
        store.sourceStatus[ChatType.Twitch],
        CombinedSourceStatus.needsSetup,
      );
    });

    test('focus keeps the combo, pauses YouTube; ↩ Combined resumes', () async {
      store.bindToChatType();
      await settingsBox().put(
        SettingsKeys.SelectedChatType.name,
        ChatType.Combined,
      );
      await until(() => kick.selectedChannelSlug == 'kicker');
      await until(
        () => youTube.chatConnection != YouTubeChatConnectionState.idle,
      );
      expect(youTube.pollingPaused, isFalse);

      store.focus(ChatType.Kick);
      await until(() => youTube.pollingPaused);

      /// Still the combo's channel on Kick, no restore ran.
      expect(store.focusedPlatform, ChatType.Kick);
      expect(store.active, isTrue);
      expect(kick.selectedChannelSlug, 'kicker');
      expect(youTube.pollingPaused, isTrue);
      expect(youTube.chatConnection, YouTubeChatConnectionState.idle);

      store.returnToCombined();
      await until(() => !youTube.pollingPaused);

      expect(store.focusedPlatform, isNull);
      expect(youTube.selectedChannelLabel, kYouTubeOwnChannelLabel);
      await store.dispose();
    });

    test('a real type switch after a focus jump still restores', () async {
      store.bindToChatType();
      await settingsBox().put(
        SettingsKeys.SelectedChatType.name,
        ChatType.Combined,
      );
      await until(() => kick.selectedChannelSlug == 'kicker');

      store.focus(ChatType.Kick);
      await until(() => store.focusedPlatform == ChatType.Kick);
      await until(() => youTube.pollingPaused);

      /// From the focused Kick view the user picks YouTube in the type
      /// dropdown - that's leaving Combined.
      await settingsBox().put(
        SettingsKeys.SelectedChatType.name,
        ChatType.YouTube,
      );
      await until(() => kick.selectedChannelSlug == 'aaa');

      expect(store.active, isFalse);
      expect(store.focusedPlatform, isNull);
      expect(youTube.selectedChannelLabel, 'A');
      expect(youTube.pollingPaused, isFalse);
      await store.dispose();
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

    test('a scrolled-up reader anchors the merged cut and holds every '
        'platform buffer; release puts the caps back', () async {
      await store.activate();
      await until(
        () => kick.chatConnection == KickChatConnectionState.connected,
      );
      kick.messages
        ..clear()
        ..addAll([
          for (var i = 0; i < 600; i++)
            kickMessage(
              'k$i',
              DateTime.utc(2026, 9, 24, 12).add(Duration(seconds: i)),
            ),
        ]);
      expect(store.timeline, hasLength(500));

      store.holdScrollback();

      /// Rows cut off before the hold don't come back above the reader
      /// (that jumped the list); new ones land below
      expect(store.timeline, hasLength(500));
      expect(store.timeline.first.key, 'kick:k100');
      kick.messages.add(
        kickMessage('k600', DateTime.utc(2026, 9, 24, 12, 10, 0)),
      );
      expect(store.timeline, hasLength(501));
      expect(store.timeline.first.key, 'kick:k100');
      expect(twitch.messageCap.holding, isTrue);
      expect(youTube.messageCap.holding, isTrue);
      expect(kick.messageCap.holding, isTrue);

      store.releaseScrollback();
      expect(store.timeline, hasLength(500));
      expect(kick.messageCap.holding, isFalse);
      expect(kick.messages, hasLength(500));
      expect(store.timeline.first.key, 'kick:k101');
    });

    test('status maps each source', () async {
      await store.activate();
      await until(
        () => kick.chatConnection == KickChatConnectionState.connected,
      );

      expect(store.sourceStatus[ChatType.Kick], CombinedSourceStatus.connected);

      /// The fake resolver finds no live stream for the own channel.
      await until(() => youTube.awaitingLiveStream);
      expect(
        store.sourceStatus[ChatType.YouTube],
        CombinedSourceStatus.offline,
      );
    });

    group('writing', () {
      test('the target defaults to the first writable source and the pick '
          'persists', () async {
        await store.activate();

        expect(store.writableTargets, [ChatType.YouTube, ChatType.Kick]);
        expect(store.sendTarget, ChatType.YouTube);

        store.selectSendTarget(ChatType.Kick);
        expect(store.sendTarget, ChatType.Kick);
        expect(
          settingsBox().get(SettingsKeys.CombinedChatSendTarget.name),
          'Kick',
        );

        final fresh = CombinedChatStore(
          twitchStore: () => twitch,
          youTubeStore: () => youTube,
          kickStore: () => kick,
        );
        await fresh.activate();
        expect(fresh.sendTarget, ChatType.Kick);
      });

      test('a pick that is not writable falls back', () async {
        await store.activate();
        store.selectSendTarget(ChatType.Kick);
        await store.setPlatformEnabled(ChatType.Kick, false);

        expect(store.sendTarget, ChatType.YouTube);
      });

      test('a reply locks the target to its platform; picking another '
          'target drops it', () async {
        await store.activate();
        final message = kickMessage('k1', DateTime.utc(2026, 9, 25));

        store.setReplyTarget(message);
        expect(kick.replyTarget, same(message));
        expect(store.replyPlatform, ChatType.Kick);
        expect(store.sendTarget, ChatType.Kick);

        store.selectSendTarget(ChatType.YouTube);
        expect(kick.replyTarget, isNull);
        expect(store.sendTarget, ChatType.YouTube);
      });

      test('send goes to the target store with its reply', () async {
        await store.activate();
        await until(
          () => kick.chatConnection == KickChatConnectionState.connected,
        );
        store.setReplyTarget(kickMessage('k1', DateTime.utc(2026, 9, 25)));

        expect(await store.send('hello kick'), isTrue);

        expect(kickApi.sendCalls.single.content, 'hello kick');
        expect(kickApi.sendCalls.single.replyToMessageId, 'k1');
        expect(kickApi.sendCalls.single.broadcasterUserId, 9001);
        expect(kick.replyTarget, isNull);
      });

      test('nothing writable: no target, send refuses', () async {
        await store.setPlatformEnabled(ChatType.Kick, false);
        await store.setPlatformEnabled(ChatType.YouTube, false);
        await store.activate();

        expect(store.sendTarget, isNull);
        expect(await store.send('hi'), isFalse);
      });
    });
  });
}
