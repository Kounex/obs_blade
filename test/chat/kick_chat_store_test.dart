import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/kick_auth.dart';
import 'package:obs_blade/stores/views/kick_chat.dart';
import 'package:obs_blade/stores/views/kick_emotes.dart';
import 'package:obs_blade/stores/views/third_party_emotes.dart';
import 'package:obs_blade/types/classes/kick/kick_channel.dart';
import 'package:obs_blade/types/classes/kick/kick_chat_message.dart';
import 'package:obs_blade/types/classes/kick/kick_pusher_event.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/kick/kick_auth_service.dart';
import 'package:obs_blade/utils/kick/kick_channel_service.dart';
import 'package:obs_blade/utils/kick/kick_pusher_service.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_kick_services.dart';
import 'support/fake_twitch_services.dart' show FakeThirdPartyEmoteService;

KickChannelInfo channelInfo(
  String slug, {
  int id = 101,
  int chatroomId = 42,
  bool isLive = true,
  int? viewerCount = 1234,
}) => KickChannelInfo(
  id: id,
  userId: id + 1000,
  slug: slug,
  username: 'User $slug',
  chatroom: KickChatroom(id: chatroomId),
  livestream: KickLivestreamInfo(isLive: isLive, viewerCount: viewerCount),
);

Map<String, Object?> messageData(
  String id, {
  int senderId = 1,
  String? username,
  String? content,
  String type = 'message',
  String? createdAt,
}) {
  final name = username ?? 'user-$senderId';
  return <String, Object?>{
    'id': id,
    'chatroom_id': 42,
    'content': content ?? 'text $id',
    'type': type,
    'created_at': createdAt ?? '2026-09-22T12:04:49+00:00',
    'sender': <String, Object?>{
      'id': senderId,
      'username': name,
      'slug': name.toLowerCase(),
      'identity': <String, Object?>{'color': '#FFAE76', 'badges': []},
    },
    'metadata': <String, Object?>{'message_ref': 'ref-$id'},
  };
}

KickPusherEvent messageEvent(
  String id, {
  int senderId = 1,
  String username = 'user-1',
  String? content,
}) => KickPusherEvent(
  event: 'App\\Events\\ChatMessageEvent',
  channel: 'chatrooms.42.v2',
  data: messageData(
    id,
    senderId: senderId,
    username: username,
    content: content,
  ),
);

KickPusherEvent deletedEvent(String messageId) => KickPusherEvent(
  event: 'App\\Events\\MessageDeletedEvent',
  channel: 'chatrooms.42.v2',
  data: <String, Object?>{
    'id': 'evt-$messageId',
    'message': <String, Object?>{'id': messageId},
  },
);

KickPusherEvent bannedEvent(int userId) => KickPusherEvent(
  event: 'App\\Events\\UserBannedEvent',
  channel: 'chatrooms.42.v2',
  data: <String, Object?>{
    'user': <String, Object?>{'id': userId, 'username': 'user-$userId'},
    'expires_at': null,
  },
);

/// Waits until [condition] holds (the connection flow progresses on the
/// event loop) or ~1s passes.
Future<void> until(bool Function() condition) async {
  for (var i = 0; i < 1000 && !condition(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
}

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late FakeKickChannelService channelService;
  late FakeKickAuthService authService;
  late FakeKickApiService apiService;
  late List<FakeKickPusherService> pushers;
  late bool isPro;
  late FakeThirdPartyEmoteService emoteService;
  late ThirdPartyEmoteStore emoteStore;
  late FakeKickEmoteService kickEmoteService;
  late KickEmoteStore kickEmoteStore;
  late KickChatStore store;

  Box settingsBox() => Hive.box(HiveKeys.Settings.name);

  Box<KickAuth> authBox() => Hive.box<KickAuth>(HiveKeys.KickAuth.name);

  /// The most recently created socket (a channel switch swaps it).
  FakeKickPusherService pusher() => pushers.last;

  KickChatStore newStore() => KickChatStore(
    channelService: channelService,
    authService: authService,
    apiService: apiService,
    pusherFactory: ({required onEvent, required onStateChanged}) {
      final created = FakeKickPusherService(
        onEvent: onEvent,
        onStateChanged: onStateChanged,
      );
      pushers.add(created);
      return created;
    },
    isProResolver: () => isPro,
    emoteStoreResolver: () => emoteStore,
    kickEmoteStoreResolver: () => kickEmoteStore,
  );

  /// A valid, unexpired, fully-scoped stored session (user id 9001
  /// matches [FakeKickAuthService]'s scripted identity).
  KickAuth validAuth() => KickAuth(
    accessToken: 'access-1',
    refreshToken: 'refresh-1',
    expiresAtMs: DateTime.now().millisecondsSinceEpoch + 3600 * 1000,
    scopes: kKickChatScopes,
    userId: 9001,
    username: 'kicker',
    profilePicture: 'https://pic.example/k.png',
  );

  /// Two channels: 'aaa' → chatroom 42, 'bbb' → chatroom 43.
  void configure() {
    settingsBox().put(SettingsKeys.KickUsernames.name, <String>['aaa', 'bbb']);
    channelService.channels['aaa'] = channelInfo(
      'aaa',
      id: 101,
      chatroomId: 42,
    );
    channelService.channels['bbb'] = channelInfo(
      'bbb',
      id: 102,
      chatroomId: 43,
    );
  }

  /// Connected to 'aaa' with a signed-in session.
  Future<void> connectSignedIn() async {
    configure();
    await authBox().put(KickAuth.kBoxKey, validAuth());
    await store.init();
    await until(
      () => store.chatConnection == KickChatConnectionState.connected,
    );
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('kick_store_test');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);
    await Hive.openBox<KickAuth>(HiveKeys.KickAuth.name);
    channelService = FakeKickChannelService();
    authService = FakeKickAuthService();
    apiService = FakeKickApiService();
    pushers = <FakeKickPusherService>[];
    isPro = true;
    emoteService = FakeThirdPartyEmoteService();
    emoteStore = ThirdPartyEmoteStore(service: emoteService);
    kickEmoteService = FakeKickEmoteService();
    kickEmoteStore = KickEmoteStore(service: kickEmoteService);
    store = newStore();
  });

  tearDown(() async {
    await store.dispose();
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('init', () {
    test('no channels → idle, nothing resolves', () async {
      await store.init();

      expect(store.channels, isEmpty);
      expect(store.selectedChannelSlug, isNull);
      expect(store.chatConnection, KickChatConnectionState.idle);
      expect(channelService.resolveCalls, 0);
    });

    test('auto-selects the first channel and connects', () async {
      configure();

      await store.init();
      await until(
        () => store.chatConnection == KickChatConnectionState.connected,
      );
      // 1 resolve to connect 'aaa', plus 2 more from the live-preview poll
      // (every added channel, including the selected one) started at the
      // end of init.
      await until(() => channelService.resolveCalls >= 3);

      expect(store.selectedChannelSlug, 'aaa');
      expect(channelService.resolveCalls, 3);
      expect(pusher().connectCalls, [42]);
      expect(store.channelInfo?.slug, 'aaa');
    });

    test('a fresh store restores the persisted selection on init', () async {
      configure();
      settingsBox().put(SettingsKeys.SelectedKickUsername.name, 'bbb');

      await store.init();
      await until(
        () => store.chatConnection == KickChatConnectionState.connected,
      );

      expect(store.selectedChannelSlug, 'bbb');
      expect(pusher().connectCalls, [43]);
    });

    test('a persisted selection outside the list falls back to the first '
        'channel', () async {
      configure();
      settingsBox().put(SettingsKeys.SelectedKickUsername.name, 'ghost');

      await store.init();
      await until(
        () => store.chatConnection == KickChatConnectionState.connected,
      );

      expect(store.selectedChannelSlug, 'aaa');
    });
  });

  group('connect', () {
    test(
      'connectChat refuses to connect without the Pro entitlement',
      () async {
        configure();
        isPro = false;

        await store.init();
        // Give a hypothetical connection flow a beat to (not) start.
        await Future<void>.delayed(Duration.zero);

        expect(channelService.resolveCalls, 0);
        expect(store.chatConnection, isNot(KickChatConnectionState.connected));
        // The selection is still restored — only the connection is gated.
        expect(store.selectedChannelSlug, 'aaa');
      },
    );

    test('unknown slug → offline, no error, no socket', () async {
      settingsBox().put(SettingsKeys.KickUsernames.name, <String>['ghost']);

      await store.init();
      await until(
        () => store.chatConnection == KickChatConnectionState.offline,
      );

      expect(store.chatError, isNull);
      expect(store.channelInfo, isNull);
      expect(channelService.backfillCalls, 0);
    });

    test('resolve failure → error state with message', () async {
      configure();
      channelService.resolveThrows = const KickApiException(
        'Resolving the Kick channel failed (500)',
        statusCode: 500,
      );

      await store.init();
      await until(() => store.chatConnection == KickChatConnectionState.error);

      expect(store.chatError, isNotNull);
    });

    test('backfill failure does not block the live feed', () async {
      configure();
      channelService.backfillThrows = const KickApiException(
        'Loading the Kick chat history failed (500)',
        statusCode: 500,
      );

      await store.init();
      await until(
        () => store.chatConnection == KickChatConnectionState.connected,
      );

      expect(store.chatConnection, KickChatConnectionState.connected);
      pusher().emitEvent(messageEvent('m1'));
      await until(() => store.messages.isNotEmpty);
      expect(store.messages.single.id, 'm1');
    });

    test('backfill lands sorted by created_at, deduped against live', () async {
      configure();
      channelService.backfills[101] = [
        KickChatMessage.fromJson(
          messageData('m2', createdAt: '2026-09-22T12:05:10+00:00'),
        ),
        KickChatMessage.fromJson(
          messageData('m1', createdAt: '2026-09-22T12:04:49+00:00'),
        ),
      ];

      await store.init();
      await until(
        () => store.chatConnection == KickChatConnectionState.connected,
      );

      expect(store.messages.map((m) => m.id), ['m1', 'm2']);

      // A live echo of a backfilled message is a no-op.
      pusher().emitEvent(messageEvent('m1'));
      pusher().emitEvent(messageEvent('m3'));
      await until(() => store.messages.length == 3);
      expect(store.messages.map((m) => m.id), ['m1', 'm2', 'm3']);
    });

    test(
      'the buffer caps at kMaxMessages (500), dropping the oldest',
      () async {
        configure();
        const maxMessages = 500; // KickChatStore.kMaxMessages
        channelService.backfills[101] = [
          for (var i = 0; i < maxMessages; i++)
            KickChatMessage.fromJson(
              messageData(
                'm$i',
                createdAt: DateTime.utc(
                  2026,
                  9,
                  22,
                  12,
                ).add(Duration(seconds: i)).toIso8601String(),
              ),
            ),
        ];

        await store.init();
        await until(() => store.messages.length == maxMessages);

        pusher().emitEvent(messageEvent('overflow'));
        await until(() => store.messages.any((m) => m.id == 'overflow'));

        expect(store.messages.length, maxMessages);
        expect(store.messages.first.id, 'm1');
        expect(store.messages.last.id, 'overflow');
      },
    );

    test('ChatMessageSentEvent (the newer alias) appends too', () async {
      configure();
      await store.init();
      await until(
        () => store.chatConnection == KickChatConnectionState.connected,
      );

      pusher().emitEvent(
        KickPusherEvent(
          event: 'App\\Events\\ChatMessageSentEvent',
          channel: 'chatrooms.42.v2',
          data: messageData('m1'),
        ),
      );
      await until(() => store.messages.isNotEmpty);
      expect(store.messages.single.id, 'm1');
    });

    test('reconnecting keeps the buffer and flips the state', () async {
      configure();
      channelService.backfills[101] = [
        KickChatMessage.fromJson(messageData('m1')),
      ];
      await store.init();
      await until(
        () => store.chatConnection == KickChatConnectionState.connected,
      );

      pusher().emitState(KickPusherConnectionState.reconnecting);
      await until(
        () => store.chatConnection == KickChatConnectionState.reconnecting,
      );

      expect(store.messages.map((m) => m.id), ['m1']);

      pusher().emitState(KickPusherConnectionState.connected);
      await until(
        () => store.chatConnection == KickChatConnectionState.connected,
      );
    });
  });

  group('live preview (dropdown)', () {
    test(
      'init resolves every added channel, not just the selected one',
      () async {
        configure();

        await store.init();
        await until(() => store.channelLivePreview.length == 2);

        expect(store.isChannelLive('aaa'), isTrue);
        expect(store.viewerCountForChannel('aaa'), 1234);
        expect(store.isChannelLive('bbb'), isTrue);
        expect(store.viewerCountForChannel('bbb'), 1234);
      },
    );

    test(
      'an unresolved slug reports not-live with a null viewer count',
      () async {
        expect(store.isChannelLive('never-added'), isFalse);
        expect(store.viewerCountForChannel('never-added'), isNull);
      },
    );

    test('an offline channel reports not-live', () async {
      settingsBox().put(SettingsKeys.KickUsernames.name, <String>['aaa']);
      channelService.channels['aaa'] = channelInfo(
        'aaa',
        isLive: false,
        viewerCount: null,
      );

      await store.init();
      await until(() => store.channelLivePreview.containsKey('aaa'));

      expect(store.isChannelLive('aaa'), isFalse);
      expect(store.viewerCountForChannel('aaa'), isNull);
    });

    test('a resolve failure leaves the preview empty, never throws', () async {
      configure();
      channelService.resolveThrows = const KickApiException(
        'Resolving the Kick channel failed (500)',
        statusCode: 500,
      );

      await store.init();
      await until(() => store.chatConnection == KickChatConnectionState.error);
      await Future<void>.delayed(Duration.zero);

      expect(store.channelLivePreview, isEmpty);
    });

    test(
      'gated behind Pro — no resolve calls without the entitlement',
      () async {
        configure();
        isPro = false;

        await store.init();
        await Future<void>.delayed(Duration.zero);

        expect(channelService.resolveCalls, 0);
        expect(store.channelLivePreview, isEmpty);
      },
    );

    test('reloadChannels drops preview entries for retired slugs', () async {
      configure();
      await store.init();
      await until(() => store.channelLivePreview.length == 2);

      await settingsBox().put(SettingsKeys.KickUsernames.name, <String>['aaa']);
      store.reloadChannels();
      await until(
        () =>
            !store.channelLivePreview.containsKey('bbb') &&
            store.channelLivePreview.containsKey('aaa'),
      );

      expect(store.channelLivePreview.containsKey('bbb'), isFalse);
      expect(store.channelLivePreview.containsKey('aaa'), isTrue);
    });
  });

  group('third-party emotes', () {
    test('connecting refetches the 7TV catalog for the channel\'s Kick '
        'user id', () async {
      configure();
      await store.init();
      await until(
        () => store.chatConnection == KickChatConnectionState.connected,
      );
      await Future<void>.delayed(Duration.zero);

      /// 'aaa' resolves to channel id 101 → userId 1101 (see the
      /// channelInfo() fixture's default userId = id + 1000).
      expect(emoteService.lastKickUserId, '1101');
      expect(emoteService.sevenTvKickChannelCalls, 1);
      expect(emoteService.bttvChannelCalls, 0);
    });

    test('disabling the setting skips the fetch entirely', () async {
      settingsBox().put(SettingsKeys.KickChatThirdPartyEmotes.name, false);
      configure();
      await store.init();
      await until(
        () => store.chatConnection == KickChatConnectionState.connected,
      );
      await Future<void>.delayed(Duration.zero);

      expect(emoteService.sevenTvKickChannelCalls, 0);
    });

    test(
      'a fetch failure never blocks or errors the chat connection',
      () async {
        configure();
        emoteService.sevenTvGlobalThrows = Exception('boom');
        await store.init();
        await until(
          () => store.chatConnection == KickChatConnectionState.connected,
        );
        await Future<void>.delayed(Duration.zero);

        expect(store.chatConnection, KickChatConnectionState.connected);
        expect(store.chatError, isNull);
      },
    );
  });

  group('channel emotes (picker)', () {
    test(
      'connecting refetches the picker catalog for the channel slug',
      () async {
        configure();
        await store.init();
        await until(
          () => store.chatConnection == KickChatConnectionState.connected,
        );
        await Future<void>.delayed(Duration.zero);

        expect(kickEmoteService.fetchCalls, ['aaa']);
      },
    );

    test(
      'a fetch failure never blocks or errors the chat connection',
      () async {
        configure();
        kickEmoteService.fetchThrows = Exception('boom');
        await store.init();
        await until(
          () => store.chatConnection == KickChatConnectionState.connected,
        );
        await Future<void>.delayed(Duration.zero);

        expect(store.chatConnection, KickChatConnectionState.connected);
        expect(store.chatError, isNull);
      },
    );
  });

  group('lifecycle', () {
    Future<void> connect() async {
      configure();
      await store.init();
      await until(
        () => store.chatConnection == KickChatConnectionState.connected,
      );
    }

    test(
      'history pin is shown, a create replaces it, a delete clears it',
      () async {
        configure();
        channelService.pinnedBackfills[101] = KickChatMessage(
          id: 'from-history',
          content: 'house rules',
          sender: const KickChatSender(id: 7, username: 'Mod'),
        );
        await store.init();
        await until(
          () => store.chatConnection == KickChatConnectionState.connected,
        );
        expect(store.pinnedMessage?.content, 'house rules');

        pusher().emitEvent(
          KickPusherEvent(
            event: 'App\\Events\\PinnedMessageCreatedEvent',
            data: <String, Object?>{
              'message': messageData(
                'pin-1',
                username: 'Mod',
                content: 'new rules',
              ),
            },
          ),
        );
        await until(() => store.pinnedMessage?.id == 'pin-1');
        expect(store.pinnedMessage?.authorName, 'Mod');

        pusher().emitEvent(
          const KickPusherEvent(
            event: 'App\\Events\\PinnedMessageDeletedEvent',
          ),
        );
        await until(() => store.pinnedMessage == null);
      },
    );

    test('MessageDeletedEvent tombstones a buffered message; unknown ids '
        'are dropped', () async {
      await connect();
      pusher().emitEvent(messageEvent('m1'));
      await until(() => store.messages.isNotEmpty);

      pusher().emitEvent(deletedEvent('ghost'));
      pusher().emitEvent(deletedEvent('m1'));
      await until(() => store.messages.single.isTombstoned);

      expect(store.messages.single.id, 'm1');
    });

    test('UserBannedEvent purges only that author’s messages', () async {
      await connect();
      pusher().emitEvent(messageEvent('m1', senderId: 1));
      pusher().emitEvent(messageEvent('m2', senderId: 2, username: 'user-2'));
      pusher().emitEvent(messageEvent('m3', senderId: 1));
      await until(() => store.messages.length == 3);

      pusher().emitEvent(bannedEvent(1));
      await until(() => store.messages.any((m) => m.isTombstoned));

      expect(store.messages.length, 3, reason: 'the ban event is not a row');
      expect(store.messages[0].isTombstoned, isTrue);
      expect(store.messages[1].isTombstoned, isFalse);
      expect(store.messages[2].isTombstoned, isTrue);
    });

    test('UserUnbannedEvent does not resurrect tombstoned rows', () async {
      await connect();
      pusher().emitEvent(messageEvent('m1', senderId: 1));
      await until(() => store.messages.isNotEmpty);
      pusher().emitEvent(bannedEvent(1));
      await until(() => store.messages.single.isTombstoned);

      pusher().emitEvent(
        const KickPusherEvent(
          event: 'App\\Events\\UserUnbannedEvent',
          channel: 'chatrooms.42.v2',
          data: <String, Object?>{
            'user': <String, Object?>{'id': 1},
          },
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(store.messages.single.isTombstoned, isTrue);
    });

    test('ChatroomClearEvent clears the buffer and leaves a notice', () async {
      await connect();
      pusher().emitEvent(messageEvent('m1'));
      pusher().emitEvent(messageEvent('m2'));
      await until(() => store.messages.length == 2);

      pusher().emitEvent(
        const KickPusherEvent(
          event: 'App\\Events\\ChatroomClearEvent',
          channel: 'chatrooms.42.v2',
        ),
      );
      await until(() => store.messages.length == 1);

      expect(store.messages.single.type, KickChatMessageType.system);
    });

    test('SubscriptionEvent appends a sub notice', () async {
      await connect();

      pusher().emitEvent(
        const KickPusherEvent(
          event: 'App\\Events\\SubscriptionEvent',
          channel: 'chatrooms.42.v2',
          data: <String, Object?>{'username': 'Loyal', 'months': 6},
        ),
      );
      await until(() => store.messages.isNotEmpty);

      final notice = store.messages.single;
      expect(notice.type, KickChatMessageType.system);
      expect(notice.content, contains('Loyal'));
      expect(notice.content, contains('6 months'));
    });

    test('SubscriptionEvent with a missing field is dropped, not '
        'garbled', () async {
      await connect();

      pusher().emitEvent(
        const KickPusherEvent(
          event: 'App\\Events\\SubscriptionEvent',
          channel: 'chatrooms.42.v2',
          data: <String, Object?>{'username': 'Loyal'},
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(store.messages, isEmpty);
    });

    test('GiftedSubscriptionsEvent appends a gift notice', () async {
      await connect();

      pusher().emitEvent(
        const KickPusherEvent(
          event: 'App\\Events\\GiftedSubscriptionsEvent',
          channel: 'chatrooms.42.v2',
          data: <String, Object?>{
            'gifter_username': 'BigSpender',
            'gifted_usernames': <Object?>['Alice', 'Bob'],
          },
        ),
      );
      await until(() => store.messages.isNotEmpty);

      final notice = store.messages.single;
      expect(notice.type, KickChatMessageType.system);
      expect(notice.content, contains('BigSpender'));
      expect(notice.content, contains('2 subs'));
    });

    test('StreamHostEvent appends a host notice', () async {
      await connect();

      pusher().emitEvent(
        const KickPusherEvent(
          event: 'App\\Events\\StreamHostEvent',
          channel: 'chatrooms.42.v2',
          data: <String, Object?>{
            'host_username': 'BigStreamer',
            'number_viewers': 250,
          },
        ),
      );
      await until(() => store.messages.isNotEmpty);

      final notice = store.messages.single;
      expect(notice.type, KickChatMessageType.system);
      expect(notice.content, contains('BigStreamer'));
      expect(notice.content, contains('250 viewers'));
    });

    test('ChatroomUpdatedEvent refreshes the cached chatroom modes', () async {
      await connect();
      expect(store.channelInfo?.chatroom.slowMode, isFalse);

      pusher().emitEvent(
        const KickPusherEvent(
          event: 'App\\Events\\ChatroomUpdatedEvent',
          channel: 'chatrooms.42.v2',
          data: <String, Object?>{'slow_mode': true, 'message_interval': 3},
        ),
      );
      await until(() => store.channelInfo?.chatroom.slowMode ?? false);

      expect(store.channelInfo?.chatroom.messageInterval, 3);
      expect(store.channelInfo?.chatroomId, 42);
    });

    test('ChatroomUpdatedEvent applies the live nested {enabled: bool} '
        'shape too', () async {
      await connect();
      expect(store.channelInfo?.chatroom.slowMode, isFalse);

      pusher().emitEvent(
        const KickPusherEvent(
          event: 'App\\Events\\ChatroomUpdatedEvent',
          channel: 'chatrooms.42.v2',
          data: <String, Object?>{
            'slow_mode': <String, Object?>{
              'enabled': true,
              'message_interval': 5,
            },
            'subscribers_mode': <String, Object?>{'enabled': true},
            'followers_mode': <String, Object?>{
              'enabled': true,
              'min_duration': 10,
            },
            'emotes_mode': <String, Object?>{'enabled': false},
          },
        ),
      );
      await until(() => store.channelInfo?.chatroom.slowMode ?? false);

      final chatroom = store.channelInfo!.chatroom;
      expect(chatroom.slowMode, isTrue);
      expect(chatroom.messageInterval, 5);
      expect(chatroom.subscribersMode, isTrue);
      expect(chatroom.followersMode, isTrue);
      expect(chatroom.followingMinDuration, 10);
      expect(chatroom.emotesMode, isFalse);
    });

    test('a malformed event never breaks the feed', () async {
      await connect();
      pusher().emitEvent(
        const KickPusherEvent(
          event: 'App\\Events\\ChatMessageEvent',
          channel: 'chatrooms.42.v2',
          data: <String, Object?>{'no-id': true},
        ),
      );
      pusher().emitEvent(messageEvent('m1'));
      await until(() => store.messages.isNotEmpty);
      expect(store.messages.single.id, 'm1');
    });
  });

  group('channel switch', () {
    test('swaps buffers, disconnects the old socket, persists the '
        'selection', () async {
      configure();
      channelService.backfills[101] = [
        KickChatMessage.fromJson(messageData('a1')),
      ];
      channelService.backfills[102] = [
        KickChatMessage.fromJson(messageData('b1')),
      ];

      await store.init();
      await until(
        () => store.chatConnection == KickChatConnectionState.connected,
      );
      expect(store.messages.map((m) => m.id), ['a1']);

      await store.selectChannel('bbb');
      await until(() => store.messages.any((m) => m.id == 'b1'));

      expect(pushers.first.disconnectCalls, 1);
      expect(pushers.length, 2);
      expect(pusher().connectCalls, [43]);
      expect(store.messages.map((m) => m.id), ['b1']);
      expect(settingsBox().get(SettingsKeys.SelectedKickUsername.name), 'bbb');

      // Let init's one-shot live-preview poll (both channels) settle
      // before snapshotting — otherwise it can land mid-test and make
      // the "unchanged" assertion below flaky.
      await until(() => store.channelLivePreview.length == 2);

      // Back to 'aaa': buffered history restored without re-resolving or
      // re-backfilling.
      final resolveCalls = channelService.resolveCalls;
      final backfillCalls = channelService.backfillCalls;
      await store.selectChannel('aaa');
      expect(store.messages.map((m) => m.id), ['a1']);
      await until(() => pushers.length == 3);
      expect(pusher().connectCalls, [42]);
      expect(channelService.resolveCalls, resolveCalls);
      expect(channelService.backfillCalls, backfillCalls);
      expect(settingsBox().get(SettingsKeys.SelectedKickUsername.name), 'aaa');
    });

    test('selectChannel keeps the selection but does not connect without '
        'Pro', () async {
      configure();
      isPro = false;
      await store.init();

      await store.selectChannel('bbb');
      await Future<void>.delayed(Duration.zero);

      expect(store.selectedChannelSlug, 'bbb');
      expect(store.chatConnection, KickChatConnectionState.idle);
      expect(channelService.resolveCalls, 0);
    });

    test(
      'removed and re-added slug cannot resurrect its retired history',
      () async {
        configure();
        channelService.backfills[101] = [
          KickChatMessage.fromJson(messageData('retired')),
        ];
        await store.init();
        await until(() => store.messages.isNotEmpty);

        await settingsBox().put(SettingsKeys.KickUsernames.name, <String>[]);
        store.reloadChannels();
        expect(store.selectedChannelSlug, isNull);
        expect(store.messages, isEmpty);
        expect(store.chatConnection, KickChatConnectionState.idle);
        expect(
          settingsBox().get(SettingsKeys.SelectedKickUsername.name),
          isNull,
        );

        await settingsBox().put(SettingsKeys.KickUsernames.name, <String>[
          'aaa',
        ]);
        // Fresh network data for the re-added slug is expected (the point
        // is the retired BUFFER stays gone) — none this time.
        channelService.backfills.clear();
        store.reloadChannels();
        await store.selectChannel('aaa');
        expect(store.messages, isEmpty);
        await until(
          () => store.chatConnection == KickChatConnectionState.connected,
        );
        expect(store.messages, isEmpty);
      },
    );
  });

  group('auth', () {
    test('init without a stored session stays signed out', () async {
      configure();

      await store.init();

      expect(store.authState, KickAuthState.signedOut);
      expect(store.isSignedIn, isFalse);
      expect(store.canWrite, isFalse);
    });

    test('init restores a valid stored session', () async {
      configure();
      await authBox().put(KickAuth.kBoxKey, validAuth());

      await store.init();

      expect(store.authState, KickAuthState.signedIn);
      expect(store.isSignedInState, isTrue);
      expect(store.canWrite, isTrue);
      expect(store.selfUserId, 9001);
      expect(store.selfUsername, 'kicker');
      expect(authService.refreshCalls, 0, reason: 'token is not due');
    });

    test('init refreshes an expired session and persists the rotated '
        'pair', () async {
      configure();
      final expired = validAuth()
        ..expiresAtMs = DateTime.now().millisecondsSinceEpoch - 1000;
      await authBox().put(KickAuth.kBoxKey, expired);

      await store.init();

      expect(store.authState, KickAuthState.signedIn);
      expect(authService.refreshCalls, 1);
      expect(authService.lastRefreshToken, 'refresh-1');
      final stored = authBox().get(KickAuth.kBoxKey);
      expect(stored?.accessToken, 'access-new');
      expect(stored?.refreshToken, 'refresh-new');
    });

    test('init wipes the session on a definitive refresh failure', () async {
      configure();
      final expired = validAuth()
        ..expiresAtMs = DateTime.now().millisecondsSinceEpoch - 1000;
      await authBox().put(KickAuth.kBoxKey, expired);
      authService.refreshThrows = const KickAuthException(
        'Token refresh failed (400)',
        statusCode: 400,
      );

      await store.init();

      expect(store.authState, KickAuthState.signedOut);
      expect(store.authError, isNotNull);
      expect(authBox().get(KickAuth.kBoxKey), isNull);
    });

    test('init keeps the session on a transient refresh failure', () async {
      configure();
      final expired = validAuth()
        ..expiresAtMs = DateTime.now().millisecondsSinceEpoch - 1000;
      await authBox().put(KickAuth.kBoxKey, expired);
      authService.refreshThrows = const KickAuthException(
        'Token refresh failed (503)',
        statusCode: 503,
      );

      await store.init();

      expect(store.authState, KickAuthState.signedOut);
      expect(authBox().get(KickAuth.kBoxKey), isNotNull);
    });

    test('beginLogin returns the authorize URL for the app client', () async {
      final uri = await store.beginLogin();

      expect(uri, isNotNull);
      expect(uri!.queryParameters['redirect_uri'], kKickOAuthRedirectUri);
      expect(store.authState, KickAuthState.awaitingRedirect);
      expect(authService.beginSessionCalls, 1);
    });

    test(
      'beginLogin + completeLogin sign in and persist the identity',
      () async {
        settingsBox().put(SettingsKeys.KickOAuthClientId.name, 'client-1');

        final uri = await store.beginLogin();
        expect(uri, isNotNull);
        expect(store.authState, KickAuthState.awaitingRedirect);
        expect(authService.beginSessionCalls, 1);

        final ok = await store.completeLogin(
          'https://localhost/kick-callback?code=code-1&state=test-state',
        );

        expect(ok, isTrue);
        expect(store.authState, KickAuthState.signedIn);
        expect(authService.lastExchangeCode, 'code-1');
        expect(authService.lastExchangeVerifier, 'test-verifier');
        expect(authService.fetchUserCalls, 1);
        final stored = authBox().get(KickAuth.kBoxKey);
        expect(stored?.accessToken, 'access-1');
        expect(stored?.userId, 9001);
        expect(stored?.username, 'kicker');
        expect(stored?.scopes, kKickChatScopes);
      },
    );

    test(
      'completeLogin rejects a state mismatch and persists nothing',
      () async {
        settingsBox().put(SettingsKeys.KickOAuthClientId.name, 'client-1');
        await store.beginLogin();

        final ok = await store.completeLogin(
          'https://localhost/kick-callback?code=code-1&state=wrong',
        );

        expect(ok, isFalse);
        expect(store.authState, KickAuthState.error);
        expect(store.authError, contains('State mismatch'));
        expect(authBox().get(KickAuth.kBoxKey), isNull);
        expect(authService.lastExchangeCode, isNull);
      },
    );

    test('completeLogin surfaces an exchange failure', () async {
      settingsBox().put(SettingsKeys.KickOAuthClientId.name, 'client-1');
      await store.beginLogin();
      authService.exchangeThrows = const KickAuthException(
        'Token exchange failed (400)',
        statusCode: 400,
      );

      final ok = await store.completeLogin(
        'https://localhost/kick-callback?code=dead&state=test-state',
      );

      expect(ok, isFalse);
      expect(store.authState, KickAuthState.error);
      expect(store.authError, contains('Token exchange failed'));
      expect(authBox().get(KickAuth.kBoxKey), isNull);
    });

    test('logout wipes the box, revokes best-effort and keeps the '
        'read connection alive', () async {
      await connectSignedIn();
      expect(store.chatConnection, KickChatConnectionState.connected);

      await store.logout();

      expect(store.authState, KickAuthState.signedOut);
      expect(store.canWrite, isFalse);
      expect(authBox().get(KickAuth.kBoxKey), isNull);
      expect(authService.revokedTokens, ['access-1']);

      /// Reads are anonymous — the socket stays up.
      expect(store.chatConnection, KickChatConnectionState.connected);
    });

    test(
      'an external box wipe (data management) resets the auth state',
      () async {
        await connectSignedIn();
        expect(store.authState, KickAuthState.signedIn);

        await authBox().delete(KickAuth.kBoxKey);
        await until(() => store.authState == KickAuthState.signedOut);

        expect(store.canWrite, isFalse);
      },
    );
  });

  group('send', () {
    test('refuses when signed out', () async {
      configure();
      await store.init();
      await until(
        () => store.chatConnection == KickChatConnectionState.connected,
      );

      expect(await store.sendChatMessage('hi'), isFalse);
      expect(apiService.sendCalls, isEmpty);
    });

    test('refuses while not connected', () async {
      await authBox().put(KickAuth.kBoxKey, validAuth());
      await store.init();

      expect(store.chatConnection, KickChatConnectionState.idle);
      expect(await store.sendChatMessage('hi'), isFalse);
      expect(apiService.sendCalls, isEmpty);
    });

    test('sends to the channel owner id and renders via the Pusher echo '
        'exactly once', () async {
      await connectSignedIn();

      final sent = await store.sendChatMessage('  hello kick  ');

      expect(sent, isTrue);
      expect(apiService.sendCalls.single.content, 'hello kick');
      expect(
        apiService.sendCalls.single.broadcasterUserId,
        store.channelInfo!.userId,
      );
      expect(apiService.sendCalls.single.replyToMessageId, isNull);

      /// No optimistic append — the echo is the render.
      expect(store.messages, isEmpty);
      pusher().emitEvent(messageEvent('sent-1', senderId: 9001));
      await until(() => store.messages.isNotEmpty);
      expect(store.messages.map((m) => m.id), ['sent-1']);

      /// A replayed echo is dropped by the id-dedup backstop.
      pusher().emitEvent(messageEvent('sent-1', senderId: 9001));
      await Future<void>.delayed(Duration.zero);
      expect(store.messages.length, 1);
    });

    test('a send failure surfaces sendChatError and keeps the reply '
        'target', () async {
      await connectSignedIn();
      final target = KickChatMessage.fromJson(messageData('m0'));
      store.setReplyTarget(target);
      apiService.sendThrows = const KickApiException(
        'Could not send the message — Kick rate limit hit, wait a moment',
        statusCode: 429,
      );

      final sent = await store.sendChatMessage('spam');

      expect(sent, isFalse);
      expect(store.sendChatError, contains('rate limit'));
      expect(store.replyTarget, same(target));
      expect(store.sendingChat, isFalse);
    });
  });

  group('reply', () {
    test(
      'sends reply_to_message_id and clears the target on success',
      () async {
        await connectSignedIn();
        final target = KickChatMessage.fromJson(messageData('m0'));
        store.setReplyTarget(target);

        final sent = await store.sendChatMessage('answer');

        expect(sent, isTrue);
        expect(apiService.sendCalls.single.replyToMessageId, 'm0');
        expect(store.replyTarget, isNull);
      },
    );

    test('clearReplyTarget drops the pending reply', () async {
      await connectSignedIn();
      store.setReplyTarget(KickChatMessage.fromJson(messageData('m0')));

      store.clearReplyTarget();

      expect(store.replyTarget, isNull);
    });

    test('selectChannel drops the pending reply', () async {
      await connectSignedIn();
      store.setReplyTarget(KickChatMessage.fromJson(messageData('m0')));

      await store.selectChannel('bbb');

      expect(store.replyTarget, isNull);
    });
  });

  group('live preview', () {
    test('a refreshed preview updates the selected channel\'s live state '
        'and viewers (header / combined chips)', () async {
      configure();
      channelService.channels['aaa'] = channelInfo(
        'aaa',
        id: 101,
        chatroomId: 42,
        isLive: false,
      );
      await store.init();
      await until(
        () => store.chatConnection == KickChatConnectionState.connected,
      );
      final slug = store.selectedChannelSlug!;
      expect(slug, 'aaa');
      expect(store.channelInfo?.isLive, isFalse);

      /// The streamer goes live: the next preview round carries it over.
      final current = channelService.channels[slug]!;
      channelService.channels[slug] = current.copyWith(
        livestream: const KickLivestreamInfo(isLive: true, viewerCount: 42),
      );
      await store.refreshChannelLivePreviews();

      expect(store.channelInfo?.isLive, isTrue);
      expect(store.channelInfo?.viewerCount, 42);
      expect(store.channelInfo?.chatroomId, current.chatroomId);
    });
  });

  group('stream on/off air push', () {
    test('StreamerIsLive / StopStreamBroadcast flip the live state; the '
        'socket subscribes channel.{id}', () async {
      configure();
      channelService.channels['aaa'] = channelInfo(
        'aaa',
        id: 101,
        chatroomId: 42,
        isLive: false,
      );
      await store.init();
      await until(
        () => store.chatConnection == KickChatConnectionState.connected,
      );
      expect(pusher().connectChannelIds.last, 101);
      expect(store.channelInfo?.isLive, isFalse);

      channelService.channels['aaa'] = channelInfo(
        'aaa',
        id: 101,
        chatroomId: 42,
        viewerCount: 55,
      );
      pusher().emitEvent(
        const KickPusherEvent(
          event: 'App\\Events\\StreamerIsLive',
          channel: 'channel.101',
          data: <String, Object?>{
            'livestream': <String, Object?>{'id': 1, 'channel_id': 101},
          },
        ),
      );
      expect(store.channelInfo?.isLive, isTrue);
      await until(() => store.channelInfo?.viewerCount == 55);

      pusher().emitEvent(
        const KickPusherEvent(
          event: 'App\\Events\\StopStreamBroadcast',
          channel: 'channel.101',
        ),
      );
      expect(store.channelInfo?.isLive, isFalse);
      expect(store.liveStateForChannel('aaa'), isFalse);
    });
  });

  group('moderation', () {
    test('wrappers refuse when signed out', () async {
      configure();
      await store.init();
      await until(
        () => store.chatConnection == KickChatConnectionState.connected,
      );

      expect(await store.deleteChatMessage('m1'), isFalse);
      expect(await store.timeoutUser(7, 5), isFalse);
      expect(await store.banUser(7), isFalse);
      expect(await store.unbanUser(7), isFalse);
      expect(apiService.deleteCalls, isEmpty);
      expect(apiService.banCalls, isEmpty);
      expect(apiService.unbanCalls, isEmpty);
    });

    test('deleteChatMessage calls the API; a 403 surfaces honestly', () async {
      await connectSignedIn();

      expect(await store.deleteChatMessage('m1'), isTrue);
      expect(apiService.deleteCalls, ['m1']);

      apiService.deleteThrows = const KickApiException(
        'Could not delete the message — no permission (moderator status or a chat mode restriction)',
        statusCode: 403,
      );
      expect(await store.deleteChatMessage('m2'), isFalse);
      expect(store.modActionError, contains('no permission'));
    });

    test('timeoutUser/banUser target the channel owner + user', () async {
      await connectSignedIn();

      expect(await store.timeoutUser(7, 10), isTrue);
      expect(apiService.banCalls.single.userId, 7);
      expect(apiService.banCalls.single.durationMinutes, 10);
      expect(
        apiService.banCalls.single.broadcasterUserId,
        store.channelInfo!.userId,
      );

      expect(await store.banUser(8), isTrue);
      expect(apiService.banCalls.last.userId, 8);
      expect(apiService.banCalls.last.durationMinutes, isNull);
    });

    test(
      'unbanUser lifts via the API; failures surface modActionError',
      () async {
        await connectSignedIn();

        expect(await store.unbanUser(7), isTrue);
        expect(apiService.unbanCalls.single.userId, 7);

        apiService.unbanThrows = const KickApiException(
          'Could not lift the ban — no permission (moderator status or a chat mode restriction)',
          statusCode: 403,
        );
        expect(await store.unbanUser(7), isFalse);
        expect(store.modActionError, contains('no permission'));
      },
    );

    test('a 403 marks the action as forbidden (not a mod)', () async {
      await connectSignedIn();
      apiService.banThrows = const KickApiException(
        'no permission',
        statusCode: 403,
      );
      expect(await store.banUser(7), isFalse);
      expect(store.modActionForbidden, isTrue);

      apiService.banThrows = const KickApiException('rate', statusCode: 429);
      expect(await store.banUser(7), isFalse);
      expect(store.modActionForbidden, isFalse);
    });

    test('bans seen (own + echoed) list newest first; unbans drop them; '
        'the list follows the channel', () async {
      await connectSignedIn();
      pusher().emitEvent(messageEvent('m1', senderId: 7, username: 'user-7'));
      await until(() => store.messages.isNotEmpty);

      expect(await store.timeoutUser(7, 10), isTrue);
      expect(store.recentBans.single.userName, 'user-7');
      expect(store.recentBans.single.isTimeout, isTrue);

      /// Another mod's ban arrives as an echo only.
      pusher().emitEvent(
        const KickPusherEvent(
          event: 'App\\Events\\UserBannedEvent',
          channel: 'chatrooms.42.v2',
          data: <String, Object?>{
            'user': <String, Object?>{'id': 9, 'username': 'spammer'},
            'banned_by': <String, Object?>{'username': 'othermod'},
            'expires_at': null,
          },
        ),
      );
      await until(() => store.recentBans.length == 2);
      expect(store.recentBans.first.userName, 'spammer');
      expect(store.recentBans.first.bannedBy, 'othermod');
      expect(store.recentBans.first.isTimeout, isFalse);

      expect(await store.unbanUser(9), isTrue);
      expect(store.recentBans.map((b) => b.userId), ['7']);

      /// An unban echo (another mod lifted it) drops the entry too.
      pusher().emitEvent(
        const KickPusherEvent(
          event: 'App\\Events\\UserUnbannedEvent',
          channel: 'chatrooms.42.v2',
          data: <String, Object?>{
            'user': <String, Object?>{'id': 7},
          },
        ),
      );
      await until(() => store.recentBans.isEmpty);
    });

    test('unbanUsername resolves the name to a user id', () async {
      await connectSignedIn();
      channelService.channels['spammer'] = const KickChannelInfo(
        id: 500,
        userId: 4242,
        slug: 'spammer',
        chatroom: KickChatroom(id: 501),
      );

      expect(await store.unbanUsername('@Spammer'), isTrue);
      expect(apiService.unbanCalls.single.userId, 4242);

      expect(await store.unbanUsername('nobody'), isFalse);
      expect(store.modActionError, 'No Kick user "nobody"');
      expect(apiService.unbanCalls, hasLength(1));
    });

    test('the UserBannedEvent echo reconciles after a local ban', () async {
      await connectSignedIn();
      pusher().emitEvent(messageEvent('m1', senderId: 7, username: 'user-7'));
      await until(() => store.messages.isNotEmpty);

      expect(await store.banUser(7), isTrue);
      pusher().emitEvent(bannedEvent(7));
      await until(() => store.messages.single.isTombstoned);

      expect(store.messages.single.id, 'm1');
    });
  });

  group('user card', () {
    test('messagesForChatter filters by sender and is newest-first', () async {
      await connectSignedIn();
      pusher().emitEvent(messageEvent('m1', senderId: 7, username: 'user-7'));
      pusher().emitEvent(messageEvent('m2', senderId: 8, username: 'user-8'));
      pusher().emitEvent(messageEvent('m3', senderId: 7, username: 'user-7'));
      await until(() => store.messages.length == 3);

      final matches = store.messagesForChatter(7);
      expect(matches.map((m) => m.id).toList(), ['m3', 'm1']);
    });

    test('messagesForChatter caps at 20', () async {
      await connectSignedIn();
      for (var i = 0; i < 25; i++) {
        pusher().emitEvent(messageEvent('m$i', senderId: 7));
      }
      await until(() => store.messages.length == 25);

      final matches = store.messagesForChatter(7);
      expect(matches.length, 20);
      expect(matches.first.id, 'm24');
    });

    test('fetchUserProfile returns null when signed out', () async {
      configure();
      await store.init();
      await until(
        () => store.chatConnection == KickChatConnectionState.connected,
      );

      expect(await store.fetchUserProfile(7), isNull);
      expect(apiService.fetchUserCalls, isEmpty);
    });

    test('fetchUserProfile calls the API when signed in', () async {
      await connectSignedIn();
      apiService.fetchUserResult = const KickUserIdentity(
        userId: 7,
        name: 'chatterly',
        profilePicture: 'https://example.com/avatar.png',
      );

      final identity = await store.fetchUserProfile(7);
      expect(identity!.name, 'chatterly');
      expect(apiService.fetchUserCalls, [7]);
    });

    test('fetchUserProfile returns null on failure', () async {
      await connectSignedIn();
      apiService.fetchUserThrows = const KickApiException(
        'Could not fetch the user (500)',
        statusCode: 500,
      );

      expect(await store.fetchUserProfile(7), isNull);
    });
  });

  group('own channel ("You" entry)', () {
    /// The signed-in account (user id 9001) owns 'kicker' — its channel
    /// resolves with `user_id` 9001 so the slug verifies.
    void ownChannel({String slug = 'kicker', int userId = 9001}) {
      channelService.channels[slug] = channelInfo(
        slug,
        id: 900,
        chatroomId: 90,
      ).copyWith(userId: userId);
    }

    Future<void> signIn() async {
      settingsBox().put(SettingsKeys.KickOAuthClientId.name, 'client-1');
      await store.beginLogin();
      await store.completeLogin(
        'https://localhost/kick-callback?code=code-1&state=test-state',
      );
    }

    test('sign-in verifies and stores the own slug, listed first', () async {
      configure();
      ownChannel();
      await store.init();

      await signIn();

      expect(authBox().get(KickAuth.kBoxKey)?.channelSlug, 'kicker');
      expect(store.ownChannelSlug, 'kicker');
      expect(store.nativeChannels, ['kicker', 'aaa', 'bbb']);
      expect(store.isOwnChannel('kicker'), isTrue);
      expect(store.isOwnChannel('aaa'), isFalse);

      /// Native-only: the WebView list stays the user's.
      expect(settingsBox().get(SettingsKeys.KickUsernames.name), [
        'aaa',
        'bbb',
      ]);
    });

    test('an underscore username resolves its hyphenated slug', () async {
      authService.identity = const KickUserIdentity(
        userId: 9001,
        name: 'Ice_Poseidon',
      );
      ownChannel(slug: 'ice-poseidon');
      await store.init();

      await signIn();

      expect(store.ownChannelSlug, 'ice-poseidon');
    });

    test('a slug owned by someone else is never claimed', () async {
      ownChannel(userId: 1234);
      await store.init();

      await signIn();

      expect(store.authState, KickAuthState.signedIn);
      expect(store.ownChannelSlug, isNull);
      expect(authBox().get(KickAuth.kBoxKey)?.channelSlug, isNull);
    });

    test('signing in with nothing selected opens the own chat', () async {
      ownChannel();
      await store.init();
      expect(store.selectedChannelSlug, isNull);

      await signIn();
      await until(
        () => store.chatConnection == KickChatConnectionState.connected,
      );

      expect(store.selectedChannelSlug, 'kicker');
      expect(store.isViewingOwnChannel, isTrue);
      expect(pusher().connectCalls, [90]);

      /// Outside the WebView list → remembered natively, shared key free.
      expect(settingsBox().get(SettingsKeys.SelectedKickUsername.name), isNull);
      expect(
        settingsBox().get(SettingsKeys.SelectedKickNativeOwnChannel.name),
        isTrue,
      );
    });

    test('init restores a selected own chat', () async {
      configure();
      ownChannel();
      await authBox().put(
        KickAuth.kBoxKey,
        validAuth()..channelSlug = 'kicker',
      );
      settingsBox().put(SettingsKeys.SelectedKickNativeOwnChannel.name, true);

      await store.init();
      await until(
        () => store.chatConnection == KickChatConnectionState.connected,
      );

      expect(store.selectedChannelSlug, 'kicker');
      expect(pusher().connectCalls, [90]);
    });

    test('picking an added channel clears the own-chat flag', () async {
      configure();
      ownChannel();
      await authBox().put(
        KickAuth.kBoxKey,
        validAuth()..channelSlug = 'kicker',
      );
      settingsBox().put(SettingsKeys.SelectedKickNativeOwnChannel.name, true);
      await store.init();

      await store.selectChannel('bbb');

      expect(settingsBox().get(SettingsKeys.SelectedKickUsername.name), 'bbb');
      expect(
        settingsBox().get(SettingsKeys.SelectedKickNativeOwnChannel.name),
        isNull,
      );
    });

    test('a session stored before the slug existed backfills it', () async {
      ownChannel();
      await authBox().put(KickAuth.kBoxKey, validAuth());

      await store.init();
      await until(() => store.ownChannelSlug != null);

      expect(store.ownChannelSlug, 'kicker');
      expect(authBox().get(KickAuth.kBoxKey)?.channelSlug, 'kicker');
    });

    test('sign-out drops the entry and falls back to an added chat', () async {
      configure();
      ownChannel();
      await authBox().put(
        KickAuth.kBoxKey,
        validAuth()..channelSlug = 'kicker',
      );
      settingsBox().put(SettingsKeys.SelectedKickNativeOwnChannel.name, true);
      await store.init();
      expect(store.selectedChannelSlug, 'kicker');

      await store.logout();
      await until(() => store.selectedChannelSlug == 'aaa');

      expect(store.ownChannelSlug, isNull);
      expect(store.nativeChannels, ['aaa', 'bbb']);
      expect(store.selectedChannelSlug, 'aaa');
      expect(
        settingsBox().get(SettingsKeys.SelectedKickNativeOwnChannel.name),
        isNull,
      );
    });

    test('an own slug the user also added is listed once and survives '
        'sign-out', () async {
      settingsBox().put(SettingsKeys.KickUsernames.name, <String>['kicker']);
      ownChannel();
      await authBox().put(
        KickAuth.kBoxKey,
        validAuth()..channelSlug = 'kicker',
      );
      await store.init();

      expect(store.nativeChannels, ['kicker']);
      expect(store.selectedChannelSlug, 'kicker');

      await store.logout();

      expect(store.nativeChannels, ['kicker']);
      expect(store.selectedChannelSlug, 'kicker');
    });

    test('reloadChannels keeps a selected own chat', () async {
      configure();
      ownChannel();
      await authBox().put(
        KickAuth.kBoxKey,
        validAuth()..channelSlug = 'kicker',
      );
      settingsBox().put(SettingsKeys.SelectedKickNativeOwnChannel.name, true);
      await store.init();

      settingsBox().put(SettingsKeys.KickUsernames.name, <String>['aaa']);
      store.reloadChannels();

      expect(store.selectedChannelSlug, 'kicker');
      expect(store.nativeChannels, ['kicker', 'aaa']);
    });
  });
}
