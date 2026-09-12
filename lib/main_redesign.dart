import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import 'redesign/workspace/workspace_app.dart';
import 'redesign/workspace/workspace_chat_fixture.dart';
import 'redesign/workspace/workspace_model.dart';

SemanticsHandle? workspaceSemanticsHandle;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  workspaceSemanticsHandle = WidgetsBinding.instance.ensureSemantics();
  final model = WorkspaceModel();
  // Reproducible, synthetic review states. This entrypoint never loads accounts.
  final query = Uri.base.queryParameters;
  final chat = LabChatScenario.values
      .where((s) => s.name == query['chat'])
      .firstOrNull;
  final focus = WorkspaceFocus.values
      .where((s) => s.name == query['focus'])
      .firstOrNull;
  if (chat != null) model.setChatScenario(chat);
  if (focus != null) model.setFocus(focus);
  runApp(WorkspaceApp(model: model));
}
