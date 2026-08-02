import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../shared/design/design.dart';
import '../../../../types/extensions/list.dart';
import '../../../../utils/styling_helper.dart';

/// In order to display the graphs in the middle of the coordinate system
/// (if no fix max value is provided), we use this value which
/// will be used to calculate the amount of steps (interval) for y and
/// the amount of "extra" steps after the max value
const int kChartsNormalizedFactor = 3;

class StatsChart extends StatefulWidget {
  final List<double> data;
  final List<int> dataTimesMS;
  final int amountFixedTooltipValue;
  final int amountFixedYAxis;
  final double? yMax;

  /// The minimum interval which should be used: we want to have reasonable
  /// interval steps depending on the possible values for a graph. Since we
  /// have values like RAM usage in GB (0.X values possible) and kbit/s (which
  /// will have values up to 6000+) we want to use different steps which are
  /// "good" depending on the steps. This value will factor the minimum interval
  /// steps used (for example 250 for kbit/s and 0.1 for RAM)
  final double minYInterval;
  final String dataName;
  final String dataUnit;
  final Color chartColor;

  final int streamEndedMS;
  final int totalTime;

  const StatsChart({
    super.key,
    required this.data,
    required this.dataTimesMS,
    this.amountFixedTooltipValue = 0,
    this.amountFixedYAxis = 0,
    this.yMax,
    this.minYInterval = 5,
    required this.dataName,
    this.dataUnit = '',
    this.chartColor = Colors.white,
    required this.streamEndedMS,
    required this.totalTime,
  });

  @override
  State<StatsChart> createState() => _StatsChartState();
}

class _StatsChartState extends State<StatsChart>
    with SingleTickerProviderStateMixin {
  /// One-shot draw-in for the line (and its gradient area) - reveals the
  /// already fully computed spots left to right
  late final AnimationController _drawController;
  late final Animation<double> _draw;

  @override
  void initState() {
    super.initState();
    _drawController = AnimationController(
      vsync: this,
      duration: AppMotion.dramatic,
    );
    _draw = CurvedAnimation(
      parent: _drawController,
      curve: AppMotion.emphasized,
    );
    _drawController.forward();
  }

  @override
  void dispose() {
    _drawController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int streamStart = this.widget.streamEndedMS - this.widget.totalTime * 1000;
    double maxData = this.widget.data.reduce(
          (value, element) => max(value, element),
        );

    double? yInterval = this.widget.yMax != null
        ? (this.widget.yMax! / this.widget.minYInterval)
        : null;
    if (yInterval == null) {
      if (maxData > 0) {
        if (this.widget.minYInterval < 1) {
          yInterval = (((maxData / this.widget.minYInterval) /
                      kChartsNormalizedFactor) *
                  this.widget.minYInterval)
              .toDouble();
        } else {
          yInterval = (((maxData / this.widget.minYInterval) ~/
                      kChartsNormalizedFactor) *
                  this.widget.minYInterval)
              .toDouble();
        }
      }
    }

    yInterval = yInterval != null && yInterval > 0
        ? yInterval
        : this.widget.minYInterval;

    /// All spots computed over the full data set - the draw-in animation
    /// only changes how many of them are shown, never their positions
    final List<FlSpot> allSpots = this
        .widget
        .data
        .mapIndexed(
          (data, index) => FlSpot(
              streamStart +
                  ((this.widget.totalTime * 1000) / this.widget.data.length) *
                      index,
              data.toDouble()),
        )
        .toList();

    final Color dividerColor =
        Theme.of(context).dividerTheme.color ?? StylingHelper.light_divider_color;

    TextStyle tooltipTextStyle =
        Theme.of(context).textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.w600,
              fontFeatures: const [
                FontFeature.tabularFigures(),
              ],
            );
    TextStyle tooltipTimeTextStyle =
        Theme.of(context).textTheme.bodySmall!.copyWith(
              fontSize: 11.0,
              fontFeatures: const [
                FontFeature.tabularFigures(),
              ],
            );
    TextStyle axisStepsTextStyle =
        Theme.of(context).textTheme.bodySmall!.copyWith(
              fontSize: 11.0,
              fontWeight: FontWeight.w500,
              fontFeatures: const [
                FontFeature.tabularFigures(),
              ],
            );
    TextStyle axisTitleTextStyle = Theme.of(context).textTheme.titleMedium!;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          child: Text(
            this.widget.dataName,
            style: axisTitleTextStyle,
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 250.0,
          ),
          child: AnimatedBuilder(
            animation: _draw,
            builder: (context, child) {
              final int visibleSpots = max(
                min(2, allSpots.length),
                (_draw.value * allSpots.length).round(),
              );

              return LineChart(
                LineChartData(
                  minY: 0.0,
                  maxY: this.widget.yMax ??
                      ((maxData ~/ yInterval!) + kChartsNormalizedFactor) *
                          yInterval,
                  minX: streamStart.toDouble(),
                  maxX: this.widget.streamEndedMS.toDouble(),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(
                        color: dividerColor.withValues(alpha: 0.2),
                        width: 1,
                      ),
                      left: BorderSide(
                        color: dividerColor.withValues(alpha: 0.2),
                        width: 1,
                      ),
                      right: const BorderSide(
                        color: Colors.transparent,
                      ),
                      top: const BorderSide(
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) =>
                          Theme.of(context).cardColor,
                      tooltipBorderRadius: BorderRadius.circular(AppRadius.md),
                      tooltipBorder: BorderSide(
                        color: dividerColor.withValues(alpha: 0.4),
                      ),
                      fitInsideHorizontally: true,
                      getTooltipItems: (touchedSpots) => touchedSpots
                          .map(
                            (touchSpot) => LineTooltipItem(
                              '${touchSpot.y.toStringAsFixed(this.widget.amountFixedTooltipValue)}${this.widget.dataUnit}\n',
                              tooltipTextStyle,
                              children: [
                                TextSpan(
                                  text: DateFormat.Hms('de_DE').format(
                                    DateTime.fromMillisecondsSinceEpoch(
                                      touchSpot.x.round(),
                                    ),
                                  ),
                                  style: tooltipTimeTextStyle,
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: yInterval,
                        reservedSize: 48.0,
                        getTitlesWidget: (interval, titleMeta) => Text(
                          interval.toStringAsFixed(
                                  this.widget.amountFixedYAxis) +
                              this.widget.dataUnit,
                          style: axisStepsTextStyle,
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: (this.widget.totalTime * 1000) / 4.5,
                        reservedSize: 32.0,
                        getTitlesWidget: (interval, titleMeta) {
                          if (interval == titleMeta.min ||
                              interval == titleMeta.max) {
                            return Container();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.sm),
                            child: Text(
                              DateFormat.Hm('de_DE').format(
                                DateTime.fromMillisecondsSinceEpoch(
                                  interval.round(),
                                ),
                              ),
                              style: axisStepsTextStyle,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false,
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false,
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: allSpots.sublist(0, visibleSpots),
                      color: this.widget.chartColor,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      isCurved: true,
                      curveSmoothness: 0.2,
                      dotData: const FlDotData(
                        show: false,
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            this
                                .widget
                                .chartColor
                                .withValues(alpha: 0.28 * _draw.value),
                            this.widget.chartColor.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
                duration: Duration.zero,
              );
            },
          ),
        ),
      ],
    );
  }
}
