import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/shared/general/custom_expansion_tile.dart';
import 'package:obs_blade/utils/youtube_video_id.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../../models/enums/chat_type.dart';
import '../../../../../models/enums/chat_engine.dart';
import '../../../../../shared/design/design.dart';
import '../../../../../shared/dialogs/confirmation.dart';
import '../../../../../shared/general/hive_builder.dart';
import '../../../../../stores/views/dashboard.dart';
import '../../../../../stores/views/twitch_chat.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../../../../../types/enums/settings_keys.dart';
import '../../../../../utils/modal_handler.dart';
import '../../../../../utils/styling_helper.dart';
import 'chat_type_brand.dart';
import 'chat_username_bar.dart/chat_username_bar.dart';
import 'native_chat_window.dart';
import 'native_twitch_chat_view.dart';
import 'twitch_device_code_dialog.dart';

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

class StreamChat extends StatefulWidget {
  final bool usernameRowPadding;
  final bool usernameRowExpandable;
  final bool usernameRowBeneath;

  const StreamChat({
    super.key,
    this.usernameRowPadding = false,
    this.usernameRowExpandable = false,
    this.usernameRowBeneath = false,
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
      ),
    );
    return controller;
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
    _loadingFallback?.cancel();
    _loadingFallback = Timer(const Duration(seconds: 8), () {
      if (this.mounted && _isChatLoading) {
        setState(() => _isChatLoading = false);
      }
    });
  }

  @override
  void dispose() {
    _loadingFallback?.cancel();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  String _urlForChatType(ChatType chatType, Box<dynamic> settingsBox) {
    if (chatType == ChatType.Twitch &&
        (settingsBox.get(SettingsKeys.SelectedTwitchUsername.name)) != null) {
      return 'https://www.twitch.tv/popout/${settingsBox.get(SettingsKeys.SelectedTwitchUsername.name)}/chat';
    }
    if (chatType == ChatType.YouTube &&
        (settingsBox.get(SettingsKeys.SelectedYouTubeUsername.name)) != null) {
      final stored = settingsBox.get(SettingsKeys.YouTubeUsernames.name)
          [settingsBox.get(SettingsKeys.SelectedYouTubeUsername.name)];
      final videoId = extractYouTubeVideoId(stored is String ? stored : null);
      if (videoId == null) return 'about:blank';
      return 'https://www.youtube.com/live_chat?v=$videoId';
    }
    if (chatType == ChatType.Owncast &&
        (settingsBox.get(SettingsKeys.SelectedOwncastUsername.name)) != null) {
      final base = settingsBox.get(SettingsKeys.OwncastUsernames.name)
          [settingsBox.get(SettingsKeys.SelectedOwncastUsername.name)] as String;
      return '${base.replaceAll(RegExp(r'/+$'), '')}/embed/chat/readwrite';
    }
    return 'about:blank';
  }

  bool anyChatActive(ChatType chatType, Box<dynamic> settingsBox) {
    bool twitchActive = chatType == ChatType.Twitch &&
        settingsBox.get(SettingsKeys.SelectedTwitchUsername.name) != null;
    bool youtubeActive = chatType == ChatType.YouTube &&
        settingsBox.get(SettingsKeys.SelectedYouTubeUsername.name) != null;
    bool owncastActive = chatType == ChatType.Owncast &&
        settingsBox.get(SettingsKeys.SelectedOwncastUsername.name) != null;

    return twitchActive || youtubeActive || owncastActive;
  }

  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = GetIt.instance<DashboardStore>();

    Widget usernameBar = Padding(
      padding: EdgeInsets.only(
        top: 0,
        left: this.widget.usernameRowPadding ? AppSpacing.xs : 0.0,
        right: this.widget.usernameRowPadding ? AppSpacing.xs : 0.0,
        bottom: AppSpacing.md,
      ),
      child: const ChatUsernameBar(),
    );

    if (this.widget.usernameRowExpandable) {
      usernameBar = CustomExpansionTile(
        headerText: 'Chat options',
        expandedBody: usernameBar,
      );
    }

    super.build(context);
    return Column(
      children: [
        if (!this.widget.usernameRowBeneath) usernameBar,
        Expanded(
          child: HiveBuilder<dynamic>(
            hiveKey: HiveKeys.Settings,
            rebuildKeys: const [
              SettingsKeys.SelectedChatType,
              SettingsKeys.SelectedChatEngine,
              SettingsKeys.SelectedTwitchUsername,
              SettingsKeys.SelectedYouTubeUsername,
              SettingsKeys.SelectedOwncastUsername,
              SettingsKeys.YouTubeUsernames,
              SettingsKeys.OwncastUsernames,
            ],
            builder: (context, settingsBox, child) {
              ChatType chatType = settingsBox.get(
                SettingsKeys.SelectedChatType.name,
                defaultValue: ChatType.Twitch,
              );

              final chatActive = anyChatActive(chatType, settingsBox);

              /// A native engine exists only where
              /// [nativeChatAvailableFor] says so (Twitch today)
              final nativeEngine = nativeChatAvailableFor(chatType) &&
                  settingsBox.get(
                        SettingsKeys.SelectedChatEngine.name,
                        defaultValue: ChatEngine.webView,
                      ) ==
                      ChatEngine.native;

              /// No WebView warm-up while the native engine owns the slot
              if (chatActive && !nativeEngine) {
                _syncWebController(_urlForChatType(chatType, settingsBox));
              }

              /// Native Twitch chat takes over the slot when the native
              /// engine is selected, wrapped in the chat window (pane +
              /// status row + connection sheet). Logged out, the content is
              /// the connect prompt. The WebView engine keeps the legacy
              /// path regardless of the login state.
              if (nativeEngine) {
                return Observer(
                  builder: (_) {
                    final twitchStore = GetIt.instance<TwitchChatStore>();
                    final loggedIn = twitchStore.isLoggedIn;
                    final displayName = twitchStore.user?.displayName ??
                        twitchStore.user?.login;

                    return NativeChatWindow(
                      chatType: chatType,
                      status: twitchChatWindowStatus(
                        twitchStore.chatConnection,
                        loggedIn,
                      ),
                      statusDetail: twitchStore.chatError,
                      accountLabel: displayName,
                      connectedAt: twitchStore.chatConnectedAt,
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
                      child: loggedIn
                          ? const NativeTwitchChatView()
                          : StaggeredEntrance(
                              child: _ChatEmptyState(
                                chatType: chatType,
                                nativeConnectPrompt: true,
                              ),
                            ),
                    );
                  },
                );
              }

              return this._buildLegacyChatStack(
                  context, settingsBox, chatType, chatActive, dashboardStore);
            },
          ),
        ),
        if (this.widget.usernameRowBeneath) usernameBar,
      ],
    );
  }

  /// The pre-native chat slot: WebView embed + loading/empty states.
  /// Verbatim the behavior before native Twitch chat existed.
  Widget _buildLegacyChatStack(
    BuildContext context,
    Box<dynamic> settingsBox,
    ChatType chatType,
    bool chatActive,
    DashboardStore dashboardStore,
  ) {
    return Stack(
      alignment: Alignment.center,
      children: [
        /// Only add the [WebView] to the widget tree if we have an
        /// actual chat to display because otherwise the [WebView]
        /// will still eat up performance
        if (chatActive && _webController != null) ...[
          /// To enable scrolling in the Twitch chat, we need to disabe scrolling for
          /// the main Scroll (the [CustomScrollView] of this view) while trying to scroll
          /// in the region where the Twitch chat is. The Listener is used to determine
          /// where the user is trying to scroll and if it's where the Twitch chat is,
          /// we change to [NeverScrollableScrollPhysics] so the WebView can consume
          /// the scroll
          Listener(
            onPointerDown: (onPointerDown) =>
                dashboardStore.setPointerOnChat(
                    onPointerDown.localPosition.dy > 150.0 &&
                        onPointerDown.localPosition.dy < 450.0),
            onPointerUp: (_) =>
                dashboardStore.setPointerOnChat(false),
            onPointerCancel: (_) =>
                dashboardStore.setPointerOnChat(false),
            child: WebViewWidget(
              key: Key(
                chatType.toString() +
                    settingsBox
                        .get(SettingsKeys.SelectedTwitchUsername.name)
                        .toString() +
                    settingsBox
                        .get(
                            SettingsKeys.SelectedYouTubeUsername.name)
                        .toString() +
                    settingsBox
                        .get(
                            SettingsKeys.SelectedOwncastUsername.name)
                        .toString(),
              ),
              controller: _webController!,
            ),
          ),

          /// Crossfading branded surface hiding the flash of the
          /// keyed [WebView] reload until the page has loaded -
          /// purely visual, touches always fall through to the
          /// [WebView] (and its pointer band) as before
          AnimatedOpacity(
            opacity: _isChatLoading ? 1.0 : 0.0,
            duration: AppMotion.medium,
            curve: AppMotion.standard,
            child: _ChatLoadingState(chatType: chatType),
          ),
        ],
        if (!chatActive)
          StaggeredEntrance(
            child: _ChatEmptyState(chatType: chatType),
          ),
      ],
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
      child: Icon(
        this.chatType.icon,
        color: this.color,
        size: 28.0,
      ),
    );
  }
}

/// Shown while no username is selected for the active platform - or, with
/// [nativeConnectPrompt], while the native Twitch engine is selected but
/// no account is connected (then the "Connect Twitch" pill lives here -
/// it belongs to native mode exclusively)
class _ChatEmptyState extends StatelessWidget {
  final ChatType chatType;
  final bool nativeConnectPrompt;

  const _ChatEmptyState({
    required this.chatType,
    this.nativeConnectPrompt = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color brandColor = this.chatType.brandColor ??
        Theme.of(context).colorScheme.secondary;

    /// Top-aligned (instead of centered in the fixed-height chat viewport)
    /// so the state sits inside the actually visible area of the dashboard
    /// scroll view
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(
          top: AppSpacing.xl,
          left: AppSpacing.xl,
          right: AppSpacing.xl,
        ),
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
              this.nativeConnectPrompt
                  ? 'Connect your Twitch account to see your chat natively.'
                  : 'No ${this.chatType.text} username selected, so no one\'s chat can be displayed.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (this.nativeConnectPrompt) ...[
              const SizedBox(height: AppSpacing.lg),
              Pressable(
                haptic: true,
                onTap: () => startTwitchLogin(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: brandColor,
                    borderRadius: AppRadius.pill,
                  ),
                  child: Text(
                    'Connect Twitch',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Opaque branded surface crossfading out once the embedded chat page has
/// loaded - masks the reload flash of the keyed [WebView]
class _ChatLoadingState extends StatelessWidget {
  final ChatType chatType;

  const _ChatLoadingState({required this.chatType});

  @override
  Widget build(BuildContext context) {
    final Color brandColor = this.chatType.brandColor ??
        Theme.of(context).colorScheme.secondary;

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
