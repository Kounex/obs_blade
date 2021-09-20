import 'package:flutter/material.dart';
import 'package:obs_blade/views/settings/widgets/action_block.dart/light_divider.dart';

class ColumnSeparated extends StatelessWidget {
  final Iterable<Widget> children;

  final EdgeInsets padding;
  final bool useSymmetricOutsidePadding;

  final EdgeInsets paddingSeparator;
  final EdgeInsets additionalPaddingSeparator;
  final bool lightDivider;

  final Widget? customSeparator;

  const ColumnSeparated({
    Key? key,
    required this.children,
    this.padding = const EdgeInsets.all(0),
    this.useSymmetricOutsidePadding = false,
    this.paddingSeparator = const EdgeInsets.symmetric(vertical: 12.0),
    this.additionalPaddingSeparator = const EdgeInsets.all(0.0),
    this.lightDivider = true,
    this.customSeparator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      padding: this.useSymmetricOutsidePadding
          ? EdgeInsets.symmetric(vertical: this.paddingSeparator.vertical / 2)
          : this.padding,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: this.children.length,
      separatorBuilder: (context, index) => Padding(
        padding: this.paddingSeparator + this.additionalPaddingSeparator,
        child: this.lightDivider ? const LightDivider() : const LightDivider(),
      ),
      itemBuilder: (context, index) => this.children.elementAt(index),
    );
  }
}
