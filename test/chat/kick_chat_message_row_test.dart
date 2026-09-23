import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/types/classes/kick/kick_chat_message.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/kick_chat_message_row.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_chrome.dart';

import '../persistence/support/hive_test_harness.dart';

KickChatMessage kickMessage(
  String id, {
  String author = 'Chatter',
  String? content,
  List<KickChatBadgeV2> badgesV2 = const [],
  List<KickChatLegacyBadge> legacyBadges = const [],
}) => KickChatMessage(
  id: id,
  content: content ?? 'text $id',
  sender: KickChatSender(
    id: 1,
    username: author,
    identity: KickChatIdentity(badgesV2: badgesV2, badges: legacyBadges),
  ),
);

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;

  Box settingsBox() => Hive.box(HiveKeys.Settings.name);

  Widget wrap(Widget child) => MaterialApp(
    home: Scaffold(body: Column(children: [child])),
  );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('kick_row_test');
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

  testWidgets('a legacy badge with text renders as a status chip', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        KickChatMessageRow(
          message: kickMessage(
            'm1',
            legacyBadges: const [
              KickChatLegacyBadge(type: 'moderator', text: 'MOD'),
            ],
          ),
          settingsBox: settingsBox(),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const Key('kick-badge-legacy-moderator')),
      findsOneWidget,
    );
    expect(find.text('MOD'), findsOneWidget);
  });

  testWidgets(
    'KickChatBadges=false hides badges entirely, even with badge data',
    (tester) async {
      /// runAsync: awaited Hive writes never complete in the fake-async
      /// zone.
      await tester.runAsync(
        () => settingsBox().put(SettingsKeys.KickChatBadges.name, false),
      );

      await tester.pumpWidget(
        wrap(
          KickChatMessageRow(
            message: kickMessage(
              'm1',
              legacyBadges: const [
                KickChatLegacyBadge(type: 'moderator', text: 'MOD'),
              ],
            ),
            settingsBox: settingsBox(),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const Key('kick-badge-legacy-moderator')),
        findsNothing,
      );
      expect(find.text('MOD'), findsNothing);
    },
  );

  testWidgets('KickChatBadges defaults to true when unset', (tester) async {
    await tester.pumpWidget(
      wrap(
        KickChatMessageRow(
          message: kickMessage(
            'm1',
            legacyBadges: const [
              KickChatLegacyBadge(type: 'subscriber', text: 'SUB', count: 3),
            ],
          ),
          settingsBox: settingsBox(),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const Key('kick-badge-legacy-subscriber')),
      findsOneWidget,
    );
    expect(find.text('SUB (3)'), findsOneWidget);
  });

  group('self-mention / keyword highlight', () {
    /// No theme extension is registered in [wrap]'s bare [MaterialApp],
    /// so [chatMentionHighlightColor] falls back to this same constant —
    /// matching the color the row would actually paint.
    final expectedColor = AppStatusColors.standard.warning.withValues(
      alpha: 0.12,
    );

    testWidgets('washes the row when content contains a self name', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          KickChatMessageRow(
            message: kickMessage('m1', content: 'hey kounex, nice stream'),
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
        wrap(
          KickChatMessageRow(
            message: kickMessage('m1', content: 'just a regular message'),
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
        wrap(
          KickChatMessageRow(
            message: kickMessage('m1', content: 'check out my GIVEAWAY'),
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
          wrap(
            KickChatMessageRow(
              message: kickMessage('m1', content: 'hey kounex!'),
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
  });

  group('screen-reader semantics', () {
    testWidgets('a plain message announces as one merged label', (
      tester,
    ) async {
      /// Disposed explicitly at the end of the test body — `test`
      /// package tearDowns run after Flutter's own end-of-test handle
      /// check, so an `addTearDown`-registered dispose is too late.
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        wrap(
          KickChatMessageRow(
            message: kickMessage('m1', author: 'Viewer1', content: 'hello'),
            settingsBox: settingsBox(),
          ),
        ),
      );
      await tester.pump();

      final semantics = tester.getSemantics(find.byType(KickChatMessageRow));
      expect(semantics.label, 'Viewer1: hello');
      handle.dispose();
    });

    testWidgets('a system row announces its notice text', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        wrap(
          KickChatMessageRow(
            message: const KickChatMessage(
              id: 'system-sub-1',
              content: 'Viewer1 subscribed',
              type: KickChatMessageType.system,
            ),
            settingsBox: settingsBox(),
          ),
        ),
      );
      await tester.pump();

      final semantics = tester.getSemantics(find.byType(KickChatMessageRow));
      expect(semantics.label, 'Viewer1 subscribed');
      handle.dispose();
    });

    testWidgets('a tombstoned message appends the deleted marker', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        wrap(
          KickChatMessageRow(
            message: kickMessage(
              'm1',
              author: 'Viewer1',
              content: 'hello',
            ).copyWith(isTombstoned: true),
            settingsBox: settingsBox(),
          ),
        ),
      );
      await tester.pump();

      final semantics = tester.getSemantics(find.byType(KickChatMessageRow));
      expect(semantics.label, 'Viewer1: hello —Deleted');
      handle.dispose();
    });
  });
}
