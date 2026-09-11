import 'package:flutter/material.dart';

import 'redesign/obs/live_workspace_model.dart';
import 'redesign/workspace/workspace_app.dart';

/// Native-only development entrypoint. No Hive, account or purchase bootstrap.
/// Enter the password in the connection pane, never in a build define.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _LiveObsLab());
}

class _LiveObsLab extends StatefulWidget {
  const _LiveObsLab();

  @override
  State<_LiveObsLab> createState() => _LiveObsLabState();
}

class _LiveObsLabState extends State<_LiveObsLab> {
  final _model = LiveWorkspaceModel(
    host: const String.fromEnvironment('OBS_HOST', defaultValue: 'localhost'),
    port: const int.fromEnvironment('OBS_PORT', defaultValue: 4455),
  );

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => WorkspaceApp(model: _model);
}
