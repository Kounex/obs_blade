import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:obs_blade/models/enums/chat_engine.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/redesign/chat/chat_lab_fixture.dart';
import 'package:obs_blade/redesign/chat/workspace_chat_timeline.dart';
import 'package:obs_blade/redesign/workspace/workspace_app.dart';
import 'package:obs_blade/redesign/workspace/workspace_model.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/twitch_chat_message_row.dart';

/// Native UI against synthetic stores and a temporary settings box. No saved
/// accounts, production data, global registrations or chat APIs are initialized.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized()
    ..framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  testWidgets('native rich chat preserves independent composition', (
    tester,
  ) async {
    final fixture = (await tester.runAsync(ChatLabFixture.create))!;
    final workspace = WorkspaceModel()..setFocus(WorkspaceFocus.chat);
    Future<void> capture(String name) async {
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await binding.endOfFrame;
      await tester.runAsync(() async {
        final directory = Directory(
          '${Directory.systemTemp.path}/workspace_chat_shots',
        )..createSync(recursive: true);
        final bytes = await binding.takeScreenshot(name);
        await File('${directory.path}/$name.png').writeAsBytes(bytes);
      });
    }

    try {
      await tester.pumpWidget(
        WorkspaceApp(
          model: workspace,
          chatPane: Builder(builder: fixture.buildPane),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await capture('native-rich-twitch');
      await tester.longPress(find.byType(TwitchChatMessageRow).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reply to River'));
      await tester.pumpAndSettle();
      final composer = find.byKey(const Key('workspace-chat-composer'));
      await tester.enterText(composer, 'Ready for the next scene');
      await tester.pumpAndSettle();
      final position = tester
          .state<ScrollableState>(
            find
                .descendant(
                  of: find.byType(WorkspaceChatTimeline),
                  matching: find.byType(Scrollable),
                )
                .first,
          )
          .position;

      final hold = find.descendant(
        of: find.byType(TwitchChatMessageRow).last,
        matching: find.byType(ChatRowLongPressListener),
      );
      expect(
        tester
            .widget<ColoredBox>(
              find
                  .descendant(of: hold, matching: find.byType(ColoredBox))
                  .first,
            )
            .color,
        Colors.transparent,
      );
      expect(position.extentAfter, lessThan(1));
      await capture('native-rich-reply');
      final picker = find.byKey(const Key('workspace-chat-channel'));
      await tester.tap(picker);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Community lounge').last);
      await tester.pumpAndSettle();
      expect(fixture.controller.text, isEmpty);
      await tester.tap(picker);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Studio chat').last);
      await tester.pumpAndSettle();
      expect(fixture.controller.text, 'Ready for the next scene');
      expect(fixture.controller.reply?.messageId, 'studio-23');
      await tester.tap(find.byKey(const Key('workspace-chat-send')));
      await tester.pumpAndSettle();
      expect(
        fixture.twitch.messages.last.message.text,
        'Ready for the next scene',
      );
      expect(fixture.controller.text, isEmpty);
      fixture.controller.setPresentation(ChatType.YouTube, ChatEngine.native);
      await tester.pumpAndSettle();
      await capture('native-rich-youtube');
      fixture.pro.boughtPro = false;
      await tester.pumpAndSettle();
      await capture('native-rich-pro');
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      workspace.dispose();
      await tester.runAsync(fixture.dispose);
    }
  });
}
