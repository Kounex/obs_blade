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
  /// (Optional) { 'sourceType':	String } - Type of the specified source.Useful for type-checking if you expect a specific settings schema
  GetSourceSettings,

  /// List existing outputs
  ///
  /// No specified parameters
  ListOutputs,

  /// Get configured special sources like Desktop Audio and Mic/Aux sources
  ///
  /// No specified parameters
  GetSpecialSources,

  /// Get configured special sources like Desktop Audio and Mic/Aux sources
  ///
  /// No specified parameters
  GetTransitionList,

  /// Get the name of the currently selected transition in the frontend's dropdown menu
  ///
  /// No specified parameters
  GetCurrentTransition,

  /// Indicates if Studio Mode is currently enabled
  ///
  /// No specified parameters
  GetStudioModeStatus,

  /// At least embedPictureFormat or saveToFilePath must be specified. Clients can specify width and height parameters to receive scaled pictures. Aspect ratio is preserved if only one of these two parameters is specified.
  ///
  /// (Optional) { 'sourceName':	String } - Source name. Note that, since scenes are also sources, you can also provide a scene name. If not provided, the currently active scene is used
  /// (Optional) { 'embedPictureFormat': String } - Format of the Data URI encoded picture. Can be "png", "jpg", "jpeg" or "bmp" (or any other value supported by Qt's Image module)
  /// (Optional) { 'saveToFilePath': String } - Full file path (file extension included) where the captured image is to be saved. Can be in a format different from pictureFormat. Can be a relative path
  /// (Optional) { 'fileFormat': String } - Format to save the image file as (one of the values provided in the supported-image-export-formats response field of GetVersion). If not specified, tries to guess based on file extension
  /// (Optional) { 'compressionQuality': int } - Compression ratio between -1 and 100 to write the image with. -1 is automatic, 1 is smallest file/most compression, 100 is largest file/least compression. Varies with image type
  /// (Optional) { 'width': int } - Screenshot width. Defaults to the source's base width
  /// (Optional) { 'height': int } - Screenshot height. Defaults to the source's base width
  TakeSourceScreenshot,

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
  PlayPauseMedia,

  /// Toggle recording on or off (depending on the current recording state)
  ///
  /// No specified parameters
  StartStopRecording,

  /// Pause the current recording. Returns an error if recording is not active or already paused
  ///
  /// No specified parameters
  PauseRecording,

  /// Resume/unpause the current recording (if paused). Returns an error if recording is not active or not paused
  ///
  /// No specified parameters
  ResumeRecording,

  /// Set the duration of the currently selected transition if supported
  ///
  /// {'duration': int } - Desired duration of the transition (in milliseconds)
  SetTransitionDuration,

  /// Set the active transition
  ///
  /// {'transition-name': String } - The name of the transition
  SetCurrentTransition,

  /// Toggles Studio Mode (depending on the current state of studio mode)
  ///
  /// No specified parameters
  ToggleStudioMode,

  /// Set the active preview scene. Will return an error if Studio Mode is not enabled
  ///
  /// {'scene-name': String } - The name of the scene to preview
  SetPreviewScene,

  /// Transitions the currently previewed scene to the main output. Will return an error if Studio Mode is not enabled
  ///
  /// (Optional) {'with-transition': Object } - Change the active transition before switching scenes. Defaults to the active transition
  /// (Optional) {'with-transition.name': String } - Name of the transition
  /// (Optional) {'with-transition.duration': int } - Transition duration (in milliseconds)
  TransitionToProgram,
}
