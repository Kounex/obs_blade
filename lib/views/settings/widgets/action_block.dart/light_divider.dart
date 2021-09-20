import 'package:flutter/material.dart';
import 'package:obs_blade/utils/styling_helper.dart';

class LightDivider extends StatelessWidget {
  final double? height;

  const LightDivider({Key? key, this.height}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: StylingHelper.light_divider_color,
      height: this.height ?? 1.0,
      thickness: 0.0,
    );
  }
}
