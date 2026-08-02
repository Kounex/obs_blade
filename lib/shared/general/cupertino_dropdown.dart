import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/utils/styling_helper.dart';

class CupertinoDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>>? items;
  final List<Widget> Function(BuildContext)? selectedItemBuilder;
  final void Function(T?)? onChanged;

  const CupertinoDropdown({
    super.key,
    this.value,
    this.items,
    this.selectedItemBuilder,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        /// Dirty workaround... but I mean it works and is minimalistic :x
        /// I want the dopdown to look just like the other textfields and instead
        /// of writing "unnecessary" code to immitate the look and feel of them
        /// I just use it for the visual part. By setting it to readonly it will
        /// not have any focus and should not interfere in any way
        ///
        /// Explicit decoration - the stock one renders pure black in dark
        /// mode; this matches the raised card surface + hairline used by
        /// the other fields
        CupertinoTextField(
          readOnly: true,
          decoration: BoxDecoration(
            color: StylingHelper.lightenDarkenColor(
                Theme.of(context).cardColor, 8),
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 0.5,
            ),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
        Container(
          padding: const EdgeInsets.only(
            left: 10.0,
            top: 4.0,
            bottom: 4.0,
            right: 2.0,
          ),
          child: DropdownButton<T>(
            underline: const SizedBox(),
            isExpanded: true,
            isDense: true,
            value: this.value,
            icon: const Icon(Icons.keyboard_arrow_down),
            borderRadius: BorderRadius.circular(AppRadius.md),
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
