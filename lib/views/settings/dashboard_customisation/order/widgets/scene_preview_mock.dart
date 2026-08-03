import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../shared/design/design.dart';

/// Compact stand-in for [ScenePreview]: same 16:9 frame language (dark
/// surface, hairline, radius) without mounting the live WebSocket preview.
class ScenePreviewMock extends StatelessWidget {
  const ScenePreviewMock({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16.0 / 9.0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(
          CupertinoIcons.play_rectangle,
          size: 28.0,
          color: Colors.white.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}
