import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_blade/models/past_record_data.dart';
import 'package:obs_blade/models/past_stream_data.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/shared/general/tag_box.dart';
import 'package:obs_blade/types/extensions/int.dart';

import '../../../../types/interfaces/past_stats_data.dart';
import '../../../../utils/routing_helper.dart';
import 'stats_date_chip.dart';

/// Unique (per box) Hero tag for the entry -> detail shared element
/// transition - prefixed by stat type since stream and record entries live
/// in different boxes and their Hive keys may collide
String statsEntryHeroTag(PastStatsData pastStatsData) {
  final Object hiveKey = pastStatsData is PastStreamData
      ? pastStatsData.key
      : (pastStatsData as PastRecordData).key;
  return 'stats-entry-${pastStatsData is PastStreamData ? 'stream' : 'record'}-'
      '$hiveKey';
}

class StatsEntry extends StatelessWidget {
  final PastStatsData pastStatsData;
  final bool usedInDetail;

  const StatsEntry({
    super.key,
    required this.pastStatsData,
    this.usedInDetail = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isStarred =
        this.pastStatsData.starred != null && this.pastStatsData.starred!;

    Widget entry = Padding(
      padding: EdgeInsets.symmetric(vertical: !this.usedInDetail ? 8.0 : 0),
      child: Stack(
        children: [
          Positioned(
            top: 4,
            right: 12,
            child: AnimatedSwitcher(
              duration: AppMotion.medium,
              switchInCurve: AppMotion.spring,
              switchOutCurve: AppMotion.exit,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: animation,
                  child: child,
                ),
              ),
              child: isStarred
                  ? Icon(
                      Icons.star,
                      key: const ValueKey('starred'),
                      color: Theme.of(context)
                          .extension<AppStatusColors>()!
                          .warning,
                      size: 28.0,
                    )
                  : const SizedBox(key: ValueKey('unstarred')),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  title: Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          this.pastStatsData.name ?? 'Unnamed entry',
                          style:
                              Theme.of(context).textTheme.labelLarge!.copyWith(
                                    fontSize: 18.0,
                                    color: this.pastStatsData.name == null
                                        ? Theme.of(context)
                                            .textTheme
                                            .bodySmall!
                                            .color
                                        : null,
                                  ),
                          maxLines: 2,
                          softWrap: true,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8.0),
                        Padding(
                          padding: const EdgeInsets.only(left: 0.0),
                          child: TagBox(
                            expand: false,
                            color: this.pastStatsData is PastStreamData
                                ? Colors.blue[800]
                                : this.pastStatsData is PastRecordData
                                    ? CupertinoColors.destructiveRed
                                    : Colors.grey,
                            icon: Icon(
                              this.pastStatsData is PastStreamData
                                  ? CupertinoIcons.dot_radiowaves_left_right
                                  : this.pastStatsData is PastRecordData
                                      ? CupertinoIcons.recordingtape
                                      : Icons.question_mark,
                              size: 18.0,
                              color: Colors.white,
                            ),
                            label: this.pastStatsData is PastStreamData
                                ? 'Stream'
                                : this.pastStatsData is PastRecordData
                                    ? 'Recording'
                                    : 'Unknown',
                            labelStyle: Theme.of(context)
                                .textTheme
                                .bodySmall!
                                .copyWith(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 250.0),
                          child: StatsDateChip(
                            label: 'From:',
                            content:
                                '${(this.pastStatsData.listEntryDateMS.last - this.pastStatsData.totalTime! * 1000).millisecondsToFormattedDateString()} - ${(this.pastStatsData.listEntryDateMS.last - this.pastStatsData.totalTime! * 1000).millisecondsToFormattedTimeString()}',
                          ),
                        ),
                        const SizedBox(height: 12.0),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 250.0),
                          child: StatsDateChip(
                            label: 'To:',
                            content:
                                '${this.pastStatsData.listEntryDateMS.last.millisecondsToFormattedDateString()} - ${this.pastStatsData.listEntryDateMS.last.millisecondsToFormattedTimeString()}',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              !this.usedInDetail
                  ? const Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                    )
                  : const SizedBox(),
            ],
          ),
        ],
      ),
    );

    if (!this.usedInDetail) {
      entry = Pressable(
        onTap: () => Navigator.pushNamed(
          context,
          StaticticsTabRoutingKeys.Detail.route,
          arguments: this.pastStatsData,
        ),
        child: entry,
      );
    }

    /// The transparent [Material] keeps text styling intact while the Hero
    /// is in flight between the list and the detail route
    return Hero(
      tag: statsEntryHeroTag(this.pastStatsData),
      child: Material(
        type: MaterialType.transparency,
        child: entry,
      ),
    );
  }
}
