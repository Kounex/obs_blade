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
}
