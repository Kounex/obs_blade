import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/twitch_auth.dart';
import 'package:obs_blade/stores/views/third_party_emotes.dart';
import 'package:obs_blade/stores/views/twitch_badges.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/classes/twitch/twitch_user.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/utils/twitch/twitch_irc_sidecar.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_twitch_services.dart';

void main() {
  group('parseIrcPrivmsgMeta', () {
    test('reads id and first-msg from a tagged PRIVMSG', () {
      const line =
          '@badge-info=;badges=;color=#FF0000;display-name=Viewer;'
          'emotes=;first-msg=1;flags=;id=msg-abc;mod=0;room-id=1;'
          'subscriber=0;tmi-sent-ts=1;turbo=0;user-id=9;user-type= '
          ':viewer!viewer@viewer.tmi.twitch.tv PRIVMSG #streamer :hi';

      final meta = parseIrcPrivmsgMeta(line);
      expect(meta?.messageId, 'msg-abc');
      expect(meta?.isFirstMessage, isTrue);
    });

    test('returns false when first-msg is 0', () {
      const line =
          '@first-msg=0;id=msg-xyz :u!u@u.tmi.twitch.tv PRIVMSG #c :yo';
      final meta = parseIrcPrivmsgMeta(line);
      expect(meta?.messageId, 'msg-xyz');
      expect(meta?.isFirstMessage, isFalse);
    });

    test('ignores non-PRIVMSG lines', () {
      expect(parseIrcPrivmsgMeta('@id=1 :tmi.twitch.tv ROOMSTATE #c'), isNull);
      expect(parseIrcPrivmsgMeta('PING :tmi.twitch.tv'), isNull);
    });
  });

  group('TwitchChatStore IRC first-msg merge', () {
    late Directory tempDir;
    late HiveTestHarness harness;
    late TwitchChatStore store;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('irc_first_msg');
      harness = HiveTestHarness(tempDir);
      await harness.init();
      await Hive.openBox<TwitchAuth>(HiveKeys.TwitchAuth.name);
      await Hive.openBox(HiveKeys.Settings.name);

      store = TwitchChatStore(
        authService: FakeTwitchAuthService(),
        eventSubFactory: (_, __, ___, ____, _____, ______, _______, ________, _________, __________) =>
            FakeTwitchEventSubService(),
        ircSidecarFactory: (_) => TwitchIrcSidecar(
          onFirstMessage: (_) {},
          channelFactory: (_) => throw StateError('no real IRC in unit test'),
        ),
      );
      store.authState = TwitchAuthState.loggedIn;
      store.user = const TwitchUser(
        id: 'self',
        login: 'selflogin',
        displayName: 'Self',
      );
      GetIt.instance.registerSingleton<TwitchChatStore>(store);
      GetIt.instance.registerSingleton<TwitchBadgeStore>(
        TwitchBadgeStore(service: FakeTwitchBadgeService()),
      );
      GetIt.instance.registerSingleton<ThirdPartyEmoteStore>(
        ThirdPartyEmoteStore(service: FakeThirdPartyEmoteService()),
      );
    });

    tearDown(() async {
      await GetIt.instance.reset();
      await store.dispose();
      await harness.close();
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    ChatMessageEvent msg(String id, {String type = 'text'}) =>
        ChatMessageEvent(
          broadcasterUserId: 'b1',
          chatterUserId: 'c1',
          chatterUserLogin: 'newbie',
          chatterUserName: 'Newbie',
          messageId: id,
          messageType: type,
          message: const ChatMessageText(
            text: 'hello',
            fragments: [ChatMessageFragment(type: 'text', text: 'hello')],
          ),
        );

    test('pending IRC first-msg stamps the EventSub row on append', () {
      store.applyIrcFirstMessage('m1');
      store.appendChatMessageForTest(msg('m1'));
      expect(store.messages.single.isFirstMessage, isTrue);
    });

    test('late IRC first-msg updates an existing row', () {
      store.appendChatMessageForTest(msg('m1'));
      expect(store.messages.single.isFirstMessage, isFalse);
      store.applyIrcFirstMessage('m1');
      expect(store.messages.single.isFirstMessage, isTrue);
    });

    test('user_intro is treated as first message without IRC', () {
      store.appendChatMessageForTest(msg('m1', type: 'user_intro'));
      expect(store.messages.single.isFirstMessage, isTrue);
    });
  });
}
