import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/stores/views/canvas_view.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/types/enums/request_type.dart';
import 'package:obs_blade/types/enums/web_socket_codes/web_socket_close_code.dart';
import 'package:obs_blade/utils/network_helper.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_obs_peer.dart';

/// A 1x1 png as OBS returns it (data URI)
const String _png =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

const String _mainUuid = 'canvas-main';
const String _verticalUuid = 'canvas-vertical';

Map<String, dynamic> _canvas(
  String uuid,
  String name, {
  required bool main,
  int width = 1920,
  int height = 1080,
}) => {
  'canvasUuid': uuid,
  'canvasName': name,
  'canvasFlags': {'MAIN': main},
  'canvasVideoSettings': {'baseWidth': width, 'baseHeight': height},
};

Map<String, dynamic> _item(int id, String name, {bool enabled = true}) => {
  'inputKind': 'image_source',
  'isGroup': false,
  'sceneItemBlendMode': 'OBS_BLEND_NORMAL',
  'sceneItemEnabled': enabled,
  'sceneItemId': id,
  'sceneItemIndex': id,
  'sceneItemLocked': false,
  'sceneItemTransform': null,
  'sourceName': name,
  'sourceType': 'OBS_SOURCE_TYPE_INPUT',
};

/// [CanvasViewStore] against a loopback fake OBS: non-main canvas reads go
/// through scoped requests, so the program state in [DashboardStore] stays
/// untouched while a vertical canvas is viewed.
void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late FakeObsPeer peer;
  late NetworkStore networkStore;
  late DashboardStore dashboardStore;
  late CanvasViewStore canvasStore;

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

  /// Every message sent before this ack was handled (single ordered socket)
  Future<void> flushPeer() => NetworkHelper.makeRequest(
    networkStore.activeSession!.socket,
    RequestType.GetVersion,
  );

  Future<void> connectWithCanvases() async {
    NetworkHelper.sendRequest(
      networkStore.activeSession!.socket,
      RequestType.GetVersion,
    );
    await waitFor(
      () => canvasStore.hasMultipleCanvases,
      'canvas list loaded after GetVersion',
    );
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('canvas_view_store');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await harness.openAllBoxes();

    peer = await FakeObsPeer.start();
    networkStore = NetworkStore();
    dashboardStore = DashboardStore();
    GetIt.instance.registerSingleton<NetworkStore>(networkStore);
    GetIt.instance.registerSingleton<DashboardStore>(dashboardStore);

    peer.responseData['GetVersion'] = {
      'availableRequests': <String>['GetCanvasList', 'GetSceneList'],
      'supportedImageFormats': ['jpg', 'png'],
    };
    peer.responseData['GetCanvasList'] = {
      'canvases': [
        _canvas(_mainUuid, 'Main', main: true),
        _canvas(
          _verticalUuid,
          'Vertical',
          main: false,
          width: 1080,
          height: 1920,
        ),
      ],
    };
    peer.responseData['GetSourceScreenshot'] = {'imageData': _png};
    peer.responseDataFor = (request) {
      final data = request['requestData'] as Map<String, dynamic>? ?? {};
      switch (request['requestType']) {
        case 'GetSceneList':
          return data['canvasUuid'] == _verticalUuid
              ? {
                  'currentProgramSceneName': null,
                  'currentPreviewSceneName': null,
                  'scenes': [
                    {
                      'sceneName': 'V Chat',
                      'sceneUuid': 'v-chat',
                      'sceneIndex': 0,
                    },
                    {
                      'sceneName': 'V Main',
                      'sceneUuid': 'v-main',
                      'sceneIndex': 1,
                    },
                  ],
                }
              : {
                  'currentProgramSceneName': 'Main',
                  'currentPreviewSceneName': null,
                  'scenes': [
                    {
                      'sceneName': 'Main',
                      'sceneUuid': 'm-main',
                      'sceneIndex': 0,
                    },
                  ],
                };
        case 'GetSceneItemList':
          return data['sceneUuid'] == 'v-main'
              ? {
                  'sceneItems': [_item(1, 'Cam'), _item(2, 'Alerts')],
                }
              : {
                  'sceneItems': [_item(7, 'Chat box')],
                };
      }
      return null;
    };

    expect(
      await networkStore.setOBSWebSocket(peer.connection),
      WebSocketCloseCode.DontClose,
    );
    dashboardStore.handleStream();
    canvasStore = CanvasViewStore()..init();
  });

  tearDown(() async {
    canvasStore.dispose();
    dashboardStore.setShouldRequestPreviewImage(false);
    dashboardStore.disposeListeners();
    NetworkHelper.failAllPendingAcks();
    networkStore.closeSession();
    await peer.close();
    await GetIt.instance.reset();
    await harness.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('loads the canvas list once GetVersion offers GetCanvasList', () async {
    await connectWithCanvases();

    expect(canvasStore.canvases.map((c) => c.name), ['Main', 'Vertical']);
    expect(canvasStore.canvases.first.isMain, isTrue);
    expect(canvasStore.canvases.last.resolutionLabel, '1080×1920');
    expect(canvasStore.isViewingOtherCanvas, isFalse);
  });

  test('no canvas list without GetCanvasList (OBS < 32.1)', () async {
    peer.responseData['GetVersion'] = {
      'availableRequests': <String>['GetSceneList'],
      'supportedImageFormats': ['jpg', 'png'],
    };
    NetworkHelper.sendRequest(
      networkStore.activeSession!.socket,
      RequestType.GetVersion,
    );
    await flushPeer();
    await flushPeer();

    expect(requestsOf('GetCanvasList'), isEmpty);
    expect(canvasStore.hasMultipleCanvases, isFalse);
  });

  test('viewing a canvas reads its scenes + items by UUID, program state '
      'untouched', () async {
    await connectWithCanvases();

    canvasStore.viewCanvas(_verticalUuid);
    await waitFor(
      () => canvasStore.sceneItems.isNotEmpty,
      'vertical scene items loaded',
    );

    /// Top of the OBS list first, like the main scene buttons
    expect(canvasStore.scenes.map((s) => s.name), ['V Main', 'V Chat']);
    expect(canvasStore.selectedSceneUuid, 'v-main');
    expect(canvasStore.sceneItems.map((i) => i.sourceName), ['Alerts', 'Cam']);
    expect(
      (requestsOf('GetSceneList').last['requestData'] as Map)['canvasUuid'],
      _verticalUuid,
    );
    expect(
      (requestsOf('GetSceneItemList').last['requestData'] as Map)['sceneUuid'],
      'v-main',
    );

    /// The scoped responses never reached the program-side handlers
    await flushPeer();
    expect(dashboardStore.scenes, isNull);
    expect(dashboardStore.activeSceneName, isNull);
    expect(dashboardStore.currentSceneItems, isEmpty);
  });

  test('preview runs on the viewed scene, the program loop pauses', () async {
    await connectWithCanvases();
    canvasStore.viewCanvas(_verticalUuid);
    await waitFor(
      () => canvasStore.selectedSceneUuid == 'v-main',
      'first vertical scene selected',
    );

    dashboardStore.setShouldRequestPreviewImage(true);
    await waitFor(
      () => canvasStore.previewImageBytes != null,
      'canvas preview applied',
    );

    final screenshots = requestsOf('GetSourceScreenshot');
    expect(screenshots, isNotEmpty);
    for (final request in screenshots) {
      expect((request['requestData'] as Map)['sourceUuid'], 'v-main');
    }

    /// Portrait canvas: never wider than its own base width
    expect(
      (screenshots.first['requestData'] as Map)['imageWidth'] as int,
      lessThanOrEqualTo(1080),
    );
    expect(dashboardStore.scenePreviewImageBytes, isNull);

    /// Back on main: the canvas loop stops, the program one resumes
    canvasStore.viewCanvas(_mainUuid);
    expect(canvasStore.isViewingOtherCanvas, isFalse);
    await waitFor(
      () => requestsOf('GetSourceScreenshot').any(
        (request) => (request['requestData'] as Map).containsKey('sourceName'),
      ),
      'program preview resumed',
    );
  });

  test('selecting another scene reloads items for that scene', () async {
    await connectWithCanvases();
    canvasStore.viewCanvas(_verticalUuid);
    await waitFor(() => canvasStore.sceneItems.isNotEmpty, 'first scene items');

    canvasStore.selectScene('v-chat');
    await waitFor(
      () =>
          canvasStore.sceneItems.length == 1 &&
          canvasStore.sceneItems.first.sourceName == 'Chat box',
      'second scene items',
    );
  });

  test('item toggles send by scene UUID; events patch only the viewed '
      'scene', () async {
    await connectWithCanvases();
    canvasStore.viewCanvas(_verticalUuid);
    await waitFor(
      () => canvasStore.sceneItems.isNotEmpty,
      'scene items loaded',
    );

    final cam = canvasStore.sceneItems.firstWhere(
      (item) => item.sourceName == 'Cam',
    );
    await canvasStore.setItemEnabled(cam, false);
    final sent = requestsOf('SetSceneItemEnabled').single['requestData'] as Map;
    expect(sent['sceneUuid'], 'v-main');
    expect(sent['sceneItemId'], 1);
    expect(sent['sceneItemEnabled'], isFalse);
    expect(
      canvasStore.sceneItems
          .firstWhere((item) => item.sceneItemId == 1)
          .sceneItemEnabled,
      isFalse,
    );

    /// Same item id in another scene: ignored
    peer.event('SceneItemEnableStateChanged', {
      'sceneName': 'Other',
      'sceneUuid': 'other-scene',
      'sceneItemId': 2,
      'sceneItemEnabled': false,
    });

    /// Viewed scene: applied
    peer.event('SceneItemLockStateChanged', {
      'sceneName': 'V Main',
      'sceneUuid': 'v-main',
      'sceneItemId': 2,
      'sceneItemLocked': true,
    });
    await waitFor(
      () => canvasStore.sceneItems
          .firstWhere((item) => item.sceneItemId == 2)
          .sceneItemLocked!,
      'lock event applied',
    );
    expect(
      canvasStore.sceneItems
          .firstWhere((item) => item.sceneItemId == 2)
          .sceneItemEnabled,
      isTrue,
    );
  });

  test('a removed canvas falls back to the main view', () async {
    await connectWithCanvases();
    canvasStore.viewCanvas(_verticalUuid);
    expect(canvasStore.isViewingOtherCanvas, isTrue);

    peer.responseData['GetCanvasList'] = {
      'canvases': [_canvas(_mainUuid, 'Main', main: true)],
    };
    peer.event('CanvasRemoved', {
      'canvasName': 'Vertical',
      'canvasUuid': _verticalUuid,
    });
    await waitFor(
      () => !canvasStore.hasMultipleCanvases,
      'canvas list re-read',
    );
    expect(canvasStore.isViewingOtherCanvas, isFalse);
    expect(canvasStore.viewedCanvasUuid, isNull);
  });

  test(
    'a reconnect rewires the canvas view: list re-read, events live again',
    () async {
      await connectWithCanvases();
      canvasStore.viewCanvas(_verticalUuid);
      await waitFor(
        () => canvasStore.sceneItems.isNotEmpty,
        'vertical scene items loaded',
      );

      /// Socket dies, fresh session attaches (the _checkOBSConnection
      /// success seam). availableRequests still holds GetCanvasList from
      /// the previous session, so a support-only reaction never refires
      await peer.closeSockets();
      expect(
        await networkStore.setOBSWebSocket(peer.connection),
        WebSocketCloseCode.DontClose,
      );
      dashboardStore.handleStream();

      await waitFor(
        () => requestsOf('GetCanvasList').length == 2,
        'canvas list re-read on the new session',
      );
      await waitFor(
        () => canvasStore.sceneItems.isNotEmpty,
        'viewed scene reloaded on the new session',
      );

      /// Events on the NEW socket must be handled - before the fix the
      /// subscription still listened on the dead socket's stream
      peer.event('SceneItemLockStateChanged', {
        'sceneName': 'V Main',
        'sceneUuid': 'v-main',
        'sceneItemId': 1,
        'sceneItemLocked': true,
      });
      await waitFor(
        () => canvasStore.sceneItems
            .firstWhere((item) => item.sceneItemId == 1)
            .sceneItemLocked!,
        'event on the new socket applied',
      );
    },
  );
}
