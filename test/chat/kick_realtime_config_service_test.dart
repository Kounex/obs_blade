import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:obs_blade/utils/kick/kick_channel_service.dart';
import 'package:obs_blade/utils/kick/kick_realtime_config_service.dart';

/// Answers captured from web.kick.com on 2026-10-20 (glorious_e)
const _pusherOnly =
    '{"data":{"connections":[{"credentials":{"app_key":"34bf7a0ff419a2a775b9",'
    '"cluster":"us2"},"provider":"pusher"}],"mode":"websocket"},'
    '"message":"success"}';
const _centrifugoOnly =
    '{"data":{"connections":[{"credentials":{"url":"wss://realtime.us-west-2.'
    'platform.kick.com/connection/websocket"},"provider":"centrifugo"}],'
    '"mode":"websocket"},"message":"success"}';

void main() {
  test('asks for the channel\'s Pusher app the way kick.com does', () async {
    late http.Request sent;
    final service = KickRealtimeConfigService(
      client: MockClient((request) async {
        sent = request;
        return http.Response(_pusherOnly, 200);
      }),
    );
    final app = await service.pusherApp(7543158);
    expect(app, const KickPusherApp('34bf7a0ff419a2a775b9', 'us2'));
    expect(sent.method, 'POST');
    expect(
      sent.url.toString(),
      'https://web.kick.com/api/v1/realtime/channels/7543158/chat/connection',
    );
    expect(sent.headers['User-Agent'], kKickUserAgent);
    final body = json.decode(sent.body) as Map<String, dynamic>;
    expect(body['capabilities'], {
      'accepted_providers': [
        {'provider': 'pusher'},
      ],
    });
    expect((body['client'] as Map)['type'], 'web');
  });

  test('no Pusher app named (Centrifugo only): null', () async {
    final service = KickRealtimeConfigService(
      client: MockClient((_) async => http.Response(_centrifugoOnly, 200)),
    );
    expect(await service.pusherApp(1), isNull);
  });

  test('an error answer throws', () async {
    final service = KickRealtimeConfigService(
      client: MockClient((_) async => http.Response('{"message":""}', 404)),
    );
    await expectLater(service.pusherApp(1), throwsA(isA<KickApiException>()));
  });
}
