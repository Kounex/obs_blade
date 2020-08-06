import 'package:flutter/material.dart';
import 'package:obs_blade/utils/styling_helper.dart';

class LightDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      color: StylingHelper.LIGHT_DIVIDER_COLOR,
      height: 0.0,
      thickness: 0.0,
    );
  }
}
