import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/types/enums/web_socket_codes/web_socket_close_code.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_obs_peer.dart';

/// Studio Mode scene tiles (user report 2026-11-13, "double-tap scene
/// transition"): a tap puts the scene in Preview right away, a second tap on
/// the same tile within [kStudioDoubleTapWindow] transitions it like the
/// Transition button (TriggerStudioModeTransition - OBS' transition and
/// duration apply). Settings -> Studio Mode -> Double Tap to Transition, on
/// by default.
void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late FakeObsPeer peer;
  late NetworkStore networkStore;
  late DashboardStore dashboardStore;

  List<Map<String, dynamic>> requestsOf(String requestType) => peer.requests
      .where((request) => request['requestType'] == requestType)
      .toList();

  /// The requests go out over a real socket - give them a moment to land
  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 150));

  final DateTime t0 = DateTime(2026, 11, 13, 20);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('studio_double_tap');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await harness.openAllBoxes();

    peer = await FakeObsPeer.start();
    peer.responseData['GetSceneList'] = {
      'scenes': [
        {'sceneName': 'Camera', 'sceneIndex': 0},
        {'sceneName': 'Game', 'sceneIndex': 1},
      ],
      'currentProgramSceneName': 'Camera',
      'currentPreviewSceneName': 'Camera',
    };
    peer.droppedRequestTypes.add('GetSceneItemList');
    networkStore = NetworkStore();
    dashboardStore = DashboardStore();
    GetIt.instance.registerSingleton<NetworkStore>(networkStore);
    GetIt.instance.registerSingleton<DashboardStore>(dashboardStore);

    final closeCode = await networkStore.setOBSWebSocket(peer.connection);
    expect(closeCode, WebSocketCloseCode.DontClose);
    dashboardStore.handleStream();
    peer.requests.clear();
  });

  tearDown(() async {
    dashboardStore.disposeListeners();
    networkStore.closeSession();
    await peer.close();
    await GetIt.instance.reset();
    await harness.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('one tap: preview right away, no transition', () async {
    dashboardStore.studioSceneTapped('Game', now: t0);
    expect(dashboardStore.studioModePreviewSceneName, 'Game');
    await settle();

    expect(requestsOf('SetCurrentPreviewScene'), hasLength(1));
    expect(requestsOf('SetCurrentPreviewScene').single['requestData'], {
      'sceneName': 'Game',
    });
    expect(requestsOf('TriggerStudioModeTransition'), isEmpty);
  });

  test('a quick second tap on the same tile transitions it', () async {
    dashboardStore.studioSceneTapped('Game', now: t0);
    dashboardStore.studioSceneTapped(
      'Game',
      now: t0.add(const Duration(milliseconds: 250)),
    );
    await settle();

    expect(requestsOf('SetCurrentPreviewScene'), hasLength(1));
    expect(requestsOf('TriggerStudioModeTransition'), hasLength(1));
    expect(dashboardStore.activeSceneName, 'Game', reason: 'optimistic');

    /// The trigger goes after the preview switch on the same socket - OBS
    /// transitions the scene that was just tapped
    final List<String> order = [
      for (final request in peer.requests)
        if (request['requestType'] == 'SetCurrentPreviewScene' ||
            request['requestType'] == 'TriggerStudioModeTransition')
          request['requestType'] as String,
    ];
    expect(order, ['SetCurrentPreviewScene', 'TriggerStudioModeTransition']);
  });

  test(
    'a third quick tap starts over (preview, no second transition)',
    () async {
      dashboardStore.studioSceneTapped('Game', now: t0);
      dashboardStore.studioSceneTapped(
        'Game',
        now: t0.add(const Duration(milliseconds: 200)),
      );
      dashboardStore.studioSceneTapped(
        'Game',
        now: t0.add(const Duration(milliseconds: 380)),
      );
      await settle();

      expect(requestsOf('TriggerStudioModeTransition'), hasLength(1));
      expect(requestsOf('SetCurrentPreviewScene'), hasLength(2));
    },
  );

  test('a slow second tap is just another preview pick', () async {
    dashboardStore.studioSceneTapped('Game', now: t0);
    dashboardStore.studioSceneTapped(
      'Game',
      now: t0.add(kStudioDoubleTapWindow + const Duration(milliseconds: 1)),
    );
    await settle();

    expect(requestsOf('SetCurrentPreviewScene'), hasLength(2));
    expect(requestsOf('TriggerStudioModeTransition'), isEmpty);
  });

  test(
    'quick taps on two different tiles: both previews, no transition',
    () async {
      dashboardStore.studioSceneTapped('Game', now: t0);
      dashboardStore.studioSceneTapped(
        'Camera',
        now: t0.add(const Duration(milliseconds: 150)),
      );
      await settle();

      expect(requestsOf('SetCurrentPreviewScene'), hasLength(2));
      expect(requestsOf('TriggerStudioModeTransition'), isEmpty);
      expect(dashboardStore.studioModePreviewSceneName, 'Camera');
    },
  );

  test('setting off: a quick second tap stays a preview pick', () async {
    await Hive.box(
      HiveKeys.Settings.name,
    ).put(SettingsKeys.StudioDoubleTapTransition.name, false);

    dashboardStore.studioSceneTapped('Game', now: t0);
    dashboardStore.studioSceneTapped(
      'Game',
      now: t0.add(const Duration(milliseconds: 200)),
    );
    await settle();

    expect(requestsOf('SetCurrentPreviewScene'), hasLength(2));
    expect(requestsOf('TriggerStudioModeTransition'), isEmpty);
  });

  test('screen reader action: preview, then transition', () async {
    dashboardStore.studioSceneToProgram('Game');
    await settle();

    expect(requestsOf('SetCurrentPreviewScene'), hasLength(1));
    expect(requestsOf('TriggerStudioModeTransition'), hasLength(1));
  });
}
