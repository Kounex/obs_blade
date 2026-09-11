import 'package:flutter/material.dart';

import 'workspace_model.dart';

/// Sources in the inspected scene. Enabled flags are OBS-confirmed; pending
/// state belongs to each target, independently from scene-output commands.
class WorkspaceSources extends StatelessWidget {
  const WorkspaceSources({super.key, required this.model});
  final WorkspaceModel model;

  @override
  Widget build(BuildContext context) {
    final controls = model.sourceControls;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (model.sourceProblem != null) ...[
          Text(model.sourceProblem!),
          TextButton.icon(
            onPressed: model.refreshSources,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh sources'),
          ),
        ] else if (!model.sourcesReady)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Loading sources…'),
          )
        else if (controls.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('This scene has no sources.'),
          ),
        for (final (index, source) in controls.indexed)
          Padding(
            key: ValueKey((source.target, index)),
            padding: EdgeInsets.only(left: source.depth.clamp(0, 3) * 12.0),
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(source.name),
              subtitle: Text(
                source.error ??
                    (source.busy
                        ? 'Waiting for OBS…'
                        : !model.sourcesReady
                        ? 'Last known state'
                        : source.hiddenByGroup
                        ? 'Hidden by group · ${source.target.owner}'
                        : '${source.isGroup ? 'Group · ' : ''}${source.enabled == null
                              ? 'State unavailable'
                              : source.enabled!
                              ? 'Enabled'
                              : 'Disabled'}${source.depth > 0 ? ' · ${source.target.owner}' : ''}'),
              ),
              value: source.enabled ?? false,
              onChanged: source.canChange
                  ? (value) => model.setSourceEnabled(source.target, value)
                  : null,
            ),
          ),
      ],
    );
  }
}
