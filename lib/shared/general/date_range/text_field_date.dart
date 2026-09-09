import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../../utils/modal_handler.dart';
import 'date_picker_sheet.dart';

class TextFieldDate extends StatefulWidget {
  final String? placeholder;
  final DateTime? selectedDate;
  final DateTime? minimumDate;
  final DateTime? maximumDate;
  final void Function(DateTime?)? updateDateTime;

  const TextFieldDate({
    super.key,
    required this.selectedDate,
    required this.updateDateTime,
    this.placeholder,
    this.minimumDate,
    this.maximumDate,
  });

  @override
  State<TextFieldDate> createState() => _TextFieldDateState();
}

class _TextFieldDateState extends State<TextFieldDate> {
  late final TextEditingController _controller;

  String _format(DateTime? date) =>
      date != null ? DateFormat.yMd('de_DE').format(date) : '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _format(widget.selectedDate));
  }

  @override
  void didUpdateWidget(TextFieldDate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _controller.text = _format(widget.selectedDate);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      controller: _controller,

      /// Only offer clearing once a date is actually selected
      clearButtonMode: widget.selectedDate != null
          ? OverlayVisibilityMode.always
          : OverlayVisibilityMode.never,
      placeholder: widget.placeholder,
      style: Theme.of(context).textTheme.bodyMedium,
      readOnly: true,
      onTap: () => ModalHandler.showBaseBottomSheet(
        context: context,
        builder: (context) => DatePickerSheet(
          selectedDate: widget.selectedDate,
          minimumDate: widget.minimumDate,
          maximumDate: widget.maximumDate,
          updateDateTime: (date) {
            _controller.text = _format(date);
            widget.updateDateTime?.call(date);
          },
        ),
      ),
      onChanged: (_) => widget.updateDateTime?.call(null),
    );
  }
}
