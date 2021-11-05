import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../base/divider.dart';

class DatePickerSheet extends StatefulWidget {
  final DateTime? minimumDate;
  final DateTime? maximumDate;
  final DateTime? selectedDate;
  final void Function(DateTime?)? updateDateTime;

  const DatePickerSheet({
    Key? key,
    this.selectedDate,
    this.updateDateTime,
    this.minimumDate,
    this.maximumDate,
  }) : super(key: key);

  @override
  _DatePickerSheetState createState() => _DatePickerSheetState();
}

class _DatePickerSheetState extends State<DatePickerSheet> {
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _date = this.widget.selectedDate ?? _initialDateTime();
  }

  DateTime _initialDateTime() {
    DateTime now = DateTime.now();
    now = DateTime(now.year, now.month, now.day);
    if (this.widget.selectedDate != null) {
      return this.widget.selectedDate!;
    } else {
      if (this.widget.maximumDate != null &&
          this.widget.maximumDate!.isBefore(now)) {
        return this.widget.maximumDate!;
      }
    }
    return now;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CupertinoButton(
              child: const Text(
                'Clear',
                style: TextStyle(
                  color: CupertinoColors.destructiveRed,
                ),
              ),
              onPressed: () {
                this.widget.updateDateTime?.call(null);
                Navigator.of(context, rootNavigator: true).pop();
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CupertinoButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                ),
                CupertinoButton(
                  child: const Text('Save'),
                  onPressed: () {
                    this.widget.updateDateTime?.call(_date);
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                )
              ],
            ),
          ],
        ),
        const BaseDivider(),
        Flexible(
          child: SizedBox(
            height: 250.0,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              initialDateTime: _date,
              minimumDate: this.widget.minimumDate,
              maximumDate: this.widget.maximumDate ?? _initialDateTime(),
              onDateTimeChanged: (dateTime) => _date = dateTime,
            ),
          ),
        ),
      ],
    );
  }
}
