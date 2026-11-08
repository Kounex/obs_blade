import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/models/hotkey.dart';
import 'package:obs_blade/shared/general/app_bar_actions.dart';
import 'package:obs_blade/shared/general/date_range/date_picker_sheet.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/types/classes/api/filter.dart';
import 'package:obs_blade/types/classes/api/input.dart';
import 'package:obs_blade/types/classes/api/scene_item.dart';
import 'package:obs_blade/utils/modal_handler.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/exposed_controls/hotkeys_control/hotkey_list.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/scene_content/audio_inputs/audio_settings_sheet.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/scene_content/media_hub/media_hub_arrange_sheet.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/scene_content/scene_items/filter_list/filter_list.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/scene_content/scene_items/text_source_sheet.dart';
import 'package:obs_blade/views/settings/about/widgets/license_modal/license_modal.dart';
import 'package:obs_blade/views/settings/custom_theme/widgets/add_edit_theme/add_edit_theme.dart';
import 'package:obs_blade/views/settings/custom_theme/widgets/color_picker/color_picker.dart';

import 'support/shots_harness.dart';

/// The Filters sheet polls OBS for filter lists every 500 ms - there is
/// no OBS session in a shot
class _ShotsDashboardStore extends DashboardStore {
  @override
  void fetchSceneItemsFilters() {}
}

/// Every dashboard / settings / picker sheet in the one shared sheet
/// (handle, pinned title, 640 pt cap, glass on iOS) - the sheets that
/// moved off the old Cupertino card in 2026-11. Each on phone (iOS glass),
/// narrow 320 pt and tablet; the chat sheets have their own specs.
void main() {
  final harness = ShotsHarness();
  late DashboardStore dashboardStore;

  setUpAll(ShotsHarness.loadFonts);

  setUp(() async {
    await harness.setUp();
    dashboardStore = _ShotsDashboardStore();
    GetIt.instance.registerSingleton<DashboardStore>(dashboardStore);
    GetIt.instance.registerSingleton<NetworkStore>(NetworkStore());
    runInAction(() {
      dashboardStore.allInputs = ObservableList.of([
        Input(
          inputKind: 'wasapi_input_capture',
          inputName: 'Desktop Audio',
          unversionedInputKind: 'wasapi_input_capture',
          audioBalance: 0.5,
          monitorType: 'OBS_MONITORING_TYPE_NONE',
        ),
        Input(
          inputKind: 'ffmpeg_source',
          inputName: 'Intro clip',
          unversionedInputKind: 'ffmpeg_source',
        ),
        Input(
          inputKind: 'ffmpeg_source',
          inputName: 'Applause',
          unversionedInputKind: 'ffmpeg_source',
        ),
      ]);
      dashboardStore.hotkeys = ObservableSet.of([
        for (final name in [
          'OBSBasic.StartStreaming',
          'OBSBasic.StopStreaming',
          'OBSBasic.StartRecording',
          'OBSBasic.StopRecording',
          'OBSBasic.Screenshot',
          'OBSBasic.ReplayBuffer.Save',
          'OBSBasic.TogglePreview',
          'OBSBasic.Transition',
        ])
          Hotkey(name),
      ]);
      dashboardStore.currentSceneItems = ObservableList.of([
        const SceneItem(
          inputKind: 'dshow_input',
          isGroup: false,
          sceneItemBlendMode: null,
          sceneItemEnabled: true,
          sceneItemId: 1,
          sceneItemIndex: 0,
          sceneItemLocked: false,
          sceneItemTransform: null,
          sourceName: 'Facecam',
          sourceType: 'OBS_SOURCE_TYPE_INPUT',
          filters: [
            Filter(
              filterEnabled: true,
              filterIndex: 0,
              filterKind: 'color_filter_v2',
              filterName: 'Color Correction',
              filterSettings: {'brightness': 0.05, 'contrast': 0.1},
            ),
            Filter(
              filterEnabled: false,
              filterIndex: 1,
              filterKind: 'chroma_key_filter_v2',
              filterName: 'Chroma Key',
              filterSettings: {'similarity': 400},
            ),
          ],
        ),
      ]);
    });
  });

  tearDown(() async {
    await GetIt.instance.reset();
    await harness.tearDown();
  });

  /// Phone on iOS (glass), narrow 320 pt and tablet on Android (solid)
  Future<void> all(
    WidgetTester tester,
    String name,
    Widget Function() build, {
    BaseSheetHeight height = BaseSheetHeight.standard,
  }) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await harness.shot(
        tester,
        'sheet_${name}_ios',
        ShotsHarness.inSheet(build, height: height),
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
    await harness.shot(
      tester,
      'sheet_${name}_narrow',
      ShotsHarness.inSheet(build, height: height),
      size: const Size(320, 640),
    );
    await harness.shot(
      tester,
      'sheet_${name}_tablet',
      ShotsHarness.inSheet(build, height: height),
      size: kShotTablet,
    );
  }

  testWidgets('audio settings', (tester) async {
    await all(
      tester,
      'audio',
      () => const AudioSettingsSheet(inputName: 'Desktop Audio'),
    );
  });

  testWidgets('hotkeys', (tester) async {
    await all(
      tester,
      'hotkeys',
      () => const HotkeyList(),
      height: BaseSheetHeight.tall,
    );
  });

  testWidgets('filters', (tester) async {
    await all(
      tester,
      'filters',
      () => FilterList(sceneItem: dashboardStore.currentSceneItems.first),
      height: BaseSheetHeight.tall,
    );
  });

  testWidgets('text source', (tester) async {
    await all(
      tester,
      'text_source',
      () => const TextSourceSheet(inputName: 'Lower third'),
    );
  });

  testWidgets('media arrange', (tester) async {
    await all(
      tester,
      'media_arrange',
      () => const MediaHubArrangeSheet(connectionKey: 'shots'),
      height: BaseSheetHeight.tall,
    );
  });

  testWidgets('credits', (tester) async {
    await all(
      tester,
      'credits',
      () => const LicenseModal(),
      height: BaseSheetHeight.tall,
    );
  });

  testWidgets('add theme', (tester) async {
    await all(
      tester,
      'add_theme',
      () => const AddEditTheme(),
      height: BaseSheetHeight.tall,
    );
  });

  testWidgets('color picker', (tester) async {
    await all(
      tester,
      'color_picker',
      () => const ColorPicker(
        title: 'Card Border Color',
        description:
            'You can set an outline color for the card elements used throughout the app to give them an extra touch',
        color: '6A5ACD',
      ),
      height: BaseSheetHeight.tall,
    );
  });

  testWidgets('date picker', (tester) async {
    await all(
      tester,
      'date_picker',
      () => DatePickerSheet(selectedDate: DateTime(2026, 11, 8)),
      height: BaseSheetHeight.tall,
    );
  });

  /// AppBarActions: Cupertino action sheet on iOS (capped at the sheet
  /// width on tablets), the shared sheet on Android
  testWidgets('action menu', (tester) async {
    Widget menu() => Builder(
      builder: (context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (ModalRoute.of(context)?.isCurrent ?? false) {
            AppBarActions.showActions(
              context,
              actionSheetTitle: 'Statistic',
              actions: [
                AppBarActionEntry(title: 'Share', onAction: () {}),
                AppBarActionEntry(title: 'Export as CSV', onAction: () {}),
                AppBarActionEntry(
                  title: 'Delete',
                  isDestructive: true,
                  onAction: () {},
                ),
              ],
            );
          }
        });
        return const ColoredBox(color: Color(0xFF3A3F55));
      },
    );
    for (final (platform, tag) in [
      (TargetPlatform.iOS, 'ios'),
      (TargetPlatform.android, 'android'),
    ]) {
      debugDefaultTargetPlatformOverride = platform;
      try {
        await harness.shot(tester, 'sheet_actions_$tag', menu());
        await harness.shot(
          tester,
          'sheet_actions_${tag}_tablet',
          menu(),
          size: kShotTablet,
        );
        await harness.shot(
          tester,
          'sheet_actions_${tag}_tablet_portrait',
          menu(),
          size: const Size(820, 1180),
        );
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    }
  });
}
