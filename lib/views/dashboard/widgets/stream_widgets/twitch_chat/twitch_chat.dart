import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

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
    // TODO: most basic form. current problems:
    // 1. zooming page when focus keyboard
    // 2. light mode
    // hard coded my chat
    return InAppWebView(
      initialUrl: 'https://www.twitch.tv/popout/kounex/chat',
      onWebViewCreated: (webController) {
        _webController = webController;
        // _webController.postUrl(
        //     url: 'https://www.twitch.tv/popout/kounex/chat',
        //     postData:
        //         Uint8List.fromList('"event"="dark_mode_toggle"'.codeUnits));
      },
    );
  }
}
