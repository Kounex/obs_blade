import 'package:flutter/material.dart';

class PlaceholderSceneItem extends StatelessWidget {
  final String text;

  PlaceholderSceneItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Center(
        child: Text(this.text),
      ),
    );
  }
}
