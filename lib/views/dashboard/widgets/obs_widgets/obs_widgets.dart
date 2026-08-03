import 'package:flutter/material.dart';

import '../../../../shared/design/design.dart';
import '../../../../shared/general/base/card.dart';
import 'stats/stats.dart';
import 'stream_chat/stream_chat.dart';

class OBSWidgets extends StatelessWidget {
  /// When true, the Stats card is on the left.
  final bool statsFirst;

  const OBSWidgets({
    super.key,
    this.statsFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    final Widget chatCard = BaseCard(
      title: 'Chat',
      rightPadding: AppSpacing.md,
      leftPadding: this.statsFirst ? AppSpacing.md : AppSpacing.lg,
      paddingChild: const EdgeInsets.all(0),
      child: const SizedBox(
        height: 750.0,
        child: StreamChat(
          usernameRowPadding: true,
        ),
      ),
    );

    final Widget statsCard = BaseCard(
      title: 'Stats',
      leftPadding: this.statsFirst ? AppSpacing.lg : AppSpacing.md,
      rightPadding: this.statsFirst ? AppSpacing.md : AppSpacing.lg,
      paddingChild: const EdgeInsets.all(0),
      child: const SizedBox(
        height: 650.0,
        child: Stats(),
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Flexible(child: this.statsFirst ? statsCard : chatCard),
        Flexible(child: this.statsFirst ? chatCard : statsCard),
      ],
    );
  }
}
