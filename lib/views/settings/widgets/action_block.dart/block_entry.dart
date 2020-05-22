import 'package:flutter/material.dart';

class BlockEntry {
  IconData leading;
  Widget title;
  Widget trailing;
  String navigateTo;

  BlockEntry({this.leading, this.title, this.trailing, this.navigateTo})
      : assert(trailing == null && navigateTo != null ||
            trailing != null && navigateTo == null);
}
