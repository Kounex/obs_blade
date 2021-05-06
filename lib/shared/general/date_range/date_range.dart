import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
    return Row(
      children: [
        Expanded(
          child: TextFieldDate(
            placeholder: this.placeholderFrom,
            selectedDate: this.selectedFromDate,
            minimumDate: this.minimumFromDate,
            maximumDate: this.maximumFromDate,
            updateDateTime: this.updateFromDate,
          ),
        ),
        SizedBox(width: 12.0),
        Expanded(
          child: TextFieldDate(
            placeholder: this.placeholderTo,
            selectedDate: this.selectedToDate,
            minimumDate: this.minimumToDate,
            maximumDate: this.maximumToDate,
            updateDateTime: this.updateToDate,
          ),
        ),
      ],
    );
  }
}
