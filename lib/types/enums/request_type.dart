enum RequestType {
  GetAuthRequired,
  Authenticate,
  GetSceneList,
  SetCurrentScene,
  GetCurrentScene,
  GetSourcesList,
  GetSourceTypesList,
  GetVolume,
}

extension RequestTypeFunctions on RequestType {
  String get type => const {
        RequestType.GetAuthRequired: 'GetAuthRequired',
        RequestType.Authenticate: 'Authenticate',
        RequestType.GetSceneList: 'GetSceneList',
        RequestType.SetCurrentScene: 'SetCurrentScene',
        RequestType.GetCurrentScene: 'GetCurrentScene',
        RequestType.GetSourcesList: 'GetSourcesList',
        RequestType.GetSourceTypesList: 'GetSourceTypesList',
        RequestType.GetVolume: 'GetVolume',
      }[this];

  // Map<String, Type> fields()
}
