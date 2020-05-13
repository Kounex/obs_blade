enum RequestType { GetAuthRequired, Authenticate, GetSceneList }

extension RequestTypeFunctions on RequestType {
  String get type => const {
        RequestType.GetAuthRequired: 'GetAuthRequired',
        RequestType.Authenticate: 'Authenticate',
        RequestType.GetSceneList: 'GetSceneList',
      }[this];
}
