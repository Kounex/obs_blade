import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

import '../../../../../../utils/modal_handler.dart';
import 'date_picker_sheet.dart';

class TextFieldDate extends StatelessWidget {
  final String? placeholder;
  final DateTime? selectedDate;
  final DateTime? minimumDate;
  final DateTime? maximumDate;
  final void Function(DateTime?)? updateDateTime;

  // ignore: prefer_const_constructors_in_immutables
  TextFieldDate({
    Key? key,
    required this.selectedDate,
    required this.updateDateTime,
    this.placeholder,
    this.minimumDate,
    this.maximumDate,
  }) : super(key: key);

  late final TextEditingController _controller;

  @override
  Widget build(BuildContext context) {
    _controller = TextEditingController(
        text: this.selectedDate != null
            ? DateFormat.yMd('de_DE').format(this.selectedDate!)
            : '');

    return CupertinoTextField(
      controller: _controller,
      clearButtonMode: OverlayVisibilityMode.always,
      placeholder: this.placeholder,
      readOnly: true,
      onTap: () => ModalHandler.showBaseBottomSheet(
        context: context,
        modalWidget: DatePickerSheet(
          selectedDate: this.selectedDate,
          minimumDate: this.minimumDate,
          maximumDate: this.maximumDate,
          updateDateTime: (date) {
            _controller.text =
                date == null ? '' : DateFormat.yMd('de_DE').format(date);
            this.updateDateTime?.call(date);
          },
        ),
      ),
      onChanged: (_) => this.updateDateTime?.call(null),
    );
  }
}
