// Live check against a REAL local OBS (macOS, docs/local-obs-e2e.md): the
// real DashboardStore plays OBS' scene transitions in its preview - switches
// from elsewhere and app taps, Swipe / Fade / Cut, a per-scene override and a
// settings change without event. Prints when the dashboard moves over and
// when the preview transition starts, relative to the switch.
//
// Changes OBS' current transition / duration / program scene and restores
// them afterwards; refuses to run while OBS streams, records or is in
// studio mode. Needs scenes plus transitions named "Fade", "Swipe" and "Cut"
// (OBS' defaults + one added Swipe). Not part of any suite - run by hand:
//   flutter test tool/obs_local/preview_transition_live_test.dart
// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/models/connection.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/types/enums/request_type.dart';
import 'package:obs_blade/types/enums/web_socket_codes/web_socket_close_code.dart';
import 'package:obs_blade/utils/network_helper.dart';

import '../../test/persistence/support/hive_test_harness.dart';

void main() {
  test('live: preview transitions against local OBS', () async {
    final tempDir = await Directory.systemTemp.createTemp('pt_live');
    final harness = HiveTestHarness(tempDir);
    await harness.init();
    await harness.openAllBoxes();

    final cfg =
        jsonDecode(
              File(
                '${Platform.environment['HOME']}/Library/Application Support/obs-studio/plugin_config/obs-websocket/config.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final networkStore = NetworkStore();
    final store = DashboardStore();
    GetIt.instance.registerSingleton<NetworkStore>(networkStore);
    GetIt.instance.registerSingleton<DashboardStore>(store);
    final code = await networkStore.setOBSWebSocket(
      Connection(
        '127.0.0.1',
        cfg['server_port'] as int? ?? 4455,
        cfg['server_password'] as String?,
      ),
    );
    expect(code, WebSocketCloseCode.DontClose);
    store.handleStream();
    store.initialRequests();
    final socket = networkStore.activeSession!.socket;

    Future<Map<String, dynamic>> req(
      RequestType type, [
      Map<String, dynamic>? data,
    ]) async =>
        (await NetworkHelper.makeScopedRequest(
          socket,
          type,
          data,
        )).responseData ??
        {};

    final stream = await req(RequestType.GetStreamStatus);
    final record = await req(RequestType.GetRecordStatus);
    if (stream['outputActive'] == true || record['outputActive'] == true) {
      fail('OBS is live / recording - not touching it');
    }
    final studio = await req(RequestType.GetStudioModeEnabled);
    if (studio['studioModeEnabled'] == true) fail('studio mode on - skipping');

    final scenes = await req(RequestType.GetSceneList);
    final String orig = scenes['currentProgramSceneName'] as String;
    final List<String> names = [
      for (final s in scenes['scenes'] as List) s['sceneName'] as String,
    ];
    final String other = names.firstWhere((n) => n != orig);
    final cur = await req(RequestType.GetCurrentSceneTransition);
    final String origTransition = cur['transitionName'] as String;
    final int? origDuration = cur['transitionDuration'] as int?;
    print('OBS: program=$orig, transition=$origTransition ${origDuration}ms');

    await Future<void>.delayed(const Duration(seconds: 1));
    store.setShouldRequestPreviewImage(true);
    final sw = Stopwatch()..start();
    var frames = 0;
    final d1 = reaction<Object?>(
      (_) => store.scenePreviewImageBytes,
      (_) => frames++,
    );
    await Future<void>.delayed(const Duration(seconds: 2));
    print('preview: ~${(frames / 2).toStringAsFixed(1)} fps on localhost');

    var events = <String>[];
    var t0 = 0;
    final d2 = reaction<Object?>((_) => store.previewTransition, (t) {
      if (t != null) {
        events.add(
          '${sw.elapsedMilliseconds - t0} ms  transition ${store.previewTransition!.spec} dir=${store.previewTransition!.spec.direction.name}',
        );
      }
    });
    final d3 = reaction<String?>((_) => store.activeSceneName, (n) {
      events.add('${sw.elapsedMilliseconds - t0} ms  activeSceneName=$n');
    });

    Future<void> run(String label, Future<void> Function() switchIt) async {
      events = [];
      t0 = sw.elapsedMilliseconds;
      await switchIt();
      await Future<void>.delayed(const Duration(milliseconds: 2000));
      print('--- $label');
      for (final e in events) {
        print('  $e');
      }
    }

    try {
      for (final transition in ['Swipe', 'Fade', 'Cut']) {
        await req(RequestType.SetCurrentSceneTransition, {
          'transitionName': transition,
        });
        if (transition != 'Cut') {
          await req(RequestType.SetCurrentSceneTransitionDuration, {
            'transitionDuration': 700,
          });
        }
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await run(
          '$transition 700ms, switch from elsewhere -> $other',
          () async {
            await req(RequestType.SetCurrentProgramScene, {'sceneName': other});
          },
        );
        await run('$transition 700ms, app tap -> $orig', () async {
          runInAction(() => store.setActiveSceneName(orig));
          await NetworkHelper.makeRequest(
            socket,
            RequestType.SetCurrentProgramScene,
            {'sceneName': orig},
          );
        });
      }

      /// Per-scene override: Fade 1200 ms into [other] while Swipe is current
      await req(RequestType.SetCurrentSceneTransition, {
        'transitionName': 'Swipe',
      });
      await req(RequestType.SetSceneSceneTransitionOverride, {
        'sceneName': other,
        'transitionName': 'Fade',
        'transitionDuration': 1200,
      });
      await run('override Fade 1200 -> $other', () async {
        await req(RequestType.SetCurrentProgramScene, {'sceneName': other});
      });
      await req(RequestType.SetSceneSceneTransitionOverride, {
        'sceneName': other,
        'transitionName': null,
        'transitionDuration': null,
      });

      /// Settings change without an event: swipe direction up
      await req(RequestType.SetCurrentSceneTransitionSettings, {
        'transitionSettings': {'direction': 'up'},
      });
      await run('Swipe direction up (no event) -> $orig', () async {
        await req(RequestType.SetCurrentProgramScene, {'sceneName': orig});
      });
      await req(RequestType.SetCurrentSceneTransitionSettings, {
        'transitionSettings': cur['transitionSettings'] ?? {},
        'overlay': false,
      });

      /// Studio mode: a T-bar drag that's cancelled puts the program back
      /// without any program event (OBSBasic::TBarReleased)
      await req(RequestType.SetStudioModeEnabled, {'studioModeEnabled': true});
      await Future<void>.delayed(const Duration(milliseconds: 800));
      await req(RequestType.SetCurrentPreviewScene, {'sceneName': other});
      await Future<void>.delayed(const Duration(milliseconds: 500));
      final List<String> previewScenes = [];
      final d4 = reaction<Object?>((_) => store.scenePreviewImageBytes, (_) {
        final String? last = previewScenes.isEmpty ? null : previewScenes.last;
        final String? now = store.debugPreviewSceneShown;
        if (now != null && now != last) {
          previewScenes.add(now);
          events.add('${sw.elapsedMilliseconds - t0} ms  preview shows $now');
        }
      });
      await run('studio: T-bar to 50 % and cancelled', () async {
        await req(RequestType.SetTBarPosition, {
          'position': 0.5,
          'release': false,
        });
        await Future<void>.delayed(const Duration(milliseconds: 800));
        events.add('${sw.elapsedMilliseconds - t0} ms  (releasing at 0)');
        await req(RequestType.SetTBarPosition, {
          'position': 0.0,
          'release': true,
        });
        await Future<void>.delayed(const Duration(seconds: 6));
      });
      final program = await req(RequestType.GetCurrentProgramScene);
      print(
        '  OBS program now: ${program['sceneName']}, '
        'app activeSceneName: ${store.activeSceneName}',
      );
      d4();
    } finally {
      await req(RequestType.SetStudioModeEnabled, {'studioModeEnabled': false});
      d1();
      d2();
      d3();
      await req(RequestType.SetCurrentSceneTransition, {
        'transitionName': origTransition,
      });
      if (origDuration != null) {
        await req(RequestType.SetCurrentSceneTransitionDuration, {
          'transitionDuration': origDuration,
        });
      }
      await req(RequestType.SetCurrentProgramScene, {'sceneName': orig});
      final now = await req(RequestType.GetCurrentSceneTransition);
      print(
        'restored: transition=${now['transitionName']} ${now['transitionDuration']}ms',
      );
      store.setShouldRequestPreviewImage(false);
      store.disposeListeners();
      networkStore.closeSession();
      await GetIt.instance.reset();
      await harness.close();
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}
