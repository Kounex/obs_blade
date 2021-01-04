enum SettingsKeys {
  /// [bool]: Using fully dark mode or not
  TrueDark,

  /// [bool]: If user wants to reduce smearing if [TrueDark] is true
  ReduceSmearing,

  /// [bool]: If user wants to use tablet mode (layout) even if size is not optimal
  EnforceTabletMode,

  /// [String]: Not typesafe (usually should be an enum) but easier with hive in this
  /// case. Will be one of those currently:
  /// [Twitch]
  /// [Youtube]
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

  /// Internally used properties which won't be changeable / seeable for the user

  /// [bool]: If the user already saw the intro - will be set after being in landing
  /// of Home Tab and will prevent the user from seeing the intro slides again
  HasUserSeenIntro,

  /// [bool]: If the user saw the warning regarding displaying the live preview of
  /// the current OBS scene and doesn't want to see this warning again
  DontShowPreviewWarning
}

extension SettingsKeysFunctions on SettingsKeys {
  String get name => const {
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
        SettingsKeys.HasUserSeenIntro: 'has-user-seen-intro',
        SettingsKeys.DontShowPreviewWarning: 'dont-show-preview-warning',
      }[this];
}
