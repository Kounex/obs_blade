import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/types/classes/api/transition.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/request_type.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/types/enums/web_socket_codes/web_socket_close_code.dart';
import 'package:obs_blade/utils/network_helper.dart';
import 'package:obs_blade/utils/preview_transition/preview_transition_spec.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_obs_peer.dart';

/// Frame "bytes" per scene - the store only base64-decodes them, so any
/// payload tells the scenes apart
Uint8List _bytesOf(String scene) => Uint8List.fromList(utf8.encode(scene));

String _imageOf(String scene) =>
    'data:image/jpeg;base64,${base64Encode(_bytesOf(scene))}';

Transition _transition(String name, String kind, {int? duration}) => Transition(
  transitionName: name,
  transitionKind: kind,
  transitionFixed: kind == 'cut_transition',
  transitionDuration: duration,
  transitionConfigurable: false,
  transitionSettings: null,
);

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late FakeObsPeer peer;
  late NetworkStore networkStore;
  late DashboardStore dashboardStore;

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

  /// OBS at the start of a transition: the program scene already names the
  /// incoming scene (obs_frontend_get_current_scene - verified on OBS
  /// 32.2.2), the program event only comes once it ended
  void obsTransitionsTo(
    String scene, {
    Map<String, dynamic> override = const {
      'transitionName': null,
      'transitionDuration': null,
    },
  }) {
    peer.responseData['GetCurrentProgramScene'] = {'sceneName': scene};
    peer.responseData['GetSceneSceneTransitionOverride'] = override;
  }

  void currentTransitionIs(
    String name,
    String kind, {
    int? duration,
    Map<String, dynamic>? settings,
  }) {
    peer.responseData['GetCurrentSceneTransition'] = {
      'transitionName': name,
      'transitionKind': kind,
      'transitionFixed': kind == 'cut_transition',
      'transitionDuration': duration,
      'transitionConfigurable': settings != null,
      'transitionSettings': settings,
    };
  }

  Future<void> startPreviewOn(String scene) async {
    runInAction(() => dashboardStore.activeSceneName = scene);
    dashboardStore.setShouldRequestPreviewImage(true);
    await waitFor(
      () =>
          dashboardStore.scenePreviewImageBytes != null &&
          listEquals(dashboardStore.scenePreviewImageBytes, _bytesOf(scene)),
      'preview shows $scene',
    );
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('preview_transitions');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await harness.openAllBoxes();
    peer = await FakeObsPeer.start();
    networkStore = NetworkStore();
    dashboardStore = DashboardStore();
    GetIt.instance.registerSingleton<NetworkStore>(networkStore);
    GetIt.instance.registerSingleton<DashboardStore>(dashboardStore);
    peer.responseDataFor = (request) {
      if (request['requestType'] != 'GetSourceScreenshot') return null;
      final String scene = request['requestData']['sourceName'] as String;
      return {'imageData': _imageOf(scene)};
    };
    peer.responseData['GetVersion'] = {
      'availableRequests': <String>[],
      'supportedImageFormats': ['jpg', 'png'],
    };
    expect(
      await networkStore.setOBSWebSocket(peer.connection),
      WebSocketCloseCode.DontClose,
    );
    dashboardStore.handleStream();
    runInAction(
      () => dashboardStore.availableTransitions = [
        _transition('Fade', 'fade_transition', duration: 300),
        _transition('Swipe', 'swipe_transition', duration: 450),
        _transition('Cut', 'cut_transition'),
        _transition('Move', 'move_transition', duration: 600),
      ],
    );
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

  test(
    'a switch made elsewhere plays the transition at its start, not its end',
    () async {
      currentTransitionIs(
        'Swipe',
        'swipe_transition',
        duration: 450,
        settings: {'direction': 'up'},
      );
      await startPreviewOn('A');

      obsTransitionsTo('B');
      peer.event('SceneTransitionStarted', {'transitionName': 'Swipe'});

      await waitFor(
        () => dashboardStore.previewTransition != null,
        'transition started',
      );
      final transition = dashboardStore.previewTransition!;
      expect(transition.fromBytes, _bytesOf('A'));
      expect(transition.toBytes, _bytesOf('B'));
      expect(transition.spec.kind, PreviewTransitionKind.swipe);
      expect(transition.spec.direction, PreviewTransitionDirection.up);
      expect(transition.spec.duration, const Duration(milliseconds: 450));

      /// The dashboard moved over without CurrentProgramSceneChanged
      expect(dashboardStore.activeSceneName, 'B');
    },
  );

  test('an app tap plays the transition into the tapped scene', () async {
    currentTransitionIs('Fade', 'fade_transition', duration: 300);
    await startPreviewOn('A');

    obsTransitionsTo('B');
    dashboardStore.setActiveSceneName('B');
    peer.event('SceneTransitionStarted', {'transitionName': 'Fade'});

    await waitFor(
      () => dashboardStore.previewTransition != null,
      'transition started',
    );
    expect(dashboardStore.previewTransition!.fromBytes, _bytesOf('A'));
    expect(
      dashboardStore.previewTransition!.spec.kind,
      PreviewTransitionKind.fade,
    );
  });

  test('a per-scene override brings its own duration', () async {
    currentTransitionIs('Fade', 'fade_transition', duration: 300);
    await startPreviewOn('A');

    obsTransitionsTo(
      'B',
      override: {'transitionName': 'Swipe', 'transitionDuration': 1200},
    );
    peer.event('SceneTransitionStarted', {'transitionName': 'Swipe'});

    await waitFor(
      () => dashboardStore.previewTransition != null,
      'transition started',
    );
    final spec = dashboardStore.previewTransition!.spec;
    expect(spec.kind, PreviewTransitionKind.swipe);
    expect(spec.duration, const Duration(milliseconds: 1200));

    /// Only the current transition's settings are readable - an override
    /// runs on its kind's defaults
    expect(spec.direction, PreviewTransitionDirection.left);
  });

  test('an override without its own duration runs OBS\' 300 ms', () async {
    currentTransitionIs('Fade', 'fade_transition', duration: 900);
    await startPreviewOn('A');

    obsTransitionsTo(
      'B',
      override: {'transitionName': 'Swipe', 'transitionDuration': null},
    );
    peer.event('SceneTransitionStarted', {'transitionName': 'Swipe'});

    await waitFor(
      () => dashboardStore.previewTransition != null,
      'transition started',
    );
    expect(
      dashboardStore.previewTransition!.spec.duration,
      const Duration(milliseconds: 300),
    );
  });

  test('a plugin transition (Move) crossfades over its duration', () async {
    currentTransitionIs('Move', 'move_transition', duration: 600);
    await startPreviewOn('A');

    obsTransitionsTo('B');
    peer.event('SceneTransitionStarted', {'transitionName': 'Move'});

    await waitFor(
      () => dashboardStore.previewTransition != null,
      'transition started',
    );
    expect(
      dashboardStore.previewTransition!.spec.kind,
      PreviewTransitionKind.fade,
    );
    expect(
      dashboardStore.previewTransition!.spec.duration,
      const Duration(milliseconds: 600),
    );
  });

  test('a cut swaps the frame without a transition', () async {
    currentTransitionIs('Cut', 'cut_transition');
    await startPreviewOn('A');

    obsTransitionsTo('B');
    peer.event('SceneTransitionStarted', {'transitionName': 'Cut'});

    await waitFor(
      () => listEquals(dashboardStore.scenePreviewImageBytes, _bytesOf('B')),
      'preview shows B',
    );
    expect(dashboardStore.previewTransition, isNull);
  });

  test('turned off in Settings: the preview cuts', () async {
    await Hive.box(
      HiveKeys.Settings.name,
    ).put(SettingsKeys.AnimatePreviewTransitions.name, false);
    currentTransitionIs('Fade', 'fade_transition', duration: 300);
    await startPreviewOn('A');

    obsTransitionsTo('B');
    peer.event('SceneTransitionStarted', {'transitionName': 'Fade'});

    await waitFor(
      () => listEquals(dashboardStore.scenePreviewImageBytes, _bytesOf('B')),
      'preview shows B',
    );
    expect(dashboardStore.previewTransition, isNull);
  });

  test('a scene change without a transition (collection read) cuts', () async {
    await startPreviewOn('A');
    runInAction(() => dashboardStore.activeSceneName = 'B');
    await waitFor(
      () => listEquals(dashboardStore.scenePreviewImageBytes, _bytesOf('B')),
      'preview shows B',
    );
    expect(dashboardStore.previewTransition, isNull);
  });

  test('a program event after the early read was sent beats it', () async {
    currentTransitionIs('Fade', 'fade_transition', duration: 300);
    await startPreviewOn('A');
    peer.heldRequestTypes.add('GetCurrentProgramScene');

    obsTransitionsTo('B');
    peer.event('SceneTransitionStarted', {'transitionName': 'Fade'});
    await waitFor(
      () => peer.requests.any(
        (request) => request['requestType'] == 'GetCurrentProgramScene',
      ),
      'early program read sent',
    );

    /// Someone switched on again before the read came back
    peer.event('CurrentProgramSceneChanged', {'sceneName': 'C'});
    await flushPeer();
    expect(dashboardStore.activeSceneName, 'C');

    peer.releaseAll('GetCurrentProgramScene');
    await flushPeer();
    expect(dashboardStore.activeSceneName, 'C');
  });

  test('a quick transition uses the duration measured last time', () async {
    currentTransitionIs('Fade', 'fade_transition', duration: 300);
    await startPreviewOn('A');

    /// First run: no override, not the current one - measured on the way
    obsTransitionsTo('B');
    peer.event('SceneTransitionStarted', {'transitionName': 'Swipe'});
    await waitFor(
      () => dashboardStore.previewTransition != null,
      'first transition',
    );
    expect(
      dashboardStore.previewTransition!.spec.duration,
      const Duration(milliseconds: 300),
    );
    await Future<void>.delayed(const Duration(milliseconds: 700));
    peer.event('SceneTransitionVideoEnded', {'transitionName': 'Swipe'});
    await flushPeer();

    final int firstId = dashboardStore.previewTransition!.id;
    obsTransitionsTo('A');
    peer.event('SceneTransitionStarted', {'transitionName': 'Swipe'});
    await waitFor(
      () => dashboardStore.previewTransition!.id != firstId,
      'second transition',
    );
    expect(
      dashboardStore.previewTransition!.spec.duration.inMilliseconds,
      inInclusiveRange(650, 1500),
    );
  });

  test('stinger: held old frame, swap at the transition point', () async {
    currentTransitionIs(
      'Stinger',
      'obs_stinger_transition',
      settings: {'transition_point': 800},
    );
    runInAction(
      () => dashboardStore.availableTransitions = [
        _transition('Stinger', 'obs_stinger_transition'),
      ],
    );
    await startPreviewOn('A');

    obsTransitionsTo('B');
    peer.event('SceneTransitionStarted', {'transitionName': 'Stinger'});
    await waitFor(
      () => dashboardStore.previewTransition != null,
      'transition started',
    );
    final spec = dashboardStore.previewTransition!.spec;
    expect(spec.kind, PreviewTransitionKind.cutAtEnd);
    expect(spec.duration.inMilliseconds, inInclusiveRange(1, 800));
  });

  group('studio mode (T-bar drags start transitions too)', () {
    test(
      'the dashboard waits for the program event, the preview animates',
      () async {
        currentTransitionIs('Fade', 'fade_transition', duration: 300);
        runInAction(() => dashboardStore.studioMode = true);
        await startPreviewOn('A');

        obsTransitionsTo('B');
        peer.event('SceneTransitionStarted', {'transitionName': 'Fade'});
        await waitFor(
          () => dashboardStore.previewTransition != null,
          'transition started',
        );
        expect(dashboardStore.previewTransition!.toBytes, _bytesOf('B'));

        /// A cancelled T-bar drag sends no program event - tiles must not
        /// have moved
        expect(dashboardStore.activeSceneName, 'A');

        peer.event('CurrentProgramSceneChanged', {'sceneName': 'B'});
        await waitFor(
          () => dashboardStore.activeSceneName == 'B',
          'program event applied',
        );
      },
    );

    test(
      'a cancelled T-bar drag brings the preview back to the program',
      () async {
        currentTransitionIs('Fade', 'fade_transition', duration: 300);
        runInAction(() => dashboardStore.studioMode = true);
        await startPreviewOn('A');

        obsTransitionsTo('B');
        peer.event('SceneTransitionStarted', {'transitionName': 'Fade'});
        await waitFor(
          () =>
              listEquals(dashboardStore.scenePreviewImageBytes, _bytesOf('B')),
          'preview shows the incoming scene',
        );

        /// OBSBasic::TBarReleased: programScene back, no program event
        peer.event('SceneTransitionEnded', {'transitionName': 'Fade'});
        await waitFor(
          () =>
              listEquals(dashboardStore.scenePreviewImageBytes, _bytesOf('A')),
          'preview back on the program',
        );
        expect(dashboardStore.activeSceneName, 'A');
      },
    );
  });

  test('a cut needs no override / settings reads', () async {
    currentTransitionIs('Cut', 'cut_transition');
    await startPreviewOn('A');

    obsTransitionsTo('B');
    peer.event('SceneTransitionStarted', {'transitionName': 'Cut'});
    await waitFor(
      () => listEquals(dashboardStore.scenePreviewImageBytes, _bytesOf('B')),
      'preview shows B',
    );
    expect(
      peer.requests.where(
        (request) =>
            request['requestType'] == 'GetSceneSceneTransitionOverride',
      ),
      isEmpty,
    );
  });

  test('an app tap resolves without waiting for the program read', () async {
    currentTransitionIs('Fade', 'fade_transition', duration: 300);
    await startPreviewOn('A');
    peer.heldRequestTypes.add('GetCurrentProgramScene');

    obsTransitionsTo('B');
    dashboardStore.setActiveSceneName('B');
    peer.event('SceneTransitionStarted', {'transitionName': 'Fade'});

    /// The program read is still out - the transition plays anyway
    await waitFor(
      () => dashboardStore.previewTransition != null,
      'transition started',
    );
    expect(
      peer.requests
          .where(
            (request) =>
                request['requestType'] == 'GetSceneSceneTransitionOverride',
          )
          .single['requestData']['sceneName'],
      'B',
    );
    peer.releaseAll('GetCurrentProgramScene');
  });

  test('a stinger with unknown settings cuts mid-video, not at once', () async {
    /// Current is Fade - the stinger only runs as B's override
    currentTransitionIs('Fade', 'fade_transition', duration: 300);
    runInAction(
      () => dashboardStore.availableTransitions = [
        _transition('Fade', 'fade_transition', duration: 300),
        _transition('Stinger', 'obs_stinger_transition'),
      ],
    );
    await startPreviewOn('A');
    obsTransitionsTo(
      'B',
      override: {'transitionName': 'Stinger', 'transitionDuration': null},
    );

    /// First run measures the video (Started -> VideoEnded)
    peer.event('SceneTransitionStarted', {'transitionName': 'Stinger'});
    await waitFor(
      () => listEquals(dashboardStore.scenePreviewImageBytes, _bytesOf('B')),
      'first run shows B',
    );
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    peer.event('SceneTransitionVideoEnded', {'transitionName': 'Stinger'});
    await flushPeer();

    obsTransitionsTo(
      'A',
      override: {'transitionName': 'Stinger', 'transitionDuration': null},
    );
    peer.event('SceneTransitionStarted', {'transitionName': 'Stinger'});
    await waitFor(
      () => dashboardStore.previewTransition != null,
      'second run holds until mid-video',
    );
    final spec = dashboardStore.previewTransition!.spec;
    expect(spec.kind, PreviewTransitionKind.cutAtEnd);
    expect(spec.duration.inMilliseconds, inInclusiveRange(500, 900));
  });
}
