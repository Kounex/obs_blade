import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/types/classes/kick/kick_chat_message.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/kick_chat_message_row.dart';

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
}
