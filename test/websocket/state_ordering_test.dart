import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/types/classes/api/scene_item.dart';
import 'package:obs_blade/types/classes/api/scene.dart';
import 'package:get_it/get_it.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/types/enums/request_type.dart';
import 'package:obs_blade/types/enums/web_socket_codes/request_status.dart';
import 'package:obs_blade/types/enums/web_socket_codes/web_socket_close_code.dart';
import 'package:obs_blade/utils/network_helper.dart';

import 'package:obs_blade/types/classes/api/input.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_obs_peer.dart';

/// "Events beat stale reads" ordering for the scenes domain: a
/// CurrentProgramSceneChanged / CurrentPreviewSceneChanged event that
/// arrives while a GetSceneList re-read is in flight must survive the
/// (older) response - per field, so an event for one field never blocks
/// the other halves of the read.
///
/// Synchronization is fully deterministic: the peer holds the re-read's
/// ack (no wall-clock delays), the test fires the mid-flight event, then
/// releases the stale ack and proves it was fully processed via the
/// flushPeer gate before asserting.
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
    for (var i = 0; i < 500; i++) {
      if (condition()) return;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    fail('Timed out waiting for: $description');
  }

  Future<void> connect() async {
    final closeCode = await networkStore.setOBSWebSocket(peer.connection);
    expect(closeCode, WebSocketCloseCode.DontClose);
  }

  /// Deterministic "everything sent before was processed" gate: the peer
  /// answers this benign request immediately (it is never held), and the
  /// WebSocket delivers server→client messages in order on the single
  /// socket - so once this ack's future completes, every earlier message
  /// (a released stale response included) has been fully handled
  /// client-side
  Future<void> flushPeer() => NetworkHelper.makeRequest(
    networkStore.activeSession!.socket,
    RequestType.GetVersion,
  );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('state_ordering');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await harness.openAllBoxes();

    peer = await FakeObsPeer.start();

    /// [flushPeer] / initialRequests GetVersion responses run through the
    /// dashboard's GetVersion handler - they must parse cleanly
    peer.responseData['GetVersion'] = {
      'availableRequests': <String>[],
      'supportedImageFormats': ['jpg', 'png'],
    };

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

      // drive a GetSceneList re-read via the ack layer's failure path; its
      // ack is held so the re-read stays in flight until released below
      peer.rejections['SetCurrentProgramScene'] =
          RequestStatus.InvalidResourceType.identifier;
      peer.heldRequestTypes.add('GetSceneList');
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
      await waitFor(
        () => dashboardStore.activeSceneName == 'Break',
        'event value applied',
      );
      await ackFuture; // mutation rejected

      // the stale read resolves now - it must not overwrite the event value
      peer.releaseOne('GetSceneList');
      await flushPeer();
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
    peer.heldRequestTypes.add('GetSceneList');
    final ack = await dashboardStore.sendMutation(
      RequestType.SetCurrentProgramScene,
      fields: {'sceneName': 'Nope'},
      label: 'Scene switch',
    );
    expect(ack.success, isFalse);
    await waitFor(
      () => requestsOf('GetSceneList').isNotEmpty,
      'GetSceneList re-read in flight',
    );

    peer.releaseOne('GetSceneList');
    await flushPeer();
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
      peer.heldRequestTypes.add('GetSceneList');
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
      await waitFor(
        () => dashboardStore.studioModePreviewSceneName == 'Break',
        'preview event applied',
      );
      await ackFuture;

      // the stale read resolves now - only its program half may apply
      peer.releaseOne('GetSceneList');
      await flushPeer();
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
        () => NetworkHelper.requestAckTimeout = const Duration(seconds: 35),
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

        peer.heldRequestTypes.add('GetSceneItemList');
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
        peer.releaseOne('GetSceneItemList');
        await flushPeer();
        expect(
          dashboardStore.currentSceneItems.single.sceneItemEnabled,
          isFalse,
        );
      },
    );

    /// User report: toggling visibility / lock of an item inside a group
    /// did nothing. obs-websocket names a grouped item's change by its
    /// group (the item's own obs_scene_t, EventHandler_SceneItems.cpp), and
    /// the dashboard confirms a toggle only through that event
    test('a group\'s item events reach its children - and only them '
        '(item ids are unique per scene, not across its groups)', () async {
      setupItemListPeer();
      peer.responseData['GetSceneItemList'] = {
        'sceneItems': [
          {
            'sceneItemId': 7,
            'sceneItemIndex': 1,
            'sceneItemEnabled': true,
            'sceneItemLocked': false,
            'sourceName': 't1',
            'isGroup': false,
          },
          {
            'sceneItemId': 9,
            'sceneItemIndex': 0,
            'sceneItemEnabled': true,
            'sceneItemLocked': false,
            'sourceName': 'Overlays',
            'isGroup': true,
          },
        ],
      };
      peer.responseData['GetGroupSceneItemList'] = {
        'sceneItems': [
          {
            'sceneItemId': 7,
            'sceneItemIndex': 0,
            'sceneItemEnabled': true,
            'sceneItemLocked': false,
            'sourceName': 'Alert box',
            'isGroup': false,
          },
        ],
      };
      await connect();
      dashboardStore.handleStream();
      peer.event('CurrentProgramSceneChanged', {'sceneName': 'Camera'});
      SceneItem child() => dashboardStore.currentSceneItems.singleWhere(
        (item) => item.parentGroupName == 'Overlays',
      );
      SceneItem top() => dashboardStore.currentSceneItems.singleWhere(
        (item) => item.sourceName == 't1',
      );
      await waitFor(
        () => dashboardStore.currentSceneItems.length == 3,
        'scene items + the group child applied',
      );

      peer.event('SceneItemEnableStateChanged', {
        'sceneName': 'Overlays',
        'sceneUuid': 'group-overlays',
        'sceneItemId': 7,
        'sceneItemEnabled': false,
      });
      peer.event('SceneItemLockStateChanged', {
        'sceneName': 'Overlays',
        'sceneUuid': 'group-overlays',
        'sceneItemId': 7,
        'sceneItemLocked': true,
      });
      await waitFor(
        () => child().sceneItemEnabled == false && child().sceneItemLocked!,
        'group child toggled',
      );
      expect(top().sceneItemEnabled, isTrue);
      expect(top().sceneItemLocked, isFalse);

      /// The scene's own item 7 doesn't touch the group's item 7
      peer.event('SceneItemEnableStateChanged', {
        'sceneName': 'Camera',
        'sceneItemId': 7,
        'sceneItemEnabled': false,
      });
      await waitFor(
        () => top().sceneItemEnabled == false,
        'top-level item toggled',
      );
      peer.event('SceneItemEnableStateChanged', {
        'sceneName': 'Overlays',
        'sceneItemId': 7,
        'sceneItemEnabled': true,
      });
      await waitFor(() => child().sceneItemEnabled == true, 'child back on');
      expect(top().sceneItemEnabled, isFalse);
    });

    test('a same-named scene of another canvas never patches the displayed '
        'items (UUID decides)', () async {
      setupItemListPeer();
      await applyInitialItemList();
      dashboardStore.scenes = ObservableList.of(const [
        Scene(sceneName: 'Camera', sceneIndex: 0, sceneUuid: 'cam-main'),
      ]);

      /// Vertical canvas scene, also called "Camera", same item id
      peer.event('SceneItemEnableStateChanged', {
        'sceneName': 'Camera',
        'sceneUuid': 'cam-vertical',
        'sceneItemId': 7,
        'sceneItemEnabled': false,
      });
      peer.event('SceneItemLockStateChanged', {
        'sceneName': 'Camera',
        'sceneUuid': 'cam-vertical',
        'sceneItemId': 7,
        'sceneItemLocked': true,
      });
      await flushPeer();
      expect(dashboardStore.currentSceneItems.single.sceneItemEnabled, isTrue);
      expect(
        dashboardStore.currentSceneItems.single.sceneItemLocked,
        isNot(true),
      );

      /// The displayed scene's own event still applies
      peer.event('SceneItemEnableStateChanged', {
        'sceneName': 'Camera',
        'sceneUuid': 'cam-main',
        'sceneItemId': 7,
        'sceneItemEnabled': false,
      });
      await waitFor(
        () => dashboardStore.currentSceneItems.single.sceneItemEnabled == false,
        'main scene event applied',
      );
    });

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

      peer.heldRequestTypes.add('GetSceneItemList');
      peer.event('CurrentProgramSceneChanged', {'sceneName': 'Camera'});
      await waitFor(
        () => requestsOf('GetSceneItemList').length == 2,
        'GetSceneItemList re-read in flight',
      );

      peer.releaseOne('GetSceneItemList');
      await flushPeer();
      expect(dashboardStore.currentSceneItems.single.sceneItemEnabled, isTrue);
    });

    test(
      'lock event updates the displayed item, other scenes ignored',
      () async {
        setupItemListPeer();
        await applyInitialItemList();

        peer.event('SceneItemLockStateChanged', {
          'sceneName': 'Other',
          'sceneItemId': 7,
          'sceneItemLocked': true,
        });
        peer.event('SceneItemLockStateChanged', {
          'sceneName': 'Camera',
          'sceneItemId': 7,
          'sceneItemLocked': true,
        });
        await waitFor(
          () => dashboardStore.currentSceneItems.single.sceneItemLocked == true,
          'lock applied from the displayed scene',
        );
      },
    );
  });

  /// Same ordering guarantee for the audio volume/mute domain: an
  /// InputVolumeChanged / InputMuteStateChanged event that arrives while a
  /// GetInputVolume / GetInputMute re-read is in flight must survive the
  /// (older) response
  group('scene-item list ordering', () {
    Map<String, dynamic> itemsFor(String sourceName, int id) => {
      'sceneItems': [
        {
          'sceneItemId': id,
          'sceneItemIndex': 0,
          'sceneItemEnabled': true,
          'sourceName': sourceName,
          'isGroup': false,
        },
      ],
    };

    test('a late item list for a scene the dashboard already left does not '
        'replace the current scene\'s items', () async {
      /// OBS answers from a thread pool: the Camera read (sent first)
      /// answers AFTER the Break read - simulated by holding only the
      /// Camera ack until the Break state has fully landed
      peer.responseDataFor = (request) =>
          request['requestType'] == 'GetSceneItemList'
          ? (request['requestData']['sceneName'] == 'Camera'
                ? itemsFor('webcam', 1)
                : itemsFor('brb-slate', 2))
          : null;
      peer.holdRequestFor = (request) =>
          request['requestType'] == 'GetSceneItemList' &&
          request['requestData']['sceneName'] == 'Camera';
      peer.droppedRequestTypes.add('GetSourceFilterList');
      NetworkHelper.requestAckTimeout = const Duration(milliseconds: 300);
      addTearDown(
        () => NetworkHelper.requestAckTimeout = const Duration(seconds: 35),
      );

      await connect();
      dashboardStore.handleStream();

      peer.event('CurrentProgramSceneChanged', {'sceneName': 'Camera'});
      await waitFor(
        () => requestsOf('GetSceneItemList').length == 1,
        'Camera item read in flight',
      );
      peer.event('CurrentProgramSceneChanged', {'sceneName': 'Break'});

      await waitFor(
        () =>
            dashboardStore.currentSceneItems.isNotEmpty &&
            dashboardStore.currentSceneItems.single.sourceName == 'brb-slate',
        'Break items applied',
      );

      /// the late Camera response lands now - it must be dropped
      peer.releaseOne('GetSceneItemList');
      await flushPeer();
      expect(dashboardStore.activeSceneName, 'Break');
      expect(dashboardStore.currentSceneItems.single.sourceName, 'brb-slate');
      expect(dashboardStore.sceneItemsSceneName, 'Break');
    });
  });

  group('audio volume/mute ordering', () {
    Input mic() => dashboardStore.allInputs.singleWhere(
      (input) => input.inputName == 'Mic',
    );

    void setupAudioPeer() {
      peer.responseData['GetSceneList'] = {
        'scenes': [
          {'sceneName': 'Camera', 'sceneIndex': 0},
        ],
        'currentProgramSceneName': 'Camera',
        'currentPreviewSceneName': 'Camera',
      };
      peer.droppedRequestTypes.add('GetSceneItemList'); // keep the chain quiet
      peer.responseData['GetInputList'] = {
        'inputs': [
          {'inputName': 'Mic'},
        ],
      };

      /// The Input batch (follows GetInputList automatically) and the single
      /// re-reads answer from these - the confirmed-but-stale values
      peer.responseData['GetInputVolume'] = {
        'inputVolumeMul': 0.5,
        'inputVolumeDb': -9.0,
      };
      peer.responseData['GetInputMute'] = {'inputMuted': false};
      peer.responseData['GetInputAudioSyncOffset'] = {
        'inputAudioSyncOffset': 0,
      };

      /// Kept short so dropped requests can never outlive a test - with
      /// held (not delayed) acks the timeout can no longer race a response
      NetworkHelper.requestAckTimeout = const Duration(milliseconds: 800);
      addTearDown(
        () => NetworkHelper.requestAckTimeout = const Duration(seconds: 35),
      );
    }

    Future<void> applyInitialInputState() async {
      await connect();
      dashboardStore.handleStream();
      dashboardStore.initialRequests();

      await waitFor(
        () => dashboardStore.allInputs.any((input) => input.inputName == 'Mic'),
        'initial GetInputList applied',
      );
      await waitFor(
        () => mic().inputVolumeMul == 0.5,
        'initial Input batch applied',
      );
      expect(mic().inputVolumeDb, -9.0);
      expect(mic().inputMuted, isFalse);
    }

    test(
      'volume event during in-flight GetInputVolume beats the stale re-read',
      () async {
        setupAudioPeer();
        await applyInitialInputState();

        peer.rejections['SetInputVolume'] =
            RequestStatus.GenericError.identifier;
        peer.heldRequestTypes.add('GetInputVolume');
        final ackFuture = dashboardStore.sendMutation(
          RequestType.SetInputVolume,
          fields: {'inputName': 'Mic', 'inputVolumeMul': 0.8},
          label: 'Volume',
        );
        await waitFor(
          () => requestsOf('GetInputVolume').isNotEmpty,
          'GetInputVolume re-read in flight',
        );

        /// arrives AFTER the re-read was sent, carrying newer state
        peer.event('InputVolumeChanged', {
          'inputName': 'Mic',
          'inputVolumeMul': 0.9,
          'inputVolumeDb': -0.9,
        });
        await waitFor(() => mic().inputVolumeMul == 0.9, 'event value applied');
        final ack = await ackFuture;
        expect(ack.success, isFalse);

        /// the stale re-read (0.5) resolves now - it must not overwrite the
        /// event value
        peer.releaseOne('GetInputVolume');
        await flushPeer();
        expect(mic().inputVolumeMul, 0.9);
        expect(mic().inputVolumeDb, -0.9);
      },
    );

    test('no mid-flight event: the volume re-read applies normally', () async {
      setupAudioPeer();
      await applyInitialInputState();

      /// Change the value first - with no read in flight the event applies
      /// directly. (Asserting 0.5 right after the rejection would be
      /// vacuous: the initial batch already applied 0.5.)
      peer.event('InputVolumeChanged', {
        'inputName': 'Mic',
        'inputVolumeMul': 0.9,
        'inputVolumeDb': -0.9,
      });
      await waitFor(
        () => mic().inputVolumeMul == 0.9,
        'event applied with no read in flight',
      );

      peer.rejections['SetInputVolume'] = RequestStatus.GenericError.identifier;
      peer.heldRequestTypes.add('GetInputVolume');
      final ack = await dashboardStore.sendMutation(
        RequestType.SetInputVolume,
        fields: {'inputName': 'Mic', 'inputVolumeMul': 0.8},
        label: 'Volume',
      );
      expect(ack.success, isFalse);
      await waitFor(
        () => requestsOf('GetInputVolume').isNotEmpty,
        'GetInputVolume re-read in flight',
      );

      /// no event during the re-read - it must apply and roll the value back
      /// to the confirmed 0.5 (no over-blocking)
      peer.releaseOne('GetInputVolume');
      await flushPeer();
      expect(mic().inputVolumeMul, 0.5);
      expect(mic().inputVolumeDb, -9.0);
    });

    test(
      'mute event during in-flight GetInputMute beats the stale re-read',
      () async {
        setupAudioPeer();
        await applyInitialInputState();

        peer.rejections['SetInputMute'] = RequestStatus.GenericError.identifier;
        peer.heldRequestTypes.add('GetInputMute');
        final ackFuture = dashboardStore.sendMutation(
          RequestType.SetInputMute,
          fields: {'inputName': 'Mic', 'inputMuted': true},
          label: 'Mute',
        );
        await waitFor(
          () => requestsOf('GetInputMute').isNotEmpty,
          'GetInputMute re-read in flight',
        );

        /// arrives AFTER the re-read was sent, carrying newer state
        peer.event('InputMuteStateChanged', {
          'inputName': 'Mic',
          'inputMuted': true,
        });
        await waitFor(() => mic().inputMuted, 'event value applied');
        final ack = await ackFuture;
        expect(ack.success, isFalse);

        /// the stale re-read (false) resolves now - it must not overwrite
        /// the event value
        peer.releaseOne('GetInputMute');
        await flushPeer();
        expect(mic().inputMuted, isTrue);
      },
    );
  });

  /// Epoch resets: structural events (scene-list change, renames) and the
  /// session re-attach burst invalidate in-flight read tags wholesale, so a
  /// stale response resolving afterwards must not apply
  group('epoch resets', () {
    /// Kept short so dropped requests can never outlive a test - with held
    /// (not delayed) acks the timeout can no longer race a response
    void setupShortAckTimeout() {
      NetworkHelper.requestAckTimeout = const Duration(milliseconds: 800);
      addTearDown(
        () => NetworkHelper.requestAckTimeout = const Duration(seconds: 35),
      );
    }

    test(
      'SceneListChanged invalidates an in-flight GetSceneList re-read',
      () async {
        peer.responseData['GetSceneList'] = {
          'scenes': [
            {'sceneName': 'Camera', 'sceneIndex': 0},
            {'sceneName': 'Break', 'sceneIndex': 1},
          ],
          'currentProgramSceneName': 'Camera',
          'currentPreviewSceneName': 'Camera',
        };
        peer.droppedRequestTypes.add('GetSceneItemList'); // keep chain quiet
        setupShortAckTimeout();
        await connect();
        dashboardStore.handleStream();

        /// Optimistic write the stale re-read would roll back - makes a
        /// stale application observable in the recording
        dashboardStore.setActiveSceneName('Nope');
        final recordedNames = <String?>[];
        final disposeRecording = autorun((_) {
          recordedNames.add(dashboardStore.activeSceneName);
        });
        addTearDown(() => disposeRecording());

        peer.rejections['SetCurrentProgramScene'] =
            RequestStatus.InvalidResourceType.identifier;
        peer.heldRequestTypes.add('GetSceneList');
        final ackFuture = dashboardStore.sendMutation(
          RequestType.SetCurrentProgramScene,
          fields: {'sceneName': 'Nope'},
          label: 'Scene switch',
        );
        await waitFor(
          () => requestsOf('GetSceneList').length == 1,
          'GetSceneList re-read in flight',
        );

        /// Structural change lands while the re-read is in flight. The event
        /// handler resets the epoch and sends a fresh tracked GetSceneList -
        /// its ack is held too, so both responses stay queued until the test
        /// releases them in order below
        peer.event('SceneListChanged', {
          'scenes': [
            {'sceneName': 'Camera', 'sceneIndex': 0},
            {'sceneName': 'Break', 'sceneIndex': 1},
          ],
        });
        await waitFor(
          () => requestsOf('GetSceneList').length == 2,
          'fresh GetSceneList re-read in flight',
        );
        await ackFuture;

        /// The stale response still carries 'Camera'; once it has been
        /// processed (its item-refresh chain request is the signal), swap
        /// the map so the fresh re-read's response carries 'Break'
        peer.releaseOne('GetSceneList');
        await waitFor(
          () => requestsOf('GetSceneItemList').isNotEmpty,
          'stale GetSceneList response processed',
        );
        peer.responseData['GetSceneList']!['currentProgramSceneName'] = 'Break';
        peer.releaseOne('GetSceneList');
        await flushPeer();

        /// The epoch reset gated the stale response: 'Camera' must never
        /// have landed after the SceneListChanged event
        expect(recordedNames, isNot(contains('Camera')));
        expect(dashboardStore.activeSceneName, 'Break');
      },
    );

    test(
      'SceneNameChanged invalidates an in-flight GetSceneItemList re-read',
      () async {
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
        peer.droppedRequestTypes.add('GetSourceFilterList');

        /// The rename handler re-reads the scene list; if that response were
        /// answered it would chain a FRESH item read whose confirmed value
        /// legitimately overwrites the event value below - masking the stale
        /// re-read this test gates. Dropping it keeps the assertion focused.
        peer.droppedRequestTypes.add('GetSceneList');
        setupShortAckTimeout();
        await connect();
        dashboardStore.handleStream();

        peer.event('CurrentProgramSceneChanged', {'sceneName': 'Camera'});
        await waitFor(
          () => dashboardStore.currentSceneItems.isNotEmpty,
          'initial GetSceneItemList applied',
        );
        expect(
          dashboardStore.currentSceneItems.single.sceneItemEnabled,
          isTrue,
        );

        /// The event-set value that must survive the stale re-read
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

        peer.heldRequestTypes.add('GetSceneItemList');
        peer.event('CurrentProgramSceneChanged', {'sceneName': 'Camera'});
        await waitFor(
          () => requestsOf('GetSceneItemList').length == 2,
          'GetSceneItemList re-read in flight',
        );

        /// Rename lands while the re-read is in flight (wire shape per the
        /// obs-websocket protocol: sceneUuid / oldSceneName / sceneName).
        /// Its handler resets the item-journal epoch and re-reads the scene
        /// list - that (dropped) request appearing is the signal the rename
        /// was fully processed
        peer.event('SceneNameChanged', {
          'sceneUuid': 'uuid-camera',
          'oldSceneName': 'Camera',
          'sceneName': 'Cam',
        });
        await waitFor(
          () => requestsOf('GetSceneList').isNotEmpty,
          'rename processed (scene-list re-read sent)',
        );

        /// The stale re-read (enabled: true) resolves now - the item-journal
        /// epoch reset must gate it
        peer.releaseOne('GetSceneItemList');
        await flushPeer();
        expect(
          dashboardStore.currentSceneItems.single.sceneItemEnabled,
          isFalse,
        );
      },
    );

    test(
      'reconnect on a fresh socket wipes dead-transport tags - the burst applies',
      () async {
        peer.responseData['GetSceneList'] = {
          'scenes': [
            {'sceneName': 'Camera', 'sceneIndex': 0},
            {'sceneName': 'Break', 'sceneIndex': 1},
          ],
          'currentProgramSceneName': 'Camera',
          'currentPreviewSceneName': 'Camera',
        };
        peer.droppedRequestTypes.add('GetSceneItemList'); // keep chain quiet
        setupShortAckTimeout();
        await connect();
        dashboardStore.handleStream();
        dashboardStore.initialRequests();
        await waitFor(
          () => dashboardStore.activeSceneName == 'Camera',
          'initial burst applied the program scene',
        );

        /// A re-read goes out (tag queued) but the socket dies while its ack
        /// is held - the peer drops the held ack on close, it must never
        /// land on the new session
        peer.rejections['SetCurrentProgramScene'] =
            RequestStatus.InvalidResourceType.identifier;
        peer.heldRequestTypes.add('GetSceneList');
        await dashboardStore.sendMutation(
          RequestType.SetCurrentProgramScene,
          fields: {'sceneName': 'Nope'},
          label: 'Scene switch',
        );
        await waitFor(
          () => requestsOf('GetSceneList').length == 2,
          'GetSceneList re-read in flight',
        );
        await peer.closeSockets();

        /// Reconnect on a fresh socket (the _checkOBSConnection success seam:
        /// handleStream + initialRequests). The confirmed value differs so a
        /// gated burst response is observable.
        peer.heldRequestTypes.remove('GetSceneList');
        peer.responseData['GetSceneList']!['currentProgramSceneName'] = 'Break';
        await connect();
        dashboardStore.handleStream();
        dashboardStore.initialRequests();

        /// Without the dead-transport wipe the burst's fresh GetSceneList
        /// response pops the old socket's stale tag, fails the epoch check
        /// and is discarded - the post-reconnect state never lands
        await waitFor(
          () => dashboardStore.activeSceneName == 'Break',
          'reconnect burst applies the fresh state',
        );
      },
    );
  });
}
