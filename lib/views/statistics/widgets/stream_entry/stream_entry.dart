import 'package:flutter/material.dart';
import 'package:obs_blade/views/statistics/widgets/stream_entry/stream_date_chip.dart';

import '../../../../models/past_stream_data.dart';
import '../../../../types/extensions/int.dart';
import '../../../../utils/routing_helper.dart';

class StreamEntry extends StatelessWidget {
  final PastStreamData pastStreamData;
  final bool usedInDetail;

  const StreamEntry({
    Key? key,
    required this.pastStreamData,
    this.usedInDetail = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget listTile = ListTile(
      title: Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Icon(
                this.pastStreamData.starred != null &&
                        this.pastStreamData.starred!
                    ? Icons.star
                    : Icons.star_border,
              ),
            ),
            Expanded(
              child: Text(
                this.pastStreamData.name ?? 'Unnamed stream',
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
      ),
      onTap: !this.usedInDetail
          ? () => Navigator.pushNamed(
                context,
                StaticticsTabRoutingKeys.Detail.route,
                arguments: this.pastStreamData,
              )
          : null,
      subtitle: Wrap(
        spacing: 8.0,
        runSpacing: 4.0,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 250.0),
            child: StreamDateChip(
              label: 'From:',
              content:
                  '${(this.pastStreamData.listEntryDateMS.last - this.pastStreamData.totalStreamTime! * 1000).millisecondsToFormattedDateString()} - ${(this.pastStreamData.listEntryDateMS.last - this.pastStreamData.totalStreamTime! * 1000).millisecondsToFormattedTimeString()}',
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 250.0),
            child: StreamDateChip(
              label: 'To:',
              content:
                  '${this.pastStreamData.listEntryDateMS.last.millisecondsToFormattedDateString()} - ${this.pastStreamData.listEntryDateMS.last.millisecondsToFormattedTimeString()}',
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
