import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/stores/views/youtube_chat.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_window.dart';
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

  testWidgets('sign-in dialog: account without a channel', (tester) async {
    final store = YouTubeChatStore(isProResolver: () => false);
    GetIt.instance.registerSingleton<YouTubeChatStore>(store);
    addTearDown(GetIt.instance.reset);
    runInAction(() {
      store.signedInWithoutChannel = true;
      store.authState = YouTubeAuthState.signedIn;
    });
    await harness.shot(
      tester,
      'youtube_sign_in_no_channel',
      const Center(child: YouTubeDeviceCodeDialog()),
    );
  });

  testWidgets('chat header sheet: signed in, channel not live', (tester) async {
    await harness.shot(
      tester,
      'youtube_header_offline_window',
      const NativeChatWindow(
        chatType: ChatType.YouTube,
        status: NativeChatConnectionStatus.offline,
        accountLabel: 'Brand Channel',
        offlineNote:
            'Brand Channel isn\'t live right now. The chat connects on its '
            'own when the stream starts.',
        onLogout: _noop,
        child: SizedBox(height: 300),
      ),
    );
    await tester.tap(find.text('offline'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile(
        '../../build/widget_shots/youtube_header_offline_sheet.png',
      ),
    );
  });
}

void _noop() {}
