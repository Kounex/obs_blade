import 'package:flutter/material.dart';

class StatsEntryPlaceholder extends StatelessWidget {
  final String text;

  const StatsEntryPlaceholder({super.key, required this.text});

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
