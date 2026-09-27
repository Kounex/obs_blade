import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/utils/legal_links.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

/// Records launches; [result] is what the platform reports back.
class FakeUrlLauncher extends UrlLauncherPlatform
    with MockPlatformInterfaceMixin {
  final List<(String, PreferredLaunchMode)> launches = [];
  bool result = true;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launches.add((url, options.mode));
    return result;
  }
}

void main() {
  late FakeUrlLauncher launcher;

  setUp(() {
    launcher = FakeUrlLauncher();
    UrlLauncherPlatform.instance = launcher;
  });

  Widget app(Uri uri) => MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => openLegalPage(context, uri),
          child: const Text('open'),
        ),
      ),
    ),
  );

  test('the legal pages live on the website', () {
    expect('$kPrivacyPolicyUri', 'https://obs-blade.kounex.com/privacy-policy');
    expect('$kImprintUri', 'https://obs-blade.kounex.com/imprint');
  });

  testWidgets('opens the page in the in-app browser', (tester) async {
    await tester.pumpWidget(app(kPrivacyPolicyUri));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(launcher.launches, [
      (
        'https://obs-blade.kounex.com/privacy-policy',
        PreferredLaunchMode.inAppBrowserView,
      ),
    ]);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('says so when nothing can open it', (tester) async {
    launcher.result = false;
    await tester.pumpWidget(app(kImprintUri));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Couldn\'t open the link.'), findsOneWidget);
  });
}
