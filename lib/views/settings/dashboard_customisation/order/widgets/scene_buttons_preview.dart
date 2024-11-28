import 'package:flutter/material.dart';
import 'package:obs_blade/shared/animator/selectable_box.dart';

class SceneButtonsPreview extends StatefulWidget {
  const SceneButtonsPreview({super.key});

  @override
  State<SceneButtonsPreview> createState() => _SceneButtonsPreviewState();
}

class _SceneButtonsPreviewState extends State<SceneButtonsPreview> {
  List<bool> _selected = [true, false, false];

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: Row(
        children: [
          SelectableBox(
            text: '<scene-1>',
            selected: _selected[0],
            onTap: () => setState(() {
              _selected = [true, false, false];
            }),
          ),
          const SizedBox(width: 12.0),
          SelectableBox(
            text: '<scene-2>',
            selected: _selected[1],
            onTap: () => setState(() {
              _selected = [false, true, false];
            }),
          ),
          const SizedBox(width: 12.0),
          SelectableBox(
            text: '<scene-3>',
            selected: _selected[2],
            onTap: () => setState(() {
              _selected = [false, false, true];
            }),
          ),
        ],
      ),
    );
  }
}
