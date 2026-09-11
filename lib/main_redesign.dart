import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import 'redesign/workspace/workspace_app.dart';

SemanticsHandle? workspaceSemanticsHandle;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  workspaceSemanticsHandle = WidgetsBinding.instance.ensureSemantics();
  runApp(const WorkspaceApp());
}
