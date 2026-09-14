import 'package:flutter/material.dart';

import 'redesign/chat/chat_lab_fixture.dart';
import 'redesign/workspace/workspace_app.dart';
import 'redesign/workspace/workspace_model.dart';

/// Isolated native chat UI lab. No production bootstrap or account services.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final fixture = await ChatLabFixture.create();
  final workspace = WorkspaceModel()..setFocus(WorkspaceFocus.chat);
  runApp(
    WorkspaceApp(
      model: workspace,
      chatPane: Builder(builder: fixture.buildPane),
    ),
  );
}
