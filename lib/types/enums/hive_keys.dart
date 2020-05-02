enum HiveKeys { SAVED_CONNECTIONS }

extension HiveKeysFunctions on HiveKeys {
  String get name => const {
        HiveKeys.SAVED_CONNECTIONS: 'saved-connections',
      }[this];
}
