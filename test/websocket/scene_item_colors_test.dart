import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/types/enums/request_type.dart';
import 'package:obs_blade/types/enums/web_socket_codes/request_status.dart';
import 'package:obs_blade/types/enums/web_socket_codes/web_socket_close_code.dart';
import 'package:obs_blade/utils/network_helper.dart';
import 'package:obs_blade/utils/scene_item_color.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_obs_peer.dart';

/// Source colors (OBS 32+, Sources dock -> Set Color) ride alongside the
/// scene-item list reads: each applied item list triggers one
/// GetSceneItemPrivateSettings batch (group children keyed by their parent
/// group's source name), its answers populate
/// [DashboardStore.sceneItemColors], and a color removed in OBS drops its
/// entry on the next read. Older OBS (request not in availableRequests)
/// gets no color requests at all.
void main() {
  /// The collection-change path closes any status overlay
  /// (OverlayHandler reaches WidgetsBinding through a GlobalKey)
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late HiveTestHarness harness;
  late FakeObsPeer peer;
  late NetworkStore networkStore;
  late DashboardStore dashboardStore;

  /// Private settings the peer reports per '<sceneName>|<sceneItemId>' -
  /// tests rewrite this map to simulate OBS-side color changes
  late Map<String, Map<String, dynamic>> privateSettings;

  List<Map<String, dynamic>> requestsOf(String requestType) => peer.requests
      .where((request) => request['requestType'] == requestType)
      .toList();

  /// Every sub-request of every batch carrying [requestType]
  List<Map<String, dynamic>> batchEntriesOf(String requestType) => [
    for (final batch in peer.batches)
      for (final entry
          in (batch['requests'] as List).cast<Map<String, dynamic>>())
        if (entry['requestType'] == requestType) entry,
  ];

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

  /// Deterministic "everything sent before was processed" gate (see
  /// state_ordering_test): also fills availableRequests via the GetVersion
  /// handler
  Future<void> flushPeer() => NetworkHelper.makeRequest(
    networkStore.activeSession!.socket,
    RequestType.GetVersion,
  );

  Map<String, dynamic> item(int id, String name, {bool isGroup = false}) => {
    'sceneItemId': id,
    'sceneItemIndex': id,
    'sceneItemEnabled': true,
    'sourceName': name,
    'isGroup': isGroup,
  };

  /// Scene 'Camera' with a plain item (id 1) and group 'grp' (id 2) holding
  /// one child (id 3)
  void setupPeer() {
    privateSettings = {
      'Camera|1': {'color-preset': 2}, // red preset
      'Camera|2': {'color-preset': 9}, // white preset
      'grp|3': {'color-preset': 1, 'color': '#55FF0000'}, // custom
    };

    peer.responseData['GetVersion'] = {
      'availableRequests': ['GetSceneItemPrivateSettings'],
      'supportedImageFormats': ['jpg', 'png'],
    };
    peer.responseData['GetSceneList'] = {
      'scenes': [
        {'sceneName': 'Camera', 'sceneIndex': 0},
      ],
      'currentProgramSceneName': 'Camera',
      'currentPreviewSceneName': 'Camera',
    };
    peer.responseData['GetSceneItemList'] = {
      'sceneItems': [item(1, 'cam'), item(2, 'grp', isGroup: true)],
    };
    peer.responseData['GetGroupSceneItemList'] = {
      'sceneItems': [item(3, 'child')],
    };
    peer.batchResponseDataFor = (entry) {
      if (entry['requestType'] != 'GetSceneItemPrivateSettings') return null;
      final requestData = entry['requestData'] as Map<String, dynamic>;
      final settings =
          privateSettings['${requestData['sceneName']}|${requestData['sceneItemId']}'];
      return {'sceneItemSettings': settings ?? <String, dynamic>{}};
    };

    /// The non-empty item list triggers a FilterList batch - its ack must
    /// not hang at teardown, so drop it and let the short timeout clean up
    peer.droppedRequestTypes.add('GetSourceFilterList');
    NetworkHelper.requestAckTimeout = const Duration(milliseconds: 300);
    addTearDown(
      () => NetworkHelper.requestAckTimeout = const Duration(seconds: 35),
    );
  }

  /// Connects, fills availableRequests and applies the initial scene + item
  /// lists (a program-scene event both sets the displayed scene and
  /// triggers the item read)
  Future<void> applyInitialState() async {
    await connect();
    dashboardStore.handleStream();
    await flushPeer();

    peer.event('CurrentProgramSceneChanged', {'sceneName': 'Camera'});
    await waitFor(
      () => dashboardStore.currentSceneItems.length == 3,
      'initial item list + group children applied',
    );
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('scene_item_colors');
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

  test('item list reads fetch colors in one batch - group children by their '
      'parent group\'s source name - and populate the color map', () async {
    setupPeer();
    await applyInitialState();

    await waitFor(
      () => dashboardStore.sceneItemColors.length == 3,
      'colors of all items applied',
    );

    /// Top-level items are looked up by the displayed scene's name, the
    /// group child by the group's source name
    final colorRequests = batchEntriesOf('GetSceneItemPrivateSettings');
    final requestedKeys = {
      for (final entry in colorRequests)
        '${(entry['requestData'] as Map<String, dynamic>)['sceneName']}|'
            '${(entry['requestData'] as Map<String, dynamic>)['sceneItemId']}',
    };
    expect(requestedKeys, {'Camera|1', 'Camera|2', 'grp|3'});

    expect(
      dashboardStore.sceneItemColors[sceneItemColorKey('Camera', 1)],
      const Color(0x54FF4444), // red preset at 33% alpha
    );
    expect(
      dashboardStore.sceneItemColors[sceneItemColorKey('Camera', 2)],
      const Color(0x54FFFFFF), // white preset at 33% alpha
    );
    expect(
      dashboardStore.sceneItemColors[sceneItemColorKey('grp', 3)],
      const Color(0x55FF0000), // custom HexArgb
    );
  });

  test(
    'unsupported request (old OBS): no color requests, map stays empty',
    () async {
      setupPeer();
      peer.responseData['GetVersion'] = {
        'availableRequests': <String>[],
        'supportedImageFormats': ['jpg', 'png'],
      };
      await applyInitialState();
      await flushPeer();

      expect(batchEntriesOf('GetSceneItemPrivateSettings'), isEmpty);
      expect(requestsOf('GetSceneItemPrivateSettings'), isEmpty);
      expect(dashboardStore.sceneItemColors, isEmpty);
    },
  );

  test('a new session clears the previous session\'s colors', () async {
    setupPeer();
    await applyInitialState();
    await waitFor(
      () => dashboardStore.sceneItemColors.length == 3,
      'colors applied',
    );

    /// In-view reconnect (e.g. to an older OBS without the request): the
    /// old session's colors must not render until the re-reads
    await connect();
    dashboardStore.handleStream();
    expect(dashboardStore.sceneItemColors, isEmpty);

    /// ...and the feature still works on the new session
    await flushPeer();
    peer.event('CurrentProgramSceneChanged', {'sceneName': 'Camera'});
    await waitFor(
      () => dashboardStore.sceneItemColors.length == 3,
      'colors re-read on the new session',
    );
  });

  test(
    'a scene collection switch clears the old collection\'s colors',
    () async {
      setupPeer();
      await applyInitialState();
      await waitFor(
        () => dashboardStore.sceneItemColors.length == 3,
        'colors applied',
      );

      /// Same-named scenes of the new collection carry their own colors.
      /// Hold the re-read chain so the clear is observable before the new
      /// collection's colors land; the rest of the refresh burst is not
      /// part of this test (its empty fake answers wouldn't parse)
      peer.droppedRequestTypes.addAll([
        'GetSceneCollectionList',
        'GetInputList',
        'GetSpecialInputs',
        'GetSceneTransitionList',
      ]);
      peer.heldRequestTypes.add('GetSceneList');
      peer.event('CurrentSceneCollectionChanged', {
        'sceneCollectionName': 'Other',
      });
      await waitFor(
        () => dashboardStore.sceneItemColors.isEmpty,
        'old collection colors cleared',
      );

      peer.releaseAll('GetSceneList');
      await flushPeer();
    },
  );

  test('a failed read in the colors batch keeps the cached color, the others '
      'still update', () async {
    setupPeer();
    await applyInitialState();
    await waitFor(
      () => dashboardStore.sceneItemColors.length == 3,
      'colors applied',
    );

    /// OBS side: 'cam' got recolored to the green preset - and the group
    /// row's private-settings read fails in the same batch
    privateSettings['Camera|1'] = {'color-preset': 4};
    peer.batchRejectionFor = (entry) =>
        entry['requestType'] == 'GetSceneItemPrivateSettings' &&
            (entry['requestData'] as Map<String, dynamic>)['sceneItemId'] == 2
        ? RequestStatus.InvalidResourceType.identifier
        : null;
    peer.event('CurrentProgramSceneChanged', {'sceneName': 'Camera'});
    await waitFor(
      () =>
          dashboardStore.sceneItemColors[sceneItemColorKey('Camera', 1)] ==
          const Color(0x5444FF44),
      'recolored item updated from the same batch',
    );

    expect(
      dashboardStore.sceneItemColors[sceneItemColorKey('Camera', 2)],
      const Color(0x54FFFFFF),
      reason: 'the failed read must not clear the cached color',
    );
    expect(
      dashboardStore.sceneItemColors[sceneItemColorKey('grp', 3)],
      const Color(0x55FF0000),
    );
  });

  test('color removed in OBS drops its entry on the next read', () async {
    setupPeer();
    await applyInitialState();
    await waitFor(
      () => dashboardStore.sceneItemColors.length == 3,
      'colors applied',
    );

    /// OBS side: the red preset of 'cam' was cleared (color-preset 0)
    privateSettings['Camera|1'] = {'color-preset': 0};
    peer.event('CurrentProgramSceneChanged', {'sceneName': 'Camera'});
    await waitFor(
      () => !dashboardStore.sceneItemColors.containsKey(
        sceneItemColorKey('Camera', 1),
      ),
      'cleared color dropped',
    );

    /// The other colors survived the re-read
    expect(
      dashboardStore.sceneItemColors[sceneItemColorKey('Camera', 2)],
      const Color(0x54FFFFFF),
    );
    expect(
      dashboardStore.sceneItemColors[sceneItemColorKey('grp', 3)],
      const Color(0x55FF0000),
    );
  });

  test('item removed in OBS drops its color entry on the next read', () async {
    setupPeer();
    await applyInitialState();
    await waitFor(
      () => dashboardStore.sceneItemColors.length == 3,
      'colors applied',
    );

    /// OBS side: 'cam' was removed from the scene - it is part of no color
    /// fetch anymore, so only the reconcile clears its entry
    peer.responseData['GetSceneItemList'] = {
      'sceneItems': [item(2, 'grp', isGroup: true)],
    };
    peer.event('CurrentProgramSceneChanged', {'sceneName': 'Camera'});
    await waitFor(
      () => dashboardStore.currentSceneItems.length == 2,
      'item list without cam applied',
    );
    await waitFor(
      () => !dashboardStore.sceneItemColors.containsKey(
        sceneItemColorKey('Camera', 1),
      ),
      'color of the removed item dropped',
    );
    expect(
      dashboardStore.sceneItemColors[sceneItemColorKey('Camera', 2)],
      const Color(0x54FFFFFF),
    );
  });

  test('a group whose name contains the key separator keeps its child\'s '
      'color through reconcile', () async {
    setupPeer();

    /// The group is named 'Camera|1' - with a naive '<scene>|<id>' key
    /// its child's key would parse as scene 'Camera', id garbage, and
    /// the reconcile below would drop it
    privateSettings = {
      'Camera|1': {'color-preset': 2}, // top-level 'cam', id 1
      'Camera|2': {'color-preset': 9}, // group row, id 2
      'Camera|1|3': {'color-preset': 4}, // child id 3 of group 'Camera|1'
    };
    peer.responseData['GetSceneItemList'] = {
      'sceneItems': [item(1, 'cam'), item(2, 'Camera|1', isGroup: true)],
    };
    await applyInitialState();
    await waitFor(
      () => dashboardStore.sceneItemColors.length == 3,
      'colors applied',
    );

    /// OBS side: 'cam' removed - the reconcile of scene 'Camera' drops
    /// its color but must leave the 'Camera|1' group's entries alone
    peer.responseData['GetSceneItemList'] = {
      'sceneItems': [item(2, 'Camera|1', isGroup: true)],
    };
    peer.event('CurrentProgramSceneChanged', {'sceneName': 'Camera'});
    await waitFor(
      () => dashboardStore.currentSceneItems.length == 2,
      'item list without cam applied',
    );
    await waitFor(
      () => !dashboardStore.sceneItemColors.containsKey(
        sceneItemColorKey('Camera', 1),
      ),
      'color of the removed item dropped',
    );

    expect(
      dashboardStore.sceneItemColors[sceneItemColorKey('Camera', 2)],
      const Color(0x54FFFFFF),
      reason: 'group row color survives',
    );
    expect(
      dashboardStore.sceneItemColors[sceneItemColorKey('Camera|1', 3)],
      const Color(0x5444FF44),
      reason: 'child color survives the reconcile of the parent scene',
    );
  });
}
