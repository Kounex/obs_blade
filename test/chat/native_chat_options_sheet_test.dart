import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/shared/design/app_status_colors.dart';
import 'package:obs_blade/shared/general/base/adaptive_switch.dart';
import 'package:obs_blade/stores/views/chat_history.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_options_sheet.dart';

import '../persistence/support/hive_test_harness.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

/// Opens the options the way the chat bar does - as a sheet run, so its
/// pages open as sheets of their own
Future<void> openOptions(WidgetTester tester, ChatType chatType) async {
  await tester.pumpWidget(
    wrap(
      Builder(
        builder: (context) => TextButton(
          onPressed: () =>
              showNativeChatOptionsSheet(context, chatType: chatType),
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

/// Root rows sit in sections now (All chats, the platform's own) - the
/// lower ones need scrolling into view first
Future<void> tapRow(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
}

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;

  Box settingsBox() => Hive.box(HiveKeys.Settings.name);

  Future<void> closeHiveInZone(WidgetTester tester) async {
    var closed = false;
    unawaited(harness.close().then((_) => closed = true));
    for (var i = 0; i < 150 && !closed; i++) {
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
    }
    await tester.pump();
    expect(closed, isTrue);
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('chat_options_sheet_test');
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

  testWidgets('root lists Appearance / Emotes / Badges / Event messages', (
    tester,
  ) async {
    await openOptions(tester, ChatType.Twitch);

    expect(find.text('Native chat options'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(
      find.text('Text size, emote size, spacing, and separators'),
      findsOneWidget,
    );
    expect(find.text('Highlights'), findsOneWidget);
    expect(find.text('Mute words'), findsOneWidget);
    expect(find.text('Search chat'), findsOneWidget);
    expect(find.text('Emotes'), findsOneWidget);
    expect(find.text('Badges'), findsOneWidget);
    expect(find.text('Event messages'), findsOneWidget);
    expect(
      find.text('Subs, raids, streaks, and similar system lines'),
      findsOneWidget,
    );
    expect(find.text('Third-party emotes (7TV/BTTV/FFZ)'), findsNothing);
    expect(find.text('Broadcaster'), findsNothing);
    expect(find.text('Subs & gifts'), findsNothing);
  });

  testWidgets('Appearance page shows preview, sliders, separators', (
    tester,
  ) async {
    await openOptions(tester, ChatType.Twitch);

    await tapRow(tester, 'Appearance');
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Adjust how chat lines look - size, spacing, dividers, timestamps, '
        'and name colors.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('appearance-preview')), findsOneWidget);
    expect(find.text('Text size'), findsOneWidget);
    expect(find.text('Emote size'), findsOneWidget);
    expect(find.text('Message spacing'), findsOneWidget);
    expect(find.text('Separators'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);
    expect(find.byType(Slider), findsNWidgets(3));

    final separators = find.descendant(
      of: find.widgetWithText(ListTile, 'Separators'),
      matching: find.byType(BaseAdaptiveSwitch),
    );
    expect(tester.widget<BaseAdaptiveSwitch>(separators).value, isFalse);

    await tester.tap(separators);
    await tester.pump();
    expect(
      settingsBox().get(SettingsKeys.TwitchChatMessageSeparators.name),
      isTrue,
    );

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(
      settingsBox().get(SettingsKeys.TwitchChatMessageSeparators.name),
      isFalse,
    );

    await closeHiveInZone(tester);
  });

  testWidgets('text size slider writes the settings box', (tester) async {
    await openOptions(tester, ChatType.Twitch);
    await tapRow(tester, 'Appearance');
    await tester.pumpAndSettle();

    await tester.drag(find.byType(Slider).first, const Offset(80, 0));
    await tester.pump();

    final stored =
        settingsBox().get(SettingsKeys.TwitchChatTextSize.name) as num?;
    expect(stored, isNotNull);
    expect(stored!.toDouble(), isNot(14.0));

    await closeHiveInZone(tester);
  });

  testWidgets('Emotes and Badges pages keep the existing toggles', (
    tester,
  ) async {
    await openOptions(tester, ChatType.Twitch);

    await tapRow(tester, 'Emotes');
    await tester.pumpAndSettle();
    expect(find.text('Third-party emotes (7TV/BTTV/FFZ)'), findsOneWidget);

    final emoteSwitch = find.descendant(
      of: find.widgetWithText(ListTile, 'Third-party emotes (7TV/BTTV/FFZ)'),
      matching: find.byType(BaseAdaptiveSwitch),
    );
    await tester.tap(emoteSwitch);
    await tester.pump();
    expect(
      settingsBox().get(SettingsKeys.TwitchChatThirdPartyEmotes.name),
      isFalse,
    );

    await tester.tap(find.byIcon(CupertinoIcons.chevron_back));
    await tester.pumpAndSettle();
    expect(find.text('Native chat options'), findsOneWidget);

    await tapRow(tester, 'Badges');
    await tester.pumpAndSettle();
    expect(find.text('Moderator'), findsOneWidget);

    final moderatorSwitch = find.descendant(
      of: find.widgetWithText(ListTile, 'Moderator'),
      matching: find.byType(BaseAdaptiveSwitch),
    );
    await tester.tap(moderatorSwitch);
    await tester.pump();
    expect(
      settingsBox().get(SettingsKeys.TwitchChatBadgeModerator.name),
      isFalse,
    );

    await closeHiveInZone(tester);
  });

  testWidgets('Event messages page toggles write the settings box', (
    tester,
  ) async {
    await openOptions(tester, ChatType.Twitch);

    await tapRow(tester, 'Event messages');
    await tester.pumpAndSettle();

    expect(
      find.textContaining('in-chat only - not device notifications'),
      findsOneWidget,
    );
    expect(find.text('Subs & gifts'), findsOneWidget);
    expect(find.text('First message'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);

    final subsSwitch = find.descendant(
      of: find.widgetWithText(ListTile, 'Subs & gifts'),
      matching: find.byType(BaseAdaptiveSwitch),
    );
    expect(tester.widget<BaseAdaptiveSwitch>(subsSwitch).value, isTrue);

    await tester.tap(subsSwitch);
    await tester.pump();
    expect(settingsBox().get(SettingsKeys.TwitchChatNoticeSubs.name), isFalse);

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(settingsBox().get(SettingsKeys.TwitchChatNoticeSubs.name), isTrue);

    await closeHiveInZone(tester);
  });

  testWidgets('Kick root lists Appearance + Emotes + Badges + Event '
      'messages', (tester) async {
    await openOptions(tester, ChatType.Kick);

    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Emotes'), findsOneWidget);
    expect(find.text('Third-party (7TV) emotes in chat'), findsOneWidget);
    expect(find.text('Badges'), findsOneWidget);
    expect(find.text('Role badge artwork next to names'), findsOneWidget);
    expect(find.text('Event messages'), findsOneWidget);
    expect(find.text('Subs, gifts, and host notices'), findsOneWidget);
  });

  testWidgets('Kick Badges page is a single toggle for KickChatBadges, not '
      'the per-category Twitch layout', (tester) async {
    await openOptions(tester, ChatType.Kick);

    await tapRow(tester, 'Badges');
    await tester.pumpAndSettle();
    expect(find.text('Role badge artwork'), findsOneWidget);

    await tester.tap(find.byType(BaseAdaptiveSwitch));
    await tester.pump();
    expect(
      settingsBox().get(SettingsKeys.KickChatBadges.name, defaultValue: true),
      isFalse,
    );

    await closeHiveInZone(tester);
  });

  testWidgets('Kick Emotes page toggles KickChatThirdPartyEmotes', (
    tester,
  ) async {
    await openOptions(tester, ChatType.Kick);

    await tapRow(tester, 'Emotes');
    await tester.pumpAndSettle();
    expect(find.text('Third-party emotes (7TV)'), findsOneWidget);
    expect(find.text('Third-party emotes (7TV/BTTV/FFZ)'), findsNothing);

    final emoteSwitch = find.descendant(
      of: find.widgetWithText(ListTile, 'Third-party emotes (7TV)'),
      matching: find.byType(BaseAdaptiveSwitch),
    );
    await tester.tap(emoteSwitch);
    await tester.pump();
    expect(
      settingsBox().get(SettingsKeys.KickChatThirdPartyEmotes.name),
      isFalse,
    );

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(
      settingsBox().get(SettingsKeys.KickChatThirdPartyEmotes.name),
      isTrue,
    );

    await closeHiveInZone(tester);
  });

  testWidgets('Kick Event messages page shows the smaller row set and '
      'writes Kick-prefixed keys', (tester) async {
    await openOptions(tester, ChatType.Kick);

    await tapRow(tester, 'Event messages');
    await tester.pumpAndSettle();

    expect(find.text('Subs & gifts'), findsOneWidget);
    expect(find.text('Hosts'), findsOneWidget);
    expect(find.text('First message'), findsNothing);
    expect(find.text('Raids'), findsNothing);

    final subsSwitch = find.descendant(
      of: find.widgetWithText(ListTile, 'Subs & gifts'),
      matching: find.byType(BaseAdaptiveSwitch),
    );
    await tester.tap(subsSwitch);
    await tester.pump();
    expect(settingsBox().get(SettingsKeys.KickChatNoticeSubs.name), isFalse);

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(settingsBox().get(SettingsKeys.KickChatNoticeSubs.name), isTrue);

    await closeHiveInZone(tester);
  });

  testWidgets('Highlights page toggles self-mention and shows for YouTube too '
      '(not gated per-engine)', (tester) async {
    await openOptions(tester, ChatType.YouTube);

    expect(find.text('Highlights'), findsOneWidget);
    await tapRow(tester, 'Highlights');
    await tester.pumpAndSettle();

    expect(find.text('Highlight my name'), findsOneWidget);
    expect(
      find.byKey(const Key('chat-highlight-keywords-field')),
      findsOneWidget,
    );

    final selfMentionSwitch = find.descendant(
      of: find.widgetWithText(ListTile, 'Highlight my name'),
      matching: find.byType(BaseAdaptiveSwitch),
    );
    expect(tester.widget<BaseAdaptiveSwitch>(selfMentionSwitch).value, isTrue);

    await tester.tap(selfMentionSwitch);
    await tester.pump();
    expect(
      settingsBox().get(SettingsKeys.ChatHighlightSelfMention.name),
      isFalse,
    );

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(
      settingsBox().get(SettingsKeys.ChatHighlightSelfMention.name),
      isTrue,
    );

    await closeHiveInZone(tester);
  });

  testWidgets('Highlights keyword field writes ChatHighlightKeywords', (
    tester,
  ) async {
    await openOptions(tester, ChatType.Twitch);

    await tapRow(tester, 'Highlights');
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('chat-highlight-keywords-field')),
      'giveaway, raffle',
    );
    await tester.pump();

    expect(
      settingsBox().get(SettingsKeys.ChatHighlightKeywords.name),
      'giveaway, raffle',
    );

    await closeHiveInZone(tester);
  });

  testWidgets('Mute words page writes ChatMuteWords and resets it', (
    tester,
  ) async {
    await openOptions(tester, ChatType.Kick);

    await tapRow(tester, 'Mute words');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chat-mute-words-field')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('chat-mute-words-field')),
      'giveaway',
    );
    await tester.pump();
    expect(settingsBox().get(SettingsKeys.ChatMuteWords.name), 'giveaway');

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(settingsBox().get(SettingsKeys.ChatMuteWords.name), '');

    await closeHiveInZone(tester);
  });

  testWidgets(
    'Search chat closes the options sheet and opens the search sheet',
    (tester) async {
      await openOptions(tester, ChatType.Twitch);

      await tapRow(tester, 'Search chat');
      await tester.pumpAndSettle();

      expect(find.text('Native chat options'), findsNothing);
      expect(find.text('Search chat'), findsOneWidget);
      expect(find.byKey(const Key('chat-search-field')), findsOneWidget);
    },
  );

  testWidgets('the button opens the sheet', (tester) async {
    await tester.pumpWidget(
      wrap(const NativeChatOptionsButton(chatType: ChatType.Twitch)),
    );

    await tester.tap(find.byType(NativeChatOptionsButton));
    await tester.pumpAndSettle();

    expect(find.text('Native chat options'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
  });

  testWidgets('Search chat from the button: its back chevron returns to '
      'the options sheet', (tester) async {
    await tester.pumpWidget(
      wrap(const NativeChatOptionsButton(chatType: ChatType.Twitch)),
    );
    await tester.tap(find.byType(NativeChatOptionsButton));
    await tester.pumpAndSettle();

    await tapRow(tester, 'Search chat');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-search-field')), findsOneWidget);

    await tester.tap(find.byKey(const Key('chat-sheet-back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('chat-search-field')), findsNothing);
    expect(find.text('Native chat options'), findsOneWidget);
  });

  testWidgets('a page replaces the options as a sheet of its own; its back '
      'chevron brings the options back', (tester) async {
    await openOptions(tester, ChatType.Twitch);

    await tapRow(tester, 'Emotes');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    /// The options slide down while the page slides up (no in-place swap)
    expect(find.text('Native chat options'), findsOneWidget);
    expect(find.text('Third-party emotes (7TV/BTTV/FFZ)'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Native chat options'), findsNothing);
    expect(find.byType(BottomSheet), findsOneWidget);

    await tester.tap(find.byKey(const Key('chat-sheet-back')));
    await tester.pumpAndSettle();
    expect(find.text('Native chat options'), findsOneWidget);
    expect(find.text('Third-party emotes (7TV/BTTV/FFZ)'), findsNothing);
    expect(find.byType(BottomSheet), findsOneWidget);

    /// A barrier tap ends the run - nothing reopens
    await tester.tapAt(const Offset(10.0, 10.0));
    await tester.pumpAndSettle();
    expect(find.text('Native chat options'), findsNothing);
    expect(find.byType(BottomSheet), findsNothing);
  });

  /// The "Session history" row sits in "All chats" (Twitch's own "Chat
  /// history" join-backfill row is a different page)
  Future<void> openChatHistoryPage(WidgetTester tester) async {
    await openOptions(tester, ChatType.Twitch);
    await tapRow(tester, 'Session history');
    await tester.pumpAndSettle();
  }

  testWidgets('Session history entry opens the page; back chevron returns', (
    tester,
  ) async {
    await openOptions(tester, ChatType.Twitch);
    expect(
      find.text('Messages kept for viewer cards, and their memory use'),
      findsOneWidget,
    );

    await tapRow(tester, 'Session history');
    await tester.pumpAndSettle();

    expect(find.textContaining('500-message live chat'), findsOneWidget);
    expect(find.textContaining('signing out or closing the app clears it'),
        findsOneWidget);
    expect(find.byKey(const Key('chat-history-cap-slider')), findsOneWidget);
    expect(find.text('Memory usage'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);

    await tester.tap(find.byKey(const Key('chat-sheet-back')));
    await tester.pumpAndSettle();
    expect(find.text('Native chat options'), findsOneWidget);
  });

  testWidgets('Session history slider: 10k steps inside 10k … 200k, default '
      '50k, writes the box', (tester) async {
    await openChatHistoryPage(tester);

    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.min, 10000.0);
    expect(slider.max, 200000.0);
    expect(slider.divisions, 19);
    expect(slider.value, 50000.0);
    expect(find.text('50,000 messages'), findsOneWidget);

    await tester.drag(find.byType(Slider), const Offset(-600.0, 0.0));
    await tester.pumpAndSettle();
    expect(
      settingsBox().get(SettingsKeys.ChatHistoryCap.name),
      kChatHistoryCapMin,
    );
    expect(find.text('10,000 messages'), findsOneWidget);

    await tester.drag(find.byType(Slider), const Offset(600.0, 0.0));
    await tester.pumpAndSettle();
    expect(
      settingsBox().get(SettingsKeys.ChatHistoryCap.name),
      kChatHistoryCapMax,
    );
    expect(find.text('200,000 messages'), findsOneWidget);

    await closeHiveInZone(tester);
  });

  testWidgets('Session history memory estimate follows the slider value and '
      'turns green → amber → red', (tester) async {
    Future<void> setCap(int cap) async {
      await tester.runAsync(() async {
        await settingsBox().put(SettingsKeys.ChatHistoryCap.name, cap);
        await settingsBox().flush();
      });
      await tester.pumpAndSettle();
    }

    Color memoryColor() => tester
        .widget<Text>(find.byKey(const Key('chat-history-memory')))
        .style!
        .color!;

    await openChatHistoryPage(tester);

    await setCap(10000);
    expect(find.text('~13 MB'), findsOneWidget);
    expect(memoryColor(), AppStatusColors.standard.reachable);

    /// The default sits in the green band (≤ 75 MB)
    await setCap(50000);
    expect(find.text('~64 MB'), findsOneWidget);
    expect(memoryColor(), AppStatusColors.standard.reachable);

    await setCap(100000);
    expect(find.text('~128 MB'), findsOneWidget);
    expect(memoryColor(), AppStatusColors.standard.warning);

    await setCap(200000);
    expect(find.text('~256 MB'), findsOneWidget);
    expect(memoryColor(), AppStatusColors.standard.destructive);

    await closeHiveInZone(tester);
  });

  testWidgets('Session history page applies to the live ChatHistoryStore', (
    tester,
  ) async {
    final store = ChatHistoryStore();
    GetIt.instance.registerSingleton<ChatHistoryStore>(store);
    addTearDown(GetIt.instance.reset);
    expect(store.cap, kChatHistoryCapDefault);

    await openChatHistoryPage(tester);

    await tester.drag(find.byType(Slider), const Offset(600.0, 0.0));
    await tester.pumpAndSettle();
    expect(store.cap, kChatHistoryCapMax);

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(settingsBox().get(SettingsKeys.ChatHistoryCap.name),
        kChatHistoryCapDefault);
    expect(store.cap, kChatHistoryCapDefault);

    await closeHiveInZone(tester);
  });
}
