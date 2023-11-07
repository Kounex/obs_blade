import 'package:flutter/material.dart';

import '../../../../../shared/general/base/divider.dart';

class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: BaseDivider(),
        ),
        const SizedBox(width: 24.0),
        Text(this.title, style: Theme.of(context).textTheme.labelSmall!),
        const SizedBox(width: 24.0),
        const Expanded(
          child: BaseDivider(),
        ),
      ],
    );
  }
}
