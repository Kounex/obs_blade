import 'package:flutter/material.dart';

class PlaceholderSceneItem extends StatelessWidget {
  final String text;

  const PlaceholderSceneItem({
    Key? key,
    required this.text,
  }) : super(key: key);

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
