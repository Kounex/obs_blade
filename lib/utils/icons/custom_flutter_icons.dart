/// Custom icons made on fluttericon.com
import 'package:flutter/widgets.dart';

class CustomFlutterIcons {
  static const _kFontFam = 'CustomFlutterIcons';
  static const String? _kFontPkg = null;

  static const IconData owncast_logo = IconData(
    0xe800,
    fontFamily: _kFontFam,
    fontPackage: _kFontPkg,
  );

  /// The K from Kick's official wordmark (`static.kick.com/kick-logo.svg`).
  /// Their small-size mark; the wordmark itself does not fit a 16px icon.
  static const IconData kick = IconData(
    0xe801,
    fontFamily: _kFontFam,
    fontPackage: _kFontPkg,
  );

  /// Combined chat: a speech bubble with three streams merging into one
  /// (drawn for the app — source + generator notes in
  /// `docs/combined-chat-icon.md`).
  static const IconData combined_chat = IconData(
    0xe802,
    fontFamily: _kFontFam,
    fontPackage: _kFontPkg,
  );
}
