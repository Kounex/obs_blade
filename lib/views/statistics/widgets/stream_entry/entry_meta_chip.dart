import 'package:flutter/material.dart';

class EntryMetaChip extends StatelessWidget {
  final String title;
  final String content;

  final double width;

  EntryMetaChip({
    @required this.title,
    @required this.content,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: this.width ?? double.infinity,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Chip(
          padding: const EdgeInsets.all(4.0),
          label: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    this.title,
                    style: Theme.of(context).textTheme.subtitle2.copyWith(
                          decoration: TextDecoration.underline,
                        ),
                  ),
                ),
                Text(this.content),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
