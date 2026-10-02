import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:obs_blade/utils/kick/kick_events_relay_client.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class _Channel extends Fake implements WebSocketChannel {
  final StreamController<dynamic> incoming = StreamController<dynamic>();
  final Completer<void> readyCompleter = Completer<void>();

  @override
  Stream<dynamic> get stream => this.incoming.stream;

  @override
  Future<void> get ready => this.readyCompleter.future;

  @override
  WebSocketSink get sink => _Sink(this);
}

class _Sink extends Fake implements WebSocketSink {
  final _Channel channel;

  _Sink(this.channel);

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    if (!this.channel.incoming.isClosed) await this.channel.incoming.close();
  }
}

void main() {
  test('register sends the Kick token and returns the session', () async {
    late Map<String, dynamic> sent;
    final client = KickEventsRelayClient(
      baseUrl: 'https://relay.test',
      client: MockClient((request) async {
        expect(request.url.toString(), 'https://relay.test/v1/session');
        sent = json.decode(request.body) as Map<String, dynamic>;
        return http.Response(
          json.encode({
            'session_token': 'sess',
            'broadcaster_user_id': 42,
            'username': 'me',
            'subscribed': true,
            'latest_seq': 0,
          }),
          200,
        );
      }),
    );
    final session = await client.register('kick-token');
    expect(sent, {'access_token': 'kick-token'});
    expect(session.token, 'sess');
    expect(session.broadcasterUserId, '42');
    expect(session.subscribed, isTrue);
  });

  test('register maps a refused token to its status', () async {
    final client = KickEventsRelayClient(
      baseUrl: 'https://relay.test',
      client: MockClient((_) async => http.Response('{}', 401)),
    );
    await expectLater(
      client.register('bad'),
      throwsA(
        isA<KickRelayException>().having((e) => e.statusCode, 'status', 401),
      ),
    );
  });

  test(
    'stream: auth header + cursor, events, synced, reconnect from cursor',
    () async {
      final channels = <_Channel>[];
      final uris = <Uri>[];
      final headers = <Map<String, String>>[];
      final frames = <Map<String, Object?>>[];
      final states = <KickRelayState>[];
      var cursor = 5;
      final client = KickEventsRelayClient(
        baseUrl: 'https://relay.test',
        client: MockClient((_) async => http.Response('{}', 200)),
        sleep: (_) async {},
        socketFactory: (uri, h) {
          uris.add(uri);
          headers.add(h);
          final channel = _Channel()..readyCompleter.complete();
          channels.add(channel);
          return channel;
        },
      );
      client.start(
        sessionToken: 'sess',
        cursor: () => cursor,
        onEvent: (frame) {
          frames.add(frame);
          cursor = frame['seq'] as int;
        },
        onState: states.add,
        onUnknownSession: () => fail('session is known'),
      );
      expect(uris.single.toString(), 'wss://relay.test/v1/stream?after=5');
      expect(headers.single['Authorization'], 'Bearer sess');

      channels.single.incoming
        ..add(json.encode({'type': 'hello', 'latest_seq': 6}))
        ..add(json.encode({'type': 'event', 'seq': 6, 'event_type': 'x'}))
        ..add(json.encode({'type': 'synced', 'seq': 6}));
      await pumpEventQueue();
      expect(frames.single['seq'], 6);
      expect(states, contains(KickRelayState.synced));

      await channels.single.incoming.close();
      await pumpEventQueue();
      expect(states, contains(KickRelayState.retrying));
      expect(uris.last.queryParameters['after'], '6');
      await client.stop();
    },
  );

  test('a session the relay no longer knows is reported once', () async {
    var unknown = 0;
    final client = KickEventsRelayClient(
      baseUrl: 'https://relay.test',
      client: MockClient((_) async => http.Response('{}', 401)),
      sleep: (_) async {},
      socketFactory: (uri, h) {
        final channel = _Channel()
          ..readyCompleter.completeError(
            WebSocketChannelException('upgrade failed'),
          );
        scheduleMicrotask(() => channel.incoming.close());
        return channel;
      },
    );
    client.start(
      sessionToken: 'old',
      cursor: () => 0,
      onEvent: (_) {},
      onState: (_) {},
      onUnknownSession: () => unknown++,
    );
    await pumpEventQueue(times: 50);
    expect(unknown, 1);
    await client.stop();
  });
}
