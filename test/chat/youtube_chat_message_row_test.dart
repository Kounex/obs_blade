import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/types/classes/youtube/youtube_chat_message.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/twitch_chat_message_row.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/youtube_chat_message_row.dart';

import '../persistence/support/hive_test_harness.dart';

YouTubeChatMessage ytMessage(
  String id, {
  String author = 'chan-1',
  String? authorName,
  String? text,
  bool owner = false,
  bool moderator = false,
  bool sponsor = false,
  bool verified = false,
  bool tombstoned = false,
}) =>
    YouTubeChatMessage(
      id: id,
      isTombstoned: tombstoned,
      snippet: YouTubeChatMessageSnippet(
        type: YouTubeChatMessageType.textMessage,
        publishedAt: DateTime.utc(2026, 9, 3),
        authorChannelId: author,
        displayMessage: text ?? 'text $id',
        textMessageDetails:
            YouTubeTextMessageDetails(messageText: text ?? 'text $id'),
      ),
      authorDetails: YouTubeChatAuthorDetails(
        channelId: author,
        displayName: authorName ?? 'User $author',
        isChatOwner: owner,
        isChatModerator: moderator,
        isChatSponsor: sponsor,
        isVerified: verified,
      ),
    );

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;

  Box settingsBox() => Hive.box(HiveKeys.Settings.name);

  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(
          body: Column(children: [child]),
        ),
      );

  /// Plain-text of every rendered RichText — the rows build their content
  /// as Text.rich, which `find.text` doesn't see (same idiom as
  /// shared_chat_row_test).
  String renderedRichText(WidgetTester tester) => tester
      .widgetList<RichText>(find.byType(RichText))
      .map((rich) => rich.text.toPlainText())
      .join('\n');

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('yt_row_test');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);
  });

  tearDown(() async {
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('text message renders badges, colored author and body',
      (tester) async {
    await tester.pumpWidget(wrap(YouTubeChatMessageRow(
      message: ytMessage(
        'm1',
        authorName: 'Some Chatter',
        text: 'hello stream',
        owner: true,
        moderator: true,
        sponsor: true,
        verified: true,
      ),
      settingsBox: settingsBox(),
    )));
    await tester.pump();

    expect(renderedRichText(tester), contains('Some Chatter'));
    expect(renderedRichText(tester), contains('hello stream'));
    expect(find.byKey(const Key('yt-badge-owner')), findsOneWidget);
    expect(find.byKey(const Key('yt-badge-mod')), findsOneWidget);
    expect(find.byKey(const Key('yt-badge-member')), findsOneWidget);
    expect(find.byKey(const Key('yt-badge-verified')), findsOneWidget);
  });

  testWidgets('no badge icons for a plain chatter', (tester) async {
    await tester.pumpWidget(wrap(YouTubeChatMessageRow(
      message: ytMessage('m1'),
      settingsBox: settingsBox(),
    )));
    await tester.pump();

    expect(find.byKey(const Key('yt-badge-owner')), findsNothing);
    expect(find.byKey(const Key('yt-badge-mod')), findsNothing);
    expect(find.byKey(const Key('yt-badge-member')), findsNothing);
    expect(find.byKey(const Key('yt-badge-verified')), findsNothing);
  });

  testWidgets('tombstoned message dims the body and appends the marker',
      (tester) async {
    await tester.pumpWidget(wrap(YouTubeChatMessageRow(
      message: ytMessage('m1', text: 'gone soon', tombstoned: true),
      settingsBox: settingsBox(),
    )));
    await tester.pump();

    expect(renderedRichText(tester), contains('gone soon'));
    expect(renderedRichText(tester), contains('—Deleted'));
  });

  testWidgets('super chat renders a tier card with amount and comment',
      (tester) async {
    final message = YouTubeChatMessage(
      id: 'sc1',
      snippet: YouTubeChatMessageSnippet(
        type: YouTubeChatMessageType.superChat,
        publishedAt: DateTime.utc(2026, 9, 3),
        authorChannelId: 'chan-9',
        displayMessage: 'keep it up',
        superChatDetails: YouTubeSuperChatDetails(
          amountDisplayString: '\$5.00',
          tier: 3,
          userComment: 'keep it up',
        ),
      ),
      authorDetails: YouTubeChatAuthorDetails(
          channelId: 'chan-9', displayName: 'Fan Nine'),
    );

    await tester.pumpWidget(wrap(YouTubeChatMessageRow(
      message: message,
      settingsBox: settingsBox(),
    )));
    await tester.pump();

    expect(find.byKey(const Key('yt-super-chat-card')), findsOneWidget);
    expect(find.text('\$5.00'), findsOneWidget);
    expect(renderedRichText(tester), contains('Fan Nine'));
    expect(renderedRichText(tester), contains('keep it up'));

    /// Tier 3 is the teal/green band — the card paints with it.
    final container = tester.widget<Container>(
      find.byKey(const Key('yt-super-chat-card')),
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(
      decoration.color,
      youTubeSuperChatTierColor(3).withValues(alpha: 0.15),
    );
  });

  testWidgets('super sticker renders amount + alt text (no image in the API)',
      (tester) async {
    final message = YouTubeChatMessage(
      id: 'ss1',
      snippet: YouTubeChatMessageSnippet(
        type: YouTubeChatMessageType.superSticker,
        publishedAt: DateTime.utc(2026, 9, 3),
        authorChannelId: 'chan-9',
        superStickerDetails: YouTubeSuperStickerDetails(
          amountDisplayString: '€2.00',
          tier: 1,
          superStickerMetadata:
              YouTubeSuperStickerMetadata(altText: 'Dancing banana'),
        ),
      ),
      authorDetails: YouTubeChatAuthorDetails(
          channelId: 'chan-9', displayName: 'Fan Nine'),
    );

    await tester.pumpWidget(wrap(YouTubeChatMessageRow(
      message: message,
      settingsBox: settingsBox(),
    )));
    await tester.pump();

    expect(find.byKey(const Key('yt-super-sticker-card')), findsOneWidget);
    expect(find.text('€2.00'), findsOneWidget);
    expect(renderedRichText(tester), contains('Sent a sticker:'));
    expect(renderedRichText(tester), contains('Dancing banana'));
  });

  testWidgets('member milestone renders a notice row with the comment',
      (tester) async {
    final message = YouTubeChatMessage(
      id: 'mm1',
      snippet: YouTubeChatMessageSnippet(
        type: YouTubeChatMessageType.memberMilestone,
        publishedAt: DateTime.utc(2026, 9, 3),
        authorChannelId: 'chan-7',
        memberMilestoneChatDetails: YouTubeMemberMilestoneDetails(
          memberMonth: 12,
          memberLevelName: 'Gold',
          userComment: 'a whole year!',
        ),
      ),
      authorDetails:
          YouTubeChatAuthorDetails(channelId: 'chan-7', displayName: 'Loyal'),
    );

    await tester.pumpWidget(wrap(YouTubeChatMessageRow(
      message: message,
      settingsBox: settingsBox(),
    )));
    await tester.pump();

    expect(renderedRichText(tester), contains('Loyal'));
    expect(renderedRichText(tester),
        contains('has been a member for 12 months'));
    expect(renderedRichText(tester), contains('a whole year!'));
  });

  testWidgets('new member and gifting render notice rows', (tester) async {
    final newMember = YouTubeChatMessage(
      id: 'ns1',
      snippet: YouTubeChatMessageSnippet(
        type: YouTubeChatMessageType.newSponsor,
        publishedAt: DateTime.utc(2026, 9, 3),
        authorChannelId: 'chan-1',
        newSponsorDetails: YouTubeNewSponsorDetails(memberLevelName: 'Silver'),
      ),
      authorDetails:
          YouTubeChatAuthorDetails(channelId: 'chan-1', displayName: 'Newbie'),
    );
    final gifting = YouTubeChatMessage(
      id: 'mg1',
      snippet: YouTubeChatMessageSnippet(
        type: YouTubeChatMessageType.membershipGifting,
        publishedAt: DateTime.utc(2026, 9, 3),
        authorChannelId: 'chan-2',
        membershipGiftingDetails: YouTubeMembershipGiftingDetails(
          giftMembershipsCount: 5,
          giftMembershipsLevelName: 'Gold',
        ),
      ),
      authorDetails:
          YouTubeChatAuthorDetails(channelId: 'chan-2', displayName: 'Gifter'),
    );

    await tester.pumpWidget(wrap(Column(
      children: [
        YouTubeChatMessageRow(message: newMember, settingsBox: settingsBox()),
        YouTubeChatMessageRow(message: gifting, settingsBox: settingsBox()),
      ],
    )));
    await tester.pump();

    expect(renderedRichText(tester), contains('became a member (Silver)'));
    expect(renderedRichText(tester), contains('gifted 5 Gold memberships'));
  });

  testWidgets('poll renders question, options and tallies', (tester) async {
    final message = YouTubeChatMessage(
      id: 'p1',
      snippet: YouTubeChatMessageSnippet(
        type: YouTubeChatMessageType.poll,
        publishedAt: DateTime.utc(2026, 9, 3),
        authorChannelId: 'chan-1',
        pollDetails: YouTubePollDetails(
          metadata: YouTubePollMetadata(
            questionText: 'Next game?',
            options: [
              YouTubePollOption(optionText: 'Minecraft', tally: '42'),
              YouTubePollOption(optionText: 'Terraria', tally: '7'),
            ],
          ),
        ),
      ),
      authorDetails:
          YouTubeChatAuthorDetails(channelId: 'chan-1', displayName: 'Host'),
    );

    await tester.pumpWidget(wrap(YouTubeChatMessageRow(
      message: message,
      settingsBox: settingsBox(),
    )));
    await tester.pump();

    expect(find.byKey(const Key('yt-poll-card')), findsOneWidget);
    expect(find.text('Next game?'), findsOneWidget);
    expect(find.text('Minecraft'), findsOneWidget);
    expect(find.text('Terraria'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('long-press chrome only wraps rows with a handler',
      (tester) async {
    await tester.pumpWidget(wrap(Column(
      children: [
        YouTubeChatMessageRow(
          message: ytMessage('plain'),
          settingsBox: settingsBox(),
        ),
        YouTubeChatMessageRow(
          message: ytMessage('moderatable'),
          settingsBox: settingsBox(),
          onMessageLongPress: () {},
        ),
      ],
    )));
    await tester.pump();

    expect(find.byType(ChatRowLongPressListener), findsOneWidget);
  });

  testWidgets('author color is stable per channel id', (tester) async {
    Color? first;
    Color? second;
    await tester.pumpWidget(wrap(Builder(
      builder: (context) {
        first = youTubeAuthorColor(context, 'chan-stable');
        second = youTubeAuthorColor(context, 'chan-stable');
        return const SizedBox.shrink();
      },
    )));

    expect(first, isNotNull);
    expect(first, second);
  });
}
