import '../../models/enums/chat_engine.dart';
import '../../models/enums/chat_type.dart';
import '../../stores/pro_store.dart';
import '../../stores/views/twitch_chat.dart';
import '../../stores/views/youtube_chat.dart';
import 'chat_access.dart';

/// Call inside a MobX reaction/Observer to track the store fields. This function
/// never initializes a store, connects a service, purchases, or writes settings.
ChatAccess projectChatAccess({
  required ChatType platform,
  required ChatEngine preferredEngine,
  required ProStore pro,
  required TwitchChatStore twitch,
  required YouTubeChatStore youtube,
}) {
  final native =
      preferredEngine == ChatEngine.native && nativeChatAvailableFor(platform);
  if (!native) {
    return ChatAccess(
      platform: platform,
      engine: ChatEngine.webView,
      gate: ChatGate.embedded,
    );
  }
  // Preserve the existing gate order: no login/setup prompt before Pro access.
  if (!pro.isPro) {
    return ChatAccess(
      platform: platform,
      engine: ChatEngine.native,
      gate: ChatGate.pro,
    );
  }
  return platform == ChatType.Twitch ? _twitch(twitch) : _youtube(youtube);
}

ChatAccess _twitch(TwitchChatStore store) {
  final signedIn = store.isLoggedIn && store.user != null;
  final authorizing = switch (store.authState) {
    TwitchAuthState.requestingCode ||
    TwitchAuthState.awaitingAuthorization ||
    TwitchAuthState.loggingIn => true,
    _ => false,
  };
  return ChatAccess(
    platform: ChatType.Twitch,
    engine: ChatEngine.native,
    gate: signedIn
        ? ChatGate.open
        : authorizing
        ? ChatGate.authorizing
        : ChatGate.signIn,
    link: switch (store.chatConnection) {
      TwitchChatConnectionState.disconnected => ChatLink.idle,
      TwitchChatConnectionState.connecting => ChatLink.connecting,
      TwitchChatConnectionState.live => ChatLink.connected,
      TwitchChatConnectionState.reconnecting => ChatLink.reconnecting,
      TwitchChatConnectionState.failed => ChatLink.failed,
    },
    channelId: signedIn ? store.effectiveBroadcasterId : null,
    channelLabel: signedIn ? store.effectiveBroadcasterLogin : null,
    accountLabel: signedIn
        ? store.user!.displayName ?? store.user!.login
        : null,
    writeAccess: !signedIn
        ? ChatWriteAccess.signIn
        : store.canWriteChat
        ? ChatWriteAccess.available
        : ChatWriteAccess.permissions,
    sending: store.sendingChat,
    detail: signedIn ? store.chatError : store.authError,
  );
}

ChatAccess _youtube(YouTubeChatStore store) {
  final configured = store.canRead;
  final authorizing = switch (store.authState) {
    YouTubeAuthState.requestingCode ||
    YouTubeAuthState.awaitingAuthorization ||
    YouTubeAuthState.signingIn => true,
    _ => false,
  };
  final selected = store.channels
      .where((channel) => channel.label == store.selectedChannelLabel)
      .firstOrNull;
  return ChatAccess(
    platform: ChatType.YouTube,
    engine: ChatEngine.native,
    gate: !configured
        ? ChatGate.setup
        : selected == null
        ? ChatGate.channel
        : ChatGate.open,
    link: switch (store.chatConnection) {
      YouTubeChatConnectionState.idle => ChatLink.idle,
      YouTubeChatConnectionState.connecting => ChatLink.connecting,
      YouTubeChatConnectionState.connected => ChatLink.connected,
      YouTubeChatConnectionState.offline => ChatLink.ended,
      YouTubeChatConnectionState.error => ChatLink.failed,
    },
    channelId: selected?.videoId,
    channelLabel: selected?.label,
    accountLabel: store.isSignedInState ? store.selfChannelTitle : null,
    writeAccess: authorizing
        ? ChatWriteAccess.authorizing
        : configured && store.canWrite
        ? ChatWriteAccess.available
        : ChatWriteAccess.signIn,
    sending: store.sendingChat,
    detail: store.chatError,
    quotaExhausted: store.chatQuotaExhausted,
  );
}
