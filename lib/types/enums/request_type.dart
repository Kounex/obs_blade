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

  /// Get a list of scenes in the currently active profile
  ///
  /// No specified parameters
  GetSceneList,

  /// Gets an array of all inputs in OBS.
  ///
  /// (Optional) {'inputKind': String } - Restrict the array to only inputs of the specified kind
  GetInputList,

  /// Gets an array of all available input kinds in OBS.
  ///
  /// (Optional) {'unversioned': bool } - True == Return all kinds as unversioned, False == Return with version suffixes (if available)
  GetInputKindList,

  /// Gets the current volume setting of an input.
  ///
  /// {'inputName': String } - Name of the input to get the volume of
  GetInputVolume,

  /// Gets the audio mute state of an input.
  ///
  /// {'inputName': String } - Name of input to get the mute state of
  GetInputMute,

  /// Get configured special sources like Desktop Audio and Mic/Aux sources
  ///
  /// No specified parameters
  GetSpecialInputs,

  /// Get configured special sources like Desktop Audio and Mic/Aux sources
  ///
  /// No specified parameters
  GetSceneTransitionList,

  /// Gets information about the current scene transition.
  ///
  /// No specified parameters
  GetCurrentSceneTransition,

  /// Gets a Base64-encoded screenshot of a source.
  ///
  /// The imageWidth and imageHeight parameters are treated as "scale to inner", meaning the smallest ratio
  /// will be used and the aspect ratio of the original resolution is kept. If imageWidth and imageHeight
  /// are not specified, the compressed image will use the full resolution of the source.
  ///
  /// { 'sourceName':	String } - Name of the source to take a screenshot of
  /// { 'imageFormat': String } - Image compression format to use. Use GetVersion to get compatible image formats
  /// (Optional) { 'imageHeight': int } - Height to scale the screenshot to - >= 8, <= 4096
  /// (Optional) { 'imageCompressionQuality': int } - Compression ratio between -1 and 100 to write the image with. -1 is automatic, 1 is smallest file/most compression, 100 is largest file/least compression. Varies with image typeCompression quality to use. 0 for high compression, 100 for uncompressed. -1 to use "default" (whatever that means, idk)
  GetSourceScreenshot,

  /// Gets the status of the record output.
  ///
  /// No specified parameters
  GetRecordStatus,

  /// Gets the status of the stream output.
  ///
  /// No specified parameters
  GetStreamStatus,

  /// Gets whether studio is enabled.
  ///
  /// No specified parameters
  GetStudioModeEnabled,

  /// Gets an array of all scene collections
  ///
  /// No specified parameters
  GetSceneCollectionList,

  /// Get the status of the OBS replay buffer
  ///
  /// No specified parameters
  GetReplayBufferStatus,

  /// Gets a list of all scene items in a scene.
  ///
  /// { 'sceneName': String } - Name of the scene to get the items of
  GetSceneItemList,

  /// Basically GetSceneItemList, but for groups.
  ///
  /// Using groups at all in OBS is discouraged, as they are very broken under the hood.
  ///
  /// { 'sceneName': String } - Name of the group to get the items of
  GetGroupSceneItemList,

  /// Gets the default settings for an input kind.
  ///
  /// { 'inputKind': String } - Input kind to get the default settings for
  GetInputDefaultSettings,

  /// Gets statistics about OBS, obs-websocket, and the current session.
  ///
  /// No specified parameters
  GetStats,

  /// Gets the status of the virtualcam output.
  ///
  /// No specified parameters
  GetVirtualCamStatus,

  /**
   * -----------------------------------------------------------------------
   * Requests which serve as 'setter' - we will set specific parameters
   * in our request to change something in OBS. We don't need the response
   * since we don't wait for information after this request, so no response
   * classes exist for those
   * -----------------------------------------------------------------------
   */

  /// Sets the current program scene.
  ///
  /// {'sceneName': String } - Scene to set as the current program scene
  SetCurrentProgramScene,

  /// Gets the current preview scene.
  ///
  /// Only available when studio mode is enabled.
  ///
  /// {'sceneName': String } - Scene to set as the current preview scene
  SetCurrentPreviewScene,

  /// Sets the volume setting of an input.
  ///
  /// {'inputName': String } - Name of the input to set the volume of
  /// {'inputVolumeMul': double } - Volume setting in mul - >= 0, <= 20 - inputVolumeDb should be specified
  /// {'inputVolumeDb': double } - Volume setting in dB - >= -100, <= 26 - inputVolumeMul should be specified
  SetInputVolume,

  /// Sets the mute status of a specified source
  ///
  /// {'inputName': String } - Name of the input to set the mute state of
  /// {'inputMuted': bool } - Whether to mute the input or not
  SetInputMute,

  /// Sets the scene specific properties of a source. Unspecified properties will remain unchanged. Coordinates are relative to the item's parent (the scene or group it belongs to)
  ///
  /// {'sceneName': String } - Name of the scene the item is in
  /// {'sceneItemId': int } - Numeric ID of the scene item
  /// {'sceneItemEnabled': bool} - New enable state of the scene item
  SetSceneItemEnabled,

  /// Toggles the status of the stream output.
  ///
  /// No specified parameters
  ToggleStream,

  /// Pause or play a media source. Supports ffmpeg and vlc media sources (as of OBS v25.0.8)
  ///
  /// {'sourceName': String } - Source name
  /// {'playPause': bool } - Whether to pause or play the source. false for play, true for pause
  PlayPauseMedia,

  /// Toggles the status of the record output.
  ///
  /// No specified parameters
  ToggleRecord,

  /// Pauses the record output.
  ///
  /// No specified parameters
  PauseRecord,

  /// Resumes the record output.
  ///
  /// No specified parameters
  ResumeRecord,

  /// Sets the duration of the current scene transition, if it is not fixed.
  ///
  /// {'transitionDuration': int } - Duration in milliseconds
  SetCurrentSceneTransitionDuration,

  /// Sets the current scene transition.
  ///
  /// Small note: While the namespace of scene transitions is generally unique, that uniqueness is not a guarantee as it is with other resources like inputs.
  ///
  /// {'transitionName': String } - Name of the transition to make active
  SetCurrentSceneTransition,

  /// Enables or disables studio mode
  ///
  /// {'studioModeEnabled': bool } - True == Enabled, False == Disabled
  SetStudioModeEnabled,

  /// Transitions the currently previewed scene to the main output. Will return an error if Studio Mode is not enabled
  ///
  /// (Optional) {'with-transition': Object } - Change the active transition before switching scenes. Defaults to the active transition
  /// (Optional) {'with-transition.name': String } - Name of the transition
  /// (Optional) {'with-transition.duration': int } - Transition duration (in milliseconds)
  TransitionToProgram,

  /// Switches to a scene collection.
  ///
  /// Note: This will block until the collection has finished changing.
  ///
  /// {'sceneCollectionName': String } - Name of the scene collection to switch to
  SetCurrentSceneCollection,

  /// Toggles the state of the replay buffer output.
  ///
  /// No specified parameters
  ToggleReplayBuffer,

  /// Saves the contents of the replay buffer output.
  ///
  /// No specified parameters
  SaveReplayBuffer,

  /// Toggles the state of the virtualcam output.
  ///
  /// No specified parameters
  ToggleVirtualCam,
}
