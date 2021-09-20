import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CupertinoDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>>? items;
  final List<Widget> Function(BuildContext)? selectedItemBuilder;
  final void Function(T?)? onChanged;

  const CupertinoDropdown({
    Key? key,
    this.value,
    this.items,
    this.selectedItemBuilder,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        /// Dirty workaround... but I mean it works and is minimalistic :x
        /// I want the dopdown to look just like the other textfields and instead
        /// of writing "unnecessary" code to immitate the look and feel of them
        /// I just use it for the visual part. By setting it to readonly it will
        /// not have any focus and should not interfere in any way
        const CupertinoTextField(readOnly: true),
        Container(
          padding: const EdgeInsets.only(
              left: 6.0, top: 4.0, bottom: 4.0, right: 2.0),
          child: DropdownButton<T>(
            underline: Container(),
            isExpanded: true,
            isDense: true,
            value: this.value,
            dropdownColor: Theme.of(context).scaffoldBackgroundColor,
            items: this.items,
            selectedItemBuilder: this.selectedItemBuilder,
            onChanged: this.onChanged,
          ),
        ),
      ],
    );
  }
}
