import 'package:flutter/cupertino.dart';

/// FOSS build (copied over the store version by `tool/foss/prepare.sh`):
/// no in-app tips - Settings' Tip Jar opens Buy Me a Coffee instead, so
/// this is never shown. It only keeps the shared Settings code compiling.
class SupportDialog extends StatelessWidget {
  final String title;
  final IconData icon;

  const SupportDialog({
    super.key,
    required this.title,
    this.icon = CupertinoIcons.heart_solid,
  });

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
