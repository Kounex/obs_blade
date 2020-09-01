import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:obs_blade/shared/general/base_card.dart';
import 'package:obs_blade/shared/overlay/base_result.dart';
import 'package:obs_blade/stores/views/dashboard.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/views/dashboard/widgets/stream_widgets/twitch_chat/chat_username_bar.dart/chat_username_bar.dart';
import 'package:provider/provider.dart';

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
      mainAxisSize: MainAxisSize.max,
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
                Listener(
                  onPointerDown: (_) => dashboardStore.setPointerOnTwitch(true),
                  onPointerUp: (_) => dashboardStore.setPointerOnTwitch(false),
                  onPointerCancel: (_) =>
                      dashboardStore.setPointerOnTwitch(false),
                  child: InAppWebView(
                    key: Key(settingsBox
                        .get(SettingsKeys.SelectedTwitchUsername.name)),
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
                          isPositive: false,
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
