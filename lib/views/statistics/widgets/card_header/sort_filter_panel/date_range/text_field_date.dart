import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../../utils/modal_handler.dart';
import 'date_picker_sheet.dart';

class TextFieldDate extends StatefulWidget {
  final String placeholder;
  final DateTime selectedDate;
  final DateTime minimumDate;
  final DateTime maximumDate;
  final void Function(DateTime) updateDateTime;

  TextFieldDate({
    @required this.selectedDate,
    @required this.updateDateTime,
    this.placeholder,
    this.minimumDate,
    this.maximumDate,
  });

  @override
  _TextFieldDateState createState() => _TextFieldDateState();
}

class _TextFieldDateState extends State<TextFieldDate> {
  TextEditingController _controller;

  @override
  void initState() {
    _controller = TextEditingController(text: widget.selectedDate?.toString());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      controller: _controller,
      clearButtonMode: OverlayVisibilityMode.always,
      placeholder: widget.placeholder,
      readOnly: true,
      onTap: () => ModalHandler.showBaseBottomSheet(
        context: context,
        modalWidget: DatePickerSheet(
          selectedDate: widget.selectedDate,
          minimumDate: widget.minimumDate,
          maximumDate: widget.maximumDate,
          updateDateTime: (date) {
            _controller.text =
                date == null ? '' : DateFormat.yMd('de_DE').format(date);
            widget.updateDateTime(date);
          },
        ),
      ),
      onChanged: (_) => widget.updateDateTime(null),
    );
  }
}
