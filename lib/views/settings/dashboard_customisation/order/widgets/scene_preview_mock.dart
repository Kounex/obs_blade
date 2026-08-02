import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../shared/design/design.dart';
import 'mock_parts.dart';

/// Minimal mock of the Scene Preview element: a dark 16:9 frame with a play
/// glyph, like the screenshot surface in the dashboard
class ScenePreviewMock extends StatelessWidget {
  const ScenePreviewMock({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16.0 / 9.0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: const Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              CupertinoIcons.play_rectangle,
              size: 28.0,
              color: Colors.white54,
            ),
            Positioned(
              left: AppSpacing.sm,
              right: AppSpacing.sm,
              bottom: AppSpacing.sm,
              child: MockBar(height: 5.0, color: Colors.white24),
            ),
          ],
        ),
      ),
    );
  }
}
