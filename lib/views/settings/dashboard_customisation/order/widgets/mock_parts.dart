import 'package:flutter/material.dart';

import '../../../../../shared/design/design.dart';

/// Shared building blocks for the dashboard-element mock previews shown in
/// the order editor. Purely visual skeletons - they mirror the structure of
/// the real dashboard elements without implying any live state.

/// Rounded placeholder bar (skeleton line)
class MockBar extends StatelessWidget {
  final double? width;
  final double height;
  final Color? color;

  const MockBar({super.key, this.width, this.height = 8.0, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: this.width,
      height: this.height,
      decoration: BoxDecoration(
        color: this.color ?? Theme.of(context).disabledColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
    );
  }
}

/// Round placeholder (avatars, indicators)
class MockCircle extends StatelessWidget {
  final double size;
  final Color? color;

  const MockCircle({super.key, this.size = 10.0, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: this.size,
      height: this.size,
      decoration: BoxDecoration(
        color: this.color ?? Theme.of(context).disabledColor.withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Fallback for elements without a dedicated mock (e.g. future enum values)
class GenericMockPreview extends StatelessWidget {
  const GenericMockPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MockBar(),
        SizedBox(height: AppSpacing.sm),
        MockBar(),
      ],
    );
  }
}
