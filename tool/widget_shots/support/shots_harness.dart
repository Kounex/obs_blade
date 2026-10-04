import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/app.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';

import '../../../test/persistence/support/hive_test_harness.dart';

/// Phone portrait at 2x - the default frame for a shot
const Size kShotPhone = Size(390, 844);

/// Tablet landscape (above the 700 pt tablet breakpoint)
const Size kShotTablet = Size(1180, 820);

/// Renders widget states to PNGs with the app's real theme and real fonts,
/// headless (no simulator, no OBS) - for looking at new UI states before
/// reporting a feature as done. See `tool/widget_shots/README.md`.
///
/// Flutter tests render text with the Ahem test font (black boxes) unless
/// real fonts are loaded - [ShotsHarness.setUpAll] loads Roboto + the
/// Material / Cupertino icon fonts + the app's own icon fonts.
class ShotsHarness {
  late Directory _tempDir;
  late HiveTestHarness _hive;

  /// Call from `setUpAll`
  static Future<void> loadFonts() async {
    final flutterRoot = Platform.environment['FLUTTER_ROOT'];
    if (flutterRoot == null) {
      throw StateError('FLUTTER_ROOT not set - run through flutter test');
    }
    final material = '$flutterRoot/bin/cache/artifacts/material_fonts';
    for (final weight in ['Regular', 'Medium', 'Bold']) {
      await _font('Roboto', '$material/Roboto-$weight.ttf');
    }
    await _font('MaterialIcons', '$material/MaterialIcons-Regular.otf');

    /// cupertino_icons ships its font in the package - found through the
    /// package config (Isolate.resolvePackageUri isn't available in tests)
    final config =
        jsonDecode(File('.dart_tool/package_config.json').readAsStringSync())
            as Map<String, dynamic>;
    final cupertinoPackage = (config['packages'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .firstWhere((package) => package['name'] == 'cupertino_icons');

    /// rootUri is absolute (pub cache) or relative to .dart_tool/, and has
    /// no trailing slash
    final cupertinoRoot = Uri.parse(
      '.dart_tool/',
    ).resolve('${cupertinoPackage['rootUri']}/');
    final cupertino = File.fromUri(
      Directory.current.uri
          .resolveUri(cupertinoRoot)
          .resolve('assets/CupertinoIcons.ttf'),
    ).path;
    await _font('packages/cupertino_icons/CupertinoIcons', cupertino);
    await _font('CupertinoIcons', cupertino);

    await _font('JamIcons', 'assets/fonts/JamIcons.ttf');
    await _font('CustomFlutterIcons', 'assets/fonts/CustomFlutterIcons.ttf');
  }

  static Future<void> _font(String family, String path) async {
    final loader = FontLoader(family)
      ..addFont(
        Future.value(ByteData.sublistView(File(path).readAsBytesSync())),
      );
    await loader.load();
  }

  /// Call from `setUp` - fresh Hive boxes (settings, hidden scenes, ...)
  Future<void> setUp() async {
    _tempDir = await Directory.systemTemp.createTemp('widget_shots');
    _hive = HiveTestHarness(_tempDir);
    await _hive.init();
    await _hive.openAllBoxes();
  }

  /// Call from `tearDown`
  Future<void> tearDown() async {
    await _hive.close();
    if (_tempDir.existsSync()) _tempDir.deleteSync(recursive: true);
  }

  /// Pumps [child] in a [MaterialApp] with the app's theme (current Hive
  /// settings) inside a [Scaffold], lets animations settle and writes
  /// `build/widget_shots/<name>.png`.
  ///
  /// The route carries a [ScrollController] argument like the app's tab
  /// routes - dashboard widgets read it from `ModalRoute.settings`.
  Future<void> shot(
    WidgetTester tester,
    String name,
    Widget child, {
    Size size = kShotPhone,
    double devicePixelRatio = 2.0,
  }) async {
    tester.view.physicalSize = size * devicePixelRatio;
    tester.view.devicePixelRatio = devicePixelRatio;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        /// Keyed per shot: the route below is generated once per app, so
        /// a second shot in the same test kept showing the first child
        key: ValueKey(name),
        debugShowCheckedModeBanner: false,
        theme: App.buildTheme(Hive.box(HiveKeys.Settings.name)).copyWith(
          /// Roboto is the font flutter_test can load here - the app uses
          /// the platform font (SF on iOS, Roboto on Android)
          textTheme: App.buildTheme(
            Hive.box(HiveKeys.Settings.name),
          ).textTheme.apply(fontFamily: 'Roboto'),
        ),
        onGenerateRoute: (settings) => MaterialPageRoute(
          settings: RouteSettings(arguments: ScrollController()),
          builder: (_) => Scaffold(body: SafeArea(child: child)),
        ),
      ),
    );

    /// Many frames, not one long pump: staggered entrances start from
    /// delayed callbacks and need frames after those fire
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../build/widget_shots/$name.png'),
    );
  }
}
