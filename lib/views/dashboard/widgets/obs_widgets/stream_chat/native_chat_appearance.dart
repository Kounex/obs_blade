import 'package:hive_ce/hive.dart';
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

  static const double messageSpacingDefault = 2.0;
  static const double messageSpacingMin = 0.0;
  static const double messageSpacingMax = 12.0;

  static const bool separatorsDefault = false;

  static double textSize(Box settings) => _double(
        settings,
        SettingsKeys.TwitchChatTextSize,
        textSizeDefault,
      );

  static double emoteSize(Box settings) => _double(
        settings,
        SettingsKeys.TwitchChatEmoteSize,
        emoteSizeDefault,
      );

  static double messageSpacing(Box settings) => _double(
        settings,
        SettingsKeys.TwitchChatMessageSpacing,
        messageSpacingDefault,
      );

  static bool separators(Box settings) =>
      settings.get(
        SettingsKeys.TwitchChatMessageSeparators.name,
        defaultValue: separatorsDefault,
      ) as bool;

  static double _double(Box settings, SettingsKeys key, double fallback) {
    final value = settings.get(key.name, defaultValue: fallback);
    if (value is num) return value.toDouble();
    return fallback;
  }
}
