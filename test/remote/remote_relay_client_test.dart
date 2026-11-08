import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:obs_blade/utils/remote/remote_relay_client.dart';

/// Answers shaped like tool/remote_relay/relay.py (README "Pairing"/"App").
void main() {
  late List<http.Request> sent;

  RemoteRelayClient client(http.Response Function(http.Request) answer) {
    sent = [];
    return RemoteRelayClient(
      baseUrl: 'https://relay.example',
      client: MockClient((request) async {
        sent.add(request);
        return answer(request);
      }),
    );
  }

  http.Response jsonAnswer(int status, Object body) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );

  test('appSocketUri: wss with the bridge as query, ws for a local relay', () {
    expect(
      RemoteRelayClient(
        baseUrl: 'https://relay.obs-blade.com',
      ).appSocketUri('b_1').toString(),
      'wss://relay.obs-blade.com/v1/app?bridge=b_1',
    );
    expect(
      RemoteRelayClient(
        baseUrl: 'http://127.0.0.1:18426',
      ).appSocketUri('b_1').toString(),
      'ws://127.0.0.1:18426/v1/app?bridge=b_1',
    );
  });

  test(
    'createPairing sends the app user id, returns code + secret id',
    () async {
      final relay = client(
        (_) => jsonAnswer(201, {
          'pairing_id': 'secret',
          'code': 'K7F3Q9XM',
          'expires_in': 120,
        }),
      );
      final ticket = await relay.createPairing(
        appUserId: r'$RCAnonymousID:a',
        deviceName: 'iPhone',
        platform: 'ios',
      );
      expect(
        (ticket.code, ticket.pairingId, ticket.expiresIn),
        ('K7F3Q9XM', 'secret', const Duration(minutes: 2)),
      );
      expect(sent.single.url.path, '/v1/pairings');
      expect(jsonDecode(sent.single.body), {
        'app_user_id': r'$RCAnonymousID:a',
        'device_name': 'iPhone',
        'platform': 'ios',
      });
    },
  );

  test('createPairing without Pro throws pro_required', () async {
    final relay = client((_) => jsonAnswer(403, {'error': 'pro_required'}));
    await expectLater(
      relay.createPairing(appUserId: 'x', deviceName: '', platform: ''),
      throwsA(
        isA<RemoteRelayException>().having(
          (e) => e.isProRequired,
          'isProRequired',
          isTrue,
        ),
      ),
    );
  });

  test(
    'collectPairing: waiting -> null, paired -> pairing, gone -> 404',
    () async {
      var answers = [
        jsonAnswer(200, {'state': 'waiting', 'expires_in': 100}),
        jsonAnswer(200, {
          'state': 'paired',
          'device_id': 'd_1',
          'app_token': 'tok',
          'bridge': {'id': 'b_1', 'name': 'GAMING-PC', 'kind': 'standalone'},
        }),
        jsonAnswer(404, {'error': 'unknown_pairing'}),
      ];
      final relay = client((_) => answers.removeAt(0));
      expect(await relay.collectPairing('secret'), isNull);
      final pairing = (await relay.collectPairing('secret'))!;
      expect(
        (
          pairing.deviceId,
          pairing.appToken,
          pairing.bridgeId,
          pairing.bridgeName,
          pairing.bridgeKind,
        ),
        ('d_1', 'tok', 'b_1', 'GAMING-PC', 'standalone'),
      );
      await expectLater(
        relay.collectPairing('secret'),
        throwsA(
          isA<RemoteRelayException>().having(
            (e) => e.error,
            'error',
            'unknown_pairing',
          ),
        ),
      );
      // The pairing id is a secret: body only, never the URL.
      expect(sent.every((r) => !r.url.toString().contains('secret')), isTrue);
    },
  );

  test('bridgeInfo parses state and devices', () async {
    final relay = client(
      (_) => jsonAnswer(200, {
        'id': 'b_1',
        'name': 'GAMING-PC',
        'kind': 'plugin',
        'version': '0.2.0',
        'online': false,
        'last_seen': 1794000000,
        'obs': 'closed',
        'update_required': false,
        'status': {},
        'status_at': 0,
        'devices': [
          {
            'id': 'd_1',
            'name': 'iPhone',
            'platform': 'ios',
            'created_at': 1,
            'last_used': 1794000000,
            'connected': false,
            'self': true,
          },
          {
            'id': 'd_2',
            'name': 'iPad',
            'platform': 'ios',
            'created_at': 1,
            'last_used': 1793000000,
            'connected': true,
          },
        ],
      }),
    );
    final info = await relay.bridgeInfo('b_1', 'tok');
    expect(sent.single.headers['Authorization'], 'Bearer tok');
    expect(
      (info.online, info.obsState, info.isStandalone),
      (false, 'closed', false),
    );
    expect(
      info.lastSeen,
      DateTime.fromMillisecondsSinceEpoch(1794000000 * 1000),
    );
    expect(info.devices.map((d) => (d.id, d.isThisDevice, d.connected)), [
      ('d_1', true, false),
      ('d_2', false, true),
    ]);
  });

  test('removeDevice expects 204; start-obs 409 carries the reason', () async {
    var answers = [
      http.Response('', 204),
      jsonAnswer(409, {'error': 'not_supported'}),
    ];
    final relay = client((_) => answers.removeAt(0));
    await relay.removeDevice('d_2', 'tok');
    expect(
      (sent.last.method, sent.last.url.path),
      ('DELETE', '/v1/devices/d_2'),
    );
    await expectLater(
      relay.startObs('b_1', 'tok'),
      throwsA(
        isA<RemoteRelayException>().having(
          (e) => (e.statusCode, e.error),
          'answer',
          (409, 'not_supported'),
        ),
      ),
    );
  });

  test('network failure is a RemoteRelayException without status', () async {
    final relay = RemoteRelayClient(
      baseUrl: 'https://relay.example',
      client: MockClient((_) async => throw http.ClientException('offline')),
    );
    await expectLater(
      relay.bridgeInfo('b_1', 'tok'),
      throwsA(
        isA<RemoteRelayException>().having(
          (e) => e.isNetwork,
          'isNetwork',
          isTrue,
        ),
      ),
    );
  });
}
