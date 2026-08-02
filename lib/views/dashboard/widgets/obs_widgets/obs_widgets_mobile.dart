import 'package:flutter/material.dart';

import '../../../../shared/design/design.dart';
import 'stats/stats.dart';
import 'stream_chat/stream_chat.dart';

class OBSWidgetsMobile extends StatelessWidget {
  const OBSWidgetsMobile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

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
                  tabs: const [
                    Tab(
                      child: Text('Chat'),
                    ),
                    Tab(
                      child: Text('Stats'),
                    )
                  ],
                ),
              ),
              const SizedBox(
                height: 720.0,
                child: TabBarView(
                  physics: NeverScrollableScrollPhysics(),
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                          top: AppSpacing.md,
                          left: AppSpacing.sm,
                          right: AppSpacing.sm),
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
                  ],
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}
