import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../shared/design/design.dart';
import '../accent_icon_tile.dart';

class SupportHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const SupportHeader({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.sm,
        top: AppSpacing.lg,
        bottom: AppSpacing.sm,
      ),
      child: Row(
        children: [
          AccentIconTile(icon: this.icon, size: 44.0, iconSize: 24.0),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              this.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.clear_circled_solid, size: 24.0),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
