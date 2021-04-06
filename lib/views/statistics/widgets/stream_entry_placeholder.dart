import 'package:flutter/material.dart';

class StreamEntryPlaceholder extends StatelessWidget {
  final String text;

  StreamEntryPlaceholder({required this.text}) : assert(text != null);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(
          this.text,
          textAlign: TextAlign.justify,
        ),
      ),
    );
  }
}
