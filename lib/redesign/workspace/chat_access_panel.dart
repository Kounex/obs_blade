import 'package:flutter/material.dart';

import '../../models/enums/chat_type.dart';
import '../chat/chat_access.dart';

enum ChatIntent {
  viewPro('View Pro'),
  webView('Use WebView chat'),
  setup('Set up YouTube'),
  signIn('Sign in'),
  permissions('Update chat permissions'),
  channel('Choose channel'),
  retry('Retry chat');

  const ChatIntent(this.label);
  final String label;
}

class ChatAccessPanel extends StatelessWidget {
  const ChatAccessPanel({
    super.key,
    required this.access,
    required this.onAction,
  });
  final ChatAccess access;
  final ValueChanged<ChatIntent> onAction;

  @override
  Widget build(BuildContext context) {
    final (title, body, action) = switch (access.gate) {
      ChatGate.pro => (
        'Native chat with Pro',
        'Read and take part in your conversation with native chat. WebView chat stays free.',
        ChatIntent.viewPro,
      ),
      ChatGate.setup => (
        'Set up YouTube chat',
        'Add your YouTube API key to read live chat. Sign in when you want to send messages.',
        ChatIntent.setup,
      ),
      ChatGate.signIn => (
        'Connect ${access.platform.text}',
        'Sign in to open native chat. Your OBS connection stays independent.',
        ChatIntent.signIn,
      ),
      ChatGate.authorizing => (
        'Finish signing in',
        'Complete authorization, then return to your conversation.',
        null,
      ),
      ChatGate.channel => (
        'Choose your conversation',
        'Select the channel or stream you want to follow.',
        ChatIntent.channel,
      ),
      ChatGate.embedded => (
        'WebView chat',
        'Open the platform’s embedded chat.',
        ChatIntent.webView,
      ),
      ChatGate.open => ('', '', null),
    };
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 24),
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Text(body),
        if (access.detail != null) ...[
          const SizedBox(height: 12),
          Text(access.detail!),
        ],
        const SizedBox(height: 24),
        if (action != null)
          FilledButton(
            onPressed: () => onAction(action),
            child: Text(action.label),
          ),
        if (access.gate == ChatGate.pro || access.gate == ChatGate.signIn)
          TextButton(
            onPressed: () => onAction(ChatIntent.webView),
            child: Text(ChatIntent.webView.label),
          ),
      ],
    );
  }
}

class ChatReadinessNotice extends StatelessWidget {
  const ChatReadinessNotice({
    super.key,
    required this.access,
    required this.onAction,
  });
  final ChatAccess access;
  final ValueChanged<ChatIntent> onAction;

  @override
  Widget build(BuildContext context) {
    final String text;
    final ChatIntent? action;
    if (access.link != ChatLink.connected) {
      text = access.quotaExhausted
          ? 'YouTube quota reached. Your draft is kept; repeated retries may not help until quota resets.'
          : '${access.statusLabel}. Your draft is kept.';
      action = switch (access.link) {
        ChatLink.failed || ChatLink.idle => ChatIntent.retry,
        ChatLink.ended => ChatIntent.channel,
        _ => null,
      };
    } else if (access.writeAccess == ChatWriteAccess.authorizing) {
      text = 'Finish signing in. You can keep reading and prepare a draft.';
      action = null;
    } else if (access.writeAccess != ChatWriteAccess.available) {
      text = 'Chat is read-only. You can keep reading and prepare a draft.';
      action = access.writeAccess == ChatWriteAccess.permissions
          ? ChatIntent.permissions
          : ChatIntent.signIn;
    } else {
      return const SizedBox.shrink();
    }
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(text, style: Theme.of(context).textTheme.bodySmall),
            if (action != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => onAction(action!),
                  child: Text(action.label),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
