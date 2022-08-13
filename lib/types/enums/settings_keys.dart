enum SettingsKeys {
  /// ******************************************************************************
  /// Internally used properties which won't be changeable / seeable for the user
  /// ******************************************************************************

  /// [bool]: If the user already saw the intro - will be set after being in landing
  /// of Home Tab and will prevent the user from seeing the intro slides again
  /// IMPORTANT: Deprecated! We use the ones bound to dates to ensure users have
  /// seen them after a spsecific time (even existing users) since there have been
  /// important changes
  //HasUserSeenIntro,

  /// [bool]: If the user already saw the intro - will be set after being in landing
  /// of Home Tab and will prevent the user from seeing the intro slides again
  HasUserSeenIntro202208,

  /// [bool]: If the user has bought Blacksmith. Will be checked in [PurchaseBase] on the fly
  /// (checked from the App Store) but the user might have no internet connection so it's persisted
  /// here additionally
  BoughtBlacksmith,

  /// ******************************************************************************
  /// Actively set by user via settings page or using the app
  /// ******************************************************************************

  /// [bool]: Using fully dark mode or not
  TrueDark,

  /// [bool]: If user wants to reduce smearing if [TrueDark] is true
  ReduceSmearing,

  /// [bool]: If user wants to use tablet mode (layout) even if size is not optimal
  EnforceTabletMode,

  /// [ChatType]: enum which can be peristed with Hive as well
  SelectedChatType,

  /// [List<String>]: All entered twitch usernames by the user
  TwitchUsernames,

  /// [String]: The currently selected twitch username to use for the twitch chat
  SelectedTwitchUsername,

  /// [Map<String, String>]: All entered youtube users to see the chat from
  /// key: username (just for the user of this app to recognize)
  /// value: youtube chat url
  YoutubeUsernames,

  /// [String]: The currently selected youtube username to use for the youtube chat
  SelectedYoutubeUsername,

  /// [bool]: If user wants to use his custom theme
  CustomTheme,

  /// [String]: UUID of the active custom theme (only used if [CustomTheme] is true)
  ActiveCustomThemeUUID,

  /// [bool]: Indicates if the user wants to let his device stay active in the [DashboardView].
  /// Active by default
  WakeLock,

  /// [bool]: If the recording functions (start/stop/pause) should be shown in the
  /// dashboard instead of in the menu action list of the app bar
  ExposeRecordingControls,

  /// [bool]: If the studio mode controls should be enabled and shown in the dashboard
  /// (won't be shown anywhere else if disabled)
  ExposeStudioControls,

  /// [bool]: If the streaming controls (start / stop) should be shown in the dashboard
  /// instead of in the menu action list of the app bar
  ExposeStreamingControls,

  /// [bool]: If the OBS scene preview should be shown in the dashboard (on by default)
  /// but if someone wants to minimise their view, they can even remove that
  ExposeScenePreview,

  /// [bool]: If the scene collection dropdown to see the current scene collection and
  /// change it should be shown in the dashboard
  ExposeSceneCollection,

  /// [bool]: If the replay buffer functions (start/stop/save) should be shown in the
  /// dashboard instead of in the menu action list of the app bar
  ExposeReplayBufferControls,

  /// [bool]: If true OBS Blade will try to reconnect to an OBS instance on connection
  /// lost indefinetily instead of an amount of retries before aborting
  UnlimitedReconnects,

  /// ******************************************************************************
  /// "Don't show dialog again" - settings set by user by checkbox in dialog
  /// IMPORTANT: Name should always start with 'DontShow'/'dont-show'
  /// ******************************************************************************

  /// [bool]: If the user saw the warning regarding displaying the live preview of
  /// the current OBS scene and doesn't want to see this warning again
  DontShowPreviewWarning,

  /// [bool]: If the user saw the warning regarding hiding scene items which could
  /// lead to items "reappearing" if the scenes name has been changed or the hidden item
  /// has been renamed or re-inserted (since the combination of scene name, id and name has
  /// to remain the same) and doesn't want to see this warning again
  DontShowHidingSceneItemsWarning,

  /// [bool]: If the user saw the warning regarding youtube chat support being in
  /// beta and might cause trouble and doesn't want to see this warning again
  DontShowYouTubeChatBetaWarning,

  /// [bool]: If the user saw the warning regarding hiding scenes which could
  /// have false behaviour due to OBS WebSocket only transmitting the scene name
  /// without any identifier. Therefore I have to rely on the connection name
  /// (if present) or the used ip address which could change and make scenes
  /// either reappear or be hidden in wrong occassions
  DontShowHidingScenesWarning,

  /// [bool]: If the user saw the message regarding going live and doesn't want
  /// to see this warning again
  DontShowStreamStartMessage,

  /// [bool]: If the user saw the message regarding going offline and doesn't want
  /// to see this warning again
  DontShowStreamStopMessage,

  /// [bool]: If the user saw the message regarding start recording and doesn't want
  /// to see this warning again
  DontShowRecordStartMessage,

  /// [bool]: If the user saw the message regarding stop recording and doesn't want
  /// to see this warning again
  DontShowRecordStopMessage,

  /// [bool]: If the user attempts to leave a tip without having purchased Blacksmith
  /// and doesn't want to see this warning again
  DontShowConsiderBlacksmithBeforeTip,
}

extension SettingsKeysFunctions on SettingsKeys {
  String get name => const {
        // SettingsKeys.HasUserSeenIntro: 'has-user-seen-intro',
        SettingsKeys.HasUserSeenIntro202208: 'has-user-seen-intro-202208',
        SettingsKeys.BoughtBlacksmith: 'bought-blacksmith',
        SettingsKeys.TrueDark: 'true-dark',
        SettingsKeys.ReduceSmearing: 'reduce-smearing',
        SettingsKeys.EnforceTabletMode: 'enforce-tablet-mode',
        SettingsKeys.SelectedChatType: 'selected-chat-type',
        SettingsKeys.TwitchUsernames: 'twitch-usernames',
        SettingsKeys.SelectedTwitchUsername: 'selected-twitch-username',
        SettingsKeys.YoutubeUsernames: 'youtube-usernames',
        SettingsKeys.SelectedYoutubeUsername: 'selected-youtube-username',
        SettingsKeys.CustomTheme: 'custom-theme',
        SettingsKeys.ActiveCustomThemeUUID: 'active-custom-theme-uuid',
        SettingsKeys.WakeLock: 'wake-lock',
        SettingsKeys.ExposeRecordingControls: 'expose-recording-controls',
        SettingsKeys.ExposeStudioControls: 'expose-studio-controls',
        SettingsKeys.ExposeStreamingControls: 'expose-streaming-controls',
        SettingsKeys.ExposeScenePreview: 'expose-scene-preview',
        SettingsKeys.ExposeSceneCollection: 'expose-scene-collection',
        SettingsKeys.ExposeReplayBufferControls:
            'expose-replay-buffer-collection',
        SettingsKeys.UnlimitedReconnects: 'unlimited-reconnects',
        SettingsKeys.DontShowPreviewWarning: 'dont-show-preview-warning',
        SettingsKeys.DontShowHidingSceneItemsWarning:
            'dont-show-hiding-scene-items-warning',
        SettingsKeys.DontShowYouTubeChatBetaWarning:
            'dont-show-youtube-chat-beta-warning',
        SettingsKeys.DontShowHidingScenesWarning:
            'dont-show-hiding-scenes-warning',
        SettingsKeys.DontShowStreamStartMessage:
            'dont-show-stream-start-message',
        SettingsKeys.DontShowStreamStopMessage: 'dont-show-stream-stop-message',
        SettingsKeys.DontShowRecordStartMessage:
            'dont-show-record-start-message',
        SettingsKeys.DontShowRecordStopMessage: 'dont-show-record-stop-message',
        SettingsKeys.DontShowConsiderBlacksmithBeforeTip:
            'dont-show-consider-blacksmith-before-tip',
      }[this]!;
}
