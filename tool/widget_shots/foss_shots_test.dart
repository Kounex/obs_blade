import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/enums/chat_engine.dart';
import 'package:obs_blade/stores/pro_store.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/build_flavor.dart';
import 'package:obs_blade/utils/pro_purchase_service.dart';
import 'package:obs_blade/views/chat/chat_view.dart';
import 'package:obs_blade/views/settings/faq/faq.dart';
import 'package:obs_blade/views/settings/settings.dart';

import '../../test/pro/support/fake_pro_purchase_gateway.dart';
import 'support/shots_harness.dart';

/// The FOSS build's screens (docs/foss-build.md) - only with the define:
///
///   tool/widget_shots/run.sh --dart-define=OBS_BLADE_FOSS=true \
///     tool/widget_shots/foss_shots_test.dart
///
/// Starts from a state that shows Pro in the store build (bought flag,
/// native engine) - none of it may show here.
void main() {
  final harness = ShotsHarness();
  late ProStore proStore;

  setUpAll(ShotsHarness.loadFonts);
  setUp(() async {
    await harness.setUp();
    final settings = Hive.box(HiveKeys.Settings.name);
    await settings.put(SettingsKeys.BoughtPro.name, true);
    await settings.put(SettingsKeys.SelectedChatEngine.name, ChatEngine.native);
    proStore = ProStore(
      service: ProPurchaseService(gateway: FakeProPurchaseGateway()),
    )..init();
    GetIt.instance.registerSingleton<ProStore>(proStore);
  });
  tearDown(() async {
    proStore.dispose();
    await GetIt.instance.reset();
    await harness.tearDown();
  });

  testWidgets('chat tab - phone', (tester) async {
    await harness.shot(tester, 'foss_chat_phone', const ChatView());
  }, skip: !kFoss);

  testWidgets('chat tab - tablet', (tester) async {
    await harness.shot(
      tester,
      'foss_chat_tablet',
      const ChatView(),
      size: kShotTablet,
    );
  }, skip: !kFoss);

  testWidgets('settings (whole list)', (tester) async {
    await harness.shot(
      tester,
      'foss_settings',
      const SettingsView(),
      size: const Size(390, 2300),
    );
  }, skip: !kFoss);

  testWidgets('FAQ (whole page)', (tester) async {
    await harness.shot(
      tester,
      'foss_faq',
      const FAQView(),
      size: const Size(390, 3600),
    );
  }, skip: !kFoss);
}
