import 'package:flutter/material.dart';

import 'workspace_model.dart';

const _scaffold = Color(0xFF141B24);
const _border = Color(0xFF334355);
const _secondary = Color(0xFFACB8C8);
const _blue = Color(0xFFB3CEFF);
const _coral = Color(0xFFF39E8F);

class ChatPanel extends StatefulWidget {
  const ChatPanel({super.key, required this.model});

  final WorkspaceModel model;

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  late final TextEditingController _composer = TextEditingController(
    text: widget.model.draft,
  );
  final ScrollController _scroll = ScrollController();
  int _messageCount = 0;

  @override
  void initState() {
    super.initState();
    _messageCount = widget.model.messages.length;
    _scroll.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _returnLive());
  }

  @override
  void didUpdateWidget(covariant ChatPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_composer.text != widget.model.draft) {
      _composer.value = TextEditingValue(
        text: widget.model.draft,
        selection: TextSelection.collapsed(offset: widget.model.draft.length),
      );
    }
    if (widget.model.messages.length != _messageCount) {
      _messageCount = widget.model.messages.length;
      if (!widget.model.chatPaused) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _returnLive());
      }
    }
  }

  @override
  void dispose() {
    _scroll.removeListener(_handleScroll);
    _scroll.dispose();
    _composer.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scroll.hasClients) return;
    widget.model.setChatPaused(_scroll.position.extentAfter > 96);
  }

  void _returnLive() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
    widget.model.setChatPaused(false);
  }

  Future<void> _send() async {
    await widget.model.sendMessage();
    if (!mounted) return;
    if (widget.model.sendError == null) _composer.clear();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compactHeight = constraints.maxHeight < 380;
        return Column(
          children: [
            _ChatToolbar(
              model: widget.model,
              onShowActivity: () => _showActivity(context),
            ),
            if (widget.model.showActivity && !compactHeight)
              _ActivityRow(onTap: () => _showActivity(context)),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ListView.builder(
                      key: const ValueKey('chat-timeline'),
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                      itemCount: widget.model.messages.length,
                      itemBuilder: (context, index) => _MessageRow(
                        message: widget.model.messages[index],
                        onReply: () => widget.model.setReply(
                          widget.model.messages[index].author,
                        ),
                      ),
                    ),
                  ),
                  if (widget.model.chatPaused)
                    Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: OutlinedButton.icon(
                          onPressed: _returnLive,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E2936),
                          ),
                          icon: const Icon(Icons.arrow_downward, size: 18),
                          label: const Text('Return live'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            _Composer(
              model: widget.model,
              controller: _composer,
              onSend: _send,
            ),
          ],
        );
      },
    );
  }

  void _showActivity(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1E2936),
      showDragHandle: true,
      builder: (context) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recent activity',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 6),
              Text(
                'Simulated examples for this workspace prototype.',
                style: TextStyle(color: _secondary),
              ),
              SizedBox(height: 20),
              _ActivityHistoryRow(
                icon: Icons.favorite_outline,
                title: 'Mira subscribed',
                time: '2 min ago',
              ),
              _ActivityHistoryRow(
                icon: Icons.person_add_alt,
                title: 'river followed',
                time: '7 min ago',
              ),
              _ActivityHistoryRow(
                icon: Icons.campaign_outlined,
                title: 'Jules shared an announcement',
                time: '16 min ago',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatToolbar extends StatelessWidget {
  const _ChatToolbar({required this.model, required this.onShowActivity});

  final WorkspaceModel model;
  final VoidCallback onShowActivity;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.only(left: 16, right: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'studio_chat',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: Color(0xFF87C99B)),
                    SizedBox(width: 6),
                    Text(
                      'Chat connected',
                      style: TextStyle(fontSize: 12, color: _secondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Chat tools',
            onSelected: (action) {
              if (action == 'history') {
                onShowActivity();
              } else {
                model.toggleActivity();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'history',
                child: Text('View recent activity'),
              ),
              PopupMenuItem(
                value: 'toggle',
                child: Text(
                  model.showActivity
                      ? 'Hide recent activity'
                      : 'Show recent activity',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Recent activity. Mira subscribed, 2 minutes ago. Open history.',
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFF18222D),
            border: Border(bottom: BorderSide(color: _border)),
          ),
          child: const Row(
            children: [
              Icon(Icons.favorite_outline, color: _blue, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Recent activity',
                      style: TextStyle(fontSize: 11, color: _secondary),
                    ),
                    Text('Mira subscribed · 2 min ago'),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: _secondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageRow extends StatelessWidget {
  const _MessageRow({required this.message, required this.onReply});

  final WorkspaceMessage message;
  final VoidCallback onReply;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${message.author} says ${message.text}',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: message.isYou ? _blue : _border,
                shape: BoxShape.circle,
              ),
              child: Text(
                message.author.characters.first.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: message.isYou ? _scaffold : Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.author,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: message.isYou ? _blue : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message.text,
                    style: const TextStyle(fontSize: 15, height: 1.35),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Reply to ${message.author}',
              onPressed: onReply,
              icon: const Icon(Icons.reply, size: 19, color: _secondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.model,
    required this.controller,
    required this.onSend,
  });

  final WorkspaceModel model;
  final TextEditingController controller;
  final Future<void> Function() onSend;

  @override
  Widget build(BuildContext context) {
    final canSend = model.draft.trim().isNotEmpty && !model.sending;
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        8 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1E2936),
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (model.replyTo case final author?)
            Container(
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                children: [
                  const Icon(Icons.reply, size: 18, color: _blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Replying to $author',
                      style: const TextStyle(color: _secondary),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cancel reply',
                    onPressed: () => model.setReply(null),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
          if (model.sendError case final error?)
            Semantics(
              liveRegion: true,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: _coral, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        error,
                        style: const TextStyle(color: _coral, fontSize: 13),
                      ),
                    ),
                    TextButton(
                      onPressed: canSend ? onSend : null,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  key: const Key('chat-composer'),
                  controller: controller,
                  enabled: !model.sending,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: model.setDraft,
                  onSubmitted: canSend ? (_) => onSend() : null,
                  decoration: const InputDecoration(
                    labelText: 'Message studio_chat',
                    hintText: 'Write a message',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                key: const Key('send-message'),
                tooltip: model.sending ? 'Sending message' : 'Send message',
                onPressed: canSend ? onSend : null,
                icon: model.sending
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_outlined),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityHistoryRow extends StatelessWidget {
  const _ActivityHistoryRow({
    required this.icon,
    required this.title,
    required this.time,
  });

  final IconData icon;
  final String title;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 54),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Icon(icon, color: _blue, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
          Text(time, style: const TextStyle(color: _secondary, fontSize: 12)),
        ],
      ),
    );
  }
}
