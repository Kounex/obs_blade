import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../shared/design/design.dart';

/// Row chrome matching [SceneItemTile]: type icon + name + eye toggle,
/// using the same Cupertino glyphs as the live list (no GetIt / scene data).
class SceneItemsPreview extends StatelessWidget {
  const SceneItemsPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final Color? iconColor = Theme.of(context).iconTheme.color;
    final Color? muted = Theme.of(context).textTheme.bodySmall?.color;

    Widget row({
      required IconData typeIcon,
      required String name,
      required bool visible,
    }) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            children: [
              Icon(typeIcon, size: 18.0, color: iconColor),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Icon(
                visible ? CupertinoIcons.eye_solid : CupertinoIcons.eye_slash,
                size: 18.0,
                color: visible ? iconColor : muted,
              ),
            ],
          ),
        );

    return IgnorePointer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          row(
            typeIcon: CupertinoIcons.photo_on_rectangle,
            name: 'Camera',
            visible: true,
          ),
          row(
            typeIcon: CupertinoIcons.folder_solid,
            name: 'Overlays',
            visible: false,
          ),
          row(
            typeIcon: CupertinoIcons.photo_on_rectangle,
            name: 'Gameplay',
            visible: true,
          ),
        ],
      ),
    );
  }
}
