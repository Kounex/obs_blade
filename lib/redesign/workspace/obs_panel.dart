import 'package:flutter/material.dart';

import 'workspace_model.dart';
import 'workspace_sources.dart';

const _border = Color(0xFF334355);
const _text = Color(0xFFEDF2F7);
const _secondary = Color(0xFFACB8C8);
const _blue = Color(0xFFB3CEFF);
const _coral = Color(0xFFF39E8F);

class ObsPanel extends StatefulWidget {
  const ObsPanel({super.key, required this.model});

  final WorkspaceModel model;

  @override
  State<ObsPanel> createState() => _ObsPanelState();
}

class _ObsPanelState extends State<ObsPanel> {
  final _passwordController = TextEditingController();
  bool _showingDetails = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.model.connection != ObsConnection.connected) {
      return _ConnectionPane(
        model: widget.model,
        passwordController: _passwordController,
      );
    }
    return _ControlPane(
      model: widget.model,
      showingDetails: _showingDetails,
      onInspect: (scene) {
        widget.model.inspect(scene);
        setState(() => _showingDetails = true);
      },
      onBack: () => setState(() => _showingDetails = false),
    );
  }
}

class _ConnectionPane extends StatelessWidget {
  const _ConnectionPane({
    required this.model,
    required this.passwordController,
  });

  final WorkspaceModel model;
  final TextEditingController passwordController;

  @override
  Widget build(BuildContext context) {
    final connecting = model.connection == ObsConnection.connecting;
    final reconnecting = model.connection == ObsConnection.reconnecting;
    final authFailed = model.connection == ObsConnection.failed;
    final title = switch (model.connection) {
      ObsConnection.connecting => 'Connecting to ${model.connectionName}',
      ObsConnection.reconnecting => 'Connection interrupted',
      ObsConnection.failed => 'Password not accepted',
      _ => model.hasSavedConnection ? 'OBS not connected' : 'Connect to OBS',
    };
    final detail = switch (model.connection) {
      ObsConnection.connecting =>
        'Synchronizing OBS state. You can keep using chat.',
      ObsConnection.reconnecting =>
        'The values shown before the interruption are stale. Retry to synchronize again.',
      ObsConnection.failed =>
        'Edit the password and try this saved connection again.',
      _ =>
        model.hasSavedConnection
            ? 'Reconnect when you need production controls. Chat stays available.'
            : 'Add your first OBS connection when you are ready. Chat already works on its own.',
    };
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 24),
        Icon(
          authFailed
              ? Icons.key_outlined
              : reconnecting
              ? Icons.sync_problem_outlined
              : Icons.sensors_off_outlined,
          size: 32,
          color: authFailed ? _coral : _secondary,
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          model.connectionProblem ??
              (model.isLiveObs && !connecting
                  ? 'Connect to ${model.connectionName}. This lab operates real OBS scenes; chat is simulated.'
                  : detail),
          textAlign: TextAlign.center,
          style: const TextStyle(color: _secondary, height: 1.4),
        ),
        if (authFailed || (model.isLiveObs && !connecting)) ...[
          const SizedBox(height: 24),
          TextField(
            controller: passwordController,
            obscureText: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (value) => model.connect(password: value),
            decoration: const InputDecoration(
              labelText: 'OBS WebSocket password',
              hintText: 'Enter password',
            ),
          ),
        ],
        const SizedBox(height: 24),
        if (connecting)
          OutlinedButton.icon(
            onPressed: model.disconnect,
            icon: const Icon(Icons.close),
            label: const Text('Cancel'),
          )
        else if (reconnecting)
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: model.connect,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry now'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: model.disconnect,
                  child: const Text('Leave OBS'),
                ),
              ),
            ],
          )
        else
          FilledButton.icon(
            key: const Key('connect-obs'),
            onPressed: () => model.connect(password: passwordController.text),
            icon: const Icon(Icons.power_settings_new),
            label: Text(
              model.hasSavedConnection
                  ? 'Connect ${model.connectionName}'
                  : 'Connect to OBS',
            ),
          ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => model.setFocus(WorkspaceFocus.chat),
          icon: const Icon(Icons.chat_bubble_outline),
          label: const Text('Open chat'),
        ),
      ],
    );
  }
}

class _ControlPane extends StatelessWidget {
  const _ControlPane({
    required this.model,
    required this.showingDetails,
    required this.onInspect,
    required this.onBack,
  });

  final WorkspaceModel model;
  final bool showingDetails;
  final ValueChanged<String> onInspect;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 600;
              final browser = _SceneBrowser(
                model: model,
                onInspect: onInspect,
                includeAudio: !wide,
              );
              final details = ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (!wide)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: onBack,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Back to scenes'),
                      ),
                    ),
                  _Inspector(model: model),
                  _DisconnectAction(model: model),
                ],
              );
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: browser),
                    const VerticalDivider(width: 1),
                    Expanded(child: details),
                  ],
                );
              }
              return showingDetails ? details : browser;
            },
          ),
        ),
        _OutputActionBar(model: model),
      ],
    );
  }
}

class _SceneBrowser extends StatelessWidget {
  const _SceneBrowser({
    required this.model,
    required this.onInspect,
    required this.includeAudio,
  });
  final WorkspaceModel model;
  final ValueChanged<String> onInspect;
  final bool includeAudio;

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        sliver: SliverToBoxAdapter(child: _SignalRail(model: model)),
      ),
      const SliverPadding(
        padding: EdgeInsets.fromLTRB(16, 10, 16, 4),
        sliver: SliverToBoxAdapter(
          child: Text(
            'SCENES',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
              color: _secondary,
            ),
          ),
        ),
      ),
      SliverList.builder(
        itemCount: model.scenes.length,
        itemBuilder: (context, index) => _SceneRow(
          model: model,
          scene: model.scenes[index],
          onInspect: () => onInspect(model.scenes[index]),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverToBoxAdapter(
          child: Column(
            children: [
              if (includeAudio && model.hasAudioControls)
                AudioControl(model: model),
              _DisconnectAction(model: model),
            ],
          ),
        ),
      ),
    ],
  );
}

class _DisconnectAction extends StatelessWidget {
  const _DisconnectAction({required this.model});
  final WorkspaceModel model;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: TextButton.icon(
      key: const ValueKey('disconnect-obs'),
      onPressed: model.disconnect,
      icon: const Icon(Icons.link_off),
      label: const Text('Disconnect OBS'),
    ),
  );
}

/// Command feedback is visible at the output dock and in the quick audio tool.
class CommandFeedback extends StatelessWidget {
  const CommandFeedback({super.key, required this.model});
  final WorkspaceModel model;
  @override
  Widget build(BuildContext context) {
    final text =
        model.commandError ??
        (model.pendingCommand == null
            ? null
            : '${model.pendingCommand} pending…');
    if (text == null) return const SizedBox.shrink();
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: model.commandError == null ? _secondary : _coral,
          ),
        ),
      ),
    );
  }
}

class _OutputActionBar extends StatelessWidget {
  const _OutputActionBar({required this.model});
  final WorkspaceModel model;
  @override
  Widget build(BuildContext context) {
    final target = model.studioMode ? model.preview : model.inspectedScene;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Color(0xFF1E2936),
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommandFeedback(model: model),
          Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      !model.obsStateFresh
                          ? 'LAST KNOWN TARGET'
                          : model.studioMode
                          ? 'READY IN PREVIEW'
                          : 'SELECTED SCENE',
                      style: const TextStyle(fontSize: 11, color: _secondary),
                    ),
                    Text(
                      target,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Tooltip(
                message: 'Send $target to program',
                child: FilledButton.icon(
                  key: const ValueKey('take-scene'),
                  onPressed: model.canControl && !model.commandBusy
                      ? model.takeScene
                      : null,
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: Text(model.studioMode ? 'Take' : 'Send live'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SignalRail extends StatelessWidget {
  const _SignalRail({required this.model});

  final WorkspaceModel model;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: _border),
          bottom: BorderSide(color: _border),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Signal(
              label: model.obsStateFresh ? 'PROGRAM' : 'LAST PROGRAM',
              value: model.program,
              color: _coral,
            ),
          ),
          if (model.studioMode) ...[
            const SizedBox(
              height: 64,
              child: VerticalDivider(width: 1, color: _border),
            ),
            Expanded(
              child: _Signal(
                label: model.obsStateFresh ? 'PREVIEW' : 'LAST PREVIEW',
                value: model.preview,
                color: _blue,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Signal extends StatelessWidget {
  const _Signal({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label scene, $value',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 1,
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _SceneRow extends StatelessWidget {
  const _SceneRow({
    required this.model,
    required this.scene,
    required this.onInspect,
  });

  final WorkspaceModel model;
  final String scene;
  final VoidCallback onInspect;

  @override
  Widget build(BuildContext context) {
    final selected = model.inspectedScene == scene;
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: ListTile(
        key: Key('scene-$scene'),
        selected: selected,
        selectedTileColor: _blue.withValues(alpha: .08),
        minTileHeight: 58,
        onTap: onInspect,
        title: Text(
          scene,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        subtitle: selected
            ? const Text('Inspecting', style: TextStyle(color: _blue))
            : null,
        trailing: Tooltip(
          excludeFromSemantics: true,
          message: model.studioMode
              ? 'Set $scene as preview'
              : 'Send $scene to program',
          child: TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: model.canControl && !model.commandBusy
                ? () {
                    model.inspect(scene);
                    if (model.studioMode) {
                      model.setPreview();
                    } else {
                      model.takeScene();
                    }
                  }
                : null,
            child: Text(model.studioMode ? 'Preview' : 'Send live'),
          ),
        ),
      ),
    );
  }
}

class _Inspector extends StatelessWidget {
  const _Inspector({required this.model});

  final WorkspaceModel model;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'INSPECTOR',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 1.1,
              color: _secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            model.inspectedScene,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          if (model.isLiveObs)
            WorkspaceSources(model: model)
          else
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Camera source'),
              subtitle: const Text(
                'Scene source visibility',
                style: TextStyle(color: _secondary),
              ),
              value: model.sourceEnabled,
              onChanged: model.canControl && !model.commandBusy
                  ? (_) => model.toggleSource()
                  : null,
            ),
          if (model.hasAudioControls) const Divider(),
          if (model.hasAudioControls) AudioControl(model: model),
        ],
      ),
    );
  }
}

class AudioControl extends StatefulWidget {
  const AudioControl({super.key, required this.model});

  final WorkspaceModel model;

  @override
  State<AudioControl> createState() => _AudioControlState();
}

class _AudioControlState extends State<AudioControl> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final value = _dragValue ?? widget.model.volume;
    final enabled = widget.model.canControl && !widget.model.commandBusy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Global microphone',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    widget.model.muted ? 'Muted' : '${(value * 100).round()}%',
                    style: TextStyle(
                      color: widget.model.muted ? _secondary : _text,
                    ),
                  ),
                ],
              ),
            ),
            IconButton.outlined(
              tooltip: widget.model.muted
                  ? 'Unmute global microphone'
                  : 'Mute global microphone',
              onPressed: enabled ? widget.model.toggleMute : null,
              icon: Icon(
                widget.model.muted
                    ? Icons.mic_off_outlined
                    : Icons.mic_outlined,
              ),
            ),
          ],
        ),
        Semantics(
          label: 'Global microphone volume ${(value * 100).round()} percent',
          child: Slider(
            semanticFormatterCallback: (value) =>
                '${(value * 100).round()} percent',
            value: value,
            onChanged: enabled
                ? (next) => setState(() => _dragValue = next)
                : null,
            onChangeEnd: enabled
                ? (next) {
                    setState(() => _dragValue = null);
                    widget.model.setVolume(next);
                  }
                : null,
          ),
        ),
      ],
    );
  }
}
