import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/shared/general/custom_expansion_tile.dart';
import 'package:obs_blade/utils/youtube_target.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../../models/app_log.dart';
import '../../../../../models/enums/chat_type.dart';
import '../../../../../models/enums/chat_engine.dart';
import '../../../../../models/enums/log_level.dart';
import '../../../../../shared/design/design.dart';
import '../../../../../shared/dialogs/confirmation.dart';
import '../../../../../shared/general/base/button.dart';
import '../../../../../shared/general/hive_builder.dart';
import '../../../../../stores/pro_store.dart';
import '../../../../../stores/views/combined_chat.dart';
import '../../../../../stores/views/kick_chat.dart';
import '../../../../../stores/views/twitch_chat.dart';
import '../../../../../stores/views/youtube_chat.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../../../../../types/enums/settings_keys.dart';
import '../../../../../utils/icons/jam_icons.dart';
import '../../../../../utils/modal_handler.dart';
import '../../../../../utils/routing_helper.dart';
import '../../../../../utils/styling_helper.dart';
import '../../../../pro/widgets/pro_benefits.dart';
import '../../../../settings/widgets/accent_icon_tile.dart';
import 'chat_type_brand.dart';
import 'chat_username_bar.dart/chat_username_bar.dart';
import 'chat_username_bar.dart/dialogs/add_edit_kick_username.dart';
import 'chat_username_bar.dart/dialogs/add_edit_owncast_username.dart';
import 'chat_username_bar.dart/dialogs/add_edit_twitch_username.dart';
import 'chat_username_bar.dart/dialogs/add_edit_youtube_username.dart';
import 'chat_completion_sources.dart';
import 'chat_emote_picker.dart';
import 'kick_emote_picker.dart';
import 'kick_chat_mode_strip.dart';
import 'kick_reply_strip.dart';
import 'kick_setup_sheet.dart';
import 'native_chat_input.dart';
import 'native_chat_chrome.dart';
import 'native_chat_window.dart';
import 'native_combined_chat_view.dart';
import 'combined_sources_sheet.dart';
import 'native_kick_chat_view.dart';
import 'native_reply_strip.dart';
import 'native_twitch_chat_view.dart';
import 'native_youtube_chat_view.dart';
import 'twitch_device_code_dialog.dart';
import 'youtube_device_code_dialog.dart';
import 'youtube_setup_sheet.dart';
import 'youtube_web_live_tracker.dart';

/// Maps the Twitch store's connection state (+ login) onto the chat
/// window's platform-agnostic status.
NativeChatConnectionStatus twitchChatWindowStatus(
  TwitchChatConnectionState state,
  bool isLoggedIn,
) {
  if (!isLoggedIn) return NativeChatConnectionStatus.offline;
  return switch (state) {
    TwitchChatConnectionState.live => NativeChatConnectionStatus.live,
    TwitchChatConnectionState.connecting =>
      NativeChatConnectionStatus.connecting,
    TwitchChatConnectionState.reconnecting =>
      NativeChatConnectionStatus.reconnecting,
    TwitchChatConnectionState.failed => NativeChatConnectionStatus.failed,
    TwitchChatConnectionState.disconnected =>
      NativeChatConnectionStatus.offline,
  };
}

/// Maps the YouTube store's connection state onto the chat window's
/// platform-agnostic status. Unlike Twitch, reads don't need a sign-in —
/// the gate is API-key configuration, and a video without an active live
/// chat is `offline` (a normal state, not a failure).
NativeChatConnectionStatus youTubeChatWindowStatus(
  YouTubeChatConnectionState state,
  bool isConfigured,
) {
  if (!isConfigured) return NativeChatConnectionStatus.offline;
  return switch (state) {
    YouTubeChatConnectionState.connected => NativeChatConnectionStatus.live,
    YouTubeChatConnectionState.connecting =>
      NativeChatConnectionStatus.connecting,
    YouTubeChatConnectionState.error => NativeChatConnectionStatus.failed,
    YouTubeChatConnectionState.idle => NativeChatConnectionStatus.offline,
    YouTubeChatConnectionState.offline => NativeChatConnectionStatus.offline,
  };
}

/// Maps the Kick store's connection state onto the chat window's
/// platform-agnostic status. Kick reads are anonymous (no account, no API
/// key) — the only gates are the entitlement and a channel selection,
/// both covered by `idle`.
NativeChatConnectionStatus kickChatWindowStatus(KickChatConnectionState state) {
  return switch (state) {
    KickChatConnectionState.connected => NativeChatConnectionStatus.live,
    KickChatConnectionState.connecting => NativeChatConnectionStatus.connecting,
    KickChatConnectionState.reconnecting =>
      NativeChatConnectionStatus.reconnecting,
    KickChatConnectionState.error => NativeChatConnectionStatus.failed,
    KickChatConnectionState.idle => NativeChatConnectionStatus.offline,
    KickChatConnectionState.offline => NativeChatConnectionStatus.offline,
  };
}

class StreamChat extends StatefulWidget {
  final bool usernameRowExpandable;
  final bool usernameRowBeneath;

  /// Don't render the [ChatUsernameBar] inline - the host floats it as an
  /// overlay instead (streaming mode, where every vertical pixel goes to
  /// the chat window). The other usernameRow* flags are inert while hidden.
  final bool hideUsernameBar;

  /// Route the locked-Pro upsell pill pushes. Null = the Home tab's
  /// paywall route (the dashboard context); other tab hosts pass their own
  /// paywall route so the push resolves on their navigator.
  final String? proRoute;

  const StreamChat({
    super.key,
    this.usernameRowExpandable = false,
    this.usernameRowBeneath = false,
    this.hideUsernameBar = false,
    this.proRoute,
  });

  @override
  _StreamChatState createState() => _StreamChatState();
}

class _StreamChatState extends State<StreamChat>
    with AutomaticKeepAliveClientMixin {
  WebViewController? _webController;
  String? _loadedChatUrl;

  /// Branded loading surface covering the [WebView] until the page reports
  /// back as loaded - hides the white flash of the keyed reload
  bool _isChatLoading = false;

  /// Safety net so the loading surface can't get stuck if the page never
  /// reaches 100% progress (long polling chat pages)
  Timer? _loadingFallback;

  /// True while the chat page sits on a Google consent / sign-in host
  /// (drives the hint overlay - the page itself stays fully interactive)
  bool _webAuthWalled = false;

  /// Dock controller/focus for the native input — owned here so the emote
  /// picker (the dock's leading slot) can insert codes at the cursor and
  /// refocus after its sheet closes.
  final TextEditingController _chatInputController = TextEditingController();
  final FocusNode _chatInputFocusNode = FocusNode();

  /// Follows a YouTube *channel* entry's current stream for the WebView
  /// (the popout chat URL only takes a video id).
  final YouTubeWebLiveTracker _youTubeLiveTracker = YouTubeWebLiveTracker();

  @override
  void initState() {
    super.initState();
    this._youTubeLiveTracker.addListener(this._onYouTubeLiveChanged);
  }

  void _onYouTubeLiveChanged() {
    if (this.mounted) setState(() {});
  }

  static const _mobileSafariUserAgent =
      'Mozilla/5.0 (iPhone; CPU iPhone OS 15_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.6 Mobile/15E148 Safari/604.1';

  static const _consentBannerScript = '''
            if (document.body !== undefined) {
              let observer = new MutationObserver((mutations) => {
                mutations.forEach((mutation) => {
                  if(document.getElementsByClassName('consent-banner').length > 0) {
                    [...document.getElementsByClassName('consent-banner')].forEach((element) => element.remove());
                    observer.disconnect();
                  }
                });
              });

              observer.observe(document.body, {
                characterDataOldValue: true, 
                subtree: true, 
                childList: true, 
                characterData: true
              });
            }
          ''';

  WebViewController _createWebController() {
    final controller = WebViewController()
      ..enableZoom(false)
      ..setUserAgent(_mobileSafariUserAgent)
      ..setBackgroundColor(Colors.transparent)
      ..setJavaScriptMode(JavaScriptMode.unrestricted);

    controller.setNavigationDelegate(
      NavigationDelegate.fromPlatformCreationParams(
        const PlatformNavigationDelegateCreationParams(),
        onProgress: (progress) {
          controller.runJavaScript(_consentBannerScript);
          if (progress >= 100) {
            _finishChatLoading();
          }
        },
        onUrlChange: (change) => _syncWebAuthWall(change.url),
      ),
    );
    return controller;
  }

  /// Hosts YouTube bounces the chat embed onto when it wants something from
  /// the viewer (GDPR consent regions, bot heuristics)
  static const _webAuthWallHosts = [
    'consent.youtube.com',
    'accounts.google.com',
  ];

  /// YouTube can redirect the chat embed onto a consent / sign-in page
  /// (per-region, per-IP-reputation, A/B - not predictable). That page is
  /// fully usable inside the [WebView] and cookies persist (the app never
  /// clears them), so the user taps through it once and it sticks - surface
  /// a hint instead of letting it look like chat broke.
  void _syncWebAuthWall(String? url) {
    final walled =
        url != null &&
        _webAuthWallHosts.any((host) => url.contains(host)) == true;
    if (walled == _webAuthWalled || !this.mounted) return;
    setState(() => _webAuthWalled = walled);
    if (walled) {
      Hive.box<AppLog>(HiveKeys.AppLog.name).add(
        AppLog(
          DateTime.now().millisecondsSinceEpoch,
          LogLevel.Info,
          'WebView chat bounced onto a Google consent/sign-in host ($url)',
        ),
      );
    }
  }

  void _finishChatLoading() {
    if (!this.mounted || !_isChatLoading) return;
    setState(() {
      _isChatLoading = false;
      _loadingFallback?.cancel();
    });
  }

  /// Create once; [loadRequest] only when the resolved chat URL changes.
  void _syncWebController(String url) {
    _webController ??= _createWebController();
    if (_loadedChatUrl == url) return;
    _loadedChatUrl = url;
    _webController!.loadRequest(Uri.parse(url));

    /// Plain assignment - called from `build` before the loading overlay is
    /// constructed, so it is reflected in the current frame already
    _isChatLoading = true;
    _webAuthWalled = false;
    _loadingFallback?.cancel();
    _loadingFallback = Timer(const Duration(seconds: 8), () {
      if (this.mounted && _isChatLoading) {
        setState(() => _isChatLoading = false);
      }
    });
  }

  @override
  void dispose() {
    this._chatInputController.dispose();
    this._chatInputFocusNode.dispose();
    this._youTubeLiveTracker
      ..removeListener(this._onYouTubeLiveChanged)
      ..dispose();
    _loadingFallback?.cancel();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  String _urlForChatType(
    ChatType chatType,
    Box<dynamic> settingsBox,
    Brightness brightness,
  ) {
    final dark = brightness == Brightness.dark;
    if (chatType == ChatType.Twitch &&
        (settingsBox.get(SettingsKeys.SelectedTwitchUsername.name)) != null) {
      /// darkpopout: Twitch's own dark-theme variant of the popout chat -
      /// follows the app's brightness so a light app theme gets Twitch's
      /// light popout instead of a forced dark one.
      final popout =
          'https://www.twitch.tv/popout/${settingsBox.get(SettingsKeys.SelectedTwitchUsername.name)}/chat';
      return dark ? '$popout?darkpopout' : popout;
    }
    if (chatType == ChatType.YouTube &&
        (settingsBox.get(SettingsKeys.SelectedYouTubeUsername.name)) != null) {
      final String? videoId = switch (this._selectedYouTubeTarget(
        settingsBox,
      )) {
        YouTubeVideoTarget(:final videoId) => videoId,

        /// Channel entry: whatever stream the tracker last resolved
        YouTubeChannelTarget() => this._youTubeLiveTracker.videoId,
        null => null,
      };
      if (videoId == null) return 'about:blank';

      /// YouTube's own popout-chat form: chat-only chrome, and carrying
      /// embed_domain keeps the embed check satisfied if YouTube ever
      /// enforces it on top-level WebView loads (docs require it for
      /// iframe embeds; the value is unverifiable without a parent frame).
      /// dark_theme is undocumented but long-standing (same shape as
      /// Twitch's darkpopout above) - follows the app's brightness instead
      /// of being forced on.
      final popout =
          'https://www.youtube.com/live_chat?is_popout=1&v=$videoId&embed_domain=localhost';
      return dark ? '$popout&dark_theme=1' : popout;
    }
    if (chatType == ChatType.Owncast &&
        (settingsBox.get(SettingsKeys.SelectedOwncastUsername.name)) != null) {
      final base =
          settingsBox.get(SettingsKeys.OwncastUsernames.name)[settingsBox.get(
                SettingsKeys.SelectedOwncastUsername.name,
              )]
              as String;
      return '${base.replaceAll(RegExp(r'/+$'), '')}/embed/chat/readwrite';
    }
    if (chatType == ChatType.Kick &&
        (settingsBox.get(SettingsKeys.SelectedKickUsername.name)) != null) {
      /// Kick's own documented chat-dock URL (their OBS help article) -
      /// dark-only UI, readable logged out, no frame restrictions
      return 'https://kick.com/popout/${settingsBox.get(SettingsKeys.SelectedKickUsername.name)}/chat';
    }
    return 'about:blank';
  }

  YouTubeTarget? _selectedYouTubeTarget(Box<dynamic> settingsBox) {
    final selected = settingsBox.get(SettingsKeys.SelectedYouTubeUsername.name);
    final entries = settingsBox.get(SettingsKeys.YouTubeUsernames.name);
    if (selected == null || entries is! Map) return null;
    final stored = entries[selected];
    return parseYouTubeTarget(stored is String ? stored : null);
  }

  /// The WebView YouTube channel entry to follow right now — null whenever
  /// the WebView isn't showing a YouTube channel entry (stops the tracker).
  YouTubeChannelTarget? _webYouTubeChannel(
    ChatType chatType,
    Box<dynamic> settingsBox,
    bool webViewShowing,
  ) {
    if (!webViewShowing || chatType != ChatType.YouTube) return null;
    final target = this._selectedYouTubeTarget(settingsBox);
    return target is YouTubeChannelTarget ? target : null;
  }

  bool anyChatActive(ChatType chatType, Box<dynamic> settingsBox) {
    bool twitchActive =
        chatType == ChatType.Twitch &&
        settingsBox.get(SettingsKeys.SelectedTwitchUsername.name) != null;
    bool youtubeActive =
        chatType == ChatType.YouTube &&
        settingsBox.get(SettingsKeys.SelectedYouTubeUsername.name) != null;
    bool owncastActive =
        chatType == ChatType.Owncast &&
        settingsBox.get(SettingsKeys.SelectedOwncastUsername.name) != null;
    bool kickActive =
        chatType == ChatType.Kick &&
        settingsBox.get(SettingsKeys.SelectedKickUsername.name) != null;

    return twitchActive || youtubeActive || owncastActive || kickActive;
  }

  @override
  Widget build(BuildContext context) {
    /// No horizontal inset — hosts own the page margin, so the bar's
    /// controls align edge-to-edge with the chat window below.
    Widget usernameBar = const Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: ChatUsernameBar(),
    );

    if (this.widget.usernameRowExpandable) {
      usernameBar = CustomExpansionTile(
        headerText: 'Chat options',
        headerTextStyle: nativeChatSheetTitleStyle(context),
        expandedBody: usernameBar,
      );
    }

    super.build(context);
    return Column(
      children: [
        if (!this.widget.hideUsernameBar && !this.widget.usernameRowBeneath)
          usernameBar,
        Expanded(
          child: HiveBuilder<dynamic>(
            hiveKey: HiveKeys.Settings,
            rebuildKeys: const [
              SettingsKeys.SelectedChatType,
              SettingsKeys.SelectedChatEngine,
              SettingsKeys.SelectedTwitchUsername,
              SettingsKeys.SelectedYouTubeUsername,
              SettingsKeys.SelectedOwncastUsername,
              SettingsKeys.SelectedKickUsername,
              SettingsKeys.YouTubeUsernames,
              SettingsKeys.OwncastUsernames,
              SettingsKeys.KickUsernames,
              SettingsKeys.YouTubeApiKey,
            ],
            builder: (context, settingsBox, child) {
              ChatType chatType = settingsBox.get(
                SettingsKeys.SelectedChatType.name,
                defaultValue: ChatType.Twitch,
              );

              final chatActive = anyChatActive(chatType, settingsBox);

              /// A native engine exists only where
              /// [nativeChatAvailableFor] says so (Twitch today)
              final nativeEngine =
                  isNativeOnly(chatType) ||
                  (nativeChatAvailableFor(chatType) &&
                      settingsBox.get(
                            SettingsKeys.SelectedChatEngine.name,
                            defaultValue: ChatEngine.webView,
                          ) ==
                          ChatEngine.native);

              /// Resolve before the URL is built below; tracking stops
              /// (timer cancelled) whenever no YouTube channel entry is
              /// on screen in the WebView.
              final youTubeChannel = this._webYouTubeChannel(
                chatType,
                settingsBox,
                chatActive && !nativeEngine,
              );
              this._youTubeLiveTracker.track(youTubeChannel);

              /// No WebView warm-up while the native engine owns the slot
              if (chatActive && !nativeEngine) {
                _syncWebController(
                  _urlForChatType(
                    chatType,
                    settingsBox,
                    Theme.of(context).brightness,
                  ),
                );
              }

              if (nativeEngine) {
                /// Pro entitlement gate: Observer over [ProStore.isPro] -
                /// the entitlement read combines the box flag + debug
                /// override, which the HiveBuilder rebuildKeys can't
                /// express. Not-Pro renders the upsell pane instead of
                /// every login/setup CTA; the WebView engine (legacy
                /// stack below) stays free forever.
                return Observer(
                  builder: (context) => GetIt.instance<ProStore>().isPro
                      ? this._buildNativeChatSlot(context, chatType)
                      : StaggeredEntrance(
                          scaleFrom: 0.985,
                          child: _ChatProUpsell(
                            chatType: chatType,
                            proRoute:
                                this.widget.proRoute ??
                                HomeTabRoutingKeys.Pro.route,
                          ),
                        ),
                );
              }

              return this._buildLegacyChatStack(
                context,
                settingsBox,
                chatType,
                chatActive,
                youTubeChannel,
              );
            },
          ),
        ),
        if (!this.widget.hideUsernameBar && this.widget.usernameRowBeneath)
          usernameBar,
      ],
    );
  }

  /// The native engine slot (Pro-gated by the caller): per-platform
  /// dispatch onto the Twitch / YouTube / Kick native chat windows.
  /// Verbatim the behavior before the entitlement gate existed.
  Widget _buildNativeChatSlot(BuildContext context, ChatType chatType) {
    /// Combined: read-only merge of the "My chats" sources
    /// ([CombinedChatStore] follows the chat type and points the platform
    /// stores at them). No input dock yet.
    if (chatType == ChatType.Combined) {
      return Observer(
        builder: (_) {
          final combined = GetIt.instance<CombinedChatStore>();
          final statuses = combined.sourceStatus.values;
          return NativeChatWindow(
            chatType: chatType,
            status: combinedChatWindowStatus(statuses),
            onStatusTapOverride: () => showCombinedSourcesSheet(context),
            child: combined.activeSources.isEmpty
                ? StaggeredEntrance(
                    scaleFrom: 0.985,
                    child: _ChatEmptyState(
                      chatType: chatType,
                      nativeConnectPrompt: true,
                      promptBody:
                          'Combined chat merges your own Twitch, YouTube and Kick chats. Sign in natively on at least one platform to start.',
                      connectLabel: 'Sign in to a platform',
                      onConnectTap: () => showCombinedSourcesSheet(context),
                    ),
                  )
                : const NativeCombinedChatView(),
          );
        },
      );
    }

    /// Native Kick chat: anonymous reads (no account, no API key) — the
    /// only prerequisite is a channel in the Kick list, so the
    /// unselected state offers the add dialog directly. The optional
    /// Kick sign-in (setup sheet) unlocks the input dock; signed out,
    /// the dock is a read-only strip with a sign-in affordance.
    if (chatType == ChatType.Kick) {
      void addKickChannel() =>
          ModalHandler.showBaseDialog(
            context: context,
            dialogWidget: AddEditKickUsernameDialog(
              settingsBox: Hive.box(HiveKeys.Settings.name),
            ),
          ).then((_) {
            /// The dialog edited [SettingsKeys.KickUsernames] AND selected
            /// the new slug ([SettingsKeys.SelectedKickUsername] is shared
            /// with the native engine) — re-read, then follow the
            /// dialog's selection when nothing is selected yet.
            final store = GetIt.instance<KickChatStore>();
            store.reloadChannels();
            final selected = Hive.box(
              HiveKeys.Settings.name,
            ).get(SettingsKeys.SelectedKickUsername.name);
            if (store.selectedChannelSlug == null && selected is String) {
              store.selectChannel(selected);
            }
          });

      return Observer(
        builder: (_) {
          final kickStore = GetIt.instance<KickChatStore>();
          final hasChannel = kickStore.selectedChannelSlug != null;
          final channelInfo = kickStore.channelInfo;

          return NativeChatWindow(
            chatType: chatType,
            status: kickChatWindowStatus(kickStore.chatConnection),
            statusDetail: kickStore.chatError,
            connectedAt: kickStore.chatConnectedAt,
            channelIsLive: channelInfo?.isLive ?? false,
            channelViewerCount: (channelInfo?.isLive ?? false)
                ? channelInfo?.viewerCount
                : null,
            onRetry: kickStore.connectChat,
            onConnect: addKickChannel,
            child: hasChannel
                ? NativeKickChatView(
                    /// Fresh scroll state per channel — avoids
                    /// carrying a stuck/overscrolled controller
                    /// across multi-chat switches.
                    key: ValueKey(kickStore.selectedChannelSlug),
                    onReplyTargetSet: () =>
                        this._chatInputFocusNode.requestFocus(),
                  )
                : StaggeredEntrance(
                    scaleFrom: 0.985,
                    child: _ChatEmptyState(
                      chatType: chatType,
                      nativeConnectPrompt: true,
                      promptBody:
                          'Native Kick chat reads the channel\'s public chatroom - no account or API key needed. Add a Kick channel to see chat here.',
                      connectLabel: 'Add Kick channel',
                      onConnectTap: addKickChannel,
                    ),
                  ),
            input: hasChannel
                ? NativeChatInput(
                    controller: this._chatInputController,
                    focusNode: this._chatInputFocusNode,
                    leading: KickEmotePickerButton(
                      controller: this._chatInputController,
                      focusNode: this._chatInputFocusNode,
                      accentColor:
                          chatType.brandColor ??
                          Theme.of(context).colorScheme.secondary,
                    ),
                    canSend: kickStore.isSignedInState && kickStore.canWrite,
                    inFlight: kickStore.sendingChat,
                    errorText: kickStore.sendChatError,
                    contextStrip: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        KickChatModeStrip(
                          accentColor:
                              chatType.brandColor ??
                              Theme.of(context).colorScheme.secondary,
                        ),
                        KickReplyStrip(
                          accentColor:
                              chatType.brandColor ??
                              Theme.of(context).colorScheme.secondary,
                        ),
                      ],
                    ),
                    accentColor:
                        chatType.brandColor ??
                        Theme.of(context).colorScheme.secondary,
                    completionSource: kickChatCompletions,
                    onSend: kickStore.sendChatMessage,
                    onRelogin: () => showKickSetupSheet(context),
                    lockedHintText: 'Chat is read-only',
                    lockedActionText: 'Sign in to chat',
                  )
                : null,
          );
        },
      );
    }

    /// Native YouTube chat: API-key gated reads (signed-out
    /// timelines work — the input docks a read-only strip with
    /// a sign-in affordance), device-flow sign-in for writes.
    /// Unconfigured (no API key) shows the setup CTA.
    if (chatType == ChatType.YouTube) {
      return Observer(
        builder: (_) {
          final youTubeStore = GetIt.instance<YouTubeChatStore>();
          final configured =
              youTubeStore.authState != YouTubeAuthState.unconfigured;
          final signedIn = youTubeStore.isSignedInState;
          final channelTitle = youTubeStore.selfChannelTitle;

          return NativeChatWindow(
            chatType: chatType,
            status: youTubeChatWindowStatus(
              youTubeStore.chatConnection,
              configured,
            ),
            statusDetail: youTubeStore.chatError,
            accountLabel: channelTitle,
            channelIsLive:
                youTubeStore.chatConnection ==
                YouTubeChatConnectionState.connected,
            channelViewerCount:
                youTubeStore.chatConnection ==
                    YouTubeChatConnectionState.connected
                ? youTubeStore.selectedChannelViewerCount
                : null,
            onRetry: youTubeStore.connectChat,
            onConnect: () => configured
                ? startYouTubeLogin(context)
                : showYouTubeSetupSheet(context),
            onLogout: signedIn
                ? () => ModalHandler.showBaseDialog(
                    context: context,
                    dialogWidget: ConfirmationDialog(
                      title: 'Disconnect YouTube?',
                      body:
                          'Connected as ${channelTitle ?? 'your YouTube channel'}. You will be signed out of your Google account.',
                      okText: 'Disconnect',
                      isYesDestructive: true,
                      onOk: (_) => youTubeStore.logout(),
                    ),
                  )
                : null,
            child: configured
                ? NativeYouTubeChatView(
                    /// Fresh scroll state per channel — avoids
                    /// carrying a stuck/overscrolled controller
                    /// across multi-chat switches.
                    key: ValueKey(youTubeStore.selectedChannelLabel),
                  )
                : StaggeredEntrance(
                    scaleFrom: 0.985,
                    child: _ChatEmptyState(
                      chatType: chatType,
                      nativeConnectPrompt: true,
                      promptBody:
                          'Native YouTube chat reads through the official YouTube Data API and needs a free Google Cloud API key - set it up to see chat here.',
                      connectLabel: 'Set up YouTube chat',
                      onConnectTap: () => showYouTubeSetupSheet(context),
                    ),
                  ),
            input: configured
                ? NativeChatInput(
                    controller: this._chatInputController,
                    focusNode: this._chatInputFocusNode,
                    canSend: signedIn && youTubeStore.canWrite,
                    inFlight: youTubeStore.sendingChat,
                    errorText: youTubeStore.sendChatError,
                    accentColor:
                        chatType.brandColor ??
                        Theme.of(context).colorScheme.secondary,
                    completionSource: youTubeChatCompletions,
                    onSend: youTubeStore.sendChatMessage,
                    onRelogin: () => startYouTubeLogin(context),
                    lockedHintText: 'Chat is read-only',
                    lockedActionText: 'Sign in to chat',
                  )
                : null,
          );
        },
      );
    }

    /// Native Twitch chat takes over the slot when the native
    /// engine is selected, wrapped in the chat window (pane +
    /// status row + connection sheet). Logged out, the content is
    /// the connect prompt. The WebView engine keeps the legacy
    /// path regardless of the login state.
    return Observer(
      builder: (_) {
        final twitchStore = GetIt.instance<TwitchChatStore>();
        final loggedIn = twitchStore.isLoggedIn;
        final displayName =
            twitchStore.user?.displayName ?? twitchStore.user?.login;

        return NativeChatWindow(
          chatType: chatType,
          status: twitchChatWindowStatus(twitchStore.chatConnection, loggedIn),
          statusDetail: twitchStore.chatError,
          accountLabel: displayName,
          connectedAt: twitchStore.chatConnectedAt,
          channelIsLive: loggedIn && twitchStore.selectedChannelIsLive,
          channelViewerCount: loggedIn && twitchStore.selectedChannelIsLive
              ? twitchStore.selectedChannelViewerCount
              : null,
          channelIsMod: loggedIn && twitchStore.canModerateSelectedChannel,
          onRetry: twitchStore.connectChat,
          onConnect: () => startTwitchLogin(context),
          onLogout: () => ModalHandler.showBaseDialog(
            context: context,
            dialogWidget: ConfirmationDialog(
              title: 'Disconnect Twitch?',
              body:
                  'Connected as ${displayName ?? 'your Twitch account'}. You will be logged out of your Twitch account.',
              okText: 'Disconnect',
              isYesDestructive: true,
              onOk: (_) => twitchStore.logout(),
            ),
          ),
          selfUserId: loggedIn ? twitchStore.user?.id : null,
          child: loggedIn
              ? NativeTwitchChatView(
                  /// Fresh scroll state per channel — avoids
                  /// carrying a stuck/overscrolled controller
                  /// across multi-chat switches. Null-safe:
                  /// logged-in shells may not have [user] yet.
                  key: ValueKey(twitchStore.effectiveBroadcasterIdSafe),
                  onReplyTargetSet: () =>
                      this._chatInputFocusNode.requestFocus(),
                )
              : StaggeredEntrance(
                  scaleFrom: 0.985,
                  child: _ChatEmptyState(
                    chatType: chatType,
                    nativeConnectPrompt: true,
                  ),
                ),
          input: loggedIn
              ? NativeChatInput(
                  controller: this._chatInputController,
                  focusNode: this._chatInputFocusNode,
                  leading: ChatEmotePickerButton(
                    controller: this._chatInputController,
                    focusNode: this._chatInputFocusNode,
                    canReadEmotes: twitchStore.canReadEmotes,
                    accentColor:
                        chatType.brandColor ??
                        Theme.of(context).colorScheme.secondary,
                    onRelogin: () => startTwitchLogin(context),
                  ),
                  contextStrip: NativeReplyStrip(
                    accentColor:
                        chatType.brandColor ??
                        Theme.of(context).colorScheme.secondary,
                  ),
                  canSend: twitchStore.canWriteChat,
                  inFlight: twitchStore.sendingChat,
                  errorText: twitchStore.sendChatError,
                  accentColor:
                      chatType.brandColor ??
                      Theme.of(context).colorScheme.secondary,
                  completionSource: twitchChatCompletions,
                  onSend: twitchStore.sendChatMessage,
                  onRelogin: () => startTwitchLogin(context),
                )
              : null,
        );
      },
    );
  }

  /// The pre-native chat slot: WebView embed + loading/empty states.
  /// Verbatim the behavior before native Twitch chat existed.
  Widget _buildLegacyChatStack(
    BuildContext context,
    Box<dynamic> settingsBox,
    ChatType chatType,
    bool chatActive,
    YouTubeChannelTarget? youTubeChannel,
  ) {
    /// A channel entry with no resolved stream yet: the WebView sits on
    /// about:blank underneath, this panel explains why.
    final youTubeWaiting =
        youTubeChannel != null && this._youTubeLiveTracker.videoId == null;
    return Stack(
      alignment: Alignment.center,
      children: [
        /// Only add the [WebView] to the widget tree if we have an
        /// actual chat to display because otherwise the [WebView]
        /// will still eat up performance
        if (chatActive && _webController != null) ...[
          WebViewWidget(
            key: Key(
              chatType.toString() +
                  settingsBox
                      .get(SettingsKeys.SelectedTwitchUsername.name)
                      .toString() +
                  settingsBox
                      .get(SettingsKeys.SelectedYouTubeUsername.name)
                      .toString() +
                  settingsBox
                      .get(SettingsKeys.SelectedOwncastUsername.name)
                      .toString() +
                  settingsBox
                      .get(SettingsKeys.SelectedKickUsername.name)
                      .toString(),
            ),
            controller: _webController!,
          ),

          /// Crossfading branded surface hiding the flash of the
          /// keyed [WebView] reload until the page has loaded -
          /// purely visual: IgnorePointer makes touches always fall
          /// through to the [WebView] as before - opacity alone does
          /// not exempt a widget from hit testing
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: _isChatLoading ? 1.0 : 0.0,
              duration: AppMotion.medium,
              curve: AppMotion.standard,
              child: _ChatLoadingState(chatType: chatType),
            ),
          ),

          /// YouTube consent / sign-in hint - same purely-visual idiom:
          /// the page below stays fully tappable (that's the point -
          /// the user taps through the wall once and cookies persist)
          Positioned(
            top: AppSpacing.md,
            left: AppSpacing.md,
            right: AppSpacing.md,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _webAuthWalled ? 1.0 : 0.0,
                duration: AppMotion.medium,
                curve: AppMotion.standard,
                child: const _WebAuthWallHint(),
              ),
            ),
          ),
          if (youTubeWaiting)
            Positioned.fill(
              child: _YouTubeChannelWaitingState(
                channel: youTubeChannel,
                tracker: this._youTubeLiveTracker,
              ),
            ),
        ],
        if (!chatActive)
          StaggeredEntrance(
            scaleFrom: 0.985,
            child: _ChatEmptyState(
              chatType: chatType,
              settingsBox: settingsBox,
            ),
          ),
      ],
    );
  }
}

/// Floating hint shown when the chat [WebView] lands on a Google consent /
/// sign-in page - the page below is the user's to tap through once (cookies
/// persist, the app never clears them) instead of looking like chat broke
class _WebAuthWallHint extends StatelessWidget {
  const _WebAuthWallHint();

  @override
  Widget build(BuildContext context) {
    final infoColor =
        (Theme.of(context).extension<AppStatusColors>() ??
                AppStatusColors.standard)
            .info;

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: StylingHelper.lightenDarkenColor(Theme.of(context).cardColor),
          borderRadius: AppRadius.pill,
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
            width: 0.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.info_circle_fill, size: 16.0, color: infoColor),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                'YouTube asks for a one-time consent or sign-in - tap through it below',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular platform glyph in its brand color, shared by the empty and
/// loading chat states
class _ChatBrandIcon extends StatelessWidget {
  final ChatType chatType;
  final Color color;

  const _ChatBrandIcon({required this.chatType, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64.0,
      width: 64.0,
      decoration: BoxDecoration(
        color: this.color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(this.chatType.icon, color: this.color, size: 28.0),
    );
  }
}

/// Shown while no username is selected for the active platform - or, with
/// [nativeConnectPrompt], while a native engine is selected but its
/// prerequisite is missing (Twitch: no account connected, YouTube: no API
/// key configured - the pill then opens the setup sheet). [promptBody],
/// [connectLabel] and [onConnectTap] override the Twitch defaults.
///
/// The WebView-engine state ([settingsBox] set) offers a ghost "Add
/// username…" opening the same add dialog the chat bar uses - the dead end
/// gets an action.
class _ChatEmptyState extends StatelessWidget {
  final ChatType chatType;
  final bool nativeConnectPrompt;
  final String? promptBody;
  final String? connectLabel;
  final VoidCallback? onConnectTap;
  final Box<dynamic>? settingsBox;

  const _ChatEmptyState({
    required this.chatType,
    this.nativeConnectPrompt = false,
    this.promptBody,
    this.connectLabel,
    this.onConnectTap,
    this.settingsBox,
  });

  void _addUsername(BuildContext context) {
    final Box<dynamic> settingsBox = this.settingsBox!;
    ModalHandler.showBaseDialog(
      context: context,
      dialogWidget: switch (this.chatType) {
        ChatType.Twitch => AddEditTwitchUsernameDialog(
          settingsBox: settingsBox,
        ),
        ChatType.YouTube => AddEditYouTubeUsernameDialog(
          settingsBox: settingsBox,
        ),
        ChatType.Owncast => AddEditOwncastUsernameDialog(
          settingsBox: settingsBox,
        ),
        ChatType.Kick || ChatType.Combined => AddEditKickUsernameDialog(
          settingsBox: settingsBox,
        ),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color brandColor =
        this.chatType.brandColor ?? Theme.of(context).colorScheme.secondary;

    /// Centered in the chat viewport — every host (Chat tab, streaming
    /// mode) gives chat a bounded, fully visible height. Scrolls when the
    /// viewport is shorter than the content (landscape phone).
    return _CenteredChatPlaceholder(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ChatBrandIcon(chatType: this.chatType, color: brandColor),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '${this.chatType.text} Chat',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            this.promptBody ??
                (this.nativeConnectPrompt
                    ? 'Connect your Twitch account to see your chat natively.'
                    : 'No ${this.chatType.text} username selected, so no one\'s chat can be displayed.'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (this.nativeConnectPrompt) ...[
            const SizedBox(height: AppSpacing.lg),
            BaseButton(
              text: this.connectLabel ?? 'Connect Twitch',
              color: brandColor,
              onPressed: this.onConnectTap ?? () => startTwitchLogin(context),
            ),
          ] else if (this.settingsBox != null) ...[
            const SizedBox(height: AppSpacing.lg),
            BaseButton(
              secondary: true,
              text: 'Add username…',
              onPressed: () => this._addUsername(context),
            ),
          ],
        ],
      ),
    );
  }
}

/// Chat-slot placeholder layout (empty states, Pro upsell, waiting
/// states): [child] centered in the bounded chat viewport, scrolling
/// instead of overflowing when the viewport is shorter than the content.
class _CenteredChatPlaceholder extends StatelessWidget {
  final Widget child;

  const _CenteredChatPlaceholder({required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.hasBoundedHeight
                ? math.max(0.0, constraints.maxHeight - 2 * AppSpacing.xl)
                : 0.0,
          ),
          child: Center(child: this.child),
        ),
      ),
    );
  }
}

/// Locked pane for the chat slot when a native engine is selected
/// without the entitlement (incl. legacy persisted `SelectedChatEngine`
/// users - the engine switch no longer intercepts, it switches and lands
/// here): padlock brand tile, a taste of the benefits, and the
/// "Explore Pro" entry into the paywall. Never auto-presented: the user
/// picked the native engine first.
class _ChatProUpsell extends StatelessWidget {
  final ChatType chatType;

  /// Paywall route on the host tab's navigator
  final String proRoute;

  const _ChatProUpsell({required this.chatType, required this.proRoute});

  @override
  Widget build(BuildContext context) {
    /// Centered in the chat viewport, like [_ChatEmptyState]
    return _CenteredChatPlaceholder(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AccentIconTile(
            icon: JamIcons.padlock,
            size: 64.0,
            iconSize: 30.0,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Native ${this.chatType.text} Chat',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Native chat is locked - unlock it with OBS Blade Pro.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),

          /// Compact benefit taste - titles only; the paywall carries
          /// the full copy. Icons stay neutral (rule 5 - the padlock
          /// tile is the pane's one accent moment, paywall precedent).
          /// Skips the first (platform) benefit - the headline above
          /// already names this platform's native chat.
          for (final ProBenefit benefit in kProBenefits.skip(1).take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    benefit.icon,
                    size: 16.0,
                    color:
                        (Theme.of(context).extension<AppTextColors>() ??
                                AppTextColors.standard)
                            .textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      benefit.title,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          BaseButton(
            text: 'Explore Pro',
            onPressed: () => Navigator.of(context).pushNamed(this.proRoute),
          ),
        ],
      ),
    );
  }
}

/// Opaque branded surface crossfading out once the embedded chat page has
/// loaded - masks the reload flash of the keyed [WebView]
/// WebView YouTube channel entry between streams (or still resolving):
/// what the tracker is doing + a "Check now" to skip the wait.
class _YouTubeChannelWaitingState extends StatelessWidget {
  final YouTubeChannelTarget channel;
  final YouTubeWebLiveTracker tracker;

  const _YouTubeChannelWaitingState({
    required this.channel,
    required this.tracker,
  });

  @override
  Widget build(BuildContext context) {
    final Color brandColor =
        ChatType.YouTube.brandColor ?? Theme.of(context).colorScheme.secondary;
    final resolving = this.tracker.state == YouTubeWebLiveState.resolving;
    final String body = switch (this.tracker.state) {
      YouTubeWebLiveState.resolving =>
        'Looking for ${this.channel.displayName}\'s livestream…',
      YouTubeWebLiveState.error =>
        this.tracker.error ?? 'Could not reach YouTube',
      _ =>
        '${this.channel.displayName} isn\'t live right now. The chat opens '
            'on its own as soon as the next stream starts.',
    };

    return ColoredBox(
      color: Theme.of(context).cardColor,
      child: _CenteredChatPlaceholder(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ChatBrandIcon(chatType: ChatType.YouTube, color: brandColor),
            const SizedBox(height: AppSpacing.lg),
            Text(
              body,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            if (resolving)
              StylingHelper.isApple(context)
                  ? const CupertinoActivityIndicator(radius: 10.0)
                  : SizedBox(
                      height: 18.0,
                      width: 18.0,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: brandColor,
                      ),
                    )
            else
              BaseButton(
                text: 'Check now',
                secondary: true,
                onPressed: this.tracker.recheck,
              ),
          ],
        ),
      ),
    );
  }
}

class _ChatLoadingState extends StatelessWidget {
  final ChatType chatType;

  const _ChatLoadingState({required this.chatType});

  @override
  Widget build(BuildContext context) {
    final Color brandColor =
        this.chatType.brandColor ?? Theme.of(context).colorScheme.secondary;

    return Container(
      color: Theme.of(context).cardColor,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ChatBrandIcon(chatType: this.chatType, color: brandColor),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '${this.chatType.text} chat is loading…',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          StylingHelper.isApple(context)
              ? const CupertinoActivityIndicator(radius: 10.0)
              : SizedBox(
                  height: 18.0,
                  width: 18.0,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: brandColor,
                  ),
                ),
        ],
      ),
    );
  }
}
