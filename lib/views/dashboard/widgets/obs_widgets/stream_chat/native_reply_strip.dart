import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../../shared/design/design.dart';
import '../../../../../stores/views/twitch_chat.dart';

/// "Replying to @user: excerpt …" strip docked above the native chat
/// input while a reply target is set ([TwitchChatStore.replyTarget]).
/// Renders nothing when no target is pending; ✕ cancels. Mirrors the
/// reply preview line of [TwitchChatMessageRow] so composing and sent
/// replies read the same.
class NativeReplyStrip extends StatelessWidget {
  /// Brand accent — the reply icon and the parent @name.
  final Color accentColor;

  const NativeReplyStrip({super.key, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final store = GetIt.instance<TwitchChatStore>();
    return Observer(
      builder: (context) {
        final target = store.replyTarget;
        if (target == null) return const SizedBox.shrink();
        return Row(
          children: [
            Icon(CupertinoIcons.reply, size: 12.0, color: this.accentColor),
            const SizedBox(width: AppSpacing.xs / 2),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: Theme.of(context).textTheme.bodySmall,
                  children: [
                    const TextSpan(text: 'Replying to '),
                    TextSpan(
                      text: '@${target.chatterUserName}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: this.accentColor,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    TextSpan(text: ': ${target.message.text}'),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Pressable(
              haptic: true,
              onTap: store.clearReplyTarget,
              child: Container(
                constraints: const BoxConstraints(
                  minWidth: kMinInteractiveDimensionCupertino,
                  minHeight: kMinInteractiveDimensionCupertino,
                ),
                alignment: Alignment.center,
                child: Icon(
                  CupertinoIcons.xmark,
                  size: 14.0,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
