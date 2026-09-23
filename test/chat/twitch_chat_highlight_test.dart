import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_chrome.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/twitch_chat_message_row.dart';

import '../persistence/support/hive_test_harness.dart';

/// Self-mention / keyword row highlighting for [TwitchChatMessageRow] —
/// the shared matching logic itself is covered exhaustively (case
/// folding, substring vs. word-boundary, dedup) in
/// `chat_highlight_helper_test.dart`; this file only proves the row
/// actually wires it up and paints the wash.
ChatMessageEvent _event(String text) => ChatMessageEvent(
  broadcasterUserId: 'b1',
  chatterUserId: '1',
  chatterUserLogin: 'viewer',
  chatterUserName: 'Viewer',
  messageId: '1',
  message: ChatMessageText(text: text, fragments: const []),
);

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;

  Box settingsBox() => Hive.box(HiveKeys.Settings.name);

  /// No theme extension is registered in [_wrap]'s bare [MaterialApp], so
  /// [chatMentionHighlightColor] falls back to this same constant —
  /// matching the color the row would actually paint.
  final expectedColor = AppStatusColors.standard.warning.withValues(
    alpha: 0.12,
  );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('twitch_highlight_test');
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

  testWidgets('washes the row when content contains a self name', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        TwitchChatMessageRow(
          event: _event('hey kounex, nice stream'),
          settingsBox: settingsBox(),
          selfDisplayNames: const ['kounex'],
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byWidgetPredicate(
        (w) => w is ColoredBox && w.color == expectedColor,
      ),
      findsOneWidget,
    );
  });

  testWidgets('does not wash a row with no self-name/keyword match', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        TwitchChatMessageRow(
          event: _event('just a regular message'),
          settingsBox: settingsBox(),
          selfDisplayNames: const ['kounex'],
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byWidgetPredicate(
        (w) => w is ColoredBox && w.color == expectedColor,
      ),
      findsNothing,
    );
  });

  testWidgets('washes the row on a configured keyword match', (tester) async {
    await tester.runAsync(
      () => settingsBox().put(
        SettingsKeys.ChatHighlightKeywords.name,
        'giveaway',
      ),
    );

    await tester.pumpWidget(
      _wrap(
        TwitchChatMessageRow(
          event: _event('check out my GIVEAWAY'),
          settingsBox: settingsBox(),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byWidgetPredicate(
        (w) => w is ColoredBox && w.color == expectedColor,
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'self-mention match is suppressed when ChatHighlightSelfMention is off',
    (tester) async {
      await tester.runAsync(
        () => settingsBox().put(
          SettingsKeys.ChatHighlightSelfMention.name,
          false,
        ),
      );

      await tester.pumpWidget(
        _wrap(
          TwitchChatMessageRow(
            event: _event('hey kounex!'),
            settingsBox: settingsBox(),
            selfDisplayNames: const ['kounex'],
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byWidgetPredicate(
          (w) => w is ColoredBox && w.color == expectedColor,
        ),
        findsNothing,
      );
    },
  );

  group('screen-reader semantics', () {
    testWidgets('a plain message announces as one merged label', (
      tester,
    ) async {
      /// Disposed explicitly at the end of the test body — `test`
      /// package tearDowns run after Flutter's own end-of-test handle
      /// check, so an `addTearDown`-registered dispose is too late.
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _wrap(
          TwitchChatMessageRow(
            event: _event('hello'),
            settingsBox: settingsBox(),
          ),
        ),
      );
      await tester.pump();

      final semantics = tester.getSemantics(find.byType(TwitchChatMessageRow));
      expect(semantics.label, 'Viewer: hello');
      handle.dispose();
    });

    testWidgets('a deleted message appends the deleted marker', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _wrap(
          TwitchChatMessageRow(
            event: _event('hello'),
            settingsBox: settingsBox(),
            isDeleted: true,
          ),
        ),
      );
      await tester.pump();

      final semantics = tester.getSemantics(find.byType(TwitchChatMessageRow));
      expect(semantics.label, 'Viewer: hello -Deleted');
      handle.dispose();
    });
  });
}
