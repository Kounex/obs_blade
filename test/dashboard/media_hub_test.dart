import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/types/classes/api/input.dart';
import 'package:obs_blade/types/classes/api/input_channel.dart';
import 'package:obs_blade/types/classes/api/scene_item.dart';
import 'package:obs_blade/types/classes/media/media_status.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/scene_content/media_hub/media_hub.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/scene_content/scene_items/scene_item_tile.dart';

import '../persistence/support/hive_test_harness.dart';

Input _media(String name, {String kind = 'ffmpeg_source'}) =>
    Input(inputKind: kind, inputName: name, unversionedInputKind: kind);

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late DashboardStore dashboardStore;

  Widget wrap(Widget child) => MaterialApp(
    theme: ThemeData(
      brightness: Brightness.dark,
      cupertinoOverrideTheme: const CupertinoThemeData(),
      extensions: const [AppStatusColors.standard, AppTextColors.standard],
    ),
    onGenerateRoute: (settings) => MaterialPageRoute(
      settings: RouteSettings(arguments: ScrollController()),
      builder: (_) => Scaffold(body: SizedBox(height: 500, child: child)),
    ),
  );

  /// The entrance stagger starts on a timer - one frame to fire it, one
  /// to run the (fully transparent → semantics-less) fade to the end
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 1));
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('media_hub');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);
    GetIt.instance.registerSingleton<NetworkStore>(NetworkStore());
    dashboardStore = DashboardStore();
    GetIt.instance.registerSingleton<DashboardStore>(dashboardStore);
  });

  tearDown(() async {
    await GetIt.instance.reset();
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('pads show every media input, playing + not-in-program state', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    runInAction(() {
      dashboardStore.allInputs = ObservableList.of([
        _media('Airhorn'),
        const Input(
          inputKind: 'wasapi_input_capture',
          inputName: 'Mic',
          unversionedInputKind: 'wasapi_input_capture',
        ),
        _media('Playlist', kind: 'vlc_source'),
      ]);
      dashboardStore.mediaStatus['Airhorn'] = MediaStatus(
        state: kMediaStatePlaying,
        duration: 4000,
        cursor: 1000,
        receivedAt: DateTime.now(),
      );
      dashboardStore.mediaInProgram['Playlist'] = false;
    });

    await tester.pumpWidget(wrap(const MediaHub()));
    await settle(tester);

    expect(find.text('Airhorn'), findsOneWidget);
    expect(find.text('Playlist'), findsOneWidget);
    expect(find.text('Mic'), findsNothing);
    expect(
      find.bySemanticsLabel(RegExp(r'^Airhorn, playing$')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        RegExp(r'^Playlist, stopped, not in the live scene$'),
      ),
      findsOneWidget,
    );
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    /// Unmount so the playing pad's clock timer is cancelled
    await tester.pumpWidget(const SizedBox());
    handle.dispose();
  });

  testWidgets('list view is persisted and shows time + not-in-program', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    runInAction(() {
      dashboardStore.allInputs = ObservableList.of([_media('Intro')]);
      dashboardStore.mediaStatus['Intro'] = MediaStatus(
        state: kMediaStatePaused,
        duration: 65000,
        cursor: 12000,
        receivedAt: DateTime.now(),
      );
      dashboardStore.mediaInProgram['Intro'] = false;
    });

    await tester.pumpWidget(wrap(const MediaHub()));
    await settle(tester);

    /// The toggle writes to the settings box (real I/O) - run it in a real
    /// zone so the write completes instead of hanging teardown
    await tester.runAsync(() async {
      await tester.tap(find.byIcon(CupertinoIcons.list_bullet));
      await tester.pump();
      await Hive.box(HiveKeys.Settings.name).flush();
    });
    await settle(tester);

    expect(
      Hive.box(HiveKeys.Settings.name).get(SettingsKeys.MediaHubViewMode.name),
      kMediaHubViewList,
    );
    expect(find.text('0:12 / 1:05'), findsOneWidget);
    expect(find.text('Not in the live scene'), findsOneWidget);
    expect(find.bySemanticsLabel('Stop Intro'), findsOneWidget);

    /// OBS only plays media in the live scene: starting is locked, stopping
    /// a stuck state is not
    bool enabled(String label) => tester
        .getSemantics(find.bySemanticsLabel(label))
        .flagsCollection
        .isEnabled
        .toBoolOrNull()!;
    expect(enabled('Play Intro'), isFalse);
    expect(enabled('Restart Intro'), isFalse);
    handle.dispose();
  });

  group('outside the live scene (what OBS 32 does)', () {
    bool enabled(WidgetTester tester, String label) => tester
        .getSemantics(find.bySemanticsLabel(label))
        .flagsCollection
        .isEnabled
        .toBoolOrNull()!;

    Future<void> showList(WidgetTester tester) async {
      await tester.pumpWidget(wrap(const MediaHub()));
      await settle(tester);
      await tester.runAsync(() async {
        await tester.tap(find.byIcon(CupertinoIcons.list_bullet));
        await tester.pump();
        await Hive.box(HiveKeys.Settings.name).flush();
      });
      await settle(tester);
    }

    void seed(
      String state,
      MediaLiveBehavior behavior, {
      String kind = 'ffmpeg_source',
    }) => runInAction(() {
      dashboardStore.allInputs = ObservableList.of([
        _media('Jingle', kind: kind),
      ]);
      dashboardStore.mediaStatus['Jingle'] = MediaStatus(
        state: state,
        duration: 30000,
        cursor: 7000,
        receivedAt: DateTime.now().subtract(const Duration(seconds: 20)),
      );
      dashboardStore.mediaInProgram['Jingle'] = false;
      dashboardStore.mediaLiveBehavior['Jingle'] = behavior;
    });

    testWidgets('restart off: it keeps playing unheard - time runs', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      seed(kMediaStatePlaying, MediaLiveBehavior.keepsPlaying);
      await showList(tester);

      /// 0:07 + the 20 s since the read - the clip really plays on
      expect(find.text('0:27 / 0:30'), findsOneWidget);
      expect(find.text('Not in the live scene'), findsOneWidget);
      expect(enabled(tester, 'Pause Jingle'), isTrue);
      expect(enabled(tester, 'Stop Jingle'), isTrue);
      expect(enabled(tester, 'Restart Jingle'), isFalse);

      await tester.pumpWidget(const SizedBox());
      handle.dispose();
    });

    testWidgets('restart off: a paused clip can resume unheard', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      seed(kMediaStatePaused, MediaLiveBehavior.keepsPlaying);
      await showList(tester);

      expect(find.text('0:07 / 0:30'), findsOneWidget);
      expect(enabled(tester, 'Play Jingle'), isTrue);
      expect(enabled(tester, 'Restart Jingle'), isFalse);
      handle.dispose();
    });

    testWidgets('restart on: stopped, plays from the start once live', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      seed('OBS_MEDIA_STATE_ENDED', MediaLiveBehavior.restarts);
      await tester.pumpWidget(wrap(const MediaHub()));
      await settle(tester);

      expect(
        find.bySemanticsLabel(
          RegExp(r'^Jingle, restarts when live, not in the live scene$'),
        ),
        findsOneWidget,
      );

      await showList(tester);
      expect(find.text('Restarts when live'), findsOneWidget);
      expect(enabled(tester, 'Play Jingle'), isFalse);
      expect(enabled(tester, 'Restart Jingle'), isFalse);
      expect(enabled(tester, 'Stop Jingle'), isFalse);
      handle.dispose();
    });

    testWidgets('restart on: a queued play shows no parked cursor', (
      tester,
    ) async {
      seed(kMediaStatePlaying, MediaLiveBehavior.restarts);
      await tester.pumpWidget(wrap(const MediaHub()));
      await settle(tester);

      expect(find.text('Restarts when live'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('VLC pause_unpause: on hold at the held position', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      seed(kMediaStatePaused, MediaLiveBehavior.holds, kind: 'vlc_source');
      await showList(tester);

      expect(find.text('On hold at 0:07 · resumes when live'), findsOneWidget);
      expect(enabled(tester, 'Play Jingle'), isFalse);
      expect(enabled(tester, 'Stop Jingle'), isTrue);
      handle.dispose();
    });
  });

  group('mediaLiveBehaviorOf', () {
    test('ffmpeg: restart_on_activate, missing = OBS default (on)', () {
      expect(
        mediaLiveBehaviorOf('ffmpeg_source', {}),
        MediaLiveBehavior.restarts,
      );
      expect(
        mediaLiveBehaviorOf('ffmpeg_source', {'restart_on_activate': false}),
        MediaLiveBehavior.keepsPlaying,
      );
      expect(
        mediaLiveBehaviorOf('ffmpeg_source', {'restart_on_activate': true}),
        MediaLiveBehavior.restarts,
      );
    });

    test('VLC: playback_behavior, missing = stop_restart', () {
      expect(
        mediaLiveBehaviorOf('vlc_source', null),
        MediaLiveBehavior.restarts,
      );
      expect(
        mediaLiveBehaviorOf('vlc_source', {'playback_behavior': 'always_play'}),
        MediaLiveBehavior.keepsPlaying,
      );
      expect(
        mediaLiveBehaviorOf('vlc_source', {
          'playback_behavior': 'pause_unpause',
        }),
        MediaLiveBehavior.holds,
      );
    });

    test('other inputs have none', () {
      expect(mediaLiveBehaviorOf('text_ft2_source_v2', {'text': 'x'}), isNull);
    });
  });

  test('audio meter ticks do not re-notify the media inputs', () {
    int notified = 0;
    final dispose = reaction(
      (_) => dashboardStore.mediaInputs,
      (_) => notified++,
    );
    runInAction(
      () => dashboardStore.allInputs = ObservableList.of([_media('Clip')]),
    );
    expect(notified, 1);

    /// A meter tick: same inputs, new levels, new list
    runInAction(
      () => dashboardStore.allInputs = ObservableList.of([
        _media('Clip').copyWith(
          inputLevelsMul: [
            InputChannel(current: 0.5, average: 0.4, potential: 0.5),
          ],
        ),
      ]),
    );
    expect(notified, 1);

    runInAction(
      () => dashboardStore.allInputs = ObservableList.of([
        _media('Clip'),
        _media('Jingle'),
      ]),
    );
    expect(notified, 2);
    expect(dashboardStore.mediaInputs.map((i) => i.inputName), [
      'Clip',
      'Jingle',
    ]);
    dispose();
  });

  testWidgets('empty state explains the Soundboard scene tip', (tester) async {
    await tester.pumpWidget(wrap(const MediaHub()));
    await settle(tester);

    expect(find.text('No media sources yet'), findsOneWidget);
    expect(find.textContaining('Soundboard'), findsOneWidget);
  });

  testWidgets(
    'scene item rows keep the media transport only with the hub off',
    (tester) async {
      final handle = tester.ensureSemantics();
      const SceneItem clip = SceneItem(
        inputKind: 'ffmpeg_source',
        isGroup: false,
        sceneItemBlendMode: null,
        sceneItemEnabled: true,
        sceneItemId: 1,
        sceneItemIndex: 0,
        sceneItemLocked: false,
        sceneItemTransform: null,
        sourceName: 'Intro',
        sourceType: 'OBS_SOURCE_TYPE_INPUT',
      );

      await tester.pumpWidget(
        wrap(const Material(child: SceneItemTile(sceneItem: clip))),
      );
      await settle(tester);

      /// Default: hub on → no row transport, lock is back
      expect(find.bySemanticsLabel('Restart Intro'), findsNothing);
      expect(find.bySemanticsLabel('Lock Intro'), findsOneWidget);

      await tester.runAsync(() async {
        final box = Hive.box(HiveKeys.Settings.name);
        await box.put(SettingsKeys.ExposeMediaHub.name, false);
        await box.flush();
      });
      await settle(tester);

      expect(find.bySemanticsLabel('Restart Intro'), findsOneWidget);
      expect(find.bySemanticsLabel('Lock Intro'), findsNothing);
      handle.dispose();
    },
  );
}
