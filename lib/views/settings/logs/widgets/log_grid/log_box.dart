import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_blade/shared/general/base_card.dart';

import '../../../../../types/extensions/int.dart';
import '../../../../../utils/routing_helper.dart';

class LogBox extends StatelessWidget {
  final int dateMS;
  final double size;

  LogBox({required this.dateMS, required this.size});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pushNamed(
          SettingsTabRoutingKeys.LogDetail.route,
          arguments: this.dateMS),
      child: SizedBox(
        width: this.size,
        child: Center(
          child: BaseCard(
            topPadding: 0,
            rightPadding: 0,
            bottomPadding: 0,
            leftPadding: 0,
            constrained: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.square_list,
                  size: 32.0,
                ),
                SizedBox(height: 12.0),
                FittedBox(
                  child: Text(
                    this.dateMS.millisecondsToFormattedDateString(),
                    style: Theme.of(context).textTheme.caption,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
