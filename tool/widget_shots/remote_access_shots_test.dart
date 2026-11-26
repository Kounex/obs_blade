import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/utils/modal_handler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/models/connection.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/stores/shared/remote_bridge_updates.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/stores/views/remote_access.dart';
import 'package:obs_blade/utils/remote/remote_relay_client.dart';
import 'package:obs_blade/views/dashboard/widgets/remote_access/remote_access_sheet.dart';
import 'package:obs_blade/views/dashboard/widgets/remote_access/remote_update.dart';
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
    String version = '0.2.0',
    String? latest,
    bool available = false,
  }) => {
    'id': 'b_1',
    'name': 'GAMING-PC',
    'kind': kind,
    'version': version,
    'online': online,
    'last_seen': now - 2 * 3600,
    'obs': obs,
    'update_required': update,
    'latest_version': latest,
    'update_available': available,
    'devices': [
      {
        'id': 'd_me',
        'name': 'iPhone',
        'platform': 'ios',
        'last_used': now,
        'connected': true,
        'self': true,
      },
      {
        'id': 'd_2',
        'name': 'iPad',
        'platform': 'ios',
        'last_used': now - 86400,
        'connected': false,
      },
      {
        'id': 'd_3',
        'name': 'Android phone',
        'platform': 'android',
        'last_used': now - 3 * 86400,
        'connected': false,
      },
    ],
  };

  RemoteAccessStore store([Map<String, dynamic>? bridge]) => RemoteAccessStore(
    relay: RemoteRelayClient(
      baseUrl: 'https://relay.example',
      client: MockClient(
        (_) async => bridge == null
            ? http.Response('', 503)
            : http.Response(
                jsonEncode(bridge),
                200,
                headers: {'content-type': 'application/json'},
              ),
      ),
    ),
    appUserId: () async => 'x',
    sendCode: (_, _) async {},
    acks: () => const Stream.empty(),
  );

  Connection connection({bool paired = false, String kind = 'plugin'}) {
    final c = Connection('192.168.178.20', 4455)
      ..name = 'GAMING-PC'
      ..pw = 'secret'
      ..lastConnectedMs =
          DateTime.now().millisecondsSinceEpoch - 2 * 3600 * 1000;
    if (paired) {
      c
        ..relayBridgeId = 'b_1'
        ..relayAppToken = 'tok'
        ..relayDeviceId = 'd_me'
        ..relayBridgeName = 'GAMING-PC'
        ..relayBridgeKind = kind
        ..relayAppKey = base64Encode(List.filled(32, 1))
        ..relayBridgeKey = base64Encode(List.filled(32, 2));
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
  Future<void> all(
    WidgetTester tester,
    String name,
    Widget Function() build,
  ) async {
    await harness.shot(tester, name, build());
    await harness.shot(
      tester,
      '${name}_narrow',
      build(),
      size: const Size(320, 640),
    );
    await harness.shot(tester, '${name}_tablet', build(), size: kShotTablet);
  }

  /// The sheet as the app opens it (ModalHandler's sheet: handle, width
  /// cap, glass on Apple) - the content alone hid how the header sits
  /// in the sheet chrome (2026-11-08)
  Widget inRealSheet(Widget Function() build) =>
      ShotsHarness.inSheet(build, height: BaseSheetHeight.tall);

  testWidgets('in the real sheet: header in the sheet chrome', (tester) async {
    for (final (name, pro) in [
      ('remote_sheet_free', false),
      ('remote_sheet_pro', true),
    ]) {
      await harness.shot(
        tester,
        name,
        inRealSheet(() => sheet(store(), connection(), pro: pro)),
      );
      await harness.shot(
        tester,
        '${name}_narrow',
        inRealSheet(() => sheet(store(), connection(), pro: pro)),
        size: const Size(320, 640),
      );
    }
  });

  testWidgets('locked (not Pro): the setup pitch, Unlock Pro', (tester) async {
    await all(
      tester,
      'remote_locked',
      () => sheet(store(), connection(), pro: false),
    );
  });

  testWidgets('needs a saved connection', (tester) async {
    await harness.shot(
      tester,
      'remote_unsaved',
      sheet(store(), connection(), saved: false),
    );
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

  testWidgets('waiting too long: what is missing on the PC', (tester) async {
    for (final hint in [
      RemotePairingFailure.noBridge,
      RemotePairingFailure.noConfirmation,
    ]) {
      await all(tester, 'remote_waiting_hint_${hint.name}', () {
        final s = store();
        runInAction(() {
          s.phase = RemotePairingPhase.waitingForBridge;
          s.code = 'K7F3Q9XM';
          s.waitHint = hint;
        });
        return sheet(s, connection());
      });
    }
  });

  testWidgets('failures', (tester) async {
    for (final failure in [
      RemotePairingFailure.noBridge,
      RemotePairingFailure.noConfirmation,
      RemotePairingFailure.proRequired,
      RemotePairingFailure.network,
    ]) {
      final s = store();
      runInAction(() {
        s.phase = RemotePairingPhase.failed;
        s.failure = failure;
      });
      await harness.shot(
        tester,
        'remote_failed_${failure.name}',
        sheet(s, connection()),
      );
    }
  });

  testWidgets('paired: online, via relay', (tester) async {
    await all(
      tester,
      'remote_paired_online',
      () => sheet(store(info()), connection(paired: true), viaRemote: true),
    );
  });

  testWidgets('paired: online, on the local network', (tester) async {
    await all(
      tester,
      'remote_paired_lan',
      () => sheet(store(info()), connection(paired: true)),
    );
  });

  testWidgets('paired: plugin offline after OBS closed', (tester) async {
    await harness.shot(
      tester,
      'remote_paired_obs_closed',
      sheet(
        store(info(online: false, obs: 'closed')),
        connection(paired: true),
      ),
    );
  });

  testWidgets('paired: standalone offline, update required, ws off', (
    tester,
  ) async {
    await harness.shot(
      tester,
      'remote_paired_offline_standalone',
      sheet(
        store(info(online: false, obs: '', kind: 'standalone')),
        connection(paired: true, kind: 'standalone'),
      ),
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

  /// 2026-11-26: a newer OBS Blade Remote for the PC - card in the sheet
  /// (light too: the tint is a status color), and the connect prompt
  /// Real async: a Hive write never finishes in the test's fake async
  Future<void> lightTheme(WidgetTester tester) => tester.runAsync(() async {
    final Box settings = Hive.box(HiveKeys.Settings.name);
    await settings.put(SettingsKeys.CustomTheme.name, true);
    await settings.put(
      SettingsKeys.ActiveCustomThemeUUID.name,
      '4c6b99aa-4d4d-45a6-ba25-53dd181c36cd', // Bright Star
    );
  });

  final Map<String, Map<String, dynamic>> updates = {
    'available': info(
      kind: 'standalone',
      version: '0.4.1',
      latest: '0.4.3',
      available: true,
    ),
    'available_plugin': info(
      version: '0.4.1',
      latest: '0.4.3',
      available: true,
    ),
    'required': info(
      kind: 'standalone',
      version: '0.2.0',
      latest: '0.4.3',
      update: true,
    ),
  };

  for (final light in [false, true]) {
    testWidgets('paired: OBS Blade Remote update (light: $light)', (
      tester,
    ) async {
      if (light) await lightTheme(tester);
      final String suffix = light ? '_light' : '';
      for (final MapEntry(key: name, value: bridge) in updates.entries) {
        await harness.shot(
          tester,
          'remote_update_$name$suffix',
          sheet(
            store(bridge),
            connection(paired: true, kind: bridge['kind'] as String),
          ),
        );
      }
      await harness.shot(
        tester,
        'remote_update_card_narrow$suffix',
        sheet(
          store(updates['available']),
          connection(paired: true, kind: 'standalone'),
        ),
        size: const Size(320, 640),
      );
      for (final (name, bridge, reason) in [
        ('available', updates['available']!, null),
        ('required', updates['required']!, null),
        (
          'obs_check',
          updates['available']!,
          'OBS is running on GAMING-PC, but OBS Blade Remote 0.4.1 there '
              'doesn\'t see it - an update fixes that.',
        ),
      ]) {
        final RemoteBridgeUpdate update = RemoteBridgeUpdate(
          kind: bridge['kind'] as String,
          current: bridge['version'] as String,
          latest: bridge['latest_version'] as String,
          required: bridge['update_required'] as bool,
        );
        await harness.shot(
          tester,
          'remote_update_dialog_$name$suffix',
          Builder(
            builder: (context) => Center(
              child: remoteUpdateDialog(
                context,
                update,
                pc: 'GAMING-PC',
                reason: reason,
              ),
            ),
          ),
        );
      }
    });
  }

  testWidgets('paired: relay unreachable', (tester) async {
    await harness.shot(
      tester,
      'remote_paired_relay_down',
      sheet(store(), connection(paired: true)),
    );
  });

  testWidgets('saved connection card with remote access', (tester) async {
    final Widget card = Center(
      child: ConnectionBox(
        connection: connection(paired: true)..reachable = false,
      ),
    );
    await harness.shot(tester, 'remote_card', card);
    await harness.shot(
      tester,
      'remote_card_narrow',
      card,
      size: const Size(320, 640),
    );
    final Widget plain = Center(
      child: ConnectionBox(connection: connection()..reachable = true),
    );
    await harness.shot(tester, 'remote_card_unpaired', plain);
  });
}
