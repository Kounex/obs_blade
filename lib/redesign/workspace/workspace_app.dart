import 'package:flutter/material.dart';

import 'chat_panel.dart';
import 'obs_panel.dart';
import 'workspace_model.dart';

const _scaffold = Color(0xFF141B24);
const _panel = Color(0xFF1E2936);
const _border = Color(0xFF334355);
const _text = Color(0xFFEDF2F7);
const _secondary = Color(0xFFACB8C8);
const _blue = Color(0xFFB3CEFF);
const _coral = Color(0xFFF39E8F);

class WorkspaceApp extends StatefulWidget {
  const WorkspaceApp({super.key, this.model});

  final WorkspaceModel? model;

  @override
  State<WorkspaceApp> createState() => _WorkspaceAppState();
}

class _WorkspaceAppState extends State<WorkspaceApp> {
  late final WorkspaceModel _model = widget.model ?? WorkspaceModel();
  late final bool _ownsModel = widget.model == null;

  @override
  void dispose() {
    if (_ownsModel) _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Workspace',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _scaffold,
        colorScheme: const ColorScheme.dark(
          surface: _panel,
          primary: _blue,
          secondary: _coral,
          outline: _border,
          onSurface: _text,
        ),
        dividerColor: _border,
        textTheme: ThemeData.dark().textTheme.apply(
          bodyColor: _text,
          displayColor: _text,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(48, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(48, 48),
            foregroundColor: _text,
            side: const BorderSide(color: _border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _scaffold,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _border),
          ),
        ),
        sliderTheme: const SliderThemeData(
          activeTrackColor: _blue,
          inactiveTrackColor: _border,
          thumbColor: _blue,
        ),
      ),
      home: _WorkspaceShell(model: _model),
    );
  }
}

enum _LabAction {
  live,
  chatOnly,
  firstUse,
  authFailed,
  reconnecting,
  toggleStudio,
  rejectCommand,
  failMessage,
  externalChange,
}

class _WorkspaceShell extends StatefulWidget {
  const _WorkspaceShell({required this.model});

  final WorkspaceModel model;

  @override
  State<_WorkspaceShell> createState() => _WorkspaceShellState();
}

class _WorkspaceShellState extends State<_WorkspaceShell> {
  final _obsPaneKey = GlobalKey();
  final _chatPaneKey = GlobalKey();

  WorkspaceModel get model => widget.model;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: model,
      builder: (context, _) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                _LabStrip(model: model),
                _SessionHeader(model: model),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final tablet = constraints.maxWidth >= 900;
                      return Column(
                        children: [
                          _FocusControl(model: model, tablet: tablet),
                          Expanded(
                            child: tablet
                                ? _TabletWorkspace(
                                    model: model,
                                    obsPaneKey: _obsPaneKey,
                                    chatPaneKey: _chatPaneKey,
                                  )
                                : _PhoneWorkspace(
                                    model: model,
                                    obsPaneKey: _obsPaneKey,
                                    chatPaneKey: _chatPaneKey,
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LabStrip extends StatelessWidget {
  const _LabStrip({required this.model});

  final WorkspaceModel model;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.only(left: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF101720),
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          const Icon(Icons.science_outlined, size: 16, color: _secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              model.isLiveObs
                  ? 'Live OBS lab · chat simulated'
                  : 'Workspace lab · simulated',
              style: TextStyle(fontSize: 12, color: _secondary),
            ),
          ),
          if (model.isLiveObs)
            IconButton(
              tooltip: 'Refresh OBS state',
              onPressed:
                  model.connection == ObsConnection.connected &&
                      !model.commandBusy
                  ? model.refreshObs
                  : null,
              icon: const Icon(Icons.refresh),
            )
          else
            PopupMenuButton<_LabAction>(
              tooltip: 'Open simulated scenarios and failure controls',
              onSelected: (action) => _runLabAction(context, action),
              itemBuilder: (context) => [
                const PopupMenuItem(enabled: false, child: Text('Scenarios')),
                const PopupMenuItem(
                  value: _LabAction.live,
                  child: Text('Live session'),
                ),
                const PopupMenuItem(
                  value: _LabAction.chatOnly,
                  child: Text('Chat only'),
                ),
                const PopupMenuItem(
                  value: _LabAction.firstUse,
                  child: Text('First use'),
                ),
                const PopupMenuItem(
                  value: _LabAction.authFailed,
                  child: Text('Wrong password'),
                ),
                const PopupMenuItem(
                  value: _LabAction.reconnecting,
                  child: Text('Reconnecting'),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: _LabAction.toggleStudio,
                  enabled: model.canControl && !model.commandBusy,
                  child: Text(
                    model.studioMode
                        ? 'Turn Studio Mode off'
                        : 'Turn Studio Mode on',
                  ),
                ),
                const PopupMenuItem(
                  value: _LabAction.rejectCommand,
                  child: Text('Reject next OBS command'),
                ),
                const PopupMenuItem(
                  value: _LabAction.failMessage,
                  child: Text('Fail next chat message'),
                ),
                PopupMenuItem(
                  value: _LabAction.externalChange,
                  enabled: model.canControl,
                  child: const Text('Simulate external OBS change'),
                ),
              ],
              child: Semantics(
                button: true,
                label: 'Scenarios',
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text('Scenarios', style: TextStyle(color: _secondary)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down, color: _secondary),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _runLabAction(BuildContext context, _LabAction action) {
    switch (action) {
      case _LabAction.live:
        model.setScenario(LabScenario.live);
      case _LabAction.chatOnly:
        model.setScenario(LabScenario.chatOnly);
      case _LabAction.firstUse:
        model.setScenario(LabScenario.firstUse);
      case _LabAction.authFailed:
        model.setScenario(LabScenario.authFailed);
      case _LabAction.reconnecting:
        model.setScenario(LabScenario.reconnecting);
      case _LabAction.toggleStudio:
        model.setStudioMode(!model.studioMode);
      case _LabAction.rejectCommand:
        model.rejectNextCommand = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Next OBS command will be rejected.')),
        );
      case _LabAction.failMessage:
        model.rejectNextMessage = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Next chat message will fail.')),
        );
      case _LabAction.externalChange:
        model.simulateExternalChange();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OBS changed program externally.')),
        );
    }
  }
}

class _SessionHeader extends StatelessWidget {
  const _SessionHeader({required this.model});

  final WorkspaceModel model;

  @override
  Widget build(BuildContext context) {
    final connected = model.connection == ObsConnection.connected;
    final stale =
        model.connection == ObsConnection.reconnecting ||
        (connected && !model.obsStateFresh);
    return Container(
      constraints: const BoxConstraints(minHeight: 74),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: _panel,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Workspace',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 2),
                Text(
                  model.connectionName,
                  style: TextStyle(fontSize: 13, color: _secondary),
                ),
              ],
            ),
          ),
          if (connected || stale)
            Flexible(
              child: Semantics(
                label: stale
                    ? 'OBS state unavailable. Last program ${model.program}. State is stale.'
                    : 'OBS connected. Program ${model.program}.${model.isLiveObs ? '' : ' Live for 1 hour 42 minutes.'}',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: stale ? _secondary : _coral,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            stale
                                ? model.isLiveObs
                                      ? 'LAST KNOWN PROGRAM'
                                      : 'RECONNECTING · STALE'
                                : model.isLiveObs
                                ? 'PROGRAM'
                                : 'PROGRAM · 01:42:18',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              letterSpacing: .5,
                              color: stale ? _secondary : _coral,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            model.program,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Text(
              _connectionLabel(model.connection),
              style: const TextStyle(fontSize: 13, color: _secondary),
            ),
          if (model.hasObsDetails &&
              model.phoneFocus == WorkspaceFocus.chat) ...[
            const SizedBox(width: 8),
            IconButton.outlined(
              tooltip: 'Quick microphone audio',
              onPressed: () => showAudioSheet(context, model),
              icon: Icon(
                model.muted ? Icons.mic_off_outlined : Icons.mic_outlined,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _connectionLabel(ObsConnection connection) => switch (connection) {
  ObsConnection.disconnected => 'OBS disconnected',
  ObsConnection.connecting => 'Connecting to OBS…',
  ObsConnection.connected => 'OBS connected',
  ObsConnection.reconnecting => 'OBS reconnecting',
  ObsConnection.failed => 'OBS needs attention',
};

class _FocusControl extends StatelessWidget {
  const _FocusControl({required this.model, required this.tablet});

  final WorkspaceModel model;
  final bool tablet;

  @override
  Widget build(BuildContext context) {
    final entries = tablet
        ? const [
            (WorkspaceFocus.obs, 'OBS'),
            (WorkspaceFocus.balanced, 'Together'),
            (WorkspaceFocus.chat, 'Chat'),
          ]
        : const [(WorkspaceFocus.obs, 'OBS'), (WorkspaceFocus.chat, 'Chat')];
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          for (final entry in entries)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _FocusButton(
                  key: Key('workspace-focus-${entry.$1.name}'),
                  selected:
                      (tablet ? model.focus : model.phoneFocus) == entry.$1,
                  label: entry.$2,
                  onPressed: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    model.setFocus(entry.$1);
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FocusButton extends StatelessWidget {
  const _FocusButton({
    super.key,
    required this.selected,
    required this.label,
    required this.onPressed,
  });

  final bool selected;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: '$label workspace focus',
      excludeSemantics: true,
      onTap: onPressed,
      child: SizedBox(
        height: 48,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: selected ? _scaffold : _secondary,
            backgroundColor: selected ? _blue : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: selected ? _blue : _border),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _PhoneWorkspace extends StatelessWidget {
  const _PhoneWorkspace({
    required this.model,
    required this.obsPaneKey,
    required this.chatPaneKey,
  });

  final WorkspaceModel model;
  final GlobalKey obsPaneKey;
  final GlobalKey chatPaneKey;

  @override
  Widget build(BuildContext context) {
    final index = model.phoneFocus == WorkspaceFocus.chat ? 1 : 0;
    return IndexedStack(
      index: index,
      children: [
        ObsPanel(key: obsPaneKey, model: model),
        ChatPanel(key: chatPaneKey, model: model),
      ],
    );
  }
}

class _TabletWorkspace extends StatelessWidget {
  const _TabletWorkspace({
    required this.model,
    required this.obsPaneKey,
    required this.chatPaneKey,
  });

  final WorkspaceModel model;
  final GlobalKey obsPaneKey;
  final GlobalKey chatPaneKey;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth - 1;
        final proportion = switch (model.focus) {
          WorkspaceFocus.obs => .7,
          WorkspaceFocus.balanced => .5,
          WorkspaceFocus.chat => .3,
        };
        // Emphasis yields to usable pane width near the tablet boundary.
        final obsWidth = (width * proportion).clamp(360.0, width - 360);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: obsWidth,
              child: ObsPanel(key: obsPaneKey, model: model),
            ),
            const VerticalDivider(width: 1, thickness: 1, color: _border),
            Expanded(
              child: ChatPanel(key: chatPaneKey, model: model),
            ),
          ],
        );
      },
    );
  }
}

void showAudioSheet(BuildContext context, WorkspaceModel model) {
  FocusManager.instance.primaryFocus?.unfocus();
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: _panel,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Microphone',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Global audio · Studio OBS',
              style: TextStyle(color: _secondary),
            ),
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: model,
              builder: (context, _) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CommandFeedback(model: model),
                  AudioControl(model: model),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
