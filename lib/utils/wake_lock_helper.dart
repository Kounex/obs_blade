import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../types/enums/hive_keys.dart';
import '../types/enums/settings_keys.dart';

/// Applies the persisted Wake Lock setting app-wide (screen stays on while
/// the app is in the foreground). Called on startup, on resume and when the
/// setting changes - toggling is idempotent, so re-applying is cheap.
void applyWakeLockSetting() {
  final bool enabled = Hive.box(
    HiveKeys.Settings.name,
  ).get(SettingsKeys.WakeLock.name, defaultValue: false);
  WakelockPlus.toggle(enable: enabled);
}
