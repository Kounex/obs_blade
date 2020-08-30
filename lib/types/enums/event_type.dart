enum EventType {
  /// Streaming started successfully
  StreamStarted,

  /// A request to stop streaming has been issued
  StreamStopping,

  /// Emitted every 2 seconds when stream is active
  StreamStatus,

  /// Note: This event is not fired when the scenes are reordered
  ScenesChanged,

  /// Indicates a scene change
  SwitchScenes,

  /// A transition (other than "cut") has begun
  TransitionBegin,

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

  /// OBS is exiting
  Exiting,
}
