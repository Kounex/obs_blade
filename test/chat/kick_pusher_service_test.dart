import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/types/classes/kick/kick_pusher_event.dart';
import 'package:obs_blade/utils/kick/kick_pusher_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class _FakeChannel extends Fake implements WebSocketChannel {
  final StreamController<dynamic> incoming = StreamController<dynamic>();
  final List<Map<String, Object?>> sent = <Map<String, Object?>>[];

  @override
  Stream<dynamic> get stream => this.incoming.stream;

  @override
  WebSocketSink get sink => _FakeSink(this);
}

class _FakeSink extends Fake implements WebSocketSink {
  final _FakeChannel channel;

  _FakeSink(this.channel);

  @override
  void add(dynamic data) => this.channel.sent.add(
    json.decode(data as String) as Map<String, Object?>,
  );

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {}
}

void main() {
  test('subscribes the chatroom and, with a channel id, channel.{id}; '
      'stream on/off air events surface', () async {
    final channel = _FakeChannel();
    final events = <KickPusherEvent>[];
    final service = KickPusherService(
      onEvent: events.add,
      onStateChanged: (_) {},
      channelFactory: (_) => channel,
      sleep: (_) async {},
    );

    await service.connect(chatroomId: 42, channelId: 101);
    channel.incoming.add(
      json.encode({'event': 'pusher:connection_established', 'data': '{}'}),
    );
    await pumpEventQueue();

    final channels = [
      for (final frame in channel.sent)
        if (frame['event'] == 'pusher:subscribe')
          (frame['data'] as Map)['channel'],
    ];
    expect(channels, ['chatrooms.42.v2', 'channel.101']);

    channel.incoming.add(
      json.encode({
        'event': 'App\\Events\\StreamerIsLive',
        'channel': 'channel.101',
        'data': json.encode({
          'livestream': {'id': 1, 'channel_id': 101},
        }),
      }),
    );
    channel.incoming.add(
      json.encode({
        'event': 'App\\Events\\StopStreamBroadcast',
        'channel': 'channel.101',
        'data': '{}',
      }),
    );
    await pumpEventQueue();

    expect(events.map((e) => e.kind), [
      KickChatroomEventKind.streamStarted,
      KickChatroomEventKind.streamStopped,
    ]);
    await service.disconnect();
  });

  test('without a channel id only the chatroom is subscribed', () async {
    final channel = _FakeChannel();
    final service = KickPusherService(
      onEvent: (_) {},
      onStateChanged: (_) {},
      channelFactory: (_) => channel,
      sleep: (_) async {},
    );

    await service.connect(chatroomId: 42);
    channel.incoming.add(
      json.encode({'event': 'pusher:connection_established', 'data': '{}'}),
    );
    await pumpEventQueue();

    expect(
      channel.sent.where((f) => f['event'] == 'pusher:subscribe'),
      hasLength(1),
    );
    await service.disconnect();
  });

  test('a failed socket (onError + onDone) reconnects once - one new '
      'socket, events not doubled', () async {
    final sockets = <_FakeChannel>[];
    final events = <KickPusherEvent>[];
    final service = KickPusherService(
      onEvent: events.add,
      onStateChanged: (_) {},
      channelFactory: (_) {
        final socket = _FakeChannel();
        sockets.add(socket);
        return socket;
      },
      sleep: (_) async {},
    );

    await service.connect(chatroomId: 42);
    final first = sockets.single;
    first.incoming.addError(Exception('network blip'));
    unawaited(first.incoming.close());
    await pumpEventQueue();

    expect(sockets, hasLength(2));
    sockets.last.incoming.add(
      json.encode({
        'event': 'App\\Events\\StopStreamBroadcast',
        'channel': 'channel.101',
        'data': '{}',
      }),
    );
    await pumpEventQueue();
    expect(events, hasLength(1));
    await service.disconnect();
  });

  test('a reconnect pending from before disconnect does not open a '
      'second socket after the next connect', () async {
    final sockets = <_FakeChannel>[];
    final gate = Completer<void>();
    final service = KickPusherService(
      onEvent: (_) {},
      onStateChanged: (_) {},
      channelFactory: (_) {
        final socket = _FakeChannel();
        sockets.add(socket);
        return socket;
      },
      sleep: (_) => gate.future,
    );

    await service.connect(chatroomId: 42);
    unawaited(sockets.single.incoming.close());
    await pumpEventQueue();
    await service.disconnect();
    await service.connect(chatroomId: 43);
    expect(sockets, hasLength(2));

    gate.complete();
    await pumpEventQueue();

    expect(sockets, hasLength(2));
    await service.disconnect();
  });

  group('watchdog', () {
    const established =
        '{"event": "pusher:connection_established", '
        '"data": "{}"}';
    late List<_FakeChannel> sockets;
    late List<KickPusherConnectionState> states;
    late KickPusherService service;

    setUp(() {
      sockets = [];
      states = [];
      service = KickPusherService(
        onEvent: (_) {},
        onStateChanged: states.add,
        channelFactory: (_) {
          final socket = _FakeChannel();
          sockets.add(socket);
          return socket;
        },
        sleep: (_) async {},
        connectTimeout: const Duration(milliseconds: 40),
        quietTimeout: const Duration(milliseconds: 80),
      );
    });

    tearDown(() => service.disconnect());

    /// Dogfood 2026-10-20: the reopen never connected, no error, no done -
    /// "Reconnecting..." for good
    test('a connect that never answers is given up and opened again', () async {
      await service.connect(chatroomId: 42);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(sockets, hasLength(2));
      expect(states.last, KickPusherConnectionState.reconnecting);

      sockets.last.incoming.add(established);
      await pumpEventQueue();
      expect(states.last, KickPusherConnectionState.connected);
    });

    test('connected: frames keep the socket, silence reopens it', () async {
      await service.connect(chatroomId: 42);
      sockets.single.incoming.add(established);
      for (var i = 0; i < 3; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        sockets.single.incoming.add('{"event": "pusher:pong", "data": "{}"}');
      }
      expect(sockets, hasLength(1));

      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(sockets, hasLength(2));
      expect(states.last, KickPusherConnectionState.reconnecting);
    });

    test('the server\'s ping gets a pong', () async {
      await service.connect(chatroomId: 42);
      sockets.single.incoming
        ..add(established)
        ..add('{"event": "pusher:ping", "data": "{}"}');
      await pumpEventQueue();
      expect(
        sockets.single.sent.map((f) => f['event']),
        contains('pusher:pong'),
      );
    });

    test('disconnect stops the watchdog', () async {
      await service.connect(chatroomId: 42);
      await service.disconnect();
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(sockets, hasLength(1));
    });
  });
}
