import 'package:flutter/material.dart';

import '../../../../../utils/styling_helper.dart';

class ColorBubble extends StatelessWidget {
  final Color color;
  final double size;

  const ColorBubble({super.key, required this.color, this.size = 24.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: this.size,
      width: this.size,
      decoration: BoxDecoration(
        color: this.color,
        borderRadius: BorderRadius.circular(this.size / 2),
        border: Border.all(
          color: StylingHelper.surroundingAwareAccent(context: context),
          width: 0.0,
        ),
      ),
    );
  }
}
