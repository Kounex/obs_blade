import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:obs_blade/utils/styling_helper.dart';
import '../../../../../types/extensions/list.dart';

class StreamChart extends StatelessWidget {
  final List<double> data;
  final List<int> dataTimesMS;
  final int amountFixedTooltipValue;
  final int amountFixedYAxis;
  final double yPuffer;
  final double yMax;
  final double yInterval;
  final String dataName;
  final String dataUnit;
  final Color chartColor;

  final int streamEndedMS;
  final int totalStreamTime;

  StreamChart({
    @required this.data,
    @required this.dataTimesMS,
    this.amountFixedTooltipValue = 0,
    this.amountFixedYAxis = 0,
    this.yMax,
    this.yPuffer = 20,
    this.yInterval = 20,
    @required this.dataName,
    this.dataUnit = '',
    this.chartColor = Colors.white,
    @required this.streamEndedMS,
    @required this.totalStreamTime,
  }) : assert(data != null && streamEndedMS != null && totalStreamTime != null);

  @override
  Widget build(BuildContext context) {
    int streamStart = this.streamEndedMS - this.totalStreamTime * 1000;
    double maxData = this.data.reduce(
          (value, element) => max(value, element),
        );
    TextStyle tooltipTextStyle = Theme.of(context).textTheme.bodyText1;
    TextStyle axisStepsTextStyle = Theme.of(context).textTheme.caption;
    TextStyle axisTitleTextStyle = Theme.of(context).textTheme.subtitle1;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: Text(
            this.dataName,
            style: Theme.of(context).textTheme.headline6,
          ),
        ),
        LineChart(
          LineChartData(
            minY: 0.0,
            maxY: (this.yMax ?? maxData.toDouble()) + this.yPuffer,
            minX: streamStart.toDouble(),
            maxX: this.streamEndedMS.toDouble(),
            axisTitleData: FlAxisTitleData(
              leftTitle: AxisTitle(
                showTitle: true,
                // titleText: this.dataName,
                textStyle: axisTitleTextStyle,
                reservedSize: 2.0,
                margin: 0.0,
              ),
              bottomTitle: AxisTitle(
                showTitle: false,
                titleText: 'Time',
                textStyle: axisTitleTextStyle,
                reservedSize: 20.0,
                margin: 20.0,
              ),
            ),
            gridData: FlGridData(show: false),
            borderData: FlBorderData(
              show: true,
              border: Border(
                bottom: BorderSide(
                  color: StylingHelper.light_divider_color.withOpacity(0.2),
                  width: 1,
                ),
                left: BorderSide(
                  color: StylingHelper.light_divider_color.withOpacity(0.2),
                  width: 1,
                ),
                right: BorderSide(
                  color: Colors.transparent,
                ),
                top: BorderSide(
                  color: Colors.transparent,
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                tooltipBgColor: Theme.of(context).cardColor,
                getTooltipItems: (touchedSpots) => touchedSpots
                    .map(
                      (touchSpot) => LineTooltipItem(
                          '${touchSpot.y.toStringAsFixed(this.amountFixedTooltipValue)}${this.dataUnit}\n${DateFormat.Hms('de_DE').format(DateTime.fromMillisecondsSinceEpoch(touchSpot.x.round()))}',
                          tooltipTextStyle),
                    )
                    .toList(),
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: SideTitles(
                showTitles: true,
                margin: 15.0,
                textStyle: axisStepsTextStyle,
                interval: this.yInterval,
                getTitles: (interval) =>
                    interval.toStringAsFixed(this.amountFixedYAxis) +
                    this.dataUnit,
              ),
              bottomTitles: SideTitles(
                showTitles: true,
                margin: 15.0,
                textStyle: axisStepsTextStyle,
                interval: (this.totalStreamTime * 1000) / 5,
                getTitles: (interval) => DateFormat.Hm('de_DE').format(
                  DateTime.fromMillisecondsSinceEpoch(
                    interval.round(),
                  ),
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: this
                    .data
                    .mapIndexed(
                      (data, index) => FlSpot(
                          streamStart +
                              ((this.totalStreamTime * 1000) /
                                      this.data.length) *
                                  index,
                          data.toDouble()),
                    )
                    .toList(),
                colors: [
                  this.chartColor,
                ],
                barWidth: 2,
                isStrokeCapRound: false,
                dotData: FlDotData(
                  show: false,
                ),
                belowBarData: BarAreaData(
                  show: false,
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}
