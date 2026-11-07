import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:obs_blade/models/connection.dart';
import 'package:obs_blade/stores/views/remote_access.dart';
import 'package:obs_blade/utils/remote/remote_relay_client.dart';

import '../persistence/support/hive_test_harness.dart';

/// A relay that answers like tool/remote_relay/relay.py: a pairing waits
/// until [redeemAfterPolls] collects happened, then is paired once.
class FakeRelay {
  int redeemAfterPolls = 2;
  int expiresIn = 120;
  int? createStatus;
  String? createError;
  bool collectGone = false;
  int collects = 0;
  final List<String> deleted = [];
  int infoStatus = 200;
  bool collected = false;

  late final http.Client client = MockClient((request) async {
    final path = request.url.path;
    http.Response answer(int status, [Object? body]) => http.Response(
      body == null ? '' : jsonEncode(body),
      status,
      headers: {'content-type': 'application/json'},
    );
    if (path == '/v1/pairings') {
      if (createStatus != null) return answer(createStatus!, {'error': createError});
      return answer(201, {'pairing_id': 'pid', 'code': 'K7F3Q9XM', 'expires_in': expiresIn});
    }
    if (path == '/v1/pairings/collect') {
      collects++;
      if (collectGone || collected) return answer(404, {'error': 'unknown_pairing'});
      if (collects <= redeemAfterPolls) return answer(200, {'state': 'waiting', 'expires_in': 100});
      collected = true;
      return answer(200, {
        'state': 'paired',
        'device_id': 'd_me',
        'app_token': 'tok',
        'bridge': {'id': 'b_1', 'name': 'GAMING-PC', 'kind': 'plugin'},
      });
    }
    if (path.startsWith('/v1/devices/')) {
      deleted.add(path.split('/').last);
      return answer(204);
    }
    if (path.startsWith('/v1/bridges/')) {
      if (infoStatus != 200) return answer(infoStatus, {'error': 'unpaired'});
      return answer(200, {
        'id': 'b_1', 'name': 'GAMING-PC', 'kind': 'plugin', 'version': '0.2.0', 'online': true,
        'last_seen': 1794000000, 'obs': 'running', 'update_required': false,
        'devices': [{'id': 'd_me', 'name': 'iPhone', 'platform': 'ios', 'last_used': 1794000000, 'connected': true, 'self': true}],
      });
    }
    return answer(404);
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late HiveTestHarness harness;
  late FakeRelay relay;
  late List<String> sentCodes;
  late bool pluginAnswers;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('remote_access_store');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await harness.openAllBoxes();
    relay = FakeRelay();
    sentCodes = [];
    pluginAnswers = true;
  });

  tearDown(() async {
    await harness.close();
    await tempDir.delete(recursive: true);
  });

  RemoteAccessStore store({String? appUserId = r'$RCAnonymousID:me'}) => RemoteAccessStore(
    relay: RemoteRelayClient(baseUrl: 'https://relay.example', client: relay.client),
    appUserId: () async => appUserId,
    sendCode: (code) async {
      sentCodes.add(code);
      return pluginAnswers;
    },
    pollInterval: const Duration(milliseconds: 5),
    resendInterval: const Duration(milliseconds: 12),
  );

  test('plugin: code acknowledged once, pairing stored on the connection', () async {
    final s = store();
    final connection = Connection('192.168.1.20', 4455);
    await s.pair(connection, deviceName: 'iPhone', platform: 'ios');
    expect(s.phase, RemotePairingPhase.paired);
    expect(sentCodes, ['K7F3Q9XM']);
    expect(
      (connection.relayBridgeId, connection.relayAppToken, connection.relayDeviceId, connection.relayBridgeName, connection.relayBridgeKind),
      ('b_1', 'tok', 'd_me', 'GAMING-PC', 'plugin'),
    );
    expect(connection.hasRemote, isTrue);
  });

  test('standalone: the CustomEvent is repeated until a bridge redeems it', () async {
    pluginAnswers = false;
    relay.redeemAfterPolls = 8;
    final s = store();
    await s.pair(Connection('h', 4455), deviceName: 'iPhone', platform: 'ios');
    expect(s.phase, RemotePairingPhase.paired);
    expect(sentCodes.length, greaterThan(1));
    expect(sentCodes.toSet(), {'K7F3Q9XM'});
  });

  test('refusals map to their failure', () async {
    for (final (status, error, failure) in [
      (403, 'pro_required', RemotePairingFailure.proRequired),
      (503, 'verify_unavailable', RemotePairingFailure.verifyUnavailable),
      (429, 'rate_limited', RemotePairingFailure.rateLimited),
      (429, 'too_many_pairings', RemotePairingFailure.rateLimited),
    ]) {
      relay = FakeRelay()
        ..createStatus = status
        ..createError = error;
      final s = store();
      await s.pair(Connection('h', 4455), deviceName: 'iPhone', platform: 'ios');
      expect((s.phase, s.failure), (RemotePairingPhase.failed, failure), reason: error);
      expect(sentCodes, isEmpty);
    }
  });

  test('no RevenueCat account: nothing is asked', () async {
    final s = store(appUserId: null);
    await s.pair(Connection('h', 4455), deviceName: 'iPhone', platform: 'ios');
    expect(s.failure, RemotePairingFailure.noAccount);
    expect(relay.collects, 0);
  });

  test('nobody redeems before the code expires', () async {
    relay
      ..redeemAfterPolls = 1 << 30
      ..expiresIn = 0;
    final s = store();
    final connection = Connection('h', 4455);
    await s.pair(connection, deviceName: 'iPhone', platform: 'ios');
    expect(s.failure, RemotePairingFailure.noBridge);
    expect(connection.hasRemote, isFalse);
  });

  test('a pairing gone at the relay (404) ends the wait', () async {
    relay.collectGone = true;
    final s = store();
    await s.pair(Connection('h', 4455), deviceName: 'iPhone', platform: 'ios');
    expect(s.failure, RemotePairingFailure.noBridge);
    expect(relay.collects, 1);
  });

  test('cancel stops the loop and leaves nothing behind', () async {
    relay.redeemAfterPolls = 1 << 30;
    final s = store();
    final connection = Connection('h', 4455);
    final running = s.pair(connection, deviceName: 'iPhone', platform: 'ios');
    await Future<void>.delayed(const Duration(milliseconds: 30));
    s.cancel();
    await running;
    final polls = relay.collects;
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(relay.collects, polls);
    expect(s.phase, RemotePairingPhase.idle);
    expect(connection.hasRemote, isFalse);
  });

  test('forget removes this device at the relay and here', () async {
    final s = store();
    final connection = Connection('h', 4455);
    await s.pair(connection, deviceName: 'iPhone', platform: 'ios');
    expect(await s.forget(connection), isTrue);
    expect(relay.deleted, ['d_me']);
    expect(connection.hasRemote, isFalse);
  });

  test('a revoked pairing (401) is forgotten on refresh', () async {
    final s = store();
    final connection = Connection('h', 4455);
    await s.pair(connection, deviceName: 'iPhone', platform: 'ios');
    relay.infoStatus = 401;
    await s.refresh(connection);
    expect(connection.hasRemote, isFalse);
    expect(s.info, isNull);
  });

  test('refresh shows the bridge state', () async {
    final s = store();
    final connection = Connection('h', 4455);
    await s.pair(connection, deviceName: 'iPhone', platform: 'ios');
    await s.refresh(connection);
    expect((s.info!.online, s.info!.obsState, s.info!.devices.single.isThisDevice), (true, 'running', true));
  });
}
