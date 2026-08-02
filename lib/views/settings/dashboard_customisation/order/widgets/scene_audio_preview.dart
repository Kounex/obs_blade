import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../shared/design/design.dart';
import 'mock_parts.dart';

/// Minimal mock of the Scene Audio mixer: fader tracks with a level fill and
/// a mute speaker, one of them muted
class SceneAudioPreview extends StatelessWidget {
  const SceneAudioPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).buttonTheme.colorScheme!.secondary;
    final Color muted = Theme.of(
      context,
    ).extension<AppStatusColors>()!.recording;

    Widget fader({
      required double level,
      required IconData speaker,
      Color? fillColor,
      Color? speakerColor,
    }) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.mic,
            size: 14.0,
            color: Theme.of(context).iconTheme.color,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => Stack(
                alignment: Alignment.centerLeft,
                children: [
                  const MockBar(height: 6.0),
                  MockBar(
                    height: 6.0,
                    width: constraints.maxWidth * level,
                    color: fillColor ?? accent,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(
            speaker,
            size: 14.0,
            color: speakerColor ?? Theme.of(context).iconTheme.color,
          ),
        ],
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        fader(level: 0.7, speaker: CupertinoIcons.speaker_2_fill),
        fader(
          level: 0.35,
          speaker: CupertinoIcons.speaker_slash_fill,
          speakerColor: muted,
        ),
      ],
    );
  }
}
