import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';

/// Defaults / ranges for native chat appearance (spec
/// `2026-08-09-native-chat-appearance-design`).
abstract final class NativeChatAppearance {
  static const double textSizeDefault = 14.0;
  static const double textSizeMin = 11.0;
  static const double textSizeMax = 20.0;

  static const double emoteSizeDefault = 20.0;
  static const double emoteSizeMin = 14.0;
  static const double emoteSizeMax = 48.0;

  static const double messageSpacingDefault = 4.0;
  static const double messageSpacingMin = 0.0;
  static const double messageSpacingMax = 12.0;

  static const bool separatorsDefault = false;
  static const bool timestampsDefault = false;
  static const bool alternateRowsDefault = false;
  static const bool readableNamesDefault = true;

  static double textSize(Box settings) =>
      _double(settings, SettingsKeys.TwitchChatTextSize, textSizeDefault);

  static double emoteSize(Box settings) =>
      _double(settings, SettingsKeys.TwitchChatEmoteSize, emoteSizeDefault);

  static double messageSpacing(Box settings) => _double(
    settings,
    SettingsKeys.TwitchChatMessageSpacing,
    messageSpacingDefault,
  );

  static bool separators(Box settings) =>
      settings.get(
            SettingsKeys.TwitchChatMessageSeparators.name,
            defaultValue: separatorsDefault,
          )
          as bool;

  /// Chatterino's `showTimestamps` — `12:29` before each line.
  static bool timestamps(Box settings) =>
      settings.get(
        SettingsKeys.ChatShowTimestamps.name,
        defaultValue: timestampsDefault,
      ) ==
      true;

  /// Chatterino's `alternateMessageBackground`.
  static bool alternateRows(Box settings) =>
      settings.get(
        SettingsKeys.ChatAlternateRows.name,
        defaultValue: alternateRowsDefault,
      ) ==
      true;

  /// Lift/darken chatter name colors that would vanish on the chat
  /// background (dark blue on dark theme, yellow on light).
  static bool readableNames(Box settings) =>
      settings.get(
        SettingsKeys.ChatReadableNameColors.name,
        defaultValue: readableNamesDefault,
      ) ==
      true;

  static double _double(Box settings, SettingsKeys key, double fallback) {
    final value = settings.get(key.name, defaultValue: fallback);
    if (value is num) return value.toDouble();
    return fallback;
  }
}

/// Compact line timestamp for the chat timeline — locale-aware `HH:mm`
/// / `h:mm` without the AM/PM suffix Chatterino also drops by default.
String formatChatLineTime(DateTime time) {
  final local = time.toLocal();
  final use24h = DateFormat.jm().pattern?.contains('H') ?? true;
  return use24h
      ? DateFormat('HH:mm').format(local)
      : DateFormat('h:mm').format(local);
}

/// Background wash for every other row when [NativeChatAppearance
/// .alternateRows] is on — subtle enough to keep highlight washes legible.
Color chatAlternateRowColor(BuildContext context) =>
    Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.035);

/// Minimum WCAG contrast a chatter name keeps against the chat background.
const double kChatNameMinContrast = 3.0;

/// [color] nudged in HSL lightness (hue + saturation kept, so names stay
/// recognizable) until it reaches [kChatNameMinContrast] against
/// [background]. Colors already readable pass through untouched.
Color readableNameColor(Color color, Color background) {
  double contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final hi = la > lb ? la : lb;
    final lo = la > lb ? lb : la;
    return (hi + 0.05) / (lo + 0.05);
  }

  if (contrast(color, background) >= kChatNameMinContrast) return color;
  final darkBackground = background.computeLuminance() < 0.5;
  var hsl = HSLColor.fromColor(color);
  for (var i = 0; i < 20; i++) {
    final lightness = (hsl.lightness + (darkBackground ? 0.05 : -0.05)).clamp(
      0.0,
      1.0,
    );
    hsl = hsl.withLightness(lightness);
    final candidate = hsl.toColor();
    if (contrast(candidate, background) >= kChatNameMinContrast ||
        lightness == 0.0 ||
        lightness == 1.0) {
      return candidate;
    }
  }
  return hsl.toColor();
}

/// Muted `12:29 ` prefix span for a chat line.
TextSpan chatLineTimeSpan(BuildContext context, DateTime time, double size) =>
    TextSpan(
      text: '${formatChatLineTime(time)} ',
      style: TextStyle(
        color: Theme.of(context).textTheme.bodySmall?.color,
        fontSize: size * 0.85,
        fontWeight: FontWeight.w400,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );

/// Stable zebra striping for a chat timeline. Parity is assigned per
/// message id when the id is first seen (opposite of its predecessor) and
/// then kept — index parity would flip every row whenever the buffer
/// evicts from the front, which strobes in a busy chat.
class ChatRowParity {
  final Map<String, bool> _parity = <String, bool>{};

  /// Parity per id of [ids] (timeline order); `true` rows get the tint.
  List<bool> assign(List<String> ids) {
    final out = List<bool>.filled(ids.length, false);
    bool? previous;
    for (var i = 0; i < ids.length; i++) {
      final value = this._parity[ids[i]] ??= previous == null
          ? false
          : !previous;
      out[i] = value;
      previous = value;
    }
    if (this._parity.length > ids.length * 2 + 64) {
      final keep = ids.toSet();
      this._parity.removeWhere((id, _) => !keep.contains(id));
    }
    return out;
  }
}

/// [child] on the alternate-row tint when [tinted].
Widget chatAlternateRow(BuildContext context, bool tinted, Widget child) =>
    tinted
    ? ColoredBox(color: chatAlternateRowColor(context), child: child)
    : child;
