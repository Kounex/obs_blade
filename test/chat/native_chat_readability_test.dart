import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/twitch_chat_message_row.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_appearance.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_chrome.dart';

import '../persistence/support/hive_test_harness.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  group('readableNameColor', () {
    const dark = Color(0xFF16161A);
    const light = Color(0xFFFFFFFF);

    test('readable colors pass through untouched', () {
      const green = Color(0xFF00FF7F);
      expect(readableNameColor(green, dark), green);
    });

    test('dark blue on a dark background is lifted, hue kept', () {
      const blue = Color(0xFF0000FF);
      final fixed = readableNameColor(blue, dark);
      expect(
        _contrast(fixed, dark),
        greaterThanOrEqualTo(kChatNameMinContrast),
      );
      expect(
        HSLColor.fromColor(fixed).hue,
        closeTo(HSLColor.fromColor(blue).hue, 1.0),
      );
    });

    test('yellow on white is darkened', () {
      const yellow = Color(0xFFFFFF00);
      final fixed = readableNameColor(yellow, light);
      expect(
        _contrast(fixed, light),
        greaterThanOrEqualTo(kChatNameMinContrast),
      );
    });
  });

  group('ChatRowParity', () {
    test('alternates and stays stable when the front is evicted', () {
      final parity = ChatRowParity();
      expect(parity.assign(['a', 'b', 'c', 'd']), [false, true, false, true]);

      /// 'a' evicted, 'e' appended: survivors keep their tint.
      expect(parity.assign(['b', 'c', 'd', 'e']), [true, false, true, false]);
    });

    test('a filtered-out row does not break the rhythm of new rows', () {
      final parity = ChatRowParity();
      parity.assign(['a', 'b']);
      expect(parity.assign(['a', 'b', 'c']), [false, true, false]);
    });
  });

  test('formatChatLineTime has no AM/PM suffix', () {
    final text = formatChatLineTime(DateTime(2026, 9, 24, 21, 5));
    expect(text, anyOf('21:05', '9:05'));
  });

  group('Twitch row', () {
    late Directory tempDir;
    late HiveTestHarness harness;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('readability_test');
      harness = HiveTestHarness(tempDir);
      await harness.init();
      await Hive.openBox(HiveKeys.Settings.name);
    });

    tearDown(() async {
      await harness.close();
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    ChatMessageEvent event({bool historical = false}) => ChatMessageEvent(
      broadcasterUserId: 'b1',
      chatterUserId: 'u1',
      chatterUserLogin: 'viewer',
      chatterUserName: 'Viewer',
      messageId: 'm1',
      message: const ChatMessageText(text: 'hello'),
      receivedAt: DateTime(2026, 9, 24, 21, 5),
      isHistorical: historical,
    );

    Future<void> pumpRow(WidgetTester tester, ChatMessageEvent event) =>
        tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TwitchChatMessageRow(
                event: event,
                settingsBox: Hive.box(HiveKeys.Settings.name),
              ),
            ),
          ),
        );

    String plain(WidgetTester tester) => tester
        .widgetList<RichText>(find.byType(RichText))
        .map((r) => r.text.toPlainText())
        .join('|');

    testWidgets('timestamps follow the setting', (tester) async {
      await pumpRow(tester, event());
      expect(plain(tester), isNot(contains(':05 ')));

      /// Real I/O must leave testWidgets' fake-async zone (a bare
      /// `put` never completes there).
      await tester.runAsync(
        () => Hive.box(
          HiveKeys.Settings.name,
        ).put(SettingsKeys.ChatShowTimestamps.name, true),
      );
      await pumpRow(tester, event());
      expect(plain(tester), contains(':05 '));
    });

    testWidgets('history rows render dimmed', (tester) async {
      await pumpRow(tester, event(historical: true));
      final opacity = tester.widget<Opacity>(find.byType(Opacity).first);
      expect(opacity.opacity, kChatHistoryOpacity);
    });
  });

  group('chatHistoryDividerIndex', () {
    test('after the last history row, once a live row follows', () {
      expect(chatHistoryDividerIndex([true, true, false, false]), 2);
    });

    test('no divider with only history, only live, or nothing', () {
      expect(chatHistoryDividerIndex([true, true]), -1);
      expect(chatHistoryDividerIndex([false, false]), -1);
      expect(chatHistoryDividerIndex([]), -1);
    });
  });

  testWidgets('ChatHistoryDivider draws platform-colored lines', (
    tester,
  ) async {
    const brand = Color(0xFF53FC18);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ChatHistoryDivider(color: brand)),
      ),
    );
    expect(find.text('New messages'), findsOneWidget);
    final lines = tester
        .widgetList<Container>(find.byType(Container))
        .where((c) => c.color != null)
        .toList();
    expect(lines, hasLength(2));
    expect(
      lines.first.color!.toARGB32() & 0xFFFFFF,
      brand.toARGB32() & 0xFFFFFF,
    );
  });
}
