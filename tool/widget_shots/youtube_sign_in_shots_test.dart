import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/youtube_device_code_dialog.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/youtube_setup_sheet.dart';

import 'support/shots_harness.dart';

/// YouTube read-only setups (API key, no OAuth client): the explainer
/// dialog and the sign-in-only sheet it opens.
void main() {
  final harness = ShotsHarness();

  setUpAll(ShotsHarness.loadFonts);
  setUp(harness.setUp);
  tearDown(harness.tearDown);

  testWidgets('read-only dialog', (tester) async {
    await harness.shot(
      tester,
      'youtube_read_only_dialog',
      Builder(
        builder: (context) =>
            Center(child: YouTubeReadOnlyDialog(hostContext: context)),
      ),
    );
  });

  testWidgets('sign-in sheet', (tester) async {
    await harness.shot(
      tester,
      'youtube_sign_in_sheet',
      Builder(
        builder: (context) => Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: Theme.of(context).cardColor,
            child: YouTubeSetupSheet(hostContext: context, signInOnly: true),
          ),
        ),
      ),
    );
  });

  testWidgets('sign-in sheet, narrow', (tester) async {
    await harness.shot(
      tester,
      'youtube_sign_in_sheet_narrow',
      Builder(
        builder: (context) => Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: Theme.of(context).cardColor,
            child: YouTubeSetupSheet(hostContext: context, signInOnly: true),
          ),
        ),
      ),
      size: const Size(320, 640),
    );
  });

  testWidgets('full setup sheet', (tester) async {
    await harness.shot(
      tester,
      'youtube_setup_sheet_full',
      Builder(
        builder: (context) => Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: Theme.of(context).cardColor,
            child: YouTubeSetupSheet(hostContext: context),
          ),
        ),
      ),
      size: const Size(390, 1100),
    );
  });
}
