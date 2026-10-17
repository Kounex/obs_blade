import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/stores/views/home.dart';
import 'package:obs_blade/views/home/widgets/connect_box/connect_box.dart';
import 'package:obs_blade/views/settings/settings.dart';

import 'support/shots_harness.dart';

/// GitHub #93: Search on Start off - the Autodiscover card waits
/// for a tap on Search instead of scanning (phone, narrow 320 pt phone,
/// tablet), and the new row in Settings -> General
void main() {
  final harness = ShotsHarness();

  setUpAll(ShotsHarness.loadFonts);

  setUp(() async {
    await harness.setUp();
    GetIt.instance.registerSingleton<NetworkStore>(NetworkStore());
    GetIt.instance.registerSingleton<HomeStore>(HomeStore());
  });

  tearDown(() async {
    await GetIt.instance.reset();
    await harness.tearDown();
  });

  for (final (name, size) in [
    ('autodiscover_search_prompt', kShotPhone),
    ('autodiscover_search_prompt_narrow', const Size(320, 640)),
    ('autodiscover_search_prompt_tablet', kShotTablet),
  ]) {
    testWidgets('autodiscover card without a search: $name', (tester) async {
      await harness.shot(
        tester,
        name,
        const SingleChildScrollView(child: ConnectBox()),
        size: size,
      );
    });
  }

  testWidgets('settings general block with the new row', (tester) async {
    await harness.shot(
      tester,
      'autodiscover_settings_row',
      const SettingsView(),
    );
  });
}
