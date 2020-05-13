enum RequestType {
  GetAuthRequired,
  Authenticate,
  GetSceneList,
  SetCurrentScene
}

extension RequestTypeFunctions on RequestType {
  String get type => const {
        RequestType.GetAuthRequired: 'GetAuthRequired',
        RequestType.Authenticate: 'Authenticate',
        RequestType.GetSceneList: 'GetSceneList',
        RequestType.SetCurrentScene: 'SetCurrentScene',
      }[this];
}
