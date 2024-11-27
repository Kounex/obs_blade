import 'package:flutter/material.dart';
import 'package:obs_blade/utils/styling_helper.dart';

import 'scene_preview/scene_preview.dart';

class ResizeableScenePreview extends StatefulWidget {
  final bool resizeable;

  final double minHeight;
  final double? maxHeight;

  final double? initialHeight;

  const ResizeableScenePreview({
    super.key,
    this.resizeable = true,
    this.minHeight = 75,
    this.maxHeight,
    this.initialHeight,
  });

  @override
  State<ResizeableScenePreview> createState() => _ResizeableScenePreviewState();
}

class _ResizeableScenePreviewState extends State<ResizeableScenePreview> {
  late double _minHeight;
  late double _maxHeight;
  late double _currentHeight;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _minHeight = this.widget.minHeight;
    _currentHeight =
        this.widget.initialHeight ?? MediaQuery.sizeOf(context).height / 6;
    _maxHeight = this.widget.maxHeight ?? MediaQuery.sizeOf(context).height / 3;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: _currentHeight,
          child: const ScenePreview(
            expandable: false,
          ),
        ),
        if (this.widget.resizeable)
          Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border.symmetric(
                horizontal: BorderSide(
                  color: StylingHelper.light_divider_color.withOpacity(0.4),
                ),
              ),
            ),
            child: GestureDetector(
              onVerticalDragUpdate: (dragUpdate) {
                double update = _currentHeight + dragUpdate.delta.dy;
                if (update >= _minHeight && update <= _maxHeight) {
                  setState((() => _currentHeight = update));
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                width: 64.0,

                /// Hack: without the color attribute, the container
                /// is not correctly ioncreasing the tap size for the
                /// [GestureDetector]
                color: Colors.transparent,
                child: const Icon(
                  Icons.drag_indicator,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
