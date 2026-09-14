import 'package:flutter/material.dart';

import '../../models/enums/chat_engine.dart';
import '../../models/enums/chat_type.dart';
import '../workspace/chat_access_panel.dart';
import 'chat_access.dart';
import 'chat_composer_controller.dart';

/// Native chat composition. The host owns stores, account actions and specialized
/// timeline dependencies; changing workspace emphasis does not recreate them.
class WorkspaceChatPane extends StatefulWidget {
  const WorkspaceChatPane({
    super.key,
    required this.controller,
    required this.timeline,
    required this.onAction,
    this.onPresentationChanged,
  });

  final ChatComposerController controller;
  final Widget timeline;
  final ValueChanged<ChatIntent> onAction;
  final ValueChanged<ChatType>? onPresentationChanged;

  @override
  State<WorkspaceChatPane> createState() => _WorkspaceChatPaneState();
}

class _WorkspaceChatPaneState extends State<WorkspaceChatPane> {
  late final _text = TextEditingController(text: widget.controller.text);
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_syncText);
  }

  @override
  void didUpdateWidget(covariant WorkspaceChatPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_syncText);
      widget.controller.addListener(_syncText);
      _syncText();
    }
  }

  void _syncText() {
    final text = widget.controller.text;
    if (_text.text == text) return;
    _text.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncText);
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final controller = widget.controller;
      final access = controller.access;
      return Column(
        children: [
          _header(context, controller),
          Divider(height: 1, color: Theme.of(context).dividerColor),
          Expanded(
            child: access.showsNativeConversation
                ? LayoutBuilder(
                    builder: (context, constraints) => Column(
                      children: [
                        Expanded(child: widget.timeline),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: constraints.maxHeight * .55,
                          ),
                          child: SingleChildScrollView(
                            reverse: true,
                            child: _composer(context, controller),
                          ),
                        ),
                      ],
                    ),
                  )
                : ChatAccessPanel(access: access, onAction: widget.onAction),
          ),
        ],
      );
    },
  );

  Widget _header(BuildContext context, ChatComposerController controller) {
    final access = controller.access;
    final selected = controller.channels
        .where(
          (choice) =>
              choice.id == controller.conversation?.channel &&
              (access.platform != ChatType.YouTube ||
                  choice.label == access.channelLabel),
        )
        .firstOrNull;
    final canChoose =
        !controller.busy &&
        (access.gate == ChatGate.open || access.gate == ChatGate.channel);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonHideUnderline(
                  child: DropdownButton<ChatChannelChoice>(
                    key: const Key('workspace-chat-channel'),
                    isExpanded: true,
                    value: selected,
                    hint: Text(
                      access.channelLabel ?? 'Choose a channel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onChanged: canChoose
                        ? (choice) {
                            if (choice != null) {
                              controller.selectChannel(choice);
                            }
                          }
                        : null,
                    items: [
                      for (final choice in controller.channels)
                        DropdownMenuItem(
                          value: choice,
                          child: Text(
                            choice.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  access.statusLabel,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          PopupMenuButton<ChatType>(
            tooltip: 'Chat platform',
            enabled: !controller.busy,
            icon: const Icon(Icons.forum_outlined),
            onSelected: (platform) {
              if (controller.setPresentation(platform, ChatEngine.native)) {
                widget.onPresentationChanged?.call(platform);
              }
            },
            itemBuilder: (_) => [
              for (final platform in [ChatType.Twitch, ChatType.YouTube])
                CheckedPopupMenuItem(
                  value: platform,
                  checked: platform == access.platform,
                  child: Text(platform.name),
                ),
            ],
          ),
          PopupMenuButton<ChatIntent>(
            tooltip: 'Chat options',
            icon: const Icon(Icons.more_horiz),
            onSelected: widget.onAction,
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: ChatIntent.channel,
                child: Text('Add or manage channels'),
              ),
              PopupMenuItem(
                value: ChatIntent.webView,
                child: Text('Use free WebView chat'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _composer(BuildContext context, ChatComposerController controller) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ChatReadinessNotice(
            access: controller.access,
            onAction: widget.onAction,
          ),
          if (controller.reply case final reply?)
            Row(
              children: [
                const Icon(Icons.reply, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Replying to ${reply.chatterUserName}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  tooltip: 'Cancel reply',
                  onPressed: () => controller.setReply(null),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          if (controller.error case final error?)
            Semantics(
              liveRegion: true,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  error,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  key: const Key('workspace-chat-composer'),
                  controller: _text,
                  focusNode: _focus,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: controller.setText,
                  decoration: InputDecoration(
                    labelText:
                        'Message ${controller.access.channelLabel ?? 'chat'}',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                key: const Key('workspace-chat-send'),
                tooltip: controller.sending
                    ? 'Sending message'
                    : 'Send message',
                onPressed: controller.canSend ? controller.send : null,
                icon: controller.sending
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
