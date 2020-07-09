enum HiveKeys { SavedConnections, PastStreamData, Settings }

extension HiveKeysFunctions on HiveKeys {
  String get name => const {
        HiveKeys.SavedConnections: 'saved-connections',
        HiveKeys.PastStreamData: 'past-stream-data',
        HiveKeys.Settings: 'settings',
      }[this];
}
