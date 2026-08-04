import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
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

  setUp(() {
    channels = [];
    states = [];
    messages = [];
    revocations = [];
  });

  test('welcome triggers a subscription with the session id', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.headers['Authorization'], 'Bearer token-1');
      expect(request.headers['Client-Id'], kTwitchClientId);
      final body = json.decode(request.body) as Map<String, dynamic>;
      expect(body['type'], 'channel.chat.message');
      expect(body['version'], '1');
      expect(body['condition'], {
        'broadcaster_user_id': 'user-1',
        'user_id': 'user-1',
      });
      expect(body['transport'], {
        'method': 'websocket',
        'session_id': 'session-1',
      });
      return http.Response(
        json.encode({
          'data': [
            {'id': 'sub-1'}
          ],
        }),
        202,
      );
    });

    final service = serviceWith(client);
    await service.connect(accessToken: 'token-1', userId: 'user-1');
    channels.single.incoming.add(welcome('session-1'));
    await pumpEventQueue();

    expect(states, contains(TwitchEventSubState.connected));
  });

  test('notification parses into a chat message event', () async {
    final client = MockClient((request) async =>
        http.Response(json.encode({'data': [{'id': 'sub-1'}]}), 202));

    final service = serviceWith(client);
    await service.connect(accessToken: 'token-1', userId: 'user-1');
    channels.single.incoming.add(welcome('session-1'));
    await pumpEventQueue();
    channels.single.incoming.add(notification());
    await pumpEventQueue();

    expect(messages, hasLength(1));
    expect(messages.single.chatterUserName, 'viewer32');
    expect(messages.single.message.text, 'Hi chat');
  });

  test('session_reconnect opens a new socket at the reconnect url without resubscribing', () async {
    var subscriptionPosts = 0;
    final client = MockClient((request) async {
      subscriptionPosts++;
      return http.Response(
          json.encode({'data': [{'id': 'sub-1'}]}), 202);
    });

    final service = serviceWith(client);
    await service.connect(accessToken: 'token-1', userId: 'user-1');
    channels.single.incoming.add(welcome('session-1'));
    await pumpEventQueue();
    expect(subscriptionPosts, 1);

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
    expect(subscriptionPosts, 1);
  });

  test('socket close triggers a reconnect via the injected sleep', () async {
    final client = MockClient((request) async =>
        http.Response(json.encode({'data': [{'id': 'sub-1'}]}), 202));

    final service = serviceWith(client);
    await service.connect(accessToken: 'token-1', userId: 'user-1');
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
    await service.connect(accessToken: 'token-1', userId: 'user-1');
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

  test('dispose deletes the subscription best-effort', () async {
    String? deletedUrl;
    final client = MockClient((request) async {
      if (request.method == 'DELETE') {
        deletedUrl = request.url.toString();
        return http.Response('', 204);
      }
      return http.Response(
          json.encode({'data': [{'id': 'sub-1'}]}), 202);
    });

    final service = serviceWith(client);
    await service.connect(accessToken: 'token-1', userId: 'user-1');
    channels.single.incoming.add(welcome('session-1'));
    await pumpEventQueue();

    await service.dispose();
    expect(deletedUrl,
        'https://api.twitch.tv/helix/eventsub/subscriptions?id=sub-1');
  });
}
