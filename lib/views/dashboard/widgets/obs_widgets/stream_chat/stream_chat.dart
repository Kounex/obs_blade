import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
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

  const StreamChat({Key? key, this.usernameRowPadding = false})
      : super(key: key);

  @override
  _StreamChatState createState() => _StreamChatState();
}

class _StreamChatState extends State<StreamChat>
    with AutomaticKeepAliveClientMixin {
  late WebViewController _webController;

  void _initializeWebController(Box<dynamic> settingsBox, ChatType chatType) {
    _webController = WebViewController()
      ..loadRequest(
        Uri.parse(chatType == ChatType.Twitch &&
                settingsBox.get(SettingsKeys.SelectedTwitchUsername.name) !=
                    null
            ? 'https://www.twitch.tv/popout/${settingsBox.get(SettingsKeys.SelectedTwitchUsername.name)}/chat'
            : chatType == ChatType.YouTube &&
                    settingsBox
                            .get(SettingsKeys.SelectedYoutubeUsername.name) !=
                        null
                ? 'https://www.youtube.com/live_chat?&v=${settingsBox.get(SettingsKeys.YoutubeUsernames.name)[settingsBox.get(SettingsKeys.SelectedYoutubeUsername.name)].split(RegExp(r'[/?&]'))[0]}'
                : 'about:blank'),
      )
      ..enableZoom(false)
      ..setUserAgent(
          'Mozilla/5.0 (iPhone; CPU iPhone OS 15_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.6 Mobile/15E148 Safari/604.1')
      ..setBackgroundColor(Colors.transparent)
      ..setJavaScriptMode(JavaScriptMode.unrestricted);

    _webController.setNavigationDelegate(
      NavigationDelegate.fromPlatformCreationParams(
        const PlatformNavigationDelegateCreationParams(),
        onPageFinished: (url) {
          _webController.runJavaScript('''
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
          ''');
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = GetIt.instance<DashboardStore>();

    super.build(context);
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: this.widget.usernameRowPadding ? 4.0 : 0.0,
            right: this.widget.usernameRowPadding ? 4.0 : 0.0,
            bottom: 12.0,
          ),
          child: const ChatUsernameBar(),
        ),
        Expanded(
          child: HiveBuilder<dynamic>(
            hiveKey: HiveKeys.Settings,
            rebuildKeys: const [
              SettingsKeys.SelectedChatType,
              SettingsKeys.SelectedTwitchUsername,
              SettingsKeys.SelectedYoutubeUsername,
            ],
            builder: (context, settingsBox, child) {
              ChatType chatType = settingsBox.get(
                SettingsKeys.SelectedChatType.name,
                defaultValue: ChatType.Twitch,
              );

              _initializeWebController(settingsBox, chatType);

              return Stack(
                alignment: Alignment.center,
                children: [
                  /// Only add the [WebView] to the widget tree if we have an
                  /// actual chat to display because otherwise the [WebView]
                  /// will still eat up performance
                  if ((chatType == ChatType.Twitch &&
                          settingsBox.get(
                                  SettingsKeys.SelectedTwitchUsername.name) !=
                              null) ||
                      (chatType == ChatType.YouTube &&
                          settingsBox.get(
                                  SettingsKeys.SelectedYoutubeUsername.name) !=
                              null))

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
                                      SettingsKeys.SelectedYoutubeUsername.name)
                                  .toString(),
                        ),
                        controller: _webController,
                      ),
                      // InAppWebView(
                      //   key: Key(
                      //     chatType.toString() +
                      //         settingsBox
                      //             .get(SettingsKeys.SelectedTwitchUsername.name)
                      //             .toString() +
                      //         settingsBox
                      //             .get(SettingsKeys.SelectedYoutubeUsername.name)
                      //             .toString(),
                      //   ),
                      //   initialUrlRequest: URLRequest(
                      //     url: Uri.parse(chatType == ChatType.Twitch &&
                      //             settingsBox.get(SettingsKeys
                      //                     .SelectedTwitchUsername.name) !=
                      //                 null
                      //         ? 'https://www.twitch.tv/popout/${settingsBox.get(SettingsKeys.SelectedTwitchUsername.name)}/chat'
                      //         : chatType == ChatType.YouTube &&
                      //                 settingsBox.get(SettingsKeys
                      //                         .SelectedYoutubeUsername.name) !=
                      //                     null
                      //             ? 'https://www.youtube.com/live_chat?&v=${settingsBox.get(SettingsKeys.YoutubeUsernames.name)[settingsBox.get(SettingsKeys.SelectedYoutubeUsername.name)].split(RegExp(r'[/?&]'))[0]}'
                      //             : 'about:blank'),
                      //   ),
                      //   initialOptions: InAppWebViewGroupOptions(
                      //     crossPlatform: InAppWebViewOptions(
                      //       transparentBackground: true,
                      //       supportZoom: false,
                      //       javaScriptCanOpenWindowsAutomatically: false,
                      //       userAgent:
                      //           'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Safari/605.1.15',
                      //     ),
                      //   ),
                      //   onWebViewCreated: (webController) {
                      //     _webController = webController;
                      //   },
                      // ),
                    ),
                  if ((chatType == ChatType.Twitch &&
                          settingsBox.get(
                                  SettingsKeys.SelectedTwitchUsername.name) ==
                              null) ||
                      (chatType == ChatType.YouTube &&
                          settingsBox.get(
                                  SettingsKeys.SelectedYoutubeUsername.name) ==
                              null))
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
      ],
    );
  }
}
