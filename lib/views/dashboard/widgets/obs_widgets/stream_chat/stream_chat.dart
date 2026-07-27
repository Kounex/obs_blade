import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/shared/general/custom_expansion_tile.dart';
import 'package:obs_blade/utils/youtube_video_id.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../../models/enums/chat_type.dart';
import '../../../../../shared/general/base/card.dart';
import '../../../../../shared/general/hive_builder.dart';
import '../../../../../shared/overlay/base_result.dart';
import '../../../../../stores/views/dashboard.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../../../../../types/enums/settings_keys.dart';
import 'chat_username_bar.dart/chat_username_bar.dart';

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
        },
      ),
    );
    return controller;
  }

  /// Create once; [loadRequest] only when the resolved chat URL changes.
  void _syncWebController(String url) {
    _webController ??= _createWebController();
    if (_loadedChatUrl == url) return;
    _loadedChatUrl = url;
    _webController!.loadRequest(Uri.parse(url));
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
        left: this.widget.usernameRowPadding ? 4.0 : 0.0,
        right: this.widget.usernameRowPadding ? 4.0 : 0.0,
        bottom: 12.0,
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
              if (chatActive) {
                _syncWebController(_urlForChatType(chatType, settingsBox));
              }

              return Stack(
                alignment: Alignment.center,
                children: [
                  /// Only add the [WebView] to the widget tree if we have an
                  /// actual chat to display because otherwise the [WebView]
                  /// will still eat up performance
                  if (chatActive && _webController != null)

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
                  if (!chatActive)
                    Positioned(
                      top: 48.0,
                      child: SizedBox(
                        height: 185,
                        width: 225,
                        child: BaseCard(
                          child: BaseResult(
                            icon: BaseResultIcon.Negative,
                            text:
                                'No ${chatType.text} username selected, so no ones chat can be displayed.',
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        if (this.widget.usernameRowBeneath) usernameBar,
      ],
    );
  }
}
