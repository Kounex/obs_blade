import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:provider/provider.dart';

import '../../../../../../stores/views/statistics.dart';
import 'text_field_date.dart';

class DateRange extends StatelessWidget {
  final DateTime? selectedFromDate;
  final DateTime? selectedToDate;

  final DateTime? minimumFromDate;
  final DateTime maximumFromDate;

  final DateTime? minimumToDate;
  final DateTime? maximumToDate;

  final void Function(DateTime?)? updateFromDate;
  final void Function(DateTime?)? updateToDate;

  final String placeholderFrom;
  final String placeholderTo;

  DateRange({
    this.selectedFromDate,
    this.selectedToDate,
    this.minimumFromDate,
    DateTime? maximumFromDate,
    DateTime? minimumToDate,
    this.maximumToDate,
    this.updateFromDate,
    this.updateToDate,
    this.placeholderFrom = 'From...',
    this.placeholderTo = 'To...',
  })  : this.maximumFromDate = selectedToDate ?? DateTime.now(),
        this.minimumToDate = selectedFromDate;

  @override
  Widget build(BuildContext context) {
    StatisticsStore statisticsStore = context.read<StatisticsStore>();

    return Observer(
      builder: (_) => Row(
        children: [
          Expanded(
            child: TextFieldDate(
              placeholder: 'From...',
              selectedDate: statisticsStore.fromDate,
              maximumDate: statisticsStore.toDate,
              updateDateTime: (date) => statisticsStore.setFromDate(date),
            ),
          ),
          SizedBox(width: 12.0),
          Expanded(
            child: TextFieldDate(
              placeholder: 'To...',
              selectedDate: statisticsStore.toDate,
              minimumDate: statisticsStore.fromDate,
              updateDateTime: (date) => statisticsStore.setToDate(date
                  ?.add(Duration(days: 1))
                  .subtract(Duration(milliseconds: 1))),
            ),
          ),
        ],
      ),
    );
  }
}
