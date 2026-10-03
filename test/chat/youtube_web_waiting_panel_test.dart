import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/utils/youtube_target.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/stream_chat.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/youtube_web_live_tracker.dart';

import 'support/fake_youtube_services.dart';

void main() {
  /// Free (WebView) users with an entry saved from a channel id: the
  /// waiting panel names the entry, never the `UC…` id.
  testWidgets('a channel-id entry between streams is named by its label', (
    tester,
  ) async {
    final tracker = YouTubeWebLiveTracker(
      resolver: FakeYouTubeLiveResolver([null]),
    );
    await tester.runAsync(() async {
      tracker.track(
        const YouTubeChannelTarget('channel/UCabcdefghijklmnopqrstuv'),
      );
      await Future<void>.delayed(Duration.zero);
    });
    expect(tracker.state, YouTubeWebLiveState.offline);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          cupertinoOverrideTheme: const CupertinoThemeData(),
          extensions: const [AppStatusColors.standard, AppTextColors.standard],
        ),
        home: Scaffold(
          body: YouTubeChannelWaitingPanel(name: 'NASA', tracker: tracker),
        ),
      ),
    );

    expect(find.textContaining('NASA isn\'t live right now'), findsOneWidget);
    expect(find.textContaining('UCabc'), findsNothing);
    tracker.dispose();
  });
}
