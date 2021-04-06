import 'package:flutter/material.dart';
import 'package:obs_blade/utils/styling_helper.dart';

class ColorBubble extends StatelessWidget {
  final Color color;
  final double size;

  ColorBubble({required this.color, this.size = 24.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: this.size,
      width: this.size,
      decoration: BoxDecoration(
        color: this.color,
        borderRadius: BorderRadius.circular(this.size / 2),
        border: Border.all(
          color: StylingHelper.surroundingAwareAccent(context),
          width: 1.0,
        ),
      ),
    );
  }
}
