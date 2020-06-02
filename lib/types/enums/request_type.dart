enum RequestType {
  GetAuthRequired,
  Authenticate,
  GetSceneList,
  SetCurrentScene,
  GetCurrentScene,
}

extension RequestTypeFunctions on RequestType {
  String get type => const {
        RequestType.GetAuthRequired: 'GetAuthRequired',
        RequestType.Authenticate: 'Authenticate',
        RequestType.GetSceneList: 'GetSceneList',
        RequestType.SetCurrentScene: 'SetCurrentScene',
        RequestType.GetCurrentScene: 'GetCurrentScene',
      }[this];
}
