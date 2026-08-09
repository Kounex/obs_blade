import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/chat_lifecycle_events.dart';
import 'package:obs_blade/utils/twitch/twitch_auth_service.dart';
import 'package:obs_blade/utils/twitch/twitch_eventsub_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class FakeWebSocketChannel extends Fake implements WebSocketChannel {
  final StreamController<dynamic> incoming = StreamController<dynamic>();
  final List<dynamic> sent = <dynamic>[];
  bool closeCalled = false;

  @override
  Stream<dynamic> get stream => this.incoming.stream;

  @override
  WebSocketSink get sink => _FakeWebSocketSink(this);
}

class _FakeWebSocketSink extends Fake implements WebSocketSink {
  final FakeWebSocketChannel channel;

  _FakeWebSocketSink(this.channel);

  @override
  void add(dynamic data) => this.channel.sent.add(data);

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    this.channel.closeCalled = true;
    await this.channel.incoming.close();
  }
}

void main() {
  late List<FakeWebSocketChannel> channels;
  late List<TwitchEventSubState> states;
  late List<ChatMessageEvent> messages;
  late List<String> revocations;
  late List<ChatMessageDeleteEvent> deletes;
  late List<ChatClearUserMessagesEvent> purges;
  late List<ChatClearEvent> clears;
  late List<(String, String)> moderationDeletes;

  String welcome(String sessionId) => json.encode({
        'metadata': {
          'message_id': 'w1',
          'message_type': 'session_welcome',
          'message_timestamp': '2026-08-04T10:00:00.000Z',
        },
        'payload': {
          'session': {
            'id': sessionId,
            'status': 'connected',
            'keepalive_timeout_seconds': 30,
            'reconnect_url': null,
          },
        },
      });

  String notification() {
    final event = json.decode(File(
            'test/chat/fixtures/twitch/channel_chat_message_text.json')
        .readAsStringSync());
    return json.encode({
      'metadata': {
        'message_id': 'n1',
        'message_type': 'notification',
        'message_timestamp': '2026-08-04T10:00:00.000Z',
        'subscription_type': 'channel.chat.message',
        'subscription_version': '1',
      },
      'payload': {
        'subscription': {'type': 'channel.chat.message'},
        'event': event,
      },
    });
  }

  TwitchEventSubService serviceWith(MockClient client) =>
      TwitchEventSubService(
        onChatMessage: messages.add,
        onStateChanged: states.add,
        onRevoked: revocations.add,
        client: client,
        channelFactory: (uri) {
          final channel = FakeWebSocketChannel();
          channels.add(channel);
          return channel;
        },
        sleep: (_) async {},
      );

  TwitchEventSubService lifecycleServiceWith(MockClient client) =>
      TwitchEventSubService(
        onChatMessage: messages.add,
        onMessageDelete: deletes.add,
        onClearUserMessages: purges.add,
        onChatClear: clears.add,
        onStateChanged: states.add,
        onRevoked: revocations.add,
        client: client,
        channelFactory: (uri) {
          final channel = FakeWebSocketChannel();
          channels.add(channel);
          return channel;
        },
        sleep: (_) async {},
      );

  TwitchEventSubService moderationServiceWith(MockClient client) =>
      TwitchEventSubService(
        onChatMessage: messages.add,
        onMessageDelete: deletes.add,
        onClearUserMessages: purges.add,
        onChatClear: clears.add,
        onChannelModerate: (event) {
          final delete = event.delete;
          if (event.action == 'delete' && delete != null) {
            moderationDeletes.add((delete.messageId, event.moderatorUserName));
          }
        },
        onStateChanged: states.add,
        onRevoked: revocations.add,
        client: client,
        channelFactory: (uri) {
          final channel = FakeWebSocketChannel();
          channels.add(channel);
          return channel;
        },
        sleep: (_) async {},
      );

  setUp(() {
    channels = [];
    states = [];
    messages = [];
    revocations = [];
    deletes = [];
    purges = [];
    clears = [];
    moderationDeletes = [];
  });

  test('welcome subscribes to message + lifecycle types with the session id',
      () async {
    final bodies = <Map<String, dynamic>>[];
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.headers['Authorization'], 'Bearer token-1');
      expect(request.headers['Client-Id'], kTwitchClientId);
      bodies.add(json.decode(request.body) as Map<String, dynamic>);
      return http.Response(
        json.encode({
          'data': [
            {'id': 'sub-${bodies.length}'}
          ],
        }),
        202,
      );
    });

    final service = serviceWith(client);
    await service.connect(
        accessToken: 'token-1', userId: 'user-1', broadcasterId: 'user-1');
    channels.single.incoming.add(welcome('session-1'));
    await pumpEventQueue();

    expect(states, contains(TwitchEventSubState.connected));
    expect(bodies.map((body) => body['type']), [
      'channel.chat.message',
      'channel.chat.notification',
      'channel.chat.message_delete',
      'channel.chat.clear_user_messages',
      'channel.chat.clear',
    ]);
    for (final body in bodies) {
      expect(body['version'], '1');
      expect(body['condition'], {
        'broadcaster_user_id': 'user-1',
        'user_id': 'user-1',
      });
      expect(body['transport'], {
        'method': 'websocket',
        'session_id': 'session-1',
      });
    }
  });

  test('notification parses into a chat message event', () async {
    final client = MockClient((request) async =>
        http.Response(json.encode({'data': [{'id': 'sub-1'}]}), 202));

    final service = serviceWith(client);
    await service.connect(
        accessToken: 'token-1', userId: 'user-1', broadcasterId: 'user-1');
    channels.single.incoming.add(welcome('session-1'));
    await pumpEventQueue();
    channels.single.incoming.add(notification());
    await pumpEventQueue();

    expect(messages, hasLength(1));
    expect(messages.single.chatterUserName, 'viewer32');
    expect(messages.single.message.text, 'Hi chat');
  });

  test('subscription POST throwing routes to onRevoked instead of escaping', () async {
    final client = MockClient(
        (request) async => throw http.ClientException('connection refused'));

    final service = serviceWith(client);
    await service.connect(
        accessToken: 'token-1', userId: 'user-1', broadcasterId: 'user-1');
    channels.single.incoming.add(welcome('session-1'));
    await pumpEventQueue();

    expect(revocations, hasLength(1));
    expect(revocations.single, startsWith('subscription_failed:'));
  });

  test('session_reconnect opens a new socket at the reconnect url without resubscribing', () async {
    var subscriptionPosts = 0;
    final client = MockClient((request) async {
      subscriptionPosts++;
      return http.Response(
          json.encode({'data': [{'id': 'sub-1'}]}), 202);
    });

    final service = serviceWith(client);
    await service.connect(
        accessToken: 'token-1', userId: 'user-1', broadcasterId: 'user-1');
    channels.single.incoming.add(welcome('session-1'));
    await pumpEventQueue();
    expect(subscriptionPosts, 5);

    channels.single.incoming.add(json.encode({
      'metadata': {
        'message_id': 'r1',
        'message_type': 'session_reconnect',
        'message_timestamp': '2026-08-04T10:00:00.000Z',
      },
      'payload': {
        'session': {
          'id': 'session-1',
          'status': 'reconnecting',
          'reconnect_url': 'wss://eventsub.wss.twitch.tv/ws?resume=abc',
        },
      },
    }));
    await pumpEventQueue();
    expect(channels, hasLength(2));

    /// Resumed session: same session id → no new subscription
    channels[1].incoming.add(welcome('session-1'));
    await pumpEventQueue();
    expect(subscriptionPosts, 5);
  });

  test('socket close triggers a reconnect via the injected sleep', () async {
    final client = MockClient((request) async =>
        http.Response(json.encode({'data': [{'id': 'sub-1'}]}), 202));

    final service = serviceWith(client);
    await service.connect(
        accessToken: 'token-1', userId: 'user-1', broadcasterId: 'user-1');
    channels.single.incoming.add(welcome('session-1'));
    await pumpEventQueue();

    await channels.single.incoming.close();
    await pumpEventQueue();

    expect(channels, hasLength(2));
    expect(states, contains(TwitchEventSubState.reconnecting));
  });

  test('revocation is forwarded with its status', () async {
    final client = MockClient((request) async =>
        http.Response(json.encode({'data': [{'id': 'sub-1'}]}), 202));

    final service = serviceWith(client);
    await service.connect(
        accessToken: 'token-1', userId: 'user-1', broadcasterId: 'user-1');
    channels.single.incoming.add(welcome('session-1'));
    await pumpEventQueue();
    channels.single.incoming.add(json.encode({
      'metadata': {
        'message_id': 'v1',
        'message_type': 'revocation',
        'message_timestamp': '2026-08-04T10:00:00.000Z',
        'subscription_type': 'channel.chat.message',
        'subscription_version': '1',
      },
      'payload': {
        'subscription': {'status': 'authorization_revoked'},
      },
    }));
    await pumpEventQueue();

    expect(revocations, ['authorization_revoked']);
  });

  test('dispose deletes every created subscription best-effort', () async {
    final deletedUrls = <String>[];
    var posts = 0;
    final client = MockClient((request) async {
      if (request.method == 'DELETE') {
        deletedUrls.add(request.url.toString());
        return http.Response('', 204);
      }
      posts++;
      return http.Response(
          json.encode({
            'data': [
              {'id': 'sub-$posts'}
            ],
          }),
          202);
    });

    final service = serviceWith(client);
    await service.connect(
        accessToken: 'token-1', userId: 'user-1', broadcasterId: 'user-1');
    channels.single.incoming.add(welcome('session-1'));
    await pumpEventQueue();

    await service.dispose();
    expect(deletedUrls, [
      'https://api.twitch.tv/helix/eventsub/subscriptions?id=sub-1',
      'https://api.twitch.tv/helix/eventsub/subscriptions?id=sub-2',
      'https://api.twitch.tv/helix/eventsub/subscriptions?id=sub-3',
      'https://api.twitch.tv/helix/eventsub/subscriptions?id=sub-4',
      'https://api.twitch.tv/helix/eventsub/subscriptions?id=sub-5',
    ]);
  });

  test('lifecycle notifications dispatch to their callbacks', () async {
    final client = MockClient((request) async =>
        http.Response(json.encode({'data': [{'id': 'sub-1'}]}), 202));

    final service = lifecycleServiceWith(client);
    await service.connect(
        accessToken: 'token-1', userId: 'user-1', broadcasterId: 'user-1');
    channels.single.incoming.add(welcome('session-1'));
    await pumpEventQueue();

    String lifecycleNotification(String type, Map<String, Object?> event) =>
        json.encode({
          'metadata': {
            'message_id': 'n-$type',
            'message_type': 'notification',
            'message_timestamp': '2026-08-06T10:00:00.000Z',
            'subscription_type': type,
            'subscription_version': '1',
          },
          'payload': {
            'subscription': {'type': type},
            'event': event,
          },
        });

    /// Real Twitch payloads carry no deleting-moderator field.
    channels.single.incoming
        .add(lifecycleNotification('channel.chat.message_delete', {
      'broadcaster_user_id': 'b1',
      'target_user_id': 'u2',
      'message_id': 'm-9',
    }));
    channels.single.incoming
        .add(lifecycleNotification('channel.chat.clear_user_messages', {
      'broadcaster_user_id': 'b1',
      'target_user_id': 'u2',
    }));
    channels.single.incoming.add(lifecycleNotification('channel.chat.clear', {
      'broadcaster_user_id': 'b1',
    }));
    await pumpEventQueue();

    expect(deletes.single.messageId, 'm-9');
    expect(deletes.single.targetUserId, 'u2');
    expect(deletes.single.userName, isNull);
    expect(purges.single.targetUserId, 'u2');
    expect(clears.single.broadcasterUserId, 'b1');
    expect(messages, isEmpty);
  });

  test('a failing lifecycle POST degrades tombstones, not chat', () async {
    var posts = 0;
    final client = MockClient((request) async {
      posts++;
      /// POST 3 = `channel.chat.message_delete` (after message + notification).
      if (posts == 3) return http.Response('Forbidden', 403);
      return http.Response(
          json.encode({
            'data': [
              {'id': 'sub-$posts'}
            ],
          }),
          202);
    });

    final service = serviceWith(client);
    await service.connect(
        accessToken: 'token-1', userId: 'user-1', broadcasterId: 'user-1');
    channels.single.incoming.add(welcome('session-1'));
    await pumpEventQueue();

    expect(posts, 5);
    expect(revocations, isEmpty);
    expect(states, contains(TwitchEventSubState.connected));
  });

  test('includeModeration appends a v2 channel.moderate subscription',
      () async {
    final bodies = <Map<String, dynamic>>[];
    final client = MockClient((request) async {
      bodies.add(json.decode(request.body) as Map<String, dynamic>);
      return http.Response(
        json.encode({
          'data': [
            {'id': 'sub-${bodies.length}'}
          ],
        }),
        202,
      );
    });

    final service = serviceWith(client);
    await service.connect(
        accessToken: 'token-1',
        userId: 'user-1',
        broadcasterId: 'user-1',
        includeModeration: true);
    channels.single.incoming.add(welcome('session-1'));
    await pumpEventQueue();

    expect(bodies.map((body) => body['type']), [
      'channel.chat.message',
      'channel.chat.notification',
      'channel.chat.message_delete',
      'channel.chat.clear_user_messages',
      'channel.chat.clear',
      'channel.moderate',
    ]);
    for (final body in bodies.sublist(0, 5)) {
      expect(body['version'], '1');
      expect(body['condition'],
          {'broadcaster_user_id': 'user-1', 'user_id': 'user-1'});
    }
    expect(bodies[5]['version'], '2');
    expect(bodies[5]['condition'],
        {'broadcaster_user_id': 'user-1', 'moderator_user_id': 'user-1'});
  });

  test('moderate delete dispatches; other actions are ignored', () async {
    final client = MockClient((request) async =>
        http.Response(json.encode({'data': [{'id': 'sub-1'}]}), 202));

    final service = moderationServiceWith(client);
    await service.connect(
        accessToken: 'token-1',
        userId: 'user-1',
        broadcasterId: 'user-1',
        includeModeration: true);
    channels.single.incoming.add(welcome('session-1'));
    await pumpEventQueue();

    String moderateNotification(Map<String, Object?> event) => json.encode({
          'metadata': {
            'message_id': 'mod-1',
            'message_type': 'notification',
            'message_timestamp': '2026-08-08T10:00:00.000Z',
            'subscription_type': 'channel.moderate',
            'subscription_version': '2',
          },
          'payload': {
            'subscription': {'type': 'channel.moderate'},
            'event': event,
          },
        });

    final timeoutEvent = json.decode(File(
            'test/chat/fixtures/twitch/channel_moderate_timeout.json')
        .readAsStringSync()) as Map<String, Object?>;
    final deleteEvent = json.decode(File(
            'test/chat/fixtures/twitch/channel_moderate_delete.json')
        .readAsStringSync()) as Map<String, Object?>;

    channels.single.incoming.add(moderateNotification(timeoutEvent));
    channels.single.incoming.add(moderateNotification(deleteEvent));
    await pumpEventQueue();

    expect(moderationDeletes, [
      ('ab24e0b0-2260-4bac-94e4-05eedd4ecd0e', 'quotrok'),
    ]);
  });

  test('a failing moderate POST degrades the reveal, not chat', () async {
    var posts = 0;
    final client = MockClient((request) async {
      posts++;
      if (posts == 6) return http.Response('Forbidden', 403);
      return http.Response(
          json.encode({
            'data': [
              {'id': 'sub-$posts'}
            ],
          }),
          202);
    });

    final service = serviceWith(client);
    await service.connect(
        accessToken: 'token-1',
        userId: 'user-1',
        broadcasterId: 'user-1',
        includeModeration: true);
    channels.single.incoming.add(welcome('session-1'));
    await pumpEventQueue();

    expect(posts, 6);
    expect(revocations, isEmpty);
    expect(states, contains(TwitchEventSubState.connected));
  });

  test('a lifecycle revocation is logged, not surfaced', () async {
    final client = MockClient((request) async =>
        http.Response(json.encode({'data': [{'id': 'sub-1'}]}), 202));

    final service = serviceWith(client);
    await service.connect(
        accessToken: 'token-1', userId: 'user-1', broadcasterId: 'user-1');
    channels.single.incoming.add(welcome('session-1'));
    await pumpEventQueue();
    channels.single.incoming.add(json.encode({
      'metadata': {
        'message_id': 'v1',
        'message_type': 'revocation',
        'message_timestamp': '2026-08-06T10:00:00.000Z',
        'subscription_type': 'channel.chat.clear',
        'subscription_version': '1',
      },
      'payload': {
        'subscription': {
          'type': 'channel.chat.clear',
          'status': 'authorization_revoked',
        },
      },
    }));
    await pumpEventQueue();

    expect(revocations, isEmpty);
  });

  group('multi-channel', () {
    test('chat conditions carry the broadcaster; moderate stays own-channel',
        () async {
      final bodies = <Map<String, dynamic>>[];
      final client = MockClient((request) async {
        bodies.add(json.decode(request.body) as Map<String, dynamic>);
        return http.Response(
          json.encode({
            'data': [
              {'id': 'sub-${bodies.length}'}
            ],
          }),
          202,
        );
      });

      final service = serviceWith(client);
      await service.connect(
          accessToken: 'token-1',
          userId: 'user-1',
          broadcasterId: 'chan-9',
          includeModeration: true);
      channels.single.incoming.add(welcome('session-1'));
      await pumpEventQueue();

      for (final body in bodies.sublist(0, 5)) {
        expect(body['condition'],
            {'broadcaster_user_id': 'chan-9', 'user_id': 'user-1'});
      }
      expect(bodies[5]['condition'],
          {'broadcaster_user_id': 'user-1', 'moderator_user_id': 'user-1'});
    });

    test(
        'switchChannel deletes the channel subs and re-subscribes the new '
        'broadcaster on the same session', () async {
      final deletedUrls = <String>[];
      final bodies = <Map<String, dynamic>>[];
      final client = MockClient((request) async {
        if (request.method == 'DELETE') {
          deletedUrls.add(request.url.toString());
          return http.Response('', 204);
        }
        bodies.add(json.decode(request.body) as Map<String, dynamic>);
        return http.Response(
          json.encode({
            'data': [
              {'id': 'sub-${bodies.length}'}
            ],
          }),
          202,
        );
      });

      final service = serviceWith(client);
      await service.connect(
          accessToken: 'token-1',
          userId: 'user-1',
          broadcasterId: 'chan-1',
          includeModeration: true);
      channels.single.incoming.add(welcome('session-1'));
      await pumpEventQueue();
      expect(bodies, hasLength(6));

      await service.switchChannel('chan-2');

      /// The moderate sub (sub-6) is own-channel — never channel-scoped,
      /// so it survives the switch untouched.
      expect(deletedUrls, [
        'https://api.twitch.tv/helix/eventsub/subscriptions?id=sub-1',
        'https://api.twitch.tv/helix/eventsub/subscriptions?id=sub-2',
        'https://api.twitch.tv/helix/eventsub/subscriptions?id=sub-3',
        'https://api.twitch.tv/helix/eventsub/subscriptions?id=sub-4',
        'https://api.twitch.tv/helix/eventsub/subscriptions?id=sub-5',
      ]);
      expect(bodies, hasLength(11));
      for (final body in bodies.sublist(6)) {
        expect(body['condition'],
            {'broadcaster_user_id': 'chan-2', 'user_id': 'user-1'});
        expect(body['transport'],
            {'method': 'websocket', 'session_id': 'session-1'});
      }

      /// A successful re-subscription is the store's back-to-live signal.
      expect(states.last, TwitchEventSubState.connected);
    });

    test('a fresh session after a switch subscribes with the new broadcaster',
        () async {
      final bodies = <Map<String, dynamic>>[];
      final client = MockClient((request) async {
        if (request.method == 'DELETE') return http.Response('', 204);
        bodies.add(json.decode(request.body) as Map<String, dynamic>);
        return http.Response(
          json.encode({
            'data': [
              {'id': 'sub-${bodies.length}'}
            ],
          }),
          202,
        );
      });

      final service = serviceWith(client);
      await service.connect(
          accessToken: 'token-1', userId: 'user-1', broadcasterId: 'chan-1');
      channels.single.incoming.add(welcome('session-1'));
      await pumpEventQueue();
      await service.switchChannel('chan-2');
      expect(bodies, hasLength(10));

      /// Socket dies → reconnect → Twitch hands out a FRESH session id.
      await channels.single.incoming.close();
      await pumpEventQueue();
      expect(channels, hasLength(2));
      channels[1].incoming.add(welcome('session-3'));
      await pumpEventQueue();

      expect(bodies, hasLength(15));
      for (final body in bodies.sublist(10)) {
        expect(body['condition'],
            {'broadcaster_user_id': 'chan-2', 'user_id': 'user-1'});
        expect(body['transport'],
            {'method': 'websocket', 'session_id': 'session-3'});
      }
    });

    test('dispose after a switch deletes current subs and the moderate sub',
        () async {
      final deletedUrls = <String>[];
      final bodies = <Map<String, dynamic>>[];
      final client = MockClient((request) async {
        if (request.method == 'DELETE') {
          deletedUrls.add(request.url.toString());
          return http.Response('', 204);
        }
        bodies.add(json.decode(request.body) as Map<String, dynamic>);
        return http.Response(
          json.encode({
            'data': [
              {'id': 'sub-${bodies.length}'}
            ],
          }),
          202,
        );
      });

      final service = serviceWith(client);
      await service.connect(
          accessToken: 'token-1',
          userId: 'user-1',
          broadcasterId: 'chan-1',
          includeModeration: true);
      channels.single.incoming.add(welcome('session-1'));
      await pumpEventQueue();
      await service.switchChannel('chan-2');
      deletedUrls.clear();

      await service.dispose();

      /// sub-1..sub-5 were deleted by the switch; the live ones now are
      /// the switched channel subs (sub-7..sub-11) + the moderate sub-6.
      expect(deletedUrls, [
        'https://api.twitch.tv/helix/eventsub/subscriptions?id=sub-7',
        'https://api.twitch.tv/helix/eventsub/subscriptions?id=sub-8',
        'https://api.twitch.tv/helix/eventsub/subscriptions?id=sub-9',
        'https://api.twitch.tv/helix/eventsub/subscriptions?id=sub-10',
        'https://api.twitch.tv/helix/eventsub/subscriptions?id=sub-11',
        'https://api.twitch.tv/helix/eventsub/subscriptions?id=sub-6',
      ]);
    });
  });
}
