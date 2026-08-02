import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/shared/general/base/divider.dart';
import 'package:obs_blade/utils/styling_helper.dart';

import '../../../../shared/dialogs/confirmation.dart';
import '../../../../shared/general/flutter_modified/translucent_sliver_app_bar.dart';
import '../../../../stores/shared/network.dart';
import '../../../../stores/views/dashboard.dart';
import '../../../../utils/modal_handler.dart';
import '../../../../utils/routing_helper.dart';
import 'general_actions.dart';
import 'on_air_status_cluster.dart';

class StatusAppBar extends StatelessWidget {
  const StatusAppBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = GetIt.instance<DashboardStore>();

    /// Highlight color used for nav bar actions (same source
    /// [ThemedCupertinoButton] reads)
    final Color actionColor =
        Theme.of(context).cupertinoOverrideTheme!.primaryColor ??
            CupertinoColors.activeBlue;

    return TransculentSliverAppBar(
      pinned: true,
      elevation: 0,
      toolbarHeight: kTextTabBarHeight,
      backgroundColor: !StylingHelper.isApple(context)
          ? Theme.of(context).appBarTheme.backgroundColor!.withValues(alpha: 1.0)
          : null,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(44.0),
        child: Column(
          children: [
            BaseDivider(),
            Padding(
              padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: OnAirStatusCluster(),
            ),
          ],
        ),
      ),
      title: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Pressable(
                onTap: () => ModalHandler.showBaseDialog(
                  context: context,
                  dialogWidget: ConfirmationDialog(
                    title: 'Close Connection',
                    body:
                        'Are you sure you want to close the current WebSocket connection?',
                    isYesDestructive: true,
                    onOk: (_) {
                      dashboardStore.stopTimers();
                      Navigator.of(context).pushReplacementNamed(
                        HomeTabRoutingKeys.Landing.route,
                        arguments: ModalRoute.of(context)!.settings.arguments,
                      );
                      GetIt.instance<NetworkStore>().closeSession();
                    },
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.pill,
                    color: actionColor.withValues(alpha: 0.14),
                  ),
                  child: Text(
                    'Close',
                    style: Theme.of(context).textTheme.labelMedium!.copyWith(
                          color: actionColor,
                        ),
                  ),
                ),
              ),
              const GeneralActions(),
            ],
          ),
          Text(
            'Dashboard',
            style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
          ),
        ],
      ),
    );
  }
}
