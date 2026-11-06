import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/types/classes/api/input.dart';
import 'package:obs_blade/views/dashboard/widgets/dashboard_content/scene_content/audio_inputs/audio_settings_sheet.dart';

import 'support/shots_harness.dart';

/// Audio Settings sheet monitoring control: Off / On on OBS 33+ (on / off
/// only there), Off / Monitor / Both on older OBS. Phone, narrow 320 pt
/// and tablet
void main() {
  final harness = ShotsHarness();
  late DashboardStore dashboardStore;

  setUpAll(ShotsHarness.loadFonts);

  setUp(() async {
    await harness.setUp();
    dashboardStore = DashboardStore();
    GetIt.instance.registerSingleton<DashboardStore>(dashboardStore);
    GetIt.instance.registerSingleton<NetworkStore>(NetworkStore());
  });

  tearDown(() async {
    await GetIt.instance.reset();
    await harness.tearDown();
  });

  void state(String obsVersion, String monitorType) => runInAction(() {
    dashboardStore.obsVersion = obsVersion;
    dashboardStore.allInputs = ObservableList.of([
      Input(
        inputKind: 'wasapi_input_capture',
        inputName: 'Desktop Audio',
        unversionedInputKind: 'wasapi_input_capture',
        audioBalance: 0.5,
        monitorType: monitorType,
      ),
    ]);
  });

  const Widget sheet = AudioSettingsSheet(inputName: 'Desktop Audio');

  testWidgets('OBS 33 on', (tester) async {
    state('33.0.1', kMonitorTypeMonitorAndOutput);
    await harness.shot(tester, 'audio_monitoring_obs33_on', sheet);
    await harness.shot(
      tester,
      'audio_monitoring_obs33_on_narrow',
      sheet,
      size: const Size(320, 640),
    );
    await harness.shot(
      tester,
      'audio_monitoring_obs33_on_tablet',
      sheet,
      size: kShotTablet,
    );
  });

  testWidgets('OBS 33 off', (tester) async {
    state('33.0.1', kMonitorTypeNone);
    await harness.shot(tester, 'audio_monitoring_obs33_off', sheet);
  });

  testWidgets('OBS 32 monitor only', (tester) async {
    state('32.2.2', kMonitorTypeMonitorOnly);
    await harness.shot(tester, 'audio_monitoring_obs32_monitor', sheet);
    await harness.shot(
      tester,
      'audio_monitoring_obs32_monitor_narrow',
      sheet,
      size: const Size(320, 640),
    );
  });
}
