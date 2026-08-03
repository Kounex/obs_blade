import 'package:flutter/material.dart';

import '../../../../shared/design/design.dart';
import 'stats/stats.dart';
import 'stream_chat/stream_chat.dart';

class OBSWidgetsMobile extends StatelessWidget {
  /// When true, the Stats tab is listed (and shown) before Chat.
  final bool statsFirst;

  const OBSWidgetsMobile({
    super.key,
    this.statsFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    final List<Widget> tabs = this.statsFirst
        ? const [
            Tab(child: Text('Stats')),
            Tab(child: Text('Chat')),
          ]
        : const [
            Tab(child: Text('Chat')),
            Tab(child: Text('Stats')),
          ];

    final List<Widget> views = this.statsFirst
        ? const [
            Padding(
              padding: EdgeInsets.only(top: AppSpacing.md),
              child: Stats(
                pageIndicatorPadding: EdgeInsets.only(
                  top: AppSpacing.md,
                  bottom: AppSpacing.md,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                top: AppSpacing.md,
                left: AppSpacing.sm,
                right: AppSpacing.sm,
              ),
              child: StreamChat(),
            ),
          ]
        : const [
            Padding(
              padding: EdgeInsets.only(
                top: AppSpacing.md,
                left: AppSpacing.sm,
                right: AppSpacing.sm,
              ),
              child: StreamChat(),
            ),
            Padding(
              padding: EdgeInsets.only(top: AppSpacing.md),
              child: Stats(
                pageIndicatorPadding: EdgeInsets.only(
                  top: AppSpacing.md,
                  bottom: AppSpacing.md,
                ),
              ),
            ),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DefaultTabController(
          length: 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: theme.cupertinoOverrideTheme!.barBackgroundColor,
                child: TabBar(
                  labelColor: theme.colorScheme.secondary,
                  unselectedLabelColor: theme.textTheme.bodySmall!.color,
                  labelStyle: theme.textTheme.titleSmall!
                      .copyWith(fontWeight: FontWeight.w600),
                  unselectedLabelStyle: theme.textTheme.titleSmall,
                  indicator: UnderlineTabIndicator(
                    borderSide: BorderSide(
                      width: 3.0,
                      color: theme.colorScheme.secondary,
                    ),
                    insets:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  ),
                  indicatorSize: TabBarIndicatorSize.label,
                  dividerColor: Colors.transparent,
                  tabs: tabs,
                ),
              ),
              SizedBox(
                height: 720.0,
                child: TabBarView(
                  physics: const NeverScrollableScrollPhysics(),
                  children: views,
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}
