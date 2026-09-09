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
                child: ScaleTransition(scale: animation, child: child),
              ),
              child: isStarred
                  ? Icon(
                      Icons.star,
                      key: const ValueKey('starred'),
                      color: Theme.of(
                        context,
                      ).extension<AppStatusColors>()!.favorite,
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
                          style: Theme.of(context).textTheme.labelLarge!
                              .copyWith(
                                fontSize: 18.0,
                                color: this.pastStatsData.name == null
                                    ? Theme.of(context)
                                          .extension<AppTextColors>()!
                                          .textSecondary
                                    : null,
                              ),
                          maxLines: 2,
                          softWrap: true,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8.0),
                        Padding(
                          padding: const EdgeInsets.only(left: 0.0),
                          child: Builder(
                            builder: (context) {
                              final ThemeData theme = Theme.of(context);
                              final AppStatusColors statusColors = theme
                                  .extension<AppStatusColors>()!;
                              final AppTextColors textColors = theme
                                  .extension<AppTextColors>()!;
                              final bool isStream =
                                  this.pastStatsData is PastStreamData;
                              final bool isRecord =
                                  this.pastStatsData is PastRecordData;

                              /// Tint + brightened-text chip idiom
                              /// (token-delta §2.3): 16% status/highlight
                              /// tint carrying the …Text derivative -
                              /// same pattern as the saved-connection
                              /// Offline badge, never a solid fill
                              final Color chipText = isStream
                                  ? textColors.highlightText
                                  : isRecord
                                  ? statusColors.recordingText
                                  : textColors.textSecondary;
                              return TagBox(
                                expand: false,
                                color: isStream
                                    ? theme.colorScheme.secondary.withValues(
                                        alpha: 0.16,
                                      )
                                    : isRecord
                                    ? statusColors.recording.withValues(
                                        alpha: 0.16,
                                      )
                                    : Colors.white.withValues(alpha: 0.12),
                                icon: Icon(
                                  isStream
                                      ? CupertinoIcons.dot_radiowaves_left_right
                                      : isRecord
                                      ? CupertinoIcons.recordingtape
                                      : Icons.question_mark,
                                  size: 18.0,
                                  color: chipText,
                                ),
                                label: isStream
                                    ? 'Stream'
                                    : isRecord
                                    ? 'Recording'
                                    : 'Unknown',
                                labelStyle: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .copyWith(color: chipText),
                              );
                            },
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
                  ? Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Icon(
                        Icons.chevron_right,
                        color: Theme.of(
                          context,
                        ).extension<AppTextColors>()!.textTertiary,
                      ),
                    )
                  : const SizedBox(),
            ],
          ),
        ],
      ),
    );

    if (!this.usedInDetail) {
      /// List entries flash like settings rows (token-delta press
      /// grammar), scale is for elements with real travel
      entry = PressFlash(
        onTap: () => Navigator.pushNamed(
          context,
          StaticticsTabRoutingKeys.Detail.route,
          arguments: this.pastStatsData,
        ),
        child: entry,
      );
    }

    return entry;
  }
}
