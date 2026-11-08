import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../design/design.dart';
import '../base/sheet.dart';

class DatePickerSheet extends StatefulWidget {
  final DateTime? minimumDate;
  final DateTime? maximumDate;
  final DateTime? selectedDate;
  final void Function(DateTime?)? updateDateTime;

  const DatePickerSheet({
    super.key,
    this.selectedDate,
    this.updateDateTime,
    this.minimumDate,
    this.maximumDate,
  });

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
    return BaseSheetScaffold(
      header: BaseSheetTitle(
        'Date',
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: const EdgeInsets.only(left: AppSpacing.lg),
              onPressed: () {
                this.widget.updateDateTime?.call(null);
                Navigator.of(context).pop();
              },
              child: Text(
                'Clear',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).extension<AppStatusColors>()!.destructiveText,
                ),
              ),
            ),
            CupertinoButton(
              padding: const EdgeInsets.only(left: AppSpacing.lg),
              onPressed: () {
                this.widget.updateDateTime?.call(_date);
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
      body: SizedBox(
        height: 216.0,
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.date,
          initialDateTime: _date,
          minimumDate: this.widget.minimumDate,
          maximumDate: this.widget.maximumDate ?? _initialDateTime(),
          onDateTimeChanged: (dateTime) => _date = dateTime,
        ),
      ),
    );
  }
}
