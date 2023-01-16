import 'package:flutter/material.dart';

class BaseDropdownItem<T> {
  final T value;
  final String? text;
  final Widget? widget;

  BaseDropdownItem({required this.value, this.text, this.widget})
      : assert(text != null || widget != null);
}

class BaseDropdown<T> extends StatelessWidget {
  final T? value;
  final List<BaseDropdownItem<T>>? items;

  final void Function(T? value)? onChanged;

  final Alignment? alignment;

  final bool? isDense;
  final String? label;
  final double? minWidth;

  const BaseDropdown({
    super.key,
    required this.value,
    required this.items,
    this.onChanged,
    this.alignment,
    this.isDense,
    this.label,
    this.minWidth,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Align(
        alignment: this.alignment ?? Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            this.label != null
                ? Text(
                    this.label!,
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                : const SizedBox(),
            DropdownButton<T>(
              value: this.value,
              isDense: true,
              onChanged: this.onChanged,
              items: this
                      .items
                      ?.map(
                        (item) => DropdownMenuItem<T>(
                          value: item.value,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: this.minWidth ??
                                  (this.label != null ? 72 : 0),
                              maxWidth: constraints.maxWidth - 24,
                            ),
                            child: item.widget ??
                                Text(
                                  item.text!,
                                  overflow: TextOverflow.ellipsis,
                                ),
                          ),
                        ),
                      )
                      .toList() ??
                  [],
            ),
          ],
        ),
      );
    });
  }
}
