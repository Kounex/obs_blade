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

Map<String, dynamic> _item(int id, String name) => {
  'inputKind': 'image_source',
  'isGroup': false,
  'sceneItemBlendMode': 'OBS_BLEND_NORMAL',
  'sceneItemEnabled': true,
  'sceneItemId': id,
  'sceneItemIndex': id,
  'sceneItemLocked': false,
  'sceneItemTransform': null,
  'sourceName': name,
  'sourceType': 'OBS_SOURCE_TYPE_INPUT',
};

/// OBS-side changes the app shows but never re-read: inputs created /
/// removed without a scene change, structural filter changes, and the
/// per-profile state (video settings, record directory) after a profile
/// switch. Each event must trigger the matching re-read.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late HiveTestHarness harness;
  late FakeObsPeer peer;
  late NetworkStore networkStore;
  late DashboardStore dashboardStore;

  List<Map<String, dynamic>> requestsOf(String requestType) => peer.requests
      .where((request) => request['requestType'] == requestType)
      .toList();

  int filterListBatches() => peer.batches
      .where(
        (batch) => (batch['requests'] as List).any(
          (request) => request['requestType'] == 'GetSourceFilterList',
        ),
      )
      .length;

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
    tempDir = await Directory.systemTemp.createTemp('event_driven_refresh');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await harness.openAllBoxes();
    peer = await FakeObsPeer.start();
    networkStore = NetworkStore();
    dashboardStore = DashboardStore();
    GetIt.instance.registerSingleton<NetworkStore>(networkStore);
    GetIt.instance.registerSingleton<DashboardStore>(dashboardStore);

    peer.responseData['GetVersion'] = {
      'availableRequests': <String>[],
      'supportedImageFormats': ['jpg', 'png'],
    };
    peer.responseData['GetSceneList'] = {
      'scenes': [
        {'sceneName': 'Main', 'sceneIndex': 0},
      ],
      'currentProgramSceneName': 'Main',
      'currentPreviewSceneName': 'Main',
    };
    peer.responseData['GetSceneItemList'] = {
      'sceneItems': [_item(1, 'Cam')],
    };
    peer.responseData['GetSourceFilterList'] = {'filters': <dynamic>[]};

    expect(
      await networkStore.setOBSWebSocket(peer.connection),
      WebSocketCloseCode.DontClose,
    );
    dashboardStore.handleStream();
    dashboardStore.initialRequests();

    /// Let the connect burst (incl. the scene items + filter chain) settle
    await waitFor(() => filterListBatches() == 1, 'initial filter read');
    await flushPeer();
  });

  tearDown(() async {
    dashboardStore.disposeListeners();
    networkStore.closeSession();
    await peer.close();
    await GetIt.instance.reset();
    await harness.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('an input created outside any scene re-reads the input list', () async {
    expect(requestsOf('GetInputList'), hasLength(1));

    peer.event('InputCreated', {
      'inputName': 'Mic 2',
      'inputKind': 'coreaudio_input_capture',
      'unversionedInputKind': 'coreaudio_input_capture',
      'inputSettings': <String, dynamic>{},
      'defaultInputSettings': <String, dynamic>{},
    });

    await waitFor(
      () => requestsOf('GetInputList').length == 2,
      'input list re-read after InputCreated',
    );
  });

  test('an input removed outside any scene re-reads the input list', () async {
    peer.event('InputRemoved', {'inputName': 'Mic 2'});

    await waitFor(
      () => requestsOf('GetInputList').length == 2,
      'input list re-read after InputRemoved',
    );
  });

  test('a structural filter change re-reads the filters', () async {
    peer.event('SourceFilterCreated', {
      'sourceName': 'Cam',
      'filterName': 'Blur',
      'filterKind': 'obs_blur_filter',
      'filterIndex': 0,
      'filterSettings': <String, dynamic>{},
      'defaultFilterSettings': <String, dynamic>{},
      'filterEnabled': true,
    });

    await waitFor(
      () => filterListBatches() == 2,
      'filters re-read after SourceFilterCreated',
    );
  });

  test('a profile switch re-reads the per-profile state', () async {
    expect(requestsOf('GetVideoSettings'), hasLength(1));
    expect(requestsOf('GetRecordDirectory'), hasLength(1));

    peer.event('CurrentProfileChanged', {'profileName': 'Vertical'});

    await waitFor(
      () =>
          requestsOf('GetVideoSettings').length == 2 &&
          requestsOf('GetRecordDirectory').length == 2,
      'video settings + record directory re-read after profile switch',
    );
    expect(dashboardStore.currentProfileName, 'Vertical');
  });
}
