enum HiveKeys { SAVED_CONNECTIONS, PAST_STREAM_DATA, SETTINGS }

extension HiveKeysFunctions on HiveKeys {
  String get name => const {
        HiveKeys.SAVED_CONNECTIONS: 'saved-connections',
        HiveKeys.PAST_STREAM_DATA: 'past-stream-data',
        HiveKeys.SETTINGS: 'settings',
      }[this];
}
