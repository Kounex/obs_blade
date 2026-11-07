import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/models/connection.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/stores/views/remote_access.dart';
import 'package:obs_blade/utils/remote/remote_relay_client.dart';
import 'package:obs_blade/views/dashboard/widgets/remote_access/remote_access_sheet.dart';
import 'package:obs_blade/views/home/widgets/saved_connections/connection_box.dart';

import 'support/shots_harness.dart';

/// Remote access (Pro): the dashboard sheet in every state and the saved
/// connection card with a pairing. Phone, narrow 320 pt and tablet.
void main() {
  final harness = ShotsHarness();

  setUpAll(ShotsHarness.loadFonts);

  setUp(() async {
    await harness.setUp();
    GetIt.instance.registerSingleton<NetworkStore>(NetworkStore());
  });

  tearDown(() async {
    await GetIt.instance.reset();
    await harness.tearDown();
  });

  final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  Map<String, dynamic> info({
    bool online = true,
    String obs = 'running',
    String kind = 'plugin',
    bool update = false,
  }) => {
    'id': 'b_1',
    'name': 'GAMING-PC',
    'kind': kind,
    'version': '0.2.0',
    'online': online,
    'last_seen': now - 2 * 3600,
    'obs': obs,
    'update_required': update,
    'devices': [
      {'id': 'd_me', 'name': 'iPhone', 'platform': 'ios', 'last_used': now, 'connected': true, 'self': true},
      {'id': 'd_2', 'name': 'iPad', 'platform': 'ios', 'last_used': now - 86400, 'connected': false},
      {'id': 'd_3', 'name': 'Android phone', 'platform': 'android', 'last_used': now - 3 * 86400, 'connected': false},
    ],
  };

  RemoteAccessStore store([Map<String, dynamic>? bridge]) => RemoteAccessStore(
    relay: RemoteRelayClient(
      baseUrl: 'https://relay.example',
      client: MockClient(
        (_) async => bridge == null
            ? http.Response('', 503)
            : http.Response(jsonEncode(bridge), 200, headers: {'content-type': 'application/json'}),
      ),
    ),
    appUserId: () async => 'x',
    sendCode: (_) async => true,
  );

  Connection connection({bool paired = false, String kind = 'plugin'}) {
    final c = Connection('192.168.178.20', 4455)
      ..name = 'GAMING-PC'
      ..pw = 'secret'
      ..lastConnectedMs = DateTime.now().millisecondsSinceEpoch - 2 * 3600 * 1000;
    if (paired) {
      c
        ..relayBridgeId = 'b_1'
        ..relayAppToken = 'tok'
        ..relayDeviceId = 'd_me'
        ..relayBridgeName = 'GAMING-PC'
        ..relayBridgeKind = kind;
    }
    return c;
  }

  Widget sheet(
    RemoteAccessStore s,
    Connection c, {
    bool pro = true,
    bool saved = true,
    bool viaRemote = false,
  }) => RemoteAccessSheet(
    connection: c,
    saved: saved,
    isPro: pro,
    viaRemote: viaRemote,
    store: s,
    deviceName: 'iPhone',
    platform: 'ios',
    onGetPro: () {},
    onSaveConnection: () {},
  );

  /// [build] per shot: closing a sheet cancels its store's pairing, so
  /// every shot gets its own (as every opened sheet does in the app)
  Future<void> all(WidgetTester tester, String name, Widget Function() build) async {
    await harness.shot(tester, name, build());
    await harness.shot(tester, '${name}_narrow', build(), size: const Size(320, 640));
    await harness.shot(tester, '${name}_tablet', build(), size: kShotTablet);
  }

  testWidgets('locked (not Pro)', (tester) async {
    await harness.shot(tester, 'remote_locked', sheet(store(), connection(), pro: false));
  });

  testWidgets('needs a saved connection', (tester) async {
    await harness.shot(tester, 'remote_unsaved', sheet(store(), connection(), saved: false));
  });

  testWidgets('set up', (tester) async {
    await all(tester, 'remote_setup', () => sheet(store(), connection()));
  });

  testWidgets('waiting for the bridge', (tester) async {
    await all(tester, 'remote_waiting', () {
      final s = store();
      runInAction(() {
        s.phase = RemotePairingPhase.waitingForBridge;
        s.code = 'K7F3Q9XM';
      });
      return sheet(s, connection());
    });
  });

  testWidgets('failures', (tester) async {
    for (final failure in [RemotePairingFailure.noBridge, RemotePairingFailure.proRequired, RemotePairingFailure.network]) {
      final s = store();
      runInAction(() {
        s.phase = RemotePairingPhase.failed;
        s.failure = failure;
      });
      await harness.shot(tester, 'remote_failed_${failure.name}', sheet(s, connection()));
    }
  });

  testWidgets('paired: online, via relay', (tester) async {
    await all(tester, 'remote_paired_online', () => sheet(store(info()), connection(paired: true), viaRemote: true));
  });

  testWidgets('paired: plugin offline after OBS closed', (tester) async {
    await harness.shot(
      tester,
      'remote_paired_obs_closed',
      sheet(store(info(online: false, obs: 'closed')), connection(paired: true)),
    );
  });

  testWidgets('paired: standalone offline, update required, ws off', (tester) async {
    await harness.shot(
      tester,
      'remote_paired_offline_standalone',
      sheet(store(info(online: false, obs: '', kind: 'standalone')), connection(paired: true, kind: 'standalone')),
    );
    await harness.shot(
      tester,
      'remote_paired_update',
      sheet(store(info(update: true)), connection(paired: true)),
    );
    await harness.shot(
      tester,
      'remote_paired_ws_off',
      sheet(store(info(obs: 'ws_off')), connection(paired: true)),
    );
  });

  testWidgets('paired: relay unreachable', (tester) async {
    await harness.shot(tester, 'remote_paired_relay_down', sheet(store(), connection(paired: true)));
  });

  testWidgets('saved connection card with remote access', (tester) async {
    final Widget card = Center(child: ConnectionBox(connection: connection(paired: true)..reachable = false));
    await harness.shot(tester, 'remote_card', card);
    await harness.shot(tester, 'remote_card_narrow', card, size: const Size(320, 640));
    final Widget plain = Center(child: ConnectionBox(connection: connection()..reachable = true));
    await harness.shot(tester, 'remote_card_unpaired', plain);
  });
}
