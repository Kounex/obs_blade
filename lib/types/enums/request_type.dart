enum RequestType { GetAuthRequired, Authenticate }

extension RequestTypeFunctions on RequestType {
  String get type => const {
        RequestType.GetAuthRequired: 'GetAuthRequired',
        RequestType.Authenticate: 'Authenticate',
      }[this];
}
