enum EventType {
  /// The state of the stream output has changed.
  StreamStateChanged,

  /// The state of the record output has changed.
  RecordStateChanged,

  /// The state of the replay buffer output has changed.
  ReplayBufferStateChanged,

  /// The state of the virtualcam output has changed.
  VirtualcamStateChanged,

  /// The scene collection list has changed.
  SceneCollectionListChanged,

  /// The profile list has changed.
  ProfileListChanged,

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

  /// The current profile has changed.
  CurrentProfileChanged,

  /// A scene item has been created.
  SceneItemCreated,

  /// A scene item has been removed.
  ///
  /// This event is not emitted when the scene the item is in is removed.
  SceneItemRemoved,

  /// The name of an input has changed.
  InputNameChanged,

  /// An input's volume level has changed.
  InputVolumeChanged,

  /// An input's mute state has changed.
  InputMuteStateChanged,

  /// A scene's item list has been reindexed.
  SceneItemListReindexed,

  /// A scene item's enable state has changed.
  SceneItemEnableStateChanged,

  /// Studio mode has been enabled or disabled.
  StudioModeStateChanged,

  /// The current program scene has changed.
  CurrentProgramSceneChanged,

  /// The current preview scene has changed.
  CurrentPreviewSceneChanged,

  /// OBS has begun the shutdown process.
  ExitStarted,
}
