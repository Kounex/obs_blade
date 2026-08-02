import 'package:flutter/material.dart';

import '../../../../../shared/design/design.dart';

class PlaceholderSceneItem extends StatelessWidget {
  final String text;

  const PlaceholderSceneItem({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Center(
        child: Text(
          this.text,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}
