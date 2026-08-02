import 'package:flutter/material.dart';
import 'package:obs_blade/shared/general/base/button.dart';

/// Primary CTA for the intro flow: full-width (within the surrounding
/// [BaseConstrainedBox]) and 52pt high so it reads as the clear primary
/// action. Styling / semantics stay on [BaseButton] - only the geometry
/// is opinionated.
class IntroPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  const IntroPrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52.0,
      child: BaseButton(
        text: this.text,
        onPressed: this.onPressed,
      ),
    );
  }
}
