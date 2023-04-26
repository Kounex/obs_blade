import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_blade/models/past_record_data.dart';
import 'package:obs_blade/models/past_stream_data.dart';
import 'package:obs_blade/shared/tag_box.dart';
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
    return Padding(
      padding: EdgeInsets.symmetric(vertical: !this.usedInDetail ? 8.0 : 0),
      child: Stack(
        children: [
          this.pastStatsData.starred != null && this.pastStatsData.starred!
              ? const Positioned(
                  top: 4,
                  right: 12,
                  child: Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 28.0,
                  ),
                )
              : const SizedBox(),
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
  }
}
