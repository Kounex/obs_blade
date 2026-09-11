import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:obs_blade/redesign/obs/live_workspace_model.dart';
import 'package:obs_blade/redesign/workspace/workspace_app.dart';
import 'package:obs_blade/redesign/workspace/workspace_model.dart';

import '../test/redesign/support/obs_peer.dart';

/// Native UI + real WebSocket transport against a synthetic local peer.
/// Does not initialize production main, Hive, accounts, or an installed OBS.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('native scene workspace preserves independent chat context', (
    tester,
  ) async {
    final peer = await tester.runAsync(ObsPeer.start);
    final model = LiveWorkspaceModel(
      host: 'localhost',
      port: peer!.server.port,
    );
    try {
      await tester.pumpWidget(WorkspaceApp(model: model));
      await tester.runAsync(() => model.connect());
      await tester.pumpAndSettle();
      expect(model.program, 'Camera');
      expect(find.text('Live OBS lab · chat simulated'), findsOneWidget);
      expect(find.text('Camera source'), findsNothing);
      expect(find.text('Global microphone'), findsNothing);
      expect(find.byTooltip('Quick microphone audio'), findsNothing);
      await tester.tap(find.text('Desktop').first);
      await tester.pumpAndSettle();
      expect(model.inspectedScene, 'Desktop');
      expect(model.program, 'Camera');
      final back = find.text('Back to scenes');
      if (back.evaluate().isNotEmpty) {
        await tester.tap(back);
        await tester.pumpAndSettle();
      }
      await tester.tap(find.widgetWithText(TextButton, 'Preview').last);
      await tester.runAsync(() async {
        for (var i = 0; i < 100 && model.preview != 'Desktop'; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
      });
      await tester.pumpAndSettle();
      expect(model.preview, 'Desktop');
      // Execute through the actual persistent output control.
      await tester.tap(find.widgetWithText(FilledButton, 'Take'));
      await tester.runAsync(() async {
        for (var i = 0; i < 100 && model.program != 'Desktop'; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
      });
      await tester.pumpAndSettle();
      expect(model.program, 'Desktop');
      await tester.runAsync(() async {
        final bytes = await binding.takeScreenshot('native-scene-control');
        final dir = Directory(
          '${Directory.systemTemp.path}/workspace_scene_shots',
        )..createSync(recursive: true);
        await File('${dir.path}/native-scene-control.png').writeAsBytes(bytes);
      });
      model.setFocus(WorkspaceFocus.chat);
      model.setDraft('Preserve this draft');
      model.setReply('Synthetic viewer');
      model.disconnect();
      await tester.pumpAndSettle();
      expect(model.draft, 'Preserve this draft');
      expect(model.replyTo, 'Synthetic viewer');
      expect(find.text('Preserve this draft'), findsOneWidget);
      await tester.runAsync(() async {
        final bytes = await binding.takeScreenshot(
          'native-chat-after-disconnect',
        );
        await File(
          '${Directory.systemTemp.path}/workspace_scene_shots/native-chat-after-disconnect.png',
        ).writeAsBytes(bytes);
      });
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      model.dispose();
      await tester.runAsync(peer.close);
    }
  });
}
