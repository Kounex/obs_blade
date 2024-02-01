import 'package:flutter/material.dart';

/// Credit to: Natesh bhat
/// Taken from: https://stackoverflow.com/a/61186997/11440449
extension ColorStuff on Color {
  /// Prefixes a hash sign if [leadingHashSign] is set to `true` (default is `true`).
  String toHex({bool leadingHashSign = false, bool withAlpha = false}) =>
      '${leadingHashSign ? '#' : ''}'
      '${withAlpha ? alpha.toRadixString(16).padLeft(2, '0') : ''}'
      '${red.toRadixString(16).padLeft(2, '0')}'
      '${green.toRadixString(16).padLeft(2, '0')}'
      '${blue.toRadixString(16).padLeft(2, '0')}';

  /// Darken and lighten from: https://stackoverflow.com/a/60191441
  /// Darken a color by [percent] amount (100 = black)
  Color darken([int percent = 10]) {
    assert(1 <= percent && percent <= 100);
    var f = 1 - percent / 100;
    return Color.fromARGB(this.alpha, (this.red * f).round(),
        (this.green * f).round(), (this.blue * f).round());
  }

  /// Lighten a color by [percent] amount (100 = white)
  Color lighten([int percent = 10]) {
    assert(1 <= percent && percent <= 100);
    var p = percent / 100;
    return Color.fromARGB(
        this.alpha,
        this.red + ((255 - this.red) * p).round(),
        this.green + ((255 - this.green) * p).round(),
        this.blue + ((255 - this.blue) * p).round());
  }
}
