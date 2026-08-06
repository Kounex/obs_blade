import 'dart:async';
import 'dart:io';

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

  testWidgets('shows the emote + badge toggles, on by default',
      (tester) async {
    await tester.pumpWidget(
      wrap(const NativeChatOptionsSheet(chatType: ChatType.Twitch)),
    );

    expect(find.text('Native chat options'), findsOneWidget);
    for (final label in [
      'Third-party emotes (7TV/BTTV)',
      'Broadcaster',
      'Moderator',
      'VIP',
      'Subscriber',
      'Founder',
      'Bits',
      'Other badges',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    final switches = tester
        .widgetList<BaseAdaptiveSwitch>(find.byType(BaseAdaptiveSwitch))
        .toList();
    expect(switches, hasLength(8));
    expect(switches.every((s) => s.value), isTrue);
  });

  testWidgets('toggling a switch writes the settings box', (tester) async {
    await tester.pumpWidget(
      wrap(const NativeChatOptionsSheet(chatType: ChatType.Twitch)),
    );

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
    expect(
      tester.widget<BaseAdaptiveSwitch>(moderatorSwitch).value,
      isFalse,
    );

    /// The tap ran its Hive write in the test's FakeAsync zone, and the
    /// Completers Hive created for its write queue only dispatch their
    /// listeners through the zone they were created in - a real-zone
    /// harness.close() in tearDown would await one of them forever. So
    /// close Hive from inside the zone instead: each pump drains the
    /// zone's queue, each runAsync is a real-time window for the next
    /// file op of the close. tearDown's harness.close() is then a no-op.
    /// Same dance as chat_engine_switch_test.dart's
    /// 'tapping a segment persists the engine'.
    var closed = false;
    unawaited(harness.close().then((_) => closed = true));
    for (var i = 0; i < 10 && !closed; i++) {
      await tester.pump();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
    }
    await tester.pump();
    expect(closed, isTrue);
  });

  testWidgets('toggling the emote switch writes the settings box',
      (tester) async {
    await tester.pumpWidget(
      wrap(const NativeChatOptionsSheet(chatType: ChatType.Twitch)),
    );

    final emoteSwitch = find.descendant(
      of: find.widgetWithText(ListTile, 'Third-party emotes (7TV/BTTV)'),
      matching: find.byType(BaseAdaptiveSwitch),
    );
    expect(
      settingsBox().get(SettingsKeys.TwitchChatThirdPartyEmotes.name),
      isNull,
    );

    await tester.tap(emoteSwitch);
    await tester.pump();
    expect(
      settingsBox().get(SettingsKeys.TwitchChatThirdPartyEmotes.name),
      isFalse,
    );

    await tester.tap(emoteSwitch);
    await tester.pump();
    expect(
      settingsBox().get(SettingsKeys.TwitchChatThirdPartyEmotes.name),
      isTrue,
    );

    /// Same FakeAsync-zone dance as 'toggling a switch writes the
    /// settings box': the taps ran their Hive writes in the test's
    /// FakeAsync zone — close Hive from inside the zone so tearDown's
    /// harness.close() doesn't await a zone-parked Completer forever.
    var closed = false;
    unawaited(harness.close().then((_) => closed = true));
    for (var i = 0; i < 10 && !closed; i++) {
      await tester.pump();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
    }
    await tester.pump();
    expect(closed, isTrue);
  });

  testWidgets('the button opens the sheet', (tester) async {
    await tester.pumpWidget(
      wrap(const NativeChatOptionsButton(chatType: ChatType.Twitch)),
    );

    await tester.tap(find.byType(NativeChatOptionsButton));
    await tester.pumpAndSettle();

    expect(find.text('Native chat options'), findsOneWidget);
  });
}
