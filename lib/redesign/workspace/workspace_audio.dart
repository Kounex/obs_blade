import 'package:flutter/material.dart';

import 'audio_input_control.dart';
import 'workspace_model.dart';

class WorkspaceAudio extends StatelessWidget {
  const WorkspaceAudio({super.key, required this.model});
  final WorkspaceModel model;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'AUDIO INPUTS',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
      if (model.audioProblem != null) ...[
        const SizedBox(height: 8),
        Text(model.audioProblem!),
        TextButton.icon(
          onPressed: model.refreshAudio,
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh audio'),
        ),
      ] else if (!model.audioReady)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text('Loading audio…'),
        )
      else if (model.audioInputs.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text('No audio inputs found.'),
        ),
      for (final input in model.audioInputs)
        _InputRow(key: ValueKey(input.name), input: input, model: model),
    ],
  );
}

class _InputRow extends StatefulWidget {
  const _InputRow({super.key, required this.input, required this.model});
  final AudioInputControl input;
  final WorkspaceModel model;

  @override
  State<_InputRow> createState() => _InputRowState();
}

class _InputRowState extends State<_InputRow> {
  double? _drag;

  @override
  void didUpdateWidget(covariant _InputRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.input.canChange) _drag = null;
  }

  @override
  Widget build(BuildContext context) {
    final input = widget.input;
    final level = _drag ?? input.pendingVolume ?? input.volume ?? 0;
    final percent = (level * 100).round();
    final status = !input.fresh
        ? 'State unavailable${input.volume == null ? '' : ' · last ${(input.volume! * 100).round()}%'}'
        : input.pendingVolume != null
        ? 'Setting $percent%…'
        : input.busy
        ? 'Waiting for OBS…'
        : '${input.muted ? 'Muted · ' : ''}$percent%';
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      input.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(status, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              IconButton.outlined(
                tooltip: '${input.muted ? 'Unmute' : 'Mute'} ${input.name}',
                onPressed: input.canChange
                    ? () => widget.model.setInputMuted(input.name, !input.muted)
                    : null,
                icon: Icon(
                  input.muted
                      ? Icons.volume_off_outlined
                      : Icons.volume_up_outlined,
                ),
              ),
            ],
          ),
          Semantics(
            label: 'Volume for ${input.name}',
            child: Slider(
              key: ValueKey('volume-${input.name}'),
              value: level.clamp(0, 1),
              semanticFormatterCallback: (value) =>
                  '${(value * 100).round()} percent',
              onChanged: input.canChange
                  ? (value) => setState(() => _drag = value)
                  : null,
              onChangeEnd: input.canChange
                  ? (value) {
                      setState(() => _drag = null);
                      widget.model.setInputVolume(input.name, value);
                    }
                  : null,
            ),
          ),
          if ((input.volume ?? 0) > 1)
            Text(
              'OBS level ${(input.volume! * 100).round()}% · slider range 0–100%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          if (input.error != null)
            Text(
              input.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    );
  }
}
