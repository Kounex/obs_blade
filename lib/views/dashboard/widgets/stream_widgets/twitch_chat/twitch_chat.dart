import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:obs_blade/views/dashboard/widgets/stream_widgets/twitch_chat/chat_username_bar.dart/chat_username_bar.dart';

class TwitchChat extends StatefulWidget {
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
    super.build(context);
    // TODO: most basic form. current problems:
    // 1. zooming page when focus keyboard
    // 2. light mode
    // hard coded my chat
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, right: 4.0, bottom: 12.0),
          child: ChatUsernameBar(),
        ),
        Expanded(
          child: InAppWebView(
            initialUrl: 'https://www.twitch.tv/popout/kounex/chat',
            initialOptions: InAppWebViewGroupOptions(
              crossPlatform: InAppWebViewOptions(supportZoom: false),
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
      ],
    );
  }
}
