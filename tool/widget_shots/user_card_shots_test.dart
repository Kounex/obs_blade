import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/stores/views/kick_chat.dart';
import 'package:obs_blade/stores/views/kick_emotes.dart';
import 'package:obs_blade/stores/views/third_party_emotes.dart';
import 'package:obs_blade/stores/views/youtube_chat.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/dialogs/kick_user_card_sheet.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/dialogs/youtube_user_card_sheet.dart';

import '../../test/chat/support/fake_kick_services.dart';
import '../../test/chat/support/fake_twitch_services.dart'
    show FakeThirdPartyEmoteService;
import '../../test/chat/support/fake_youtube_services.dart';
import '../../test/chat/youtube_chat_message_row_test.dart' show ytMessage;
import 'support/shots_harness.dart';

/// YouTube and Kick user cards with the highlight / ignore rows (same as
/// Twitch's card).
void main() {
  final harness = ShotsHarness();

  setUpAll(ShotsHarness.loadFonts);
  setUp(() async {
    await harness.setUp();
    GetIt.instance
      ..registerSingleton<YouTubeChatStore>(
        YouTubeChatStore(
          authService: FakeYouTubeAuthService(),
          chatService: FakeYouTubeLiveChatService(),
          isProResolver: () => true,
        ),
      )
      ..registerSingleton<KickChatStore>(
        KickChatStore(
          channelService: FakeKickChannelService(),
          authService: FakeKickAuthService(),
          apiService: FakeKickApiService(),
          pusherFactory: ({required onEvent, required onStateChanged}) =>
              FakeKickPusherService(
                onEvent: onEvent,
                onStateChanged: onStateChanged,
              ),
          isProResolver: () => true,
          emoteStoreResolver: () =>
              ThirdPartyEmoteStore(service: FakeThirdPartyEmoteService()),
          kickEmoteStoreResolver: () =>
              KickEmoteStore(service: FakeKickEmoteService()),
        ),
      );
  });
  tearDown(() async {
    await GetIt.instance.reset();
    await harness.tearDown();
  });

  testWidgets('youtube card', (tester) async {
    await harness.shot(
      tester,
      'user_card_youtube',
      Builder(
        builder: (context) => YouTubeUserCardSheet(
          channelId: 'UCremy',
          fallbackName: 'Remy',
          hostContext: context,
        ),
      ),
    );
  });

  testWidgets('kick card', (tester) async {
    await harness.shot(
      tester,
      'user_card_kick',
      Builder(
        builder: (context) => KickUserCardSheet(
          userId: 42,
          fallbackName: 'kickfan',
          hostContext: context,
        ),
      ),
    );
  });

  testWidgets('chatty viewer, opened as a sheet', (tester) async {
    final store = GetIt.instance<YouTubeChatStore>();
    runInAction(() {
      for (var i = 0; i < 20; i++) {
        store.messages.add(
          ytMessage(
            'm$i',
            author: 'UCremy',
            authorName: 'Remy',
            text: 'message number $i with a few more words so it wraps',
          ),
        );
      }
    });
    await harness.shot(
      tester,
      'user_card_youtube_chatty_base',
      Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () =>
                showYouTubeUserCardSheet(context, channelId: 'UCremy'),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile(
        '../../build/widget_shots/user_card_youtube_chatty.png',
      ),
    );
  });
}
