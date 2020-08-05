enum HiveKeys {
  /// Returns a List of [Connection]
  SavedConnections,

  /// Returns a List of [PastStreamData]
  PastStreamData,

  /// Returns a List (which only contains one entry - singleton) of [Settings]
  Settings,

  /// Returns a List of twitch usernames to indicate which chat to display [String]
  TwitchUsernames,
}

extension HiveKeysFunctions on HiveKeys {
  String get name => const {
        HiveKeys.SavedConnections: 'saved-connections',
        HiveKeys.PastStreamData: 'past-stream-data',
        HiveKeys.Settings: 'settings',
        HiveKeys.TwitchUsernames: 'twitch-usernames',
      }[this];
}
