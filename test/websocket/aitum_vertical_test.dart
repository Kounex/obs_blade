import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/stores/views/canvas_view.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/types/classes/api/aitum_vertical.dart';
import 'package:obs_blade/types/enums/request_type.dart';
import 'package:obs_blade/types/enums/web_socket_codes/web_socket_close_code.dart';
import 'package:obs_blade/utils/network_helper.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_obs_peer.dart';

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

/// Aitum Vertical's vendor on top of the canvas view: detected per
/// connection, live scene + outputs through `CallVendorRequest`, state
/// from `VendorEvent`s - and nothing of it without the plugin.
void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late FakeObsPeer peer;
  late NetworkStore networkStore;
  late DashboardStore dashboardStore;
  late CanvasViewStore canvasStore;

  /// What the fake Aitum vendor answers, per vendor request type
  late Map<String, Map<String, dynamic>> vendorResponses;

  List<Map<String, dynamic>> vendorCalls(String vendorRequestType) => peer
      .requests
      .where(
        (request) =>
            request['requestType'] == 'CallVendorRequest' &&
            (request['requestData'] as Map)['requestType'] == vendorRequestType,
      )
      .map((request) => (request['requestData'] as Map)['requestData'] as Map)
      .cast<Map<String, dynamic>>()
      .toList();

  Future<void> waitFor(bool Function() condition, String description) async {
    for (var i = 0; i < 500; i++) {
      if (condition()) return;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    fail('Timed out waiting for: $description');
  }

  Future<void> flushPeer() => NetworkHelper.makeRequest(
    networkStore.activeSession!.socket,
    RequestType.GetVersion,
  );

  void verticalCanvasNamed(String name) {
    peer.responseData['GetCanvasList'] = {
      'canvases': [
        _canvas(_mainUuid, 'Main', main: true),
        _canvas(_verticalUuid, name, main: false, width: 1080, height: 1920),
      ],
    };
  }

  Future<void> connect() async {
    NetworkHelper.sendRequest(
      networkStore.activeSession!.socket,
      RequestType.GetVersion,
    );
    await waitFor(() => canvasStore.hasMultipleCanvases, 'canvas list');
  }

  void aitumEvent(String eventType, [Map<String, dynamic>? data]) =>
      peer.event('VendorEvent', {
        'vendorName': kAitumVendorName,
        'eventType': eventType,
        'eventData': {'width': 1080, 'height': 1920, ...?data},
      });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('aitum_vertical');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await harness.openAllBoxes();

    peer = await FakeObsPeer.start();
    networkStore = NetworkStore();
    dashboardStore = DashboardStore();
    GetIt.instance.registerSingleton<NetworkStore>(networkStore);
    GetIt.instance.registerSingleton<DashboardStore>(dashboardStore);

    vendorResponses = {
      'version': {'version': '1.6.4', 'success': true},
      'current_scene': {'scene': 'V Chat', 'success': true},
      'status': {
        'streaming': true,
        'recording': false,
        'backtrack': false,
        'virtual_camera': false,
        'success': true,
      },
    };
    peer.responseData['GetVersion'] = {
      'availableRequests': <String>[
        'GetCanvasList',
        'GetSceneList',
        'CallVendorRequest',
      ],
      'supportedImageFormats': ['jpg', 'png'],
    };
    verticalCanvasNamed(kAitumCanvasName);
    peer.responseDataFor = (request) {
      final data = request['requestData'] as Map<String, dynamic>? ?? {};
      switch (request['requestType']) {
        case 'CallVendorRequest':
          final type = data['requestType'] as String;
          return {
            'vendorName': data['vendorName'],
            'requestType': type,
            'responseData': vendorResponses[type] ?? {'success': true},
          };
        case 'GetSceneList':
          return data['canvasUuid'] == _verticalUuid
              ? {
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
              : {'scenes': []};
        case 'GetSceneItemList':
          return {'sceneItems': []};
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
    dashboardStore.disposeListeners();
    NetworkHelper.failAllPendingAcks();
    networkStore.closeSession();
    await peer.close();
    await GetIt.instance.reset();
    await harness.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('detects Aitum Vertical, reads its live scene + outputs, the shown '
      'scene follows the live one', () async {
    await connect();
    await waitFor(
      () => canvasStore.aitumSupport == AitumSupport.available,
      'vendor detected',
    );
    await waitFor(
      () => canvasStore.aitumLiveSceneName == 'V Chat',
      'live scene read',
    );
    expect(canvasStore.aitumStatus.streaming, isTrue);

    /// Requests target the canvas by its resolution
    expect(vendorCalls('status').first, {'width': 1080, 'height': 1920});

    canvasStore.viewCanvas(_verticalUuid);
    expect(canvasStore.canControlViewedCanvas, isTrue);
    expect(canvasStore.liveControlBlockedReason, isNull);

    /// Not the first listed scene (V Main) - the live one
    await waitFor(
      () => canvasStore.selectedSceneUuid == 'v-chat',
      'live scene shown',
    );
  });

  test('a tap switches the live scene by name, optimistically', () async {
    await connect();
    await waitFor(
      () => canvasStore.aitumSupport == AitumSupport.available,
      'vendor detected',
    );
    canvasStore.viewCanvas(_verticalUuid);
    await waitFor(() => canvasStore.scenes.isNotEmpty, 'scenes loaded');

    final vMain = canvasStore.scenes.firstWhere((s) => s.name == 'V Main');
    final pending = canvasStore.switchLiveScene(vMain);
    expect(canvasStore.aitumLiveSceneName, 'V Main');
    expect(canvasStore.selectedSceneUuid, 'v-main');
    await pending;

    expect(vendorCalls('switch_scene').single, {
      'scene': 'V Main',
      'width': 1080,
      'height': 1920,
    });
  });

  test('vendor events drive live scene + output state; other canvases and '
      'vendors are ignored', () async {
    await connect();
    canvasStore.viewCanvas(_verticalUuid);
    await waitFor(
      () => canvasStore.selectedSceneUuid == 'v-chat',
      'live scene shown',
    );

    aitumEvent('switch_scene', {'old_scene': 'V Chat', 'new_scene': 'V Main'});
    await waitFor(
      () => canvasStore.selectedSceneUuid == 'v-main',
      'switch from OBS followed',
    );
    expect(canvasStore.aitumLiveSceneName, 'V Main');

    aitumEvent('recording_started');
    aitumEvent('backtrack_started');
    aitumEvent('streaming_stopped', {'code': 0, 'last_error': ''});
    await waitFor(
      () => canvasStore.aitumStatus.recording,
      'recording event applied',
    );
    await waitFor(
      () => !canvasStore.aitumStatus.streaming,
      'stream stop applied',
    );
    expect(canvasStore.aitumStatus.backtrack, isTrue);

    /// A different-size Aitum canvas and another vendor: not ours
    peer.event('VendorEvent', {
      'vendorName': kAitumVendorName,
      'eventType': 'recording_stopped',
      'eventData': {'width': 720, 'height': 1280},
    });
    peer.event('VendorEvent', {
      'vendorName': 'some-other-plugin',
      'eventType': 'recording_stopped',
      'eventData': {'width': 1080, 'height': 1920},
    });
    await flushPeer();
    expect(canvasStore.aitumStatus.recording, isTrue);
  });

  test('outputs send explicit start / stop; a refusal from the plugin '
      'surfaces the failure toast', () async {
    await connect();
    await waitFor(
      () => canvasStore.aitumSupport == AitumSupport.available,
      'vendor detected',
    );
    canvasStore.viewCanvas(_verticalUuid);

    await canvasStore.setAitumStreaming(false);
    await canvasStore.setAitumRecording(true);
    await canvasStore.setAitumBacktrack(true);
    await canvasStore.saveAitumBacktrack();
    expect(vendorCalls('stop_streaming'), hasLength(1));
    expect(vendorCalls('start_recording'), hasLength(1));
    expect(vendorCalls('start_backtrack'), hasLength(1));
    expect(vendorCalls('save_backtrack').single, {
      'width': 1080,
      'height': 1920,
    });
    expect(dashboardStore.commandFailureNotice, isNull);

    vendorResponses['stop_recording'] = {'success': false};
    await canvasStore.setAitumRecording(false);
    expect(
      dashboardStore.commandFailureNotice?.message,
      contains('Stop vertical recording failed'),
    );
  });

  test('without the plugin: missing, view-only, nothing is sent', () async {
    /// obs-websocket rejects calls to an unknown vendor
    peer.rejections['CallVendorRequest'] = 600;
    await connect();
    await waitFor(
      () => canvasStore.aitumSupport == AitumSupport.missing,
      'vendor missing',
    );

    canvasStore.viewCanvas(_verticalUuid);
    expect(canvasStore.canControlViewedCanvas, isFalse);

    /// The Aitum canvas exists but its vendor doesn't answer - the plugin's
    /// known fresh-install bug, fixed by an OBS restart
    expect(canvasStore.liveControlBlockedReason, contains('restart OBS'));

    await waitFor(() => canvasStore.scenes.isNotEmpty, 'scenes loaded');
    final before = vendorCalls('switch_scene').length;
    await canvasStore.switchLiveScene(canvasStore.scenes.last);
    await canvasStore.setAitumStreaming(true);
    expect(vendorCalls('switch_scene').length, before);
    expect(vendorCalls('start_streaming'), isEmpty);

    /// Back to the first listed scene (view-only pick), not a "live" one
    expect(canvasStore.selectedSceneUuid, 'v-main');
    expect(canvasStore.aitumLiveSceneName, isNull);
  });

  test('another plugin\'s canvas: explains the plugin is needed / only '
      'drives its own canvas', () async {
    verticalCanvasNamed('Vertical');
    peer.rejections['CallVendorRequest'] = 600;
    await connect();
    await waitFor(
      () => canvasStore.aitumSupport == AitumSupport.missing,
      'vendor missing',
    );
    canvasStore.viewCanvas(_verticalUuid);
    expect(
      canvasStore.liveControlBlockedReason,
      contains('need the Aitum Vertical plugin'),
    );

    /// Plugin installed, but this canvas isn't Aitum's
    peer.rejections.remove('CallVendorRequest');
    peer.event('CanvasNameChanged', {
      'canvasUuid': _verticalUuid,
      'canvasName': 'Vertical',
    });
    await waitFor(
      () => canvasStore.aitumSupport == AitumSupport.available,
      'vendor re-checked on canvas change',
    );
    expect(canvasStore.canControlViewedCanvas, isFalse);
    expect(
      canvasStore.liveControlBlockedReason,
      contains('only work on the Aitum Vertical canvas'),
    );
  });
}
