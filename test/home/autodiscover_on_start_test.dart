import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/shared/general/base/adaptive_switch.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/stores/views/home.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/views/home/widgets/connect_box/connect_box.dart';
import 'package:obs_blade/views/settings/settings.dart';
import 'package:obs_blade/views/settings/widgets/action_block.dart/block_entry.dart';

import '../persistence/support/hive_test_harness.dart';

/// GitHub #93: the home screen's autodiscovery tries the port on every
/// address of the Wi-Fi subnet, which some networks flag as a port scan -
/// Settings -> General -> Search on Start turns the automatic
/// search off (on by default, so nothing changes for existing users)
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late HiveTestHarness harness;

  Box<dynamic> settingsBox() => Hive.box(HiveKeys.Settings.name);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('autodiscover_on_start');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);

    GetIt.instance.registerLazySingleton<NetworkStore>(() => NetworkStore());
    GetIt.instance.registerLazySingleton<HomeStore>(() => HomeStore());
  });

  tearDown(() async {
    await GetIt.instance.reset();
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('HomeStore.autodiscoverOnStart', () {
    test('searches when the setting was never touched (default on)', () {
      final homeStore = GetIt.instance<HomeStore>();

      homeStore.autodiscoverOnStart();

      expect(homeStore.autodiscoverConnections, isNotNull);
    });

    test('does not search when the setting is off', () async {
      await settingsBox().put(SettingsKeys.AutodiscoverOnStart.name, false);
      final homeStore = GetIt.instance<HomeStore>();

      homeStore.autodiscoverOnStart();

      expect(homeStore.autodiscoverConnections, isNull);
    });

    test('off clears the result of an earlier search (it may be stale by '
        'the time the home screen opens again)', () async {
      final homeStore = GetIt.instance<HomeStore>();
      homeStore.updateAutodiscoverConnections();
      expect(homeStore.autodiscoverConnections, isNotNull);

      await settingsBox().put(SettingsKeys.AutodiscoverOnStart.name, false);
      homeStore.autodiscoverOnStart();

      expect(homeStore.autodiscoverConnections, isNull);
    });
  });

  group('Autodiscover card without a search', () {
    Widget wrap() => MaterialApp(
      theme: ThemeData(
        cupertinoOverrideTheme: const CupertinoThemeData(),
        extensions: const [AppStatusColors.standard, AppTextColors.standard],
      ),
      home: const Scaffold(body: SingleChildScrollView(child: ConnectBox())),
    );

    testWidgets('offers Search instead of a spinner that never ends', (
      tester,
    ) async {
      await tester.pumpWidget(wrap());
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Searching...'), findsNothing);
    });

    testWidgets('tapping Search starts the search', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text('Search'));
      await tester.pump();

      expect(GetIt.instance<HomeStore>().autodiscoverConnections, isNotNull);
      expect(find.text('Search'), findsNothing);
    });

    testWidgets('Search with an invalid port shows the port error instead '
        'of doing nothing', (tester) async {
      GetIt.instance<HomeStore>().setAutodiscoverPort('');
      await tester.pumpWidget(wrap());
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Search'), findsOneWidget);

      await tester.tap(find.text('Search'));
      await tester.pump();

      expect(GetIt.instance<HomeStore>().autodiscoverConnections, isNull);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Invalid port'), findsOneWidget);
    });
  });

  group('Settings row', () {
    /// The settings landing route carries the tab's ScrollController as its
    /// route arguments (TabBase does this)
    Widget wrap() => MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
        cupertinoOverrideTheme: const CupertinoThemeData(),
        appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
        buttonTheme: ButtonThemeData(
          colorScheme: ColorScheme.fromSwatch(accentColor: Colors.redAccent),
        ),
        extensions: const [AppStatusColors.standard, AppTextColors.standard],
      ),
      onGenerateRoute: (routeSettings) => MaterialPageRoute(
        builder: (_) => const SettingsView(),
        settings: RouteSettings(name: '/', arguments: ScrollController()),
      ),
    );

    Finder row() => find.ancestor(
      of: find.text('Search on Start'),
      matching: find.byType(BlockEntry),
    );

    setUp(() {
      /// The Support block reads PackageInfo.fromPlatform() - no plugin in
      /// tests
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('dev.fluttercommunity.plus/package_info'),
            (call) async => <String, dynamic>{
              'appName': 'obs_blade',
              'packageName': 'de.obsblade.test',
              'version': '1.0.0',
              'buildNumber': '1',
              'buildSignature': 'test',
            },
          );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('dev.fluttercommunity.plus/package_info'),
            null,
          );
    });

    testWidgets('defaults to on and toggling persists to the settings box', (
      tester,
    ) async {
      await tester.pumpWidget(wrap());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      await tester.scrollUntilVisible(
        find.text('Search on Start'),
        200.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();

      expect(
        tester
            .widget<BaseAdaptiveSwitch>(
              find.descendant(
                of: row(),
                matching: find.byType(BaseAdaptiveSwitch),
              ),
            )
            .value,
        isTrue,
      );

      /// The switch writes to the settings Hive box (real I/O) - run the tap
      /// in a real zone and poll until the write landed
      await tester.runAsync(() async {
        await tester.tap(
          find.descendant(of: row(), matching: find.byType(Switch)),
        );
        await tester.pump();
        for (var i = 0; i < 250; i++) {
          if (settingsBox().get(SettingsKeys.AutodiscoverOnStart.name) ==
              false) {
            break;
          }
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
      });

      expect(settingsBox().get(SettingsKeys.AutodiscoverOnStart.name), isFalse);
    });
  });
}
