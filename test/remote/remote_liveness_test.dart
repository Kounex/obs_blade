import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/types/enums/web_socket_codes/web_socket_close_code.dart';
import 'package:obs_blade/utils/remote/noise_ik.dart';
import 'package:obs_blade/utils/remote/remote_e2e_channel.dart';
import 'package:obs_blade/utils/remote/remote_pacing.dart';
import 'package:web_socket_channel/io.dart';

import 'support/fake_remote_endpoint.dart';

/// Dogfood 2026-11-09: relay sessions on mobile data closed every ~30 s -
/// dart:io's ping closes when a pong is 15 s late even while data flows,
/// and the back-to-back preview filled the line. Now: no dart:io ping on
/// the relay, a data watchdog instead, and a paced preview.
void main() {
  group('relay liveness', () {
    late FakeRemoteEndpoint endpoint;
    late NoiseKeyPair appKey;

    setUp(() async {
      endpoint = await FakeRemoteEndpoint.start(FakeEndpointMode.obs);
      appKey = await NoiseKeyPair.generate();
      endpoint.pairedAppKeys.add(base64Encode(appKey.publicKey));
    });

    tearDown(() => endpoint.close());

    Future<RemoteE2eChannel> identified() async {
      final channel = RemoteE2eChannel(
        IOWebSocketChannel.connect(
          Uri.parse('ws://127.0.0.1:${endpoint.port}/v1/app'),
          protocols: const ['obswebsocket.json'],
        ),
        appKey: appKey,
        bridgeKey: endpoint.bridgeKey.publicKey,
        silenceLimit: const Duration(milliseconds: 400),
      );
      final ops = StreamController<int>.broadcast();
      channel.stream.listen(
        (raw) => ops.add((jsonDecode(raw as String) as Map)['op'] as int),
      );
      final hello = ops.stream.firstWhere((op) => op == 0);
      await hello;
      final done = ops.stream.firstWhere((op) => op == 2);
      channel.sink.add(
        jsonEncode({
          'op': 1,
          'd': {'rpcVersion': 1},
        }),
      );
      await done;
      return channel;
    }

    test('replies keep a session open past the silence limit', () async {
      final channel = await identified();
      for (var i = 0; i < 12; i++) {
        channel.sink.add(
          jsonEncode({
            'op': 6,
            'd': {'requestType': 'GetStats', 'requestId': 'r$i'},
          }),
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      expect(channel.closeCode, isNull, reason: '1.2 s with replies');
      await channel.sink.close();
    });

    test('nothing arriving ends it with RemoteSilent (4998)', () async {
      final channel = await identified();
      await Future<void>.delayed(const Duration(milliseconds: 900));
      expect(channel.closeCode, WebSocketCloseCode.RemoteSilent.identifier);
      expect(
        WebSocketCloseCode.fromIdentifier(channel.closeCode).isRemote,
        isTrue,
      );
      for (
        var i = 0;
        i < 50 && endpoint.sockets.single.closeCode == null;
        i++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      expect(
        endpoint.sockets.single.closeCode,
        4998,
        reason: 'the relay sees it',
      );
    });
  });

  group('preview pacing', () {
    final DateTime asked = DateTime(2026, 11, 9, 13);

    test('LAN: back to back', () {
      expect(
        previewPause(
          viaRemote: false,
          requestedAt: asked,
          now: asked.add(const Duration(milliseconds: 40)),
        ),
        Duration.zero,
      );
    });

    test('relay: the rest of 250 ms since the request, none after', () {
      expect(
        previewPause(
          viaRemote: true,
          requestedAt: asked,
          now: asked.add(const Duration(milliseconds: 40)),
        ),
        const Duration(milliseconds: 210),
      );
      expect(
        previewPause(
          viaRemote: true,
          requestedAt: asked,
          now: asked.add(const Duration(milliseconds: 600)),
        ),
        Duration.zero,
        reason: 'a slow line already paces itself',
      );
    });
  });
}
