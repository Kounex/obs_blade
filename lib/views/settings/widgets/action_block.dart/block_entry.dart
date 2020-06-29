import 'package:flutter/material.dart';

class BlockEntry {
  IconData leading;
  String title;
  String help;
  Widget child;
  Widget trailing;
  String navigateTo;

  BlockEntry(
      {this.leading,
      this.title,
      this.help,
      this.child,
      this.trailing,
      this.navigateTo})
      : assert(trailing == null && navigateTo != null ||
            trailing != null &&
                navigateTo == null &&
                (child == null && (leading != null || trailing != null) ||
                    child != null && leading == null && trailing == null));
}
