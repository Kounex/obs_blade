import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../../shared/general/base_card.dart';
import '../../../../../shared/overlay/base_result.dart';
import '../../../../../stores/views/dashboard.dart';
import '../../../../../types/enums/hive_keys.dart';
import '../../../../../types/enums/settings_keys.dart';
import 'chat_username_bar.dart/chat_username_bar.dart';

class TwitchChat extends StatefulWidget {
  final bool usernameRowPadding;

  TwitchChat({this.usernameRowPadding = false});

  @override
  _TwitchChatState createState() => _TwitchChatState();
}

class _TwitchChatState extends State<TwitchChat>
    with AutomaticKeepAliveClientMixin {
  InAppWebViewController _webController;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    DashboardStore dashboardStore = context.watch<DashboardStore>();

    super.build(context);
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(
              left: widget.usernameRowPadding ? 4.0 : 0.0,
              right: widget.usernameRowPadding ? 4.0 : 0.0,
              bottom: 12.0),
          child: ChatUsernameBar(),
        ),
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: Hive.box(HiveKeys.Settings.name)
                .listenable(keys: [SettingsKeys.SelectedTwitchUsername.name]),
            builder: (context, Box settingsBox, child) => Stack(
              alignment: Alignment.center,
              children: [
                /// To enable scrolling in the Twitch chat, we need to disabe scrolling for
                /// the main Scroll (the [CustomScrollView] of this view) whie trying to scroll
                /// in the region where the Twitch chat is. The Listener is used to determine
                /// where the user is trying to scroll and if it's where the Twitch chat is,
                /// we change to [NeverScrollableScrollPhysics] so the WebView can consume
                /// the scroll
                Listener(
                  onPointerDown: (onPointerDown) =>
                      dashboardStore.setPointerOnTwitch(
                          onPointerDown.localPosition.dy > 125.0 &&
                              onPointerDown.localPosition.dy < 350.0),
                  onPointerUp: (_) => dashboardStore.setPointerOnTwitch(false),
                  onPointerCancel: (_) =>
                      dashboardStore.setPointerOnTwitch(false),
                  child: InAppWebView(
                    key: Key(
                      settingsBox.get(SettingsKeys.SelectedTwitchUsername.name),
                    ),
                    initialUrl: settingsBox.get(
                                SettingsKeys.SelectedTwitchUsername.name) !=
                            null
                        ? 'https://www.twitch.tv/popout/${settingsBox.get(SettingsKeys.SelectedTwitchUsername.name)}/chat'
                        : 'about:blank',
                    initialOptions: InAppWebViewGroupOptions(
                      crossPlatform: InAppWebViewOptions(
                        supportZoom: false,
                      ),
                    ),
                    onWebViewCreated: (webController) {
                      _webController = webController;
                      // _webController.postUrl(
                      //     url: 'https://www.twitch.tv/popout/kounex/chat',
                      //     postData:
                      //         Uint8List.fromList('"event"="dark_mode_toggle"'.codeUnits));
                    },
                  ),
                ),
                if (settingsBox.get(SettingsKeys.SelectedTwitchUsername.name) ==
                    null)
                  SizedBox(
                    height: 185,
                    width: 225,
                    child: BaseCard(
                      child: BaseResult(
                          icon: BaseResultIcon.Negative,
                          text:
                              'No Twitch Username selected, so no ones chat can be displayed!'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
