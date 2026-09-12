import '../../models/enums/chat_engine.dart';
import '../../models/enums/chat_type.dart';

enum ChatGate { embedded, pro, setup, signIn, authorizing, channel, open }

enum ChatLink { idle, connecting, connected, reconnecting, ended, failed }

enum ChatWriteAccess { available, signIn, permissions, authorizing }

/// Read-only presentation contract. OBS state and pane focus are deliberately
/// absent. Native access, account permissions and connection are separate facts.
class ChatAccess {
  const ChatAccess({
    required this.platform,
    required this.engine,
    required this.gate,
    this.link = ChatLink.idle,
    this.channelId,
    this.channelLabel,
    this.accountLabel,
    this.writeAccess = ChatWriteAccess.signIn,
    this.sending = false,
    this.detail,
    this.quotaExhausted = false,
  });

  final ChatType platform;
  final ChatEngine engine;
  final ChatGate gate;
  final ChatLink link;
  // Twitch broadcaster ID / YouTube video ID, never a display label.
  final String? channelId;
  final String? channelLabel;
  final String? accountLabel;
  final ChatWriteAccess writeAccess;
  final bool sending;
  final String? detail;
  final bool quotaExhausted;

  bool get showsNativeConversation => gate == ChatGate.open;
  bool get canSend =>
      showsNativeConversation &&
      channelId != null &&
      link == ChatLink.connected &&
      writeAccess == ChatWriteAccess.available &&
      !sending;

  String get statusLabel => switch (gate) {
    ChatGate.embedded => 'WebView chat',
    ChatGate.pro => 'Native chat requires Pro',
    ChatGate.setup => 'Chat setup required',
    ChatGate.signIn => 'Sign in to connect chat',
    ChatGate.authorizing => 'Waiting for sign-in',
    ChatGate.channel => 'Choose a channel',
    ChatGate.open => switch (link) {
      ChatLink.idle => 'Chat disconnected',
      ChatLink.connecting => 'Connecting chat…',
      ChatLink.connected => 'Chat connected',
      ChatLink.reconnecting => 'Reconnecting chat…',
      ChatLink.ended => 'No active live chat',
      ChatLink.failed =>
        quotaExhausted ? 'Chat quota reached' : 'Chat unavailable',
    },
  };
}
