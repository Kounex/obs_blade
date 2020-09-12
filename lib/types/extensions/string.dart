import 'package:flutter/material.dart';
import 'package:obs_blade/utils/validation_helper.dart';

extension StringStuff on String {
  Color hexToColor() {
    final buffer = StringBuffer();
    if (this.length == 6 || this.length == 7) buffer.write('ff');
    buffer.write(this.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
