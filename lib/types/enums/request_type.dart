enum RequestType {
  /**
   * -----------------------------------------------------------------------
   * Requests which serve as 'getter' - we will get a response
   * with valueable information we want to use in the app so we
   * have a designated response class for it: types/classes/stream/responses
   * -----------------------------------------------------------------------
   */

  /// Returns the latest version of the plugin and the API
  ///
  /// No specified parameters
  GetVersion,

  /// Tells the client if authentication is required. If so, returns authentication parameters challenge and salt (see "Authentication" for more information)
  ///
  /// No specified parameters
  GetAuthRequired,

  /// Get a list of scenes in the currently active profile
  ///
  /// No specified parameters
  GetSceneList,

  /// Get the current scene's name and source items
  ///
  /// No specified parameters
  GetCurrentScene,

  /// No specified parameters
  GetSourcesList,

  /// List all sources available in the running OBS instance
  ///
  /// No specified parameters
  GetSourceTypesList,

  /// Get the volume of the specified source. Default response uses mul format, NOT SLIDER PERCENTAGE
  ///
  /// {'source': String } - Source name
  GetVolume,

  /// Get the mute status of a specified source
  ///
  /// {'source': String } - Source name
  GetMute,

  /// Get settings of the specified source
  ///
  /// { 'sourceName': String } - Source name
  /// (Optional) { 'sourceType':	String } - Type of the specified source. Useful for type-checking if you expect a specific settings schema
  GetSourceSettings,

  /// List existing outputs
  ///
  /// No specified parameters
  ListOutputs,

  /// Get configured special sources like Desktop Audio and Mic/Aux sources
  ///
  /// No specified parameters
  GetSpecialSources,

  /**
   * -----------------------------------------------------------------------
   * Requests which serve as 'setter' - we will set specific parameters
   * in our request to change something in OBS. We don't need the response
   * since we don't wait for information after this request, so no response
   * classes exist for those
   * -----------------------------------------------------------------------
   */

  /// Attempt to authenticate the client to the server
  ///
  /// {'auth': String } - Response to the auth challenge (see "Authentication" for more information)
  Authenticate,

  /// Switch to the specified scene
  ///
  /// {'scene-name': String } - Name of the scene to switch to
  SetCurrentScene,

  /// Set the volume of the specified source. Default request format uses mul, NOT SLIDER PERCENTAGE
  ///
  /// {'source': String } - Source name
  /// {'volume': double } - Desired volume. Must be between 0.0 and 1.0 for mul, and under 0.0 for dB. Note: OBS will interpret dB values under -100.0 as Inf
  /// {'useDecibel': bool } - Interperet volume data as decibels instead of amplitude/mul
  SetVolume,

  /// Sets the mute status of a specified source
  ///
  /// {'source': String } - Source name
  /// {'mute': bool } - Desired mute status
  SetMute,

  /// Sets the scene specific properties of a source. Unspecified properties will remain unchanged. Coordinates are relative to the item's parent (the scene or group it belongs to)
  ///
  /// {'item': String } - Scene Item name (currently)
  /// {'name': String } - Scene Item name (new)
  /// {'visible': bool} - The new visibility of the source. 'true' shows source, 'false' hides source
  SetSceneItemProperties,

  /// Toggle streaming on or off (depending on the current stream state)
  ///
  /// No specified parameters
  StartStopStreaming,

  /// Pause or play a media source. Supports ffmpeg and vlc media sources (as of OBS v25.0.8)
  ///
  /// {'sourceName': String } - Source name
  /// {'playPause': bool } - Whether to pause or play the source. false for play, true for pause
  PlayPauseMedia
}
