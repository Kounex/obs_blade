import 'package:flutter/material.dart';

class StatsEntryPlaceholder extends StatelessWidget {
  final String text;

  const StatsEntryPlaceholder({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(
          this.text,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
