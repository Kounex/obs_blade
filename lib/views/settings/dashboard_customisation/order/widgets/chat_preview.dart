import 'package:flutter/material.dart';

import '../../../../../shared/design/design.dart';
import 'mock_parts.dart';

/// Minimal mock of the Stream Chat element: chat lines with round avatars
class ChatPreview extends StatelessWidget {
  const ChatPreview({super.key});

  @override
  Widget build(BuildContext context) {
    Widget line({double endGap = 0.0}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          const MockCircle(size: 10.0),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(child: MockBar(height: 6.0)),
          SizedBox(width: endGap),
        ],
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        line(endGap: 48.0),
        line(endGap: 8.0),
        line(endGap: 96.0),
        line(endGap: 32.0),
      ],
    );
  }
}
