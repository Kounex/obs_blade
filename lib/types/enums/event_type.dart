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

  /// The volume of a source has changed
  SourceVolumeChanged,

  /// A source has been muted or unmuted
  SourceMuteStateChanged,

  /// A scene item's visibility has been toggled
  SceneItemVisibilityChanged,

  /// OBS is exiting
  Exiting,
}
