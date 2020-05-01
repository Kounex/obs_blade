enum ResponseStatus { OK, ERROR }

extension ResponseStatusFunctions on ResponseStatus {
  String get text => const {
        ResponseStatus.OK: 'ok',
        ResponseStatus.ERROR: 'error',
      }[this];
}
