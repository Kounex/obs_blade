import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import '../../../../../stores/views/statistics.dart';

const List<FilterType> kActiveFilterTypes = [
  FilterType.Name,
  FilterType.StatisticTime,
  FilterType.TotalTime,
];

class OrderRow extends StatefulWidget {
  @override
  _OrderRowState createState() => _OrderRowState();
}

class _OrderRowState extends State<OrderRow> with TickerProviderStateMixin {
  AnimationController _controllerUp;
  AnimationController _controllerDown;

  Animation<double> _halfTurnUp;
  Animation<double> _halfTurnDown;

  @override
  void initState() {
    super.initState();

    _controllerUp =
        AnimationController(vsync: this, duration: Duration(milliseconds: 250));

    _controllerDown =
        AnimationController(vsync: this, duration: Duration(milliseconds: 250));

    _halfTurnUp = Tween<double>(begin: 0.0, end: 0.5).animate(
        CurvedAnimation(parent: _controllerUp, curve: Curves.easeOutCubic));

    _halfTurnDown = Tween<double>(begin: 0.0, end: 0.5).animate(
        CurvedAnimation(parent: _controllerDown, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controllerUp.dispose();
    _controllerDown.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    StatisticsStore statisticsStore = context.watch<StatisticsStore>();

    return Row(
      children: [
        Expanded(
          child: Stack(
            children: [
              /// Dirty workaround... but I mean it works and is minimalistic :x
              /// I want the dopdown to look just like the other textfields and instead
              /// of writing "unnecessary" code to immitate the look and feel of them
              /// I just use it for the visual part. By setting it to readonly it will
              /// not have any focus and should not interfere in any way
              CupertinoTextField(readOnly: true),
              Observer(
                builder: (_) => Container(
                  padding: EdgeInsets.only(
                      left: 6.0, top: 4.0, bottom: 4.0, right: 2.0),
                  child: DropdownButton<FilterType>(
                    underline: Container(),
                    isExpanded: true,
                    isDense: true,
                    value: statisticsStore.filterType,
                    dropdownColor: Theme.of(context).scaffoldBackgroundColor,
                    items: FilterType.values
                        .where((filterType) =>
                            kActiveFilterTypes.contains(filterType))
                        .map(
                          (filterType) => DropdownMenuItem<FilterType>(
                            value: filterType,
                            child: Text(filterType.text),
                          ),
                        )
                        .toList(),
                    selectedItemBuilder: (context) => FilterType.values
                        .map(
                          (filterType) => Text(filterType.text),
                        )
                        .toList(),
                    onChanged: (filterType) =>
                        statisticsStore.setFilterType(filterType),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 14.0),
          child: GestureDetector(
            onTap: () {
              if (!_controllerDown.isAnimating && !_controllerUp.isAnimating) {
                statisticsStore.toggleFilterOrder();
                if (_controllerUp.isDismissed) {
                  _controllerUp.forward();
                } else if (_controllerDown.isDismissed) {
                  _controllerDown.forward().then((value) {
                    _controllerUp.reset();
                    _controllerDown.reset();
                  });
                }
              }
            },
            child: Container(
              padding: EdgeInsets.all(4.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).accentColor,
              ),
              child: AnimatedBuilder(
                animation: _controllerUp,
                child: AnimatedBuilder(
                  animation: _controllerDown,
                  child: Icon(
                    CupertinoIcons.down_arrow,
                    size: 22.0,
                  ),
                  builder: (context, child) => RotationTransition(
                    turns: _halfTurnDown,
                    child: child,
                  ),
                ),
                builder: (context, child) => RotationTransition(
                  turns: _halfTurnUp,
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
