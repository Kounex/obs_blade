enum EventType {
  /// Streaming started successfully
  StreamStarted,

  /// A request to stop streaming has been issued
  StreamStopping,

  /// Recording started successfully
  RecordingStarted,

  /// A request to stop recording has been issued
  RecordingStopping,

  /// Current recording paused
  RecordingPaused,

  /// Current recording resumed
  RecordingResumed,

  /// Emitted every 2 seconds when stream is active
  StreamStatus,

  /// Triggered when switching to another scene collection or when renaming the current scene collection
  SceneCollectionChanged,

  /// Triggered when a scene collection is created, added, renamed, or removed
  SceneCollectionListChanged,

  /// Note: This event is not fired when the scenes are reordered
  ScenesChanged,

  /// Indicates a scene change
  SwitchScenes,

  /// A transition (other than "cut") has begun
  TransitionBegin,

  /// The list of available transitions has been modified. Transitions have been added, removed, or renamed
  TransitionListChanged,

  /// The active transition duration has been changed
  TransitionDurationChanged,

  /// The active transition has been changed
  SwitchTransition,

  /// A scene item has been added to a scene
  SceneItemAdded,

  /// A scene item has been removed from a scene
  SceneItemRemoved,

  /// A source has been renamed
  SourceRenamed,

  /// The volume of a source has changed
  SourceVolumeChanged,

  /// A source has been muted or unmuted
  SourceMuteStateChanged,

  /// Scene items within a scene have been reordered
  SourceOrderChanged,

  /// A scene item's visibility has been toggled
  SceneItemVisibilityChanged,

  /// Studio Mode has been enabled or disabled
  StudioModeSwitched,

  /// The selected preview scene has changed (only available in Studio Mode)
  PreviewSceneChanged,

  /// OBS is exiting
  Exiting,
}
