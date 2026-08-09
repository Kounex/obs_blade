import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/shared/general/base/adaptive_switch.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_options_sheet.dart';

import '../persistence/support/hive_test_harness.dart';

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;

  Box settingsBox() => Hive.box(HiveKeys.Settings.name);

  Future<void> closeHiveInZone(WidgetTester tester) async {
    var closed = false;
    unawaited(harness.close().then((_) => closed = true));
    for (var i = 0; i < 30 && !closed; i++) {
      await tester.pump();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
    }
    await tester.pump();
    expect(closed, isTrue);
  }

  setUp(() async {
    tempDir =
        await Directory.systemTemp.createTemp('chat_options_sheet_test');
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

  testWidgets('root lists Appearance / Emotes / Badges / Event messages',
      (tester) async {
    await tester.pumpWidget(
      wrap(const NativeChatOptionsSheet(chatType: ChatType.Twitch)),
    );

    expect(find.text('Native chat options'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Text size, emote size, spacing, and separators'),
        findsOneWidget);
    expect(find.text('Emotes'), findsOneWidget);
    expect(find.text('Badges'), findsOneWidget);
    expect(find.text('Event messages'), findsOneWidget);
    expect(find.text('Subs, raids, streaks, and similar system lines'),
        findsOneWidget);
    expect(find.text('Third-party emotes (7TV/BTTV)'), findsNothing);
    expect(find.text('Broadcaster'), findsNothing);
    expect(find.text('Subs & gifts'), findsNothing);
  });

  testWidgets('Appearance page shows preview, sliders, separators',
      (tester) async {
    await tester.pumpWidget(
      wrap(const NativeChatOptionsSheet(chatType: ChatType.Twitch)),
    );

    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();

    expect(
      find.text(
          'Adjust how chat lines look — size, spacing, and dividers.'),
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
    await tester.pumpWidget(
      wrap(const NativeChatOptionsSheet(chatType: ChatType.Twitch)),
    );
    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(Slider).first, const Offset(80, 0));
    await tester.pump();

    final stored =
        settingsBox().get(SettingsKeys.TwitchChatTextSize.name) as num?;
    expect(stored, isNotNull);
    expect(stored!.toDouble(), isNot(14.0));

    await closeHiveInZone(tester);
  });

  testWidgets('Emotes and Badges pages keep the existing toggles',
      (tester) async {
    await tester.pumpWidget(
      wrap(const NativeChatOptionsSheet(chatType: ChatType.Twitch)),
    );

    await tester.tap(find.text('Emotes'));
    await tester.pumpAndSettle();
    expect(find.text('Third-party emotes (7TV/BTTV)'), findsOneWidget);

    final emoteSwitch = find.descendant(
      of: find.widgetWithText(ListTile, 'Third-party emotes (7TV/BTTV)'),
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

    await tester.tap(find.text('Badges'));
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

  testWidgets('Event messages page toggles write the settings box',
      (tester) async {
    await tester.pumpWidget(
      wrap(const NativeChatOptionsSheet(chatType: ChatType.Twitch)),
    );

    await tester.tap(find.text('Event messages'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('in-chat only — not device notifications'),
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
    expect(
      settingsBox().get(SettingsKeys.TwitchChatNoticeSubs.name),
      isFalse,
    );

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(
      settingsBox().get(SettingsKeys.TwitchChatNoticeSubs.name),
      isTrue,
    );

    await closeHiveInZone(tester);
  });

  testWidgets('the button opens the sheet', (tester) async {
    await tester.pumpWidget(
      wrap(const NativeChatOptionsButton(chatType: ChatType.Twitch)),
    );

    await tester.tap(find.byType(NativeChatOptionsButton));
    await tester.pumpAndSettle();

    expect(find.text('Native chat options'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
  });
}
