import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:mobx/mobx.dart' hide when;
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/types/classes/command_failure_notice.dart';
import 'package:obs_blade/types/classes/obs_request_ack.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/request_type.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/types/enums/web_socket_codes/request_status.dart';
import 'package:obs_blade/types/enums/web_socket_codes/web_socket_close_code.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_obs_peer.dart';

/// DashboardStore policy on top of the command-ack mechanism: definitive
/// failure -> re-read confirmed state via the matching Get* request (the
/// existing handlers re-apply it) + deduped toast notice + kill-switch.
void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late FakeObsPeer peer;
  late NetworkStore networkStore;
  late DashboardStore dashboardStore;

  Box<dynamic> settingsBox() => Hive.box(HiveKeys.Settings.name);

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
    tempDir = await Directory.systemTemp.createTemp('command_ack_dashboard');
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
    'rejected scene switch re-reads GetSceneList and the confirmed state is applied (self-healing)',
    () async {
      peer.responseData['GetSceneList'] = {
        'scenes': [
          {'sceneName': 'Camera', 'sceneIndex': 0},
          {'sceneName': 'Break', 'sceneIndex': 1},
        ],
        'currentProgramSceneName': 'Camera',
        'currentPreviewSceneName': 'Camera',
      };

      /// The GetSceneList handler chains a GetSceneItemList - dropping it
      /// keeps this test focused on the scene re-read (an empty sceneItems
      /// answer would trigger an empty filter batch, a pre-existing
      /// batchRequestType crash path unrelated to this wave)
      peer.droppedRequestTypes.add('GetSceneItemList');
      await connect();
      dashboardStore.handleStream();

      /// The optimistic write the defect is about: the UI shows the scene
      /// the user tapped although OBS never applied it
      dashboardStore.setActiveSceneName('Nope');
      peer.rejections['SetCurrentProgramScene'] =
          RequestStatus.InvalidResourceType.identifier;

      final ack = await dashboardStore.sendMutation(
        RequestType.SetCurrentProgramScene,
        fields: {'sceneName': 'Nope'},
        label: 'Scene switch',
      );

      expect(ack.success, isFalse);
      expect(ack.failureKind, ObsRequestFailureKind.rejected);
      await waitFor(
        () => requestsOf('GetSceneList').isNotEmpty,
        'GetSceneList re-read',
      );

      await waitFor(
        () => dashboardStore.activeSceneName == 'Camera',
        'confirmed program scene re-applied',
      );
      expect(dashboardStore.activeSceneName, 'Camera');

      expect(dashboardStore.commandFailureNotice, isNotNull);
      expect(
        dashboardStore.commandFailureNotice!.message,
        contains('Scene switch'),
      );
      expect(
        dashboardStore.commandFailureNotice!.message,
        contains('rejected'),
      );
    },
  );

  test(
    'rejected volume commit (slider onChangeEnd) re-reads GetInputVolume',
    () async {
      await connect();
      peer.rejections['SetInputVolume'] =
          RequestStatus.InvalidResourceState.identifier;

      final ack = await dashboardStore.sendMutation(
        RequestType.SetInputVolume,
        fields: {'inputName': 'Mic', 'inputVolumeMul': 0.5},
        label: 'Volume',
      );

      expect(ack.failureKind, ObsRequestFailureKind.rejected);

      await waitFor(
        () => requestsOf('GetInputVolume').isNotEmpty,
        'GetInputVolume re-read',
      );
      final reReads = requestsOf('GetInputVolume');
      expect(reReads, isNotEmpty);
      expect(reReads.last['requestData'], {'inputName': 'Mic'});
      expect(dashboardStore.commandFailureNotice, isNotNull);
    },
  );

  test('rejected mute toggle re-reads GetInputMute', () async {
    await connect();
    peer.rejections['SetInputMute'] = RequestStatus.GenericError.identifier;

    await dashboardStore.sendMutation(
      RequestType.SetInputMute,
      fields: {'inputName': 'Mic', 'inputMuted': true},
      label: 'Audio mute',
    );

    await waitFor(
      () => requestsOf('GetInputMute').isNotEmpty,
      'GetInputMute re-read',
    );
    final reReads = requestsOf('GetInputMute');
    expect(reReads.last['requestData'], {'inputName': 'Mic'});
  });

  test('rejected stream toggle re-reads via the stats batch', () async {
    await connect();
    peer.rejections['ToggleStream'] = RequestStatus.OutputRunning.identifier;

    await dashboardStore.sendMutation(
      RequestType.ToggleStream,
      label: 'Stream',
    );

    await waitFor(() => peer.batches.isNotEmpty, 'stats batch re-read');
    final batchTypes = peer.batches.last['requests'] as List;
    expect(
      batchTypes.map((request) => request['requestType']),
      containsAll(['GetStreamStatus', 'GetRecordStatus', 'GetStats']),
    );
  });

  test(
    'kill-switch off: still re-reads and logs, but no toast notice',
    () async {
      await settingsBox().put(SettingsKeys.CommandFailureToasts.name, false);
      await connect();
      peer.rejections['SetInputMute'] = RequestStatus.GenericError.identifier;

      final ack = await dashboardStore.sendMutation(
        RequestType.SetInputMute,
        fields: {'inputName': 'Mic', 'inputMuted': true},
        label: 'Audio mute',
      );

      expect(ack.failureKind, ObsRequestFailureKind.rejected);
      await waitFor(
        () => requestsOf('GetInputMute').isNotEmpty,
        'GetInputMute re-read even with toasts off',
      );
      expect(dashboardStore.commandFailureNotice, isNull);
    },
  );

  test('dedup: same failure kind in a short window surfaces once', () async {
    await connect();
    peer.rejections['SetInputMute'] = RequestStatus.GenericError.identifier;
    peer.rejections['SetInputVolume'] = RequestStatus.GenericError.identifier;

    final notices = <CommandFailureNotice>[];
    final dispose = autorun((_) {
      final notice = dashboardStore.commandFailureNotice;
      if (notice != null) notices.add(notice);
    });

    await dashboardStore.sendMutation(
      RequestType.SetInputMute,
      fields: {'inputName': 'Mic', 'inputMuted': true},
      label: 'Audio mute',
    );
    await dashboardStore.sendMutation(
      RequestType.SetInputMute,
      fields: {'inputName': 'Mic', 'inputMuted': false},
      label: 'Audio mute',
    );

    /// Same kind + same request type within the window -> one toast
    expect(notices, hasLength(1));

    /// A different failing command still surfaces
    await dashboardStore.sendMutation(
      RequestType.SetInputVolume,
      fields: {'inputName': 'Mic', 'inputVolumeMul': 0.5},
      label: 'Volume',
    );
    expect(notices, hasLength(2));

    dispose();
  });

  test(
    'connection loss storm: pending mutations fail together, one aggregate notice',
    () async {
      await connect();
      peer.droppedRequestTypes.addAll(['SetInputMute', 'SetInputVolume']);

      final notices = <CommandFailureNotice>[];
      final dispose = autorun((_) {
        final notice = dashboardStore.commandFailureNotice;
        if (notice != null) notices.add(notice);
      });

      final muteAck = dashboardStore.sendMutation(
        RequestType.SetInputMute,
        fields: {'inputName': 'Mic', 'inputMuted': true},
        label: 'Audio mute',
      );
      final volumeAck = dashboardStore.sendMutation(
        RequestType.SetInputVolume,
        fields: {'inputName': 'Mic', 'inputVolumeMul': 0.5},
        label: 'Volume',
      );

      await peer.closeSockets();

      final acks = await Future.wait([muteAck, volumeAck]);
      expect(
        acks.map((ack) => ack.failureKind),
        everyElement(ObsRequestFailureKind.connectionLost),
      );
      expect(notices, hasLength(1));
      expect(notices.single.message, contains('connection'));

      dispose();
    },
  );

  test(
    'no active session: mutation fails as connectionLost immediately',
    () async {
      final ack = await dashboardStore.sendMutation(
        RequestType.ToggleStream,
        label: 'Stream',
      );

      expect(ack.failureKind, ObsRequestFailureKind.connectionLost);
      expect(dashboardStore.commandFailureNotice, isNotNull);
    },
  );
}
