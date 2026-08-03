import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../shared/design/design.dart';

/// Layout language of [AudioSlider] rows: name, level track, speaker —
/// static levels, no [Input] / network dependency.
class SceneAudioPreview extends StatelessWidget {
  const SceneAudioPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).colorScheme.secondary;
    final Color muted =
        Theme.of(context).extension<AppStatusColors>()!.recording;

    Widget fader({
      required String name,
      required double level,
      required bool active,
    }) {
      final Color fill = active ? accent : muted;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) => Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Container(
                          height: 6.0,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .disabledColor
                                .withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                        ),
                        Container(
                          height: 6.0,
                          width: constraints.maxWidth * level,
                          decoration: BoxDecoration(
                            color: fill,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  active
                      ? CupertinoIcons.speaker_2_fill
                      : CupertinoIcons.speaker_slash_fill,
                  size: 16.0,
                  color: active
                      ? Theme.of(context).iconTheme.color
                      : muted,
                ),
              ],
            ),
          ],
        ),
      );
    }

    return IgnorePointer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          fader(name: 'Desktop Audio', level: 0.72, active: true),
          fader(name: 'Mic/Aux', level: 0.38, active: false),
        ],
      ),
    );
  }
}
