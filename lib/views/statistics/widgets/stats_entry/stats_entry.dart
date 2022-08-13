import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_blade/models/past_record_data.dart';
import 'package:obs_blade/models/past_stream_data.dart';
import 'package:obs_blade/types/extensions/int.dart';

import '../../../../types/interfaces/past_stats_data.dart';
import '../../../../utils/routing_helper.dart';
import 'stats_date_chip.dart';

class StatsEntry extends StatelessWidget {
  final PastStatsData pastStatsData;
  final bool usedInDetail;

  const StatsEntry({
    Key? key,
    required this.pastStatsData,
    this.usedInDetail = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget listTile = ListTile(
      title: Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Icon(
                    this.pastStatsData.starred != null &&
                            this.pastStatsData.starred!
                        ? Icons.star
                        : Icons.star_border,
                  ),
                ),
                Expanded(
                  child: Text(
                    this.pastStatsData.name ?? 'Unnamed entry',
                    style: Theme.of(context).textTheme.button!.copyWith(
                          fontSize: 18.0,
                        ),
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4.0),
            Padding(
              padding: const EdgeInsets.only(left: 35.0),
              child: Row(
                children: [
                  this.pastStatsData is PastStreamData
                      ? const Icon(
                          Icons.fiber_manual_record_rounded,
                          size: 18.0,
                          color: CupertinoColors.destructiveRed,
                        )
                      : this.pastStatsData is PastRecordData
                          ? const Icon(
                              Icons.sensors,
                              color: CupertinoColors.destructiveRed,
                            )
                          : const Icon(
                              Icons.question_mark,
                              color: CupertinoColors.systemGrey,
                            ),
                  const SizedBox(width: 6.0),
                  this.pastStatsData is PastStreamData
                      ? Text(
                          'Recording',
                          style: Theme.of(context).textTheme.caption,
                        )
                      : this.pastStatsData is PastRecordData
                          ? Text(
                              'Stream',
                              style: Theme.of(context).textTheme.caption,
                            )
                          : Text(
                              'Unknown',
                              style: Theme.of(context).textTheme.caption,
                            ),
                ],
              ),
            ),
            // StatusDot(
            //   color: this.pastStatsData is PastStreamData
            //       ? CupertinoColors.destructiveRed
            //       : this.pastStatsData is PastRecordData
            //           ? CupertinoColors.activeOrange
            //           : Colors.grey,
            //   text: this.pastStatsData is PastStreamData
            //       ? 'Stream'
            //       : this.pastStatsData is PastRecordData
            //           ? 'Recording'
            //           : 'Unknown',
            //   style: Theme.of(context).textTheme.caption,
            // ),
          ],
        ),
      ),
      onTap: !this.usedInDetail
          ? () => Navigator.pushNamed(
                context,
                StaticticsTabRoutingKeys.Detail.route,
                arguments: this.pastStatsData,
              )
          : null,
      subtitle: Wrap(
        spacing: 8.0,
        runSpacing: 4.0,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 250.0),
            child: StatsDateChip(
              label: 'From:',
              content:
                  '${(this.pastStatsData.listEntryDateMS.last - this.pastStatsData.totalTime! * 1000).millisecondsToFormattedDateString()} - ${(this.pastStatsData.listEntryDateMS.last - this.pastStatsData.totalTime! * 1000).millisecondsToFormattedTimeString()}',
            ),
          ),
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
    );

    return this.usedInDetail
        ? listTile
        : Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: listTile,
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: Icon(
                    Icons.chevron_right,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
  }
}
