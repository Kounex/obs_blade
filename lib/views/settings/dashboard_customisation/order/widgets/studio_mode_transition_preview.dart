import 'package:flutter/material.dart';
import 'package:obs_blade/shared/general/base/button.dart';

/// Mirrors [StudioModeTransitionButton]'s [BaseButton] chrome with static
/// placeholder labels — not the live OBS-driven control.
class StudioModeTransitionPreview extends StatelessWidget {
  const StudioModeTransitionPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.center,
        child: SizedBox(
          width: 128.0,
          child: BaseButton(
            text: 'Transition',
            secondary: true,
            onPressed: () {},
          ),
        ),
      ),
    );
  }
}
