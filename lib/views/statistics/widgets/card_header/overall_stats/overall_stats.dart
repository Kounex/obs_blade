import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_blade/views/statistics/widgets/card_header/overall_stats/amount_entries_control.dart';
import 'package:obs_blade/views/statistics/widgets/card_header/overall_stats/favorite_control.dart';
import 'package:obs_blade/views/statistics/widgets/card_header/overall_stats/filter_name.dart';

import '../card_header.dart';
import 'date_range/date_range.dart';
import 'order_row.dart';

const double _kControlsPadding = 12.0;

class OverallStats extends StatefulWidget {
  final StatsType statsType;

  OverallStats({this.statsType = StatsType.Current});

  @override
  _OverallStatsState createState() => _OverallStatsState();
}

class _OverallStatsState extends State<OverallStats> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];

    if (widget.statsType == StatsType.Current) {
      children.add(Text('Current'));
    } else {
      children.add(SizedBox(height: _kControlsPadding));
      children.add(OrderRow());
      children.add(SizedBox(height: _kControlsPadding));
      children.add(FilterName());
      children.add(SizedBox(height: _kControlsPadding));
      children.add(DateRange());
      children.add(SizedBox(height: _kControlsPadding));
      children.add(FavoriteControl());
      children.add(SizedBox(height: _kControlsPadding));
      children.add(AmountEntriesControl());
    }

    return Column(
      children: [
        Divider(height: 1.0),
        ExpansionPanelList(
          elevation: 0,
          expandedHeaderPadding: const EdgeInsets.all(0),
          expansionCallback: (_, __) =>
              setState(() => _isExpanded = !_isExpanded),
          children: [
            ExpansionPanel(
              isExpanded: _isExpanded,
              headerBuilder: (context, isExpanded) => Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 14.0),
                  child: Text('OMEGALUL'),
                ),
              ),
              body: SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    Divider(height: 1.0),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 14.0,
                        right: 14.0,
                        bottom: 12.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: children,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
