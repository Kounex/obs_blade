import 'package:hive_ce/hive.dart';

import '../type_ids.dart';
import 'chat_type.dart';

part 'chat_engine.g.dart';

/// Which implementation renders the stream chat: the classic WebView embed
/// or a native client. A native engine exists only for Twitch today - see
/// [nativeChatAvailableFor].
@HiveType(typeId: TypeIDs.ChatEngine)
enum ChatEngine {
  @HiveField(0)
  webView,

  @HiveField(1)
  native,
}

extension ChatEngineFunctions on ChatEngine {
  String get text => const {
        ChatEngine.webView: 'WebView',
        ChatEngine.native: 'Native',
      }[this]!;
}

/// The single seam deciding whether a native chat engine exists for
/// [chatType]. The engine switch's visibility and every engine read go
/// through here, so the future entitlement gate (and the auto-switch on
/// login it brings) has exactly one call site to extend.
bool nativeChatAvailableFor(ChatType chatType) => chatType == ChatType.Twitch;
