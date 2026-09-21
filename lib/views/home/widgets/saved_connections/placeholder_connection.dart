import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../shared/design/design.dart';
import '../../../../shared/general/base/card.dart';
import '../../../../stores/views/home.dart';

/// Dead-end empty state turned into the primary action: tapping the card
/// jumps to the autodiscovery pane (same entrance as the real cards)
class PlaceholderConnection extends StatelessWidget {
  final double height;
  final double width;

  const PlaceholderConnection({
    super.key,
    required this.height,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodySmall?.color;

    return Center(
      child: StaggeredEntrance(
        scaleFrom: 0.985,
        child: Pressable(
          onTap: () => GetIt.instance<HomeStore>().setConnectMode(
            ConnectMode.Autodiscover,
          ),
          child: SizedBox(
            width: this.width,
            child: BaseCard(
              topPadding: 0.0,
              rightPadding: 0.0,
              bottomPadding: 0.0,
              leftPadding: 0.0,
              paddingChild: EdgeInsets.zero,
              child: SizedBox(
                height: this.height,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.link, size: 36.0, color: muted),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'No saved connections',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Connect once, then save it here.',
                        textAlign: TextAlign.center,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: muted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
