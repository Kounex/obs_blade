import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/types/enums/request_type.dart';
import 'package:obs_blade/types/enums/web_socket_codes/request_status.dart';
import 'package:obs_blade/types/enums/web_socket_codes/web_socket_close_code.dart';
import 'package:obs_blade/utils/network_helper.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_obs_peer.dart';

/// "Events beat stale reads" ordering for the scenes domain: a
/// CurrentProgramSceneChanged / CurrentPreviewSceneChanged event that
/// arrives while a GetSceneList re-read is in flight must survive the
/// (older) response - per field, so an event for one field never blocks
/// the other halves of the read.
void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late FakeObsPeer peer;
  late NetworkStore networkStore;
  late DashboardStore dashboardStore;

  List<Map<String, dynamic>> requestsOf(String requestType) => peer.requests
      .where((request) => request['requestType'] == requestType)
      .toList();

  Future<void> waitFor(bool Function() condition, String description) async {
    for (var i = 0; i < 100; i++) {
      if (condition()) return;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    fail('Timed out waiting for: $description');
  }

  Future<void> connect() async {
    final closeCode = await networkStore.setOBSWebSocket(peer.connection);
    expect(closeCode, WebSocketCloseCode.DontClose);
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('state_ordering');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await harness.openAllBoxes();

    peer = await FakeObsPeer.start();
    networkStore = NetworkStore();
    dashboardStore = DashboardStore();
    GetIt.instance.registerSingleton<NetworkStore>(networkStore);
    GetIt.instance.registerSingleton<DashboardStore>(dashboardStore);
  });

  tearDown(() async {
    dashboardStore.disposeListeners();
    networkStore.closeSession();
    await peer.close();
    await GetIt.instance.reset();
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test(
    'scene event during in-flight GetSceneList beats the stale read',
    () async {
      peer.responseData['GetSceneList'] = {
        'scenes': [
          {'sceneName': 'Camera', 'sceneIndex': 0},
          {'sceneName': 'Break', 'sceneIndex': 1},
        ],
        'currentProgramSceneName': 'Camera',
        'currentPreviewSceneName': 'Camera',
      };
      peer.droppedRequestTypes.add('GetSceneItemList'); // keep the chain quiet
      await connect();
      dashboardStore.handleStream();

      // drive a GetSceneList re-read via the ack layer's failure path
      peer.rejections['SetCurrentProgramScene'] =
          RequestStatus.InvalidResourceType.identifier;
      peer.ackDelay = const Duration(milliseconds: 300);
      final ackFuture = dashboardStore.sendMutation(
        RequestType.SetCurrentProgramScene,
        fields: {'sceneName': 'Nope'},
        label: 'Scene switch',
      );
      await waitFor(
        () => requestsOf('GetSceneList').isNotEmpty,
        'GetSceneList re-read in flight',
      );

      // event arrives AFTER the read was sent, carrying newer state
      peer.event('CurrentProgramSceneChanged', {'sceneName': 'Break'});
      await ackFuture; // mutation rejected; re-read resolves with stale data

      await waitFor(
        () => dashboardStore.activeSceneName == 'Break',
        'event value survives the stale read',
      );
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(dashboardStore.activeSceneName, 'Break'); // never regressed
    },
  );

  test('no mid-flight event: the re-read applies normally', () async {
    peer.responseData['GetSceneList'] = {
      'scenes': [
        {'sceneName': 'Camera', 'sceneIndex': 0},
        {'sceneName': 'Break', 'sceneIndex': 1},
      ],
      'currentProgramSceneName': 'Camera',
      'currentPreviewSceneName': 'Camera',
    };
    peer.droppedRequestTypes.add('GetSceneItemList');
    await connect();
    dashboardStore.handleStream();

    /// The optimistic write the ack layer rolls back via the re-read - the
    /// read must apply when no event beat it (no over-blocking)
    dashboardStore.setActiveSceneName('Nope');
    peer.rejections['SetCurrentProgramScene'] =
        RequestStatus.InvalidResourceType.identifier;
    peer.ackDelay = const Duration(milliseconds: 300);
    final ack = await dashboardStore.sendMutation(
      RequestType.SetCurrentProgramScene,
      fields: {'sceneName': 'Nope'},
      label: 'Scene switch',
    );
    expect(ack.success, isFalse);

    await waitFor(
      () => dashboardStore.activeSceneName == 'Camera',
      're-read applies the confirmed program scene',
    );
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(dashboardStore.activeSceneName, 'Camera');
  });

  test(
    'ordering is per-field: a preview event does not block the program half of the read',
    () async {
      peer.responseData['GetSceneList'] = {
        'scenes': [
          {'sceneName': 'Camera', 'sceneIndex': 0},
          {'sceneName': 'Break', 'sceneIndex': 1},
        ],
        'currentProgramSceneName': 'Camera',
        'currentPreviewSceneName': 'Camera',
      };
      peer.droppedRequestTypes.add('GetSceneItemList');
      await connect();
      dashboardStore.handleStream();

      /// Optimistic program write the failed mutation rolls back via the
      /// re-read - proves the program half still applies while the preview
      /// half is gated by its own event
      dashboardStore.setActiveSceneName('Nope');
      peer.rejections['SetCurrentProgramScene'] =
          RequestStatus.InvalidResourceType.identifier;
      peer.ackDelay = const Duration(milliseconds: 300);
      final ackFuture = dashboardStore.sendMutation(
        RequestType.SetCurrentProgramScene,
        fields: {'sceneName': 'Nope'},
        label: 'Scene switch',
      );
      await waitFor(
        () => requestsOf('GetSceneList').isNotEmpty,
        'GetSceneList re-read in flight',
      );

      peer.event('CurrentPreviewSceneChanged', {'sceneName': 'Break'});
      await ackFuture;

      await waitFor(
        () => dashboardStore.studioModePreviewSceneName == 'Break',
        'preview event applied',
      );
      await waitFor(
        () => dashboardStore.activeSceneName == 'Camera',
        'program half of the stale read applied',
      );
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(dashboardStore.activeSceneName, 'Camera');
      expect(dashboardStore.studioModePreviewSceneName, 'Break');
    },
  );

  /// Same ordering guarantee for the scene-item visibility domain: a
  /// SceneItemEnableStateChanged event that arrives while a GetSceneItemList
  /// re-read is in flight must survive the (older) response
  group('scene-item visibility ordering', () {
    void setupItemListPeer() {
      peer.responseData['GetSceneList'] = {
        'scenes': [
          {'sceneName': 'Camera', 'sceneIndex': 0},
        ],
        'currentProgramSceneName': 'Camera',
        'currentPreviewSceneName': 'Camera',
      };
      peer.responseData['GetSceneItemList'] = {
        'sceneItems': [
          {
            'sceneItemId': 7,
            'sceneItemIndex': 0,
            'sceneItemEnabled': true,
            'sourceName': 't1',
            'isGroup': false,
          },
        ],
      };

      /// The non-empty item list triggers a FilterList batch - its ack must
      /// not hang at teardown, so drop it and let the short timeout clean up
      peer.droppedRequestTypes.add('GetSourceFilterList');
      NetworkHelper.requestAckTimeout = const Duration(milliseconds: 300);
      addTearDown(
        () => NetworkHelper.requestAckTimeout = const Duration(seconds: 10),
      );
    }

    Future<void> applyInitialItemList() async {
      await connect();
      dashboardStore.handleStream();

      /// Tests skip initialRequests - a program-scene event both sets the
      /// displayed scene and triggers the item read
      peer.event('CurrentProgramSceneChanged', {'sceneName': 'Camera'});
      await waitFor(
        () => dashboardStore.currentSceneItems.isNotEmpty,
        'initial GetSceneItemList applied',
      );
      expect(dashboardStore.currentSceneItems.single.sceneItemEnabled, isTrue);
    }

    test(
      'visibility event during in-flight GetSceneItemList beats the stale read',
      () async {
        setupItemListPeer();
        await applyInitialItemList();

        peer.ackDelay = const Duration(milliseconds: 300);
        peer.event('CurrentProgramSceneChanged', {'sceneName': 'Camera'});
        await waitFor(
          () => requestsOf('GetSceneItemList').length == 2,
          'GetSceneItemList re-read in flight',
        );

        /// arrives AFTER the re-read was sent, carrying newer state
        peer.event('SceneItemEnableStateChanged', {
          'sceneName': 'Camera',
          'sceneItemId': 7,
          'sceneItemEnabled': false,
        });
        await waitFor(
          () =>
              dashboardStore.currentSceneItems.single.sceneItemEnabled == false,
          'event value applied',
        );

        /// the stale read (enabled: true) resolves now - it must not
        /// overwrite the event value
        await Future<void>.delayed(const Duration(milliseconds: 500));
        expect(
          dashboardStore.currentSceneItems.single.sceneItemEnabled,
          isFalse,
        );
      },
    );

    test('no mid-flight event: the item re-read applies normally', () async {
      setupItemListPeer();
      await applyInitialItemList();

      /// optimistic local write the confirmed re-read must overwrite (no
      /// over-blocking)
      dashboardStore.currentSceneItems = ObservableList.of([
        dashboardStore.currentSceneItems.single.copyWith(
          sceneItemEnabled: false,
        ),
      ]);

      peer.ackDelay = const Duration(milliseconds: 300);
      peer.event('CurrentProgramSceneChanged', {'sceneName': 'Camera'});
      await waitFor(
        () => requestsOf('GetSceneItemList').length == 2,
        'GetSceneItemList re-read in flight',
      );

      await waitFor(
        () => dashboardStore.currentSceneItems.single.sceneItemEnabled == true,
        're-read applies the confirmed visibility',
      );
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(dashboardStore.currentSceneItems.single.sceneItemEnabled, isTrue);
    });
  });
}
