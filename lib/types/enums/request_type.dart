enum RequestType {
  /**
   * Requests which serve as 'getter' - we will get a response
   * with valueable information we want to use in the app so we
   * create a response class for it
   */

  /// No specified parameters
  GetAuthRequired,

  /// No specified parameters
  GetSceneList,

  /// No specified parameters
  GetCurrentScene,

  /// No specified parameters
  GetSourcesList,

  /// No specified parameters
  GetSourceTypesList,

  /// {'source': String } - Source name
  GetVolume,

  /// {'source': String } - Source name
  GetMute,

  /// { 'sourceName': String } - Source name
  /// (Optional) { 'sourceType':	String } - Type of the specified source. Useful for type-checking if you expect a specific settings schema
  GetSourceSettings,

  /// No specified parameters
  ListOutputs,

  /// No specified parameters
  GetSpecialSources,

  /**
   * Requests which serve as 'setter' - we will set specific parameters
   * in our request to change something in OBS. We don't need the response
   * since we don't wait for information after this request, so no response
   * classes exist for those
   */

  /// {'auth': String } - Response to the auth challenge (see "Authentication" for more information)
  Authenticate,

  /// {'scene-name': String } - Name of the scene to switch to
  SetCurrentScene,

  /// {'source': String } - Source name
  /// {'volume': double } - Desired volume. Must be between 0.0 and 1.0 for mul, and under 0.0 for dB. Note: OBS will interpret dB values under -100.0 as Inf
  /// {'useDecibel': bool } - Interperet volume data as decibels instead of amplitude/mul
  SetVolume,

  /// {'source': String } - Source name
  /// {'mute': bool } - Desired mute status
  SetMute,

  /// {'item': String } - Scene Item name (currently)
  /// {'name': String } - Scene Item name (new)
  /// {'visible': bool} - The new visibility of the source. 'true' shows source, 'false' hides source
  SetSceneItemProperties,

  /// Toggle streaming on or off (depending on the current stream state)
  /// No specified parameters
  StartStopStreaming
}
