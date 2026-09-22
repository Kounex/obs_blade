import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/stores/views/kick_chat.dart';
import 'package:obs_blade/types/classes/kick/kick_channel.dart';
import 'package:obs_blade/types/classes/kick/kick_chat_message.dart';
import 'package:obs_blade/types/classes/kick/kick_pusher_event.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/kick/kick_channel_service.dart';
import 'package:obs_blade/utils/kick/kick_pusher_service.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_kick_services.dart';

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
  late List<FakeKickPusherService> pushers;
  late bool isPro;
  late KickChatStore store;

  Box settingsBox() => Hive.box(HiveKeys.Settings.name);

  /// The most recently created socket (a channel switch swaps it).
  FakeKickPusherService pusher() => pushers.last;

  KickChatStore newStore() => KickChatStore(
    channelService: channelService,
    pusherFactory: ({required onEvent, required onStateChanged}) {
      final created = FakeKickPusherService(
        onEvent: onEvent,
        onStateChanged: onStateChanged,
      );
      pushers.add(created);
      return created;
    },
    isProResolver: () => isPro,
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

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('kick_store_test');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);
    channelService = FakeKickChannelService();
    pushers = <FakeKickPusherService>[];
    isPro = true;
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

      expect(store.selectedChannelSlug, 'aaa');
      expect(channelService.resolveCalls, 1);
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

  group('lifecycle', () {
    Future<void> connect() async {
      configure();
      await store.init();
      await until(
        () => store.chatConnection == KickChatConnectionState.connected,
      );
    }

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
}
