import 'package:flutter/material.dart';

import '../../../../shared/design/design.dart';

/// Placeholder bars shown while the store answers the ProductDetails
/// request. Gently breathes until the priced content replaces it via an
/// AnimatedSwitcher (see tips_content.dart / blacksmith_content.dart).
class SupportSkeleton extends StatefulWidget {
  final int rows;

  const SupportSkeleton({super.key, this.rows = 3});

  @override
  State<SupportSkeleton> createState() => _SupportSkeletonState();
}

class _SupportSkeletonState extends State<SupportSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.dramatic)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color baseColor = Theme.of(context).dividerTheme.color ?? Colors.grey;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Column(
        children: [
          for (int i = 0; i < this.widget.rows; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i < this.widget.rows - 1 ? AppSpacing.md : 0.0,
              ),
              child: Container(
                height: 40.0,
                decoration: BoxDecoration(
                  color: baseColor.withValues(alpha: 0.10 + 0.10 * _controller.value),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
