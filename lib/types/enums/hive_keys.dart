enum HiveKeys {
  /// Returns a List of [Connection]
  SavedConnections,

  /// Returns a List of [PastStreamData]
  PastStreamData,

  /// Returns a List of [PastRecordData]
  PastRecordData,

  /// Returns a List of [CustomTheme]
  CustomTheme,

  /// Returns a List of [HiddenSceneItem]
  HiddenSceneItem,

  /// Returns a List of [HiddenScene]
  HiddenScene,

  /// Returns a List of [AppLog]
  AppLog,

  /// Returns a List of [PurchasedTip]
  PurchasedTip,

  /// Returns the box containing app settings - refer to [SettingsKeys]
  /// to see which key-value pairs are available
  Settings,
}

extension HiveKeysFunctions on HiveKeys {
  String get name => const {
        HiveKeys.SavedConnections: 'saved-connections',
        HiveKeys.PastStreamData: 'past-stream-data',
        HiveKeys.PastRecordData: 'past-record-data',
        HiveKeys.CustomTheme: 'custom-theme',
        HiveKeys.HiddenSceneItem: 'hidden-scene-item',
        HiveKeys.HiddenScene: 'hidden-scene',
        HiveKeys.AppLog: 'app-log',
        HiveKeys.PurchasedTip: 'purchased-tip',
        HiveKeys.Settings: 'settings',
      }[this]!;
}
