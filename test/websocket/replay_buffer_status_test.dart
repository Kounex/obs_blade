import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/types/enums/request_type.dart';
import 'package:obs_blade/types/enums/web_socket_codes/web_socket_close_code.dart';
import 'package:obs_blade/utils/network_helper.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_obs_peer.dart';

/// Regression: connecting to an OBS whose replay buffer is ALREADY running
/// must light up the dashboard (Save button enabled) without the user
/// toggling the buffer in OBS first. The `GetReplayBufferStatus` response
/// carries `outputActive` - the DTO used to read a v4-era key that never
/// exists in v5, so the initial read always landed as `false` and only the
/// `ReplayBufferStateChanged` event (toggling in OBS) fixed the state.
void main() {
  /// The stop-event path closes overlays (OverlayHandler → WidgetsBinding)
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late HiveTestHarness harness;
  late FakeObsPeer peer;
  late NetworkStore networkStore;
  late DashboardStore dashboardStore;

  List<Map<String, dynamic>> requestsOf(String requestType) => peer.requests
      .where((request) => request['requestType'] == requestType)
      .toList();

  Future<void> waitFor(bool Function() condition, String description) async {
    for (var i = 0; i < 500; i++) {
      if (condition()) return;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    fail('Timed out waiting for: $description');
  }

  /// Deterministic "everything sent before was processed" gate (same
  /// reasoning as in preview_and_media_refresh_test.dart)
  Future<void> flushPeer() => NetworkHelper.makeRequest(
    networkStore.activeSession!.socket,
    RequestType.GetVersion,
  );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('replay_buffer_status');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await harness.openAllBoxes();
    peer = await FakeObsPeer.start();
    networkStore = NetworkStore();
    dashboardStore = DashboardStore();
    GetIt.instance.registerSingleton<NetworkStore>(networkStore);
    GetIt.instance.registerSingleton<DashboardStore>(dashboardStore);

    /// flushPeer's / initialRequests' GetVersion responses run through the
    /// dashboard's GetVersion handler - they must parse cleanly
    peer.responseData['GetVersion'] = {
      'availableRequests': <String>[],
      'supportedImageFormats': ['jpg', 'png'],
    };
    expect(
      await networkStore.setOBSWebSocket(peer.connection),
      WebSocketCloseCode.DontClose,
    );
    dashboardStore.handleStream();
  });

  tearDown(() async {
    dashboardStore.disposeListeners();
    networkStore.closeSession();
    await peer.close();
    await GetIt.instance.reset();
    await harness.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test(
    'connecting to a running replay buffer is detected from the initial burst',
    () async {
      peer.responseData['GetReplayBufferStatus'] = {'outputActive': true};

      dashboardStore.initialRequests();

      await waitFor(
        () => requestsOf('GetReplayBufferStatus').isNotEmpty,
        'initial burst asks for the replay buffer status',
      );
      await waitFor(
        () => dashboardStore.isReplayBufferActive,
        'running replay buffer reflected after connect',
      );
    },
  );

  test('a stopped replay buffer stays inactive after connect', () async {
    peer.responseData['GetReplayBufferStatus'] = {'outputActive': false};

    dashboardStore.initialRequests();
    await flushPeer();

    expect(dashboardStore.isReplayBufferActive, isFalse);
  });

  test(
    'the state-changed event still drives the state after connect',
    () async {
      peer.responseData['GetReplayBufferStatus'] = {'outputActive': true};
      dashboardStore.initialRequests();
      await waitFor(
        () => dashboardStore.isReplayBufferActive,
        'running replay buffer reflected after connect',
      );

      peer.event('ReplayBufferStateChanged', {
        'outputActive': false,
        'outputState': 'OBS_WEBSOCKET_OUTPUT_STOPPED',
      });
      await waitFor(
        () => !dashboardStore.isReplayBufferActive,
        'stop event applied',
      );
    },
  );
}
