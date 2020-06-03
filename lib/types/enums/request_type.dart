enum RequestType {
  /// No specified parameters
  GetAuthRequired,

  /// {'auth': String } - Response to the auth challenge (see "Authentication" for more information)
  Authenticate,

  /// No specified parameters
  GetSceneList,

  /// {'scene-name': String } - Name of the scene to switch to
  SetCurrentScene,

  /// No specified parameters
  GetCurrentScene,

  /// No specified parameters
  GetSourcesList,

  /// No specified parameters
  GetSourceTypesList,

  /// {'source': String } - Source name
  GetVolume,

  /// { 'sourceName': String } - Source name
  /// (Optional) { 'sourceType':	String } - Type of the specified source. Useful for type-checking if you expect a specific settings schema
  GetSourceSettings,

  /// No specified parameters
  ListOutputs,
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
        RequestType.GetSourceSettings: 'GetSourceSettings',
        RequestType.ListOutputs: 'ListOutputs',
      }[this];
}
