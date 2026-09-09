import 'package:flutter/material.dart';

/// Semantic status colors (live, recording, warnings, reachability) for the
/// "On Air" design system.
///
/// Registered as a [ThemeExtension] in `App._getCurrentTheme` (lib/app.dart),
/// so consumers can read:
///
/// ```dart
/// Theme.of(context).extension<AppStatusColors>()!.live
/// ```
///
/// These colors are intentionally constant across custom themes - they are
/// semantic (signal) colors, not brand colors. Defaults match the dark
/// variants of the previously hardcoded Cupertino status colors
/// (`CupertinoColors.activeGreen` / `CupertinoColors.destructiveRed`).
@immutable
class AppStatusColors extends ThemeExtension<AppStatusColors> {
  /// Streaming / LIVE indicator
  final Color live;

  /// Recording indicator
  final Color recording;

  /// Warning states
  final Color warning;

  /// Connection reachable
  final Color reachable;

  /// Connection unreachable
  final Color unreachable;

  /// On-air / program tally (active scene ring + tint, PGM tag, scene-button
  /// fill during transitions) - references this token, never [recording]
  final Color program;

  /// Recording color as small text on same-hue tints (REC pill, rec chip,
  /// offline badge)
  final Color recordingText;

  /// Favorite / star-on
  final Color favorite;

  const AppStatusColors({
    required this.live,
    required this.recording,
    required this.warning,
    required this.reachable,
    required this.unreachable,
    required this.program,
    required this.recordingText,
    required this.favorite,
  });

  /// App-wide defaults (dark variants of the Cupertino status palette -
  /// the app is dark-first)
  static const AppStatusColors standard = AppStatusColors(
    live: Color(0xFF30D158),
    recording: Color(0xFFFF453A),
    warning: Color(0xFFFFC107),
    reachable: Color(0xFF30D158),
    unreachable: Color(0xFFFF453A),
    program: Color(0xFFFF453A),
    recordingText: Color(0xFFFF6B60),
    favorite: Color(0xFFFFD60A),
  );

  /// Darkened [program] fill for the PGM tag carrying white text
  /// (color-mix 85% program with black, ≈#D93B32)
  Color get programTagFill => Color.lerp(program, Colors.black, 0.15)!;

  @override
  AppStatusColors copyWith({
    Color? live,
    Color? recording,
    Color? warning,
    Color? reachable,
    Color? unreachable,
    Color? program,
    Color? recordingText,
    Color? favorite,
  }) => AppStatusColors(
    live: live ?? this.live,
    recording: recording ?? this.recording,
    warning: warning ?? this.warning,
    reachable: reachable ?? this.reachable,
    unreachable: unreachable ?? this.unreachable,
    program: program ?? this.program,
    recordingText: recordingText ?? this.recordingText,
    favorite: favorite ?? this.favorite,
  );

  @override
  AppStatusColors lerp(ThemeExtension<AppStatusColors>? other, double t) {
    if (other is! AppStatusColors) {
      return this;
    }
    return AppStatusColors(
      live: Color.lerp(live, other.live, t)!,
      recording: Color.lerp(recording, other.recording, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      reachable: Color.lerp(reachable, other.reachable, t)!,
      unreachable: Color.lerp(unreachable, other.unreachable, t)!,
      program: Color.lerp(program, other.program, t)!,
      recordingText: Color.lerp(recordingText, other.recordingText, t)!,
      favorite: Color.lerp(favorite, other.favorite, t)!,
    );
  }
}
