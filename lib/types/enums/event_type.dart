enum EventType {
  /// The state of the stream output has changed.
  StreamStateChanged,

  /// The state of the record output has changed.
  RecordStateChanged,

  /// The state of the replay buffer output has changed.
  ReplayBufferStateChanged,

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

  /// A scene transition has started.
  SceneTransitionStarted,

  /// The current scene transition has changed.
  CurrentSceneTransitionChanged,

  /// The current scene transition duration has changed.
  CurrentSceneTransitionDurationChanged,

  /// The current scene collection has begun changing.
  ///
  /// Note: We recommend using this event to trigger a pause of all polling requests,
  /// as performing any requests during a scene collection change is considered undefined
  /// behavior and can cause crashes!
  CurrentSceneCollectionChanging,

  /// The current scene collection has changed.
  ///
  /// Note: If polling has been paused during CurrentSceneCollectionChanging,
  /// this is the que to restart polling.
  CurrentSceneCollectionChanged,

  /// A scene item has been added to a scene
  SceneItemAdded,

  /// A scene item has been removed from a scene
  SceneItemRemoved,

  /// A source has been renamed
  SourceRenamed,

  /// An input's volume level has changed.
  InputVolumeChanged,

  /// An input's mute state has changed.
  InputMuteStateChanged,

  /// Scene items within a scene have been reordered
  SourceOrderChanged,

  /// A scene item's enable state has changed.
  SceneItemEnableStateChanged,

  /// Studio Mode has been enabled or disabled
  StudioModeSwitched,

  /// The current program scene has changed.
  CurrentProgramSceneChanged,

  /// The current preview scene has changed.
  CurrentPreviewSceneChanged,

  /// OBS has begun the shutdown process.
  ExitStarted,
}
