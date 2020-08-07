import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:obs_blade/utils/styling_helper.dart';
import '../../../../models/past_stream_data.dart';
import '../../../../types/extensions/list.dart';

class StreamChart extends StatelessWidget {
  final PastStreamData pastStreamData;

  StreamChart({@required this.pastStreamData}) : assert(pastStreamData != null);

  @override
  Widget build(BuildContext context) {
    int streamStart =
        this.pastStreamData.streamEndedMS - this.pastStreamData.totalStreamTime;
    double maxFPS = this.pastStreamData.fpsList.reduce(
          (value, element) => max(value, element),
        );
    TextStyle tooltipTextStyle = Theme.of(context).textTheme.bodyText1;
    TextStyle axisStepsTextStyle = Theme.of(context).textTheme.caption;
    TextStyle axisTitleTextStyle = Theme.of(context).textTheme.subtitle1;

    return LineChart(
      LineChartData(
        minY: 0.0,
        maxY: maxFPS + 20.0,
        minX: (this.pastStreamData.streamEndedMS -
                this.pastStreamData.totalStreamTime)
            .toDouble(),
        maxX: this.pastStreamData.streamEndedMS.toDouble(),
        axisTitleData: FlAxisTitleData(
          leftTitle: AxisTitle(
            showTitle: true,
            titleText: 'FPS',
            textStyle: axisTitleTextStyle,
            reservedSize: 20.0,
          ),
          bottomTitle: AxisTitle(
            showTitle: true,
            titleText: 'Time',
            textStyle: axisTitleTextStyle,
            reservedSize: 20.0,
          ),
        ),
        gridData: FlGridData(show: false),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(
              color: StylingHelper.LIGHT_DIVIDER_COLOR.withOpacity(0.2),
              width: 1,
            ),
            left: BorderSide(
              color: StylingHelper.LIGHT_DIVIDER_COLOR.withOpacity(0.2),
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
            tooltipBgColor: Colors.black,
            getTooltipItems: (touchedSpots) => touchedSpots
                .map(
                  (touchSpot) => LineTooltipItem(
                      '${touchSpot.y.round().toString()}\n${DateFormat.Hm('en_US').format(DateTime.fromMillisecondsSinceEpoch(touchSpot.x.round()))}',
                      tooltipTextStyle),
                )
                .toList(),
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: SideTitles(
            showTitles: true,
            margin: 10.0,
            textStyle: axisStepsTextStyle,
            interval: 20.0,
            getTitles: (interval) => interval.round().toString(),
          ),
          bottomTitles: SideTitles(
            showTitles: true,
            margin: 10.0,
            textStyle: axisStepsTextStyle,
            interval: this.pastStreamData.totalStreamTime / 5,
            getTitles: (interval) => DateFormat.Hm('en_US').format(
              DateTime.fromMillisecondsSinceEpoch(
                interval.round(),
              ),
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: this.pastStreamData.fpsList.mapIndexed(
              (fps, index) {
                print(fps);
                return FlSpot(
                    streamStart +
                        (this.pastStreamData.totalStreamTime /
                                this.pastStreamData.fpsList.length) *
                            index,
                    fps.round().toDouble());
              },
            ).toList(),
            isCurved: true,
            colors: [
              const Color(0xff4af699),
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
    );
  }
}
