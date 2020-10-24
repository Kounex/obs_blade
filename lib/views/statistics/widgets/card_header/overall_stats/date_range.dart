import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_blade/utils/modal_handler.dart';
import 'package:obs_blade/views/settings/widgets/action_block.dart/light_divider.dart';

class DateRange extends StatefulWidget {
  @override
  _DateRangeState createState() => _DateRangeState();
}

class _DateRangeState extends State<DateRange> {
  TextEditingController _fromDateTextController = TextEditingController();
  TextEditingController _toDateTextController = TextEditingController();

  DateTime fromDate;
  DateTime toDate;

  Widget _datePickerSheet(BuildContext context,
          TextEditingController controller, DateTime date) =>
      SizedBox(
        height: MediaQuery.of(context).size.height / 3,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CupertinoButton(
                  child: Text(
                    'Clear',
                    style: TextStyle(
                      color: CupertinoColors.destructiveRed,
                    ),
                  ),
                  onPressed: () {
                    controller.text = '';
                    date = null;
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                ),
                CupertinoButton(
                  child: Text('Save'),
                  onPressed: () {
                    controller.text = date.toString();
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                )
              ],
            ),
            LightDivider(),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: date,
                onDateTimeChanged: (dateTime) =>
                    setState(() => date = dateTime),
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CupertinoTextField(
            controller: _fromDateTextController,
            placeholder: 'From...',
            readOnly: true,
            onTap: () => ModalHandler.showBaseBottomSheet(
              context: context,
              modalWidget:
                  _datePickerSheet(context, _fromDateTextController, fromDate),
            ),
          ),
        ),
        SizedBox(width: 12.0),
        Expanded(
          child: CupertinoTextField(
            controller: _toDateTextController,
            placeholder: 'To...',
          ),
        ),
      ],
    );
  }
}
