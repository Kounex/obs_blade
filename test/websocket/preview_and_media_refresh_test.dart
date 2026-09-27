import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/types/classes/api/input.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/types/enums/web_socket_codes/request_status.dart';
import 'package:obs_blade/types/enums/web_socket_codes/web_socket_close_code.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_obs_peer.dart';

/// A 1x1 png as OBS returns it (data URI)
const String _png =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

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
    for (var i = 0; i < 200; i++) {
      if (condition()) return;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    fail('Timed out waiting for: $description');
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('preview_media_refresh');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await harness.openAllBoxes();
    peer = await FakeObsPeer.start();
    networkStore = NetworkStore();
    dashboardStore = DashboardStore();
    GetIt.instance.registerSingleton<NetworkStore>(networkStore);
    GetIt.instance.registerSingleton<DashboardStore>(dashboardStore);
    peer.responseData['GetSourceScreenshot'] = {'imageData': _png};
    expect(
      await networkStore.setOBSWebSocket(peer.connection),
      WebSocketCloseCode.DontClose,
    );
    dashboardStore.handleStream();
  });

  tearDown(() async {
    dashboardStore.setShouldRequestPreviewImage(false);
    dashboardStore.disposeListeners();
    networkStore.closeSession();
    await peer.close();
    await GetIt.instance.reset();
    await harness.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('scene preview loop', () {
    test('repeated starts keep ONE screenshot in flight', () async {
      /// Slow answers: every extra start used to open another loop
      peer.ackDelayFor = (request) =>
          request['requestType'] == 'GetSourceScreenshot'
          ? const Duration(milliseconds: 200)
          : null;

      dashboardStore.setShouldRequestPreviewImage(true);
      dashboardStore.setShouldRequestPreviewImage(true);
      dashboardStore.setShouldRequestPreviewImage(true);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(requestsOf('GetSourceScreenshot'), hasLength(1));

      /// After the answer, exactly one follow-up (not three)
      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(requestsOf('GetSourceScreenshot'), hasLength(2));
      expect(dashboardStore.scenePreviewImageBytes, isNotNull);
    });

    test('a failed screenshot retries instead of ending the loop', () async {
      peer.rejections['GetSourceScreenshot'] =
          RequestStatus.ResourceNotFound.identifier;
      dashboardStore.setShouldRequestPreviewImage(true);
      await waitFor(
        () => requestsOf('GetSourceScreenshot').isNotEmpty,
        'first screenshot request',
      );

      peer.rejections.remove('GetSourceScreenshot');
      await waitFor(
        () => requestsOf('GetSourceScreenshot').length >= 2,
        'retry after the failure',
      );
      await waitFor(
        () => dashboardStore.scenePreviewImageBytes != null,
        'preview recovers',
      );
    });
  });

  test(
    'a media source leaving the live scene gets its status re-read',
    () async {
      /// One media input known to the store (GetInputList is not driven here)
      runInAction(
        () => dashboardStore.allInputs = ObservableList.of([
          Input(
            inputKind: 'ffmpeg_source',
            inputName: 'Clip',
            unversionedInputKind: 'ffmpeg_source',
          ),
        ]),
      );
      peer.responseData['GetSourceActive'] = {
        'videoActive': true,
        'videoShowing': true,
      };
      dashboardStore.requestMediaInProgram();
      await waitFor(
        () => dashboardStore.mediaInProgram['Clip'] == true,
        'initial in-program read',
      );
      final int statusReads = requestsOf('GetMediaInputStatus').length;

      peer.responseData['GetSourceActive'] = {
        'videoActive': false,
        'videoShowing': false,
      };
      dashboardStore.requestMediaInProgram();
      await waitFor(
        () => dashboardStore.mediaInProgram['Clip'] == false,
        'left the live scene',
      );
      await waitFor(
        () => requestsOf('GetMediaInputStatus').length == statusReads + 1,
        'status re-read after the flip',
      );
    },
  );

  test(
    'the in-program state is re-read once OBS settled after a transition',
    () async {
      runInAction(
        () => dashboardStore.allInputs = ObservableList.of([
          Input(
            inputKind: 'ffmpeg_source',
            inputName: 'Clip',
            unversionedInputKind: 'ffmpeg_source',
          ),
        ]),
      );
      peer.responseData['GetSourceActive'] = {
        'videoActive': true,
        'videoShowing': true,
      };
      dashboardStore.requestMediaInProgram();
      await waitFor(
        () => dashboardStore.mediaInProgram['Clip'] == true,
        'initial in-program read',
      );

      /// OBS deactivates the old scene's sources a frame AFTER the event -
      /// the read at the event still sees "active"
      peer.event('SceneTransitionEnded', {'transitionName': 'Fade'});
      await waitFor(
        () => requestsOf('GetSourceActive').length == 2,
        'read at the event',
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(dashboardStore.mediaInProgram['Clip'], isTrue);
      peer.responseData['GetSourceActive'] = {
        'videoActive': false,
        'videoShowing': false,
      };

      await waitFor(
        () => dashboardStore.mediaInProgram['Clip'] == false,
        'settled re-read sees it left the live scene',
      );
      expect(requestsOf('GetSourceActive'), hasLength(3));
    },
  );
}
