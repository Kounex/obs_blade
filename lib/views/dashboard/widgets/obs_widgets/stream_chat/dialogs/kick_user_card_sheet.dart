import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/stores/views/kick_chat.dart';
import 'package:obs_blade/types/classes/kick/kick_chat_message.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/utils/kick/kick_auth_service.dart'
    show KickUserIdentity;
import 'package:obs_blade/utils/modal_handler.dart';
import 'package:obs_blade/utils/styling_helper.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/kick_chat_message_row.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_appearance.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_chrome.dart';

/// Opens the native Kick chat user card for [userId].
void showKickUserCardSheet(
  BuildContext context, {
  required int userId,
  String? fallbackName,
}) => ModalHandler.showBaseBottomSheet(
  context: context,
  barrierDismissible: true,
  enableDrag: true,
  maxHeightFraction: 0.85,
  builder: (_) => KickUserCardSheet(userId: userId, fallbackName: fallbackName),
);

/// Minimal Kick viewer card — avatar, name, recent chat history. There's
/// no facts block (unlike [ChatUserCardSheet]'s Twitch Helix rows):
/// Kick's public API (`GET /users?id=`) exposes nothing beyond name +
/// avatar for an arbitrary user, so there's nothing else honest to show.
/// The avatar lookup itself only works for a signed-in reader (their own
/// token is what authorizes looking someone else up) — anonymous readers
/// see the buffer identity with a placeholder avatar.
class KickUserCardSheet extends StatefulWidget {
  final int userId;
  final String? fallbackName;

  const KickUserCardSheet({super.key, required this.userId, this.fallbackName});

  @override
  State<KickUserCardSheet> createState() => _KickUserCardSheetState();
}

class _KickUserCardSheetState extends State<KickUserCardSheet> {
  KickChatStore get _store => GetIt.instance<KickChatStore>();

  bool _loadingProfile = true;
  KickUserIdentity? _profile;

  List<KickChatMessage> get _bufferedMessages =>
      this._store.messagesForChatter(this.widget.userId);

  KickChatMessage? get _newestBuffered =>
      this._bufferedMessages.isEmpty ? null : this._bufferedMessages.first;

  @override
  void initState() {
    super.initState();
    unawaited(this._loadProfile());
  }

  Future<void> _loadProfile() async {
    final profile = await this._store.fetchUserProfile(this.widget.userId);
    if (!mounted) return;
    this.setState(() {
      this._profile = profile;
      this._loadingProfile = false;
    });
  }

  String _displayName() =>
      this._profile?.name ??
      this.widget.fallbackName ??
      this._newestBuffered?.authorName ??
      'Chatter';

  @override
  Widget build(BuildContext context) {
    final settingsBox = Hive.box(HiveKeys.Settings.name);
    final messages = this._bufferedMessages;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            nativeChatSheetDragHandle(context),
            this._header(context),
            const SizedBox(height: AppSpacing.lg),
            this._liveDivider(context),
            const SizedBox(height: AppSpacing.sm),
            if (messages.isEmpty)
              Text(
                'No messages in this chat yet',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else ...[
              for (var i = 0; i < messages.length; i++) ...[
                if (i > 0 && NativeChatAppearance.separators(settingsBox))
                  nativeChatHairline(context),
                KickChatMessageRow(
                  key: ValueKey('card-msg-${messages[i].id}'),
                  message: messages[i],
                  settingsBox: settingsBox,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final avatarUrl = this._profile?.profilePicture;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 28.0,
          backgroundColor: StylingHelper.lightenDarkenColor(
            Theme.of(context).cardColor,
          ),
          backgroundImage: avatarUrl == null ? null : NetworkImage(avatarUrl),
          onBackgroundImageError: avatarUrl == null ? null : (_, _) {},
          child: avatarUrl != null
              ? null
              : this._loadingProfile
              ? SizedBox(
                  width: 16.0,
                  height: 16.0,
                  child: StylingHelper.isApple(context)
                      ? const CupertinoActivityIndicator()
                      : const CircularProgressIndicator(strokeWidth: 2.0),
                )
              : Icon(
                  CupertinoIcons.person_fill,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            this._displayName(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: kickAuthorColor(
                context,
                this._newestBuffered?.sender?.identity?.color,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _liveDivider(BuildContext context) => Row(
    children: [
      Expanded(child: nativeChatHairline(context)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Text(
          'LIVE',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color:
                (Theme.of(context).extension<AppStatusColors>() ??
                        AppStatusColors.standard)
                    .live,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
      ),
      Expanded(child: nativeChatHairline(context)),
    ],
  );
}
