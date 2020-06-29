import 'package:flutter/material.dart';

class BlockEntry {
  IconData leading;
  String title;
  String help;
  Widget trailing;
  String navigateTo;

  BlockEntry(
      {this.leading, this.title, this.help, this.trailing, this.navigateTo})
      : assert(trailing == null && navigateTo != null ||
            trailing != null && navigateTo == null);
}
