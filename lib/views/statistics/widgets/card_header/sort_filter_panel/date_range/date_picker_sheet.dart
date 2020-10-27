import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../settings/widgets/action_block.dart/light_divider.dart';

class DatePickerSheet extends StatefulWidget {
  final DateTime minimumDate;
  final DateTime maximumDate;
  final DateTime selectedDate;
  final void Function(DateTime) updateDateTime;

  DatePickerSheet({
    @required this.selectedDate,
    @required this.updateDateTime,
    this.minimumDate,
    this.maximumDate,
  });

  @override
  _DatePickerSheetState createState() => _DatePickerSheetState();
}

class _DatePickerSheetState extends State<DatePickerSheet> {
  DateTime _date;

  @override
  void initState() {
    super.initState();
    _date = widget.selectedDate ?? _initialDateTime();
  }

  DateTime _initialDateTime() {
    DateTime now = DateTime.now();
    now = DateTime(now.year, now.month, now.day);
    if (widget.selectedDate != null) {
      return widget.selectedDate;
    } else {
      if (widget.maximumDate != null && widget.maximumDate.isBefore(now)) {
        return widget.maximumDate;
      }
    }
    return now;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height / 3,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CupertinoButton(
                child: Text(
                  'Clear',
                  style: TextStyle(
                    color: CupertinoColors.destructiveRed,
                  ),
                ),
                onPressed: () {
                  this.widget.updateDateTime(null);
                  Navigator.of(context, rootNavigator: true).pop();
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CupertinoButton(
                    child: Text('Cancel'),
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).pop();
                    },
                  ),
                  CupertinoButton(
                    child: Text('Save'),
                    onPressed: () {
                      this.widget.updateDateTime(_date);
                      Navigator.of(context, rootNavigator: true).pop();
                    },
                  )
                ],
              ),
            ],
          ),
          LightDivider(),
          Expanded(
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              initialDateTime: _date,
              minimumDate: widget.minimumDate,
              maximumDate: widget.maximumDate ?? _initialDateTime(),
              onDateTimeChanged: (dateTime) => _date = dateTime,
            ),
          ),
        ],
      ),
    );
  }
}
