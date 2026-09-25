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

  /// [bool]: If the user has bought Pro (any of the pro product ids - subscription
  /// or lifetime). Set in [PurchaseBase] on purchased/restored events; lapsed
  /// subscription enforcement is a documented limitation (needs server-side
  /// receipt validation - backend wave)
  BoughtPro,

  /// [bool]: Debug-only override which unlocks Pro without a purchase - consumed
  /// ONLY under kDebugMode (see [ProStore.isPro]) so it can never grant the
  /// entitlement in release builds
  ProDebugOverride,

  /// [bool]: Guard so the cold-start `restorePurchases()` (reinstall recovery -
  /// `queryPastPurchases` was removed in in_app_purchase 3.3.0) fires only
  /// once per install
  ProColdStartRestoreDone,

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

  /// [ChatEngine]: enum which can be peristed with Hive as well
  SelectedChatEngine,

  /// [List<String>]: All entered twitch usernames by the user
  TwitchUsernames,

  /// [String]: The currently selected twitch username to use for the twitch chat
  SelectedTwitchUsername,

  /// [Map<String, String>]: All entered youtube users to see the chat from
  /// key: username (just for the user of this app to recognize)
  /// value: youtube chat url
  YouTubeUsernames,

  /// [String]: The currently selected youtube username to use for the youtube chat
  SelectedYouTubeUsername,

  /// [String]: The user's own YouTube Data API key (BYO) for native
  /// YouTube chat reads - falls back to the app-owned `kYouTubeApiKey`
  /// constant (empty until an app-owned key exists)
  YouTubeApiKey,

  /// [String]: The user's own Google OAuth client id for the YouTube
  /// device flow sign-in - falls back to the app-owned
  /// `kYouTubeOAuthClientId` constant (empty until an app-owned client
  /// exists)
  YouTubeOAuthClientId,

  /// [String]: The user's own Google OAuth client secret paired with
  /// [YouTubeOAuthClientId] - Google's device flow for TVs/limited-input
  /// clients requires one. Falls back to the app-owned
  /// `kYouTubeOAuthClientSecret` constant (empty until an app-owned
  /// client exists)
  YouTubeOAuthClientSecret,

  /// [String]: The label (map key of [YouTubeUsernames] - stable across
  /// re-edits) of the currently selected native YouTube chat channel
  SelectedYouTubeNativeChannelId,

  /// [Map<String, String>]: All entered owncast users to see the chat from
  /// key: username (just for the user of this app to recognize)
  /// value: owncast chat domain + protocol
  OwncastUsernames,

  /// [String]: The currently selected owncast username to use for the owncast chat
  SelectedOwncastUsername,

  /// [List<String>]: All entered kick channel slugs by the user
  KickUsernames,

  /// [String]: The currently selected kick channel slug to use for the
  /// kick chat
  SelectedKickUsername,

  /// [bool]: The native Kick chat shows the signed-in account's own
  /// channel - which isn't part of [KickUsernames], so it can't live in
  /// the shared [SelectedKickUsername]
  SelectedKickNativeOwnChannel,

  /// [List<String>]: `ChatType.name`s switched off in the combined chat's
  /// built-in "My chats" combo
  MyChatsDisabledPlatforms,

  /// [Map<String, String?>]: per-platform selection (`ChatType.name` →
  /// channel key) the native stores had before the combined chat took
  /// them over - restored when the user leaves Combined, even after a
  /// restart
  CombinedChatRestore,

  /// [List<Map>]: user-built combined chats (`CombinedCombo.toJson`)
  CombinedChatCombos,

  /// [String]: id of the combo the combined chat shows (`my` = "My chats")
  SelectedCombinedCombo,

  /// [String]: `ChatType.name` the combined chat's input sends to when no
  /// reply is pending (the user's last pick of the target chip)
  CombinedChatSendTarget,

  /// [String]: The user's own Kick OAuth client id for the native Kick
  /// chat sign-in (manual-paste PKCE flow - Kick has no device flow) -
  /// falls back to the app-owned `kKickOAuthClientId` constant (empty
  /// until an app-owned client exists)
  KickOAuthClientId,

  /// [String]: The user's own Kick OAuth client secret paired with
  /// [KickOAuthClientId] - falls back to the app-owned
  /// `kKickOAuthClientSecret` constant (empty until an app-owned client
  /// exists)
  KickOAuthClientSecret,

  /// [bool]: Show the broadcaster badge in the native Twitch chat.
  /// Active by default
  TwitchChatBadgeBroadcaster,

  /// [bool]: Show the moderator badge in the native Twitch chat.
  /// Active by default
  TwitchChatBadgeModerator,

  /// [bool]: Show the VIP badge in the native Twitch chat.
  /// Active by default
  TwitchChatBadgeVip,

  /// [bool]: Show the subscriber badge in the native Twitch chat.
  /// Active by default
  TwitchChatBadgeSubscriber,

  /// [bool]: Show the founder badge in the native Twitch chat.
  /// Active by default
  TwitchChatBadgeFounder,

  /// [bool]: Show bits (cheer) badges in the native Twitch chat.
  /// Active by default
  TwitchChatBadgeBits,

  /// [bool]: Show all badges not covered by the dedicated toggles
  /// (sub-gifter, staff, partner, premium, event badges, ...).
  /// Active by default
  TwitchChatBadgeOther,

  /// [bool]: Render 7TV/BTTV/FFZ emotes inline in the native Twitch chat
  /// (fetches the public 7TV/BTTV/FFZ catalogs on chat connect).
  /// Active by default
  TwitchChatThirdPartyEmotes,

  /// [double]: Native chat message text size in logical pixels (sp).
  /// Default 14 — see appearance options sheet.
  TwitchChatTextSize,

  /// [double]: Inline emote height/width in the native chat (px).
  /// Default 20.
  TwitchChatEmoteSize,

  /// [double]: Vertical padding (px) above/below each native chat message.
  /// Default 4.
  TwitchChatMessageSpacing,

  /// [bool]: Show sub / gift / upgrade chat notifications.
  /// Active by default
  TwitchChatNoticeSubs,

  /// [bool]: Show watch-streak chat notifications.
  /// Active by default
  TwitchChatNoticeStreaks,

  /// [bool]: Show raid / unraid chat notifications.
  /// Active by default
  TwitchChatNoticeRaids,

  /// [bool]: Show announcement chat notifications.
  /// Active by default
  TwitchChatNoticeAnnouncements,

  /// [bool]: Show bits-badge-tier chat notifications.
  /// Active by default
  TwitchChatNoticeBitsBadge,

  /// [bool]: Show charity-donation chat notifications.
  /// Active by default
  TwitchChatNoticeCharity,

  /// [bool]: Show modiversary chat notifications.
  /// Active by default
  TwitchChatNoticeModiversary,

  /// [bool]: Show unrecognized chat notification types.
  /// Active by default
  TwitchChatNoticeOther,

  /// [bool]: Highlight first-time chatter messages (`user_intro`).
  /// Active by default
  TwitchChatNoticeFirstMessage,

  /// [bool]: Draw a very thin hairline between native chat messages.
  /// Off by default.
  TwitchChatMessageSeparators,

  /// [bool]: Prefix native chat lines with their time (all engines).
  /// Off by default
  ChatShowTimestamps,

  /// [bool]: Tint every other native chat row (all engines).
  /// Off by default
  ChatAlternateRows,

  /// [bool]: Adjust chatter name colors that are hard to read on the chat
  /// background (all engines). Active by default
  ChatReadableNameColors,

  /// [bool]: Backfill recent chat history (recent-messages.robotty.de)
  /// when the native Twitch chat joins a channel.
  /// Active by default
  TwitchChatLoadHistory,

  /// [List<dynamic>]: json maps ([TwitchChannelRef.toJson]) of the
  /// channels the user added to the native multi-chat. The user's own
  /// channel is never stored here — it is derived from the Twitch auth.
  NativeChatChannels,

  /// [String?]: id of the currently selected native chat channel;
  /// null/missing means the user's own channel (the default)
  SelectedNativeChatChannelId,

  /// [bool]: If user wants to use his custom theme
  CustomTheme,

  /// [String]: UUID of the active custom theme (only used if [CustomTheme] is true)
  ActiveCustomThemeUUID,

  /// [bool]: If we should use the "non native" elements like switch, dialogs in
  /// the app now that the app is somewhat adaptive
  ForceNonNativeElements,

  /// [bool]: Indicates if the user wants to let his device stay active in the [DashboardView].
  /// Active by default
  WakeLock,

  /// [bool]: If true, the dashboard will transform into a "streaming"
  /// mode where scene preview and chat will be the focus while the
  /// rest will be cut or shown underneath
  StreamingMode,

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

  /// [bool]: If the profile dropdown to see the current profile and
  /// change it should be shown in the dashboard
  ExposeProfile,

  /// [bool]: If the replay buffer functions (start/stop/save) should be shown in the
  /// dashboard instead of in the menu action list of the app bar
  ExposeReplayBufferControls,

  /// [bool]: If the hotkeys button (and feature) should be shown in the dashboard
  /// so users can list available OBS hotkeys and trigger them
  ExposeHotkeys,

  /// [bool]: If audio sync offset should be shown for each audio input and if
  /// they can be adjusted in the app
  ExposeInputAudioSyncOffset,

  /// [bool]: If true OBS Blade will try to reconnect to an OBS instance on connection
  /// lost indefinetily instead of an amount of retries before aborting
  UnlimitedReconnects,

  /// [bool]: If true, a toast is shown in the dashboard when an OBS command
  /// (scene switch, mute, ...) definitively fails (rejected / timed out /
  /// connection lost) after the state has been re-synced from OBS. If false,
  /// failures are only written to the logs. Active by default
  CommandFailureToasts,

  /// [List<DashboardElement>]: A list which represents the order in which the
  /// elements in the dashboard will be shown
  DashboardElementsOrder,

  /// [bool]: Whether the floating stream-health pill (bitrate / dropped
  /// frames / cpu) overlays the scene preview in streaming mode. On by
  /// default - toggled via the floating chart button on the preview
  StreamingModeStatsOverlay,

  /// [bool]: Whether the floating chat-header panel (platform / channel /
  /// engine / account controls) is currently open over the chat in
  /// streaming mode. Hidden by default - toggled via the floating tune
  /// button on the chat
  StreamingModeChatHeaderOpen,

  /// [double]: Vertical position of the floating chat-header toggle in
  /// streaming mode as a 0..1 fraction of its draggable range (right edge,
  /// clamped between the window header zone and the input dock).
  /// 1.0 = bottom (default)
  StreamingModeChatToggleDyFraction,

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

  /// [bool]: Legacy. The YouTube chat beta warning is no longer shown.
  /// The key stays so existing installs keep a stable settings map.
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

  /// [bool]: Dead — belonged to the removed "consider Blacksmith before
  /// tipping" nudge (Blacksmith is no longer sold). Key kept so existing
  /// settings boxes keep decoding.
  DontShowConsiderBlacksmithBeforeTip,

  /// [bool]: If the user saw the message regarding the technical preview state of
  /// the hotkey feature and doesn't want to see this warning again
  DontShowHotkeysTechnicalPreviewWarning,

  /// [bool]: Show sub / gift-sub chat notifications in native Kick chat.
  /// Active by default
  KickChatNoticeSubs,

  /// [bool]: Show host chat notifications in native Kick chat.
  /// Active by default
  KickChatNoticeHosts,

  /// [bool]: Render third-party (7TV) emotes inline in native Kick chat.
  /// Active by default
  KickChatThirdPartyEmotes,

  /// [bool]: Show role badge artwork next to names in native Kick chat.
  /// A single master toggle, unlike Twitch's per-category rows — Kick's
  /// `badge_type` values are free-form and unverified, so there is no
  /// stable catalog to build per-category rows from. Active by default
  KickChatBadges,

  /// [bool]: Wash a message row when it contains the signed-in user's own
  /// display name — shared across all three native engines (not
  /// per-engine: the feature and its master toggle are the same
  /// everywhere). Active by default
  ChatHighlightSelfMention,

  /// [String]: Raw newline/comma-separated extra highlight keywords,
  /// shared across all three native engines — see
  /// [parseChatHighlightKeywords]. Empty by default (feature is
  /// self-mention-only until the user adds something)
  ChatHighlightKeywords,

  /// [String]: Raw newline/comma-separated mute words, shared across all
  /// three native engines — see [chatContentIsMuted]. A match drops the
  /// row from the timeline entirely (filtered at the message-list level,
  /// not per-row). Empty by default (no-op until the user adds something)
  ChatMuteWords,

  /// [bool]: Mute-word matches are replaced with `***` instead of hiding
  /// the whole row (Chatterino's ignore "replace" mode). Off by default
  ChatMuteReplace,

  /// [String]: Raw newline/comma-separated usernames whose messages get
  /// the highlight wash (all engines) — see [parseChatUserList]
  ChatHighlightUsers,

  /// [String]: Raw newline/comma-separated usernames whose messages are
  /// hidden from the timeline (all engines) — see [parseChatUserList]
  ChatIgnoredUsers;

  String get name => const {
    // SettingsKeys.HasUserSeenIntro: 'has-user-seen-intro',
    SettingsKeys.HasUserSeenIntro202208: 'has-user-seen-intro-202208',
    SettingsKeys.BoughtBlacksmith: 'bought-blacksmith',
    SettingsKeys.BoughtPro: 'bought-pro',
    SettingsKeys.ProDebugOverride: 'pro-debug-override',
    SettingsKeys.ProColdStartRestoreDone: 'pro-cold-start-restore-done',
    SettingsKeys.TrueDark: 'true-dark',
    SettingsKeys.ReduceSmearing: 'reduce-smearing',
    SettingsKeys.EnforceTabletMode: 'enforce-tablet-mode',
    SettingsKeys.SelectedChatType: 'selected-chat-type',
    SettingsKeys.SelectedChatEngine: 'selected-chat-engine',
    SettingsKeys.TwitchUsernames: 'twitch-usernames',
    SettingsKeys.SelectedTwitchUsername: 'selected-twitch-username',
    SettingsKeys.YouTubeUsernames: 'youtube-usernames',
    SettingsKeys.SelectedYouTubeUsername: 'selected-youtube-username',
    SettingsKeys.YouTubeApiKey: 'youtube-api-key',
    SettingsKeys.YouTubeOAuthClientId: 'youtube-oauth-client-id',
    SettingsKeys.YouTubeOAuthClientSecret: 'youtube-oauth-client-secret',
    SettingsKeys.SelectedYouTubeNativeChannelId:
        'selected-youtube-native-channel-id',
    SettingsKeys.OwncastUsernames: 'owncast-usernames',
    SettingsKeys.SelectedOwncastUsername: 'selected-owncast-username',
    SettingsKeys.KickUsernames: 'kick-usernames',
    SettingsKeys.SelectedKickUsername: 'selected-kick-username',
    SettingsKeys.SelectedKickNativeOwnChannel:
        'selected-kick-native-own-channel',
    SettingsKeys.MyChatsDisabledPlatforms: 'my-chats-disabled-platforms',
    SettingsKeys.CombinedChatRestore: 'combined-chat-restore',
    SettingsKeys.CombinedChatCombos: 'combined-chat-combos',
    SettingsKeys.SelectedCombinedCombo: 'selected-combined-combo',
    SettingsKeys.CombinedChatSendTarget: 'combined-chat-send-target',
    SettingsKeys.KickOAuthClientId: 'kick-oauth-client-id',
    SettingsKeys.KickOAuthClientSecret: 'kick-oauth-client-secret',
    SettingsKeys.TwitchChatBadgeBroadcaster: 'twitch-chat-badge-broadcaster',
    SettingsKeys.TwitchChatBadgeModerator: 'twitch-chat-badge-moderator',
    SettingsKeys.TwitchChatBadgeVip: 'twitch-chat-badge-vip',
    SettingsKeys.TwitchChatBadgeSubscriber: 'twitch-chat-badge-subscriber',
    SettingsKeys.TwitchChatBadgeFounder: 'twitch-chat-badge-founder',
    SettingsKeys.TwitchChatBadgeBits: 'twitch-chat-badge-bits',
    SettingsKeys.TwitchChatBadgeOther: 'twitch-chat-badge-other',
    SettingsKeys.TwitchChatThirdPartyEmotes: 'twitch-chat-third-party-emotes',
    SettingsKeys.TwitchChatTextSize: 'twitch-chat-text-size',
    SettingsKeys.TwitchChatEmoteSize: 'twitch-chat-emote-size',
    SettingsKeys.TwitchChatMessageSpacing: 'twitch-chat-message-spacing',
    SettingsKeys.TwitchChatMessageSeparators: 'twitch-chat-message-separators',
    SettingsKeys.TwitchChatLoadHistory: 'twitch-chat-load-history',
    SettingsKeys.ChatShowTimestamps: 'chat-show-timestamps',
    SettingsKeys.ChatAlternateRows: 'chat-alternate-rows',
    SettingsKeys.ChatReadableNameColors: 'chat-readable-name-colors',
    SettingsKeys.TwitchChatNoticeSubs: 'twitch-chat-notice-subs',
    SettingsKeys.TwitchChatNoticeStreaks: 'twitch-chat-notice-streaks',
    SettingsKeys.TwitchChatNoticeRaids: 'twitch-chat-notice-raids',
    SettingsKeys.TwitchChatNoticeAnnouncements:
        'twitch-chat-notice-announcements',
    SettingsKeys.TwitchChatNoticeBitsBadge: 'twitch-chat-notice-bits-badge',
    SettingsKeys.TwitchChatNoticeCharity: 'twitch-chat-notice-charity',
    SettingsKeys.TwitchChatNoticeModiversary: 'twitch-chat-notice-modiversary',
    SettingsKeys.TwitchChatNoticeOther: 'twitch-chat-notice-other',
    SettingsKeys.TwitchChatNoticeFirstMessage:
        'twitch-chat-notice-first-message',
    SettingsKeys.NativeChatChannels: 'native-chat-channels',
    SettingsKeys.SelectedNativeChatChannelId: 'selected-native-chat-channel-id',
    SettingsKeys.CustomTheme: 'custom-theme',
    SettingsKeys.ActiveCustomThemeUUID: 'active-custom-theme-uuid',
    SettingsKeys.ForceNonNativeElements: 'force-non-native-elements',
    SettingsKeys.WakeLock: 'wake-lock',
    SettingsKeys.StreamingMode: 'streaming-mode',
    SettingsKeys.ExposeRecordingControls: 'expose-recording-controls',
    SettingsKeys.ExposeStudioControls: 'expose-studio-controls',
    SettingsKeys.ExposeStreamingControls: 'expose-streaming-controls',
    SettingsKeys.ExposeScenePreview: 'expose-scene-preview',
    SettingsKeys.ExposeSceneCollection: 'expose-scene-collection',
    SettingsKeys.ExposeProfile: 'expose-profile',
    SettingsKeys.ExposeReplayBufferControls: 'expose-replay-buffer-collection',
    SettingsKeys.ExposeHotkeys: 'expose-hotkeys',
    SettingsKeys.ExposeInputAudioSyncOffset: 'expose-input-audio-sync-offset',
    SettingsKeys.UnlimitedReconnects: 'unlimited-reconnects',
    SettingsKeys.CommandFailureToasts: 'command-failure-toasts',
    SettingsKeys.DashboardElementsOrder: 'dashboard-elements-order',
    SettingsKeys.StreamingModeStatsOverlay: 'streaming-mode-stats-overlay',
    SettingsKeys.StreamingModeChatHeaderOpen: 'streaming-mode-chat-header-open',
    SettingsKeys.StreamingModeChatToggleDyFraction:
        'streaming-mode-chat-toggle-dy-fraction',
    SettingsKeys.DontShowPreviewWarning: 'dont-show-preview-warning',
    SettingsKeys.DontShowHidingSceneItemsWarning:
        'dont-show-hiding-scene-items-warning',
    SettingsKeys.DontShowYouTubeChatBetaWarning:
        'dont-show-youtube-chat-beta-warning',
    SettingsKeys.DontShowHidingScenesWarning: 'dont-show-hiding-scenes-warning',
    SettingsKeys.DontShowStreamStartMessage: 'dont-show-stream-start-message',
    SettingsKeys.DontShowStreamStopMessage: 'dont-show-stream-stop-message',
    SettingsKeys.DontShowRecordStartMessage: 'dont-show-record-start-message',
    SettingsKeys.DontShowRecordStopMessage: 'dont-show-record-stop-message',
    SettingsKeys.DontShowConsiderBlacksmithBeforeTip:
        'dont-show-consider-blacksmith-before-tip',
    SettingsKeys.DontShowHotkeysTechnicalPreviewWarning:
        'dont-show-hotkeys-technical-preview-warning',
    SettingsKeys.KickChatNoticeSubs: 'kick-chat-notice-subs',
    SettingsKeys.KickChatNoticeHosts: 'kick-chat-notice-hosts',
    SettingsKeys.KickChatThirdPartyEmotes: 'kick-chat-third-party-emotes',
    SettingsKeys.KickChatBadges: 'kick-chat-badges',
    SettingsKeys.ChatHighlightSelfMention: 'chat-highlight-self-mention',
    SettingsKeys.ChatHighlightKeywords: 'chat-highlight-keywords',
    SettingsKeys.ChatMuteWords: 'chat-mute-words',
    SettingsKeys.ChatMuteReplace: 'chat-mute-replace',
    SettingsKeys.ChatHighlightUsers: 'chat-highlight-users',
    SettingsKeys.ChatIgnoredUsers: 'chat-ignored-users',
  }[this]!;
}
