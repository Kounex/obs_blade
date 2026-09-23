import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/stores/views/youtube_chat.dart';
import 'package:obs_blade/types/classes/youtube/youtube_chat_message.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/utils/icons/jam_icons.dart';
import 'package:obs_blade/utils/modal_handler.dart';
import 'package:obs_blade/utils/styling_helper.dart';
import 'package:obs_blade/utils/youtube/youtube_live_chat_service.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_appearance.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_chrome.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/youtube_chat_message_row.dart';

/// Opens the native YouTube chat user card for [channelId].
void showYouTubeUserCardSheet(
  BuildContext context, {
  required String channelId,
  String? fallbackName,
  String? fallbackAvatarUrl,
}) => ModalHandler.showBaseBottomSheet(
  context: context,
  barrierDismissible: true,
  enableDrag: true,
  maxHeightFraction: 0.85,
  builder: (_) => YouTubeUserCardSheet(
    channelId: channelId,
    fallbackName: fallbackName,
    fallbackAvatarUrl: fallbackAvatarUrl,
  ),
);

/// YouTube viewer card — avatar, identity, role facts and recent chat.
/// Unlike [ChatUserCardSheet]'s Twitch Helix rows, the role facts (owner /
/// moderator / member / verified) cost nothing extra: every buffered
/// message already carries them in `authorDetails`. The one optional
/// enrichment call is `channels.list` for the channel's creation date
/// (1 quota unit, plain API-key read — works signed-out too).
class YouTubeUserCardSheet extends StatefulWidget {
  final String channelId;
  final String? fallbackName;
  final String? fallbackAvatarUrl;

  const YouTubeUserCardSheet({
    super.key,
    required this.channelId,
    this.fallbackName,
    this.fallbackAvatarUrl,
  });

  @override
  State<YouTubeUserCardSheet> createState() => _YouTubeUserCardSheetState();
}

class _YouTubeUserCardSheetState extends State<YouTubeUserCardSheet> {
  YouTubeChatStore get _store => GetIt.instance<YouTubeChatStore>();

  bool _loadingChannel = true;
  YouTubeChannelInfo? _channelInfo;

  List<YouTubeChatMessage> get _bufferedMessages =>
      this._store.messagesForChatter(this.widget.channelId);

  YouTubeChatMessage? get _newestBuffered =>
      this._bufferedMessages.isEmpty ? null : this._bufferedMessages.first;

  @override
  void initState() {
    super.initState();
    unawaited(this._loadChannel());
  }

  Future<void> _loadChannel() async {
    final info = await this._store.fetchChannelInfo(this.widget.channelId);
    if (!mounted) return;
    this.setState(() {
      this._channelInfo = info;
      this._loadingChannel = false;
    });
  }

  String _displayName() =>
      this._newestBuffered?.authorName ??
      this.widget.fallbackName ??
      this._channelInfo?.title ??
      'Chatter';

  String? _avatarUrl() =>
      this._newestBuffered?.authorProfileImageUrl ??
      this.widget.fallbackAvatarUrl ??
      this._channelInfo?.thumbnailUrl;

  String _formatFactDate(DateTime date) =>
      DateFormat.yMMMMd().format(date.toLocal());

  @override
  Widget build(BuildContext context) {
    final settingsBox = Hive.box(HiveKeys.Settings.name);
    final messages = this._bufferedMessages;

    return NativeChatSheetScaffold(
      headerGap: AppSpacing.lg,
      header: this._header(context),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          this._factsBlock(context),
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
              YouTubeChatMessageRow(
                key: ValueKey('card-msg-${messages[i].id}'),
                message: messages[i],
                settingsBox: settingsBox,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    final avatarUrl = this._avatarUrl();
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
          child: avatarUrl == null
              ? Icon(
                  CupertinoIcons.person_fill,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                )
              : null,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            this._displayName(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: youTubeAuthorColor(context, this.widget.channelId),
            ),
          ),
        ),
      ],
    );
  }

  Widget _factsBlock(BuildContext context) {
    if (this._loadingChannel) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Center(
          child: StylingHelper.isApple(context)
              ? const CupertinoActivityIndicator()
              : const SizedBox(
                  width: 20.0,
                  height: 20.0,
                  child: CircularProgressIndicator(strokeWidth: 2.0),
                ),
        ),
      );
    }

    final newest = this._newestBuffered;
    final rows = <Widget>[];
    if (newest?.isOwner ?? false) {
      rows.add(
        this._factRow(
          context,
          icon: JamIcons.crown_f,
          iconColor: const Color(0xFFFFB300),
          label: 'Channel owner',
        ),
      );
    }
    if (newest?.isModerator ?? false) {
      rows.add(
        this._factRow(context, icon: JamIcons.wrench_f, label: 'Moderator'),
      );
    }
    if (newest?.isSponsor ?? false) {
      rows.add(
        this._factRow(
          context,
          icon: JamIcons.star_f,
          iconColor: kYouTubeMemberAccent,
          label: 'Channel member',
        ),
      );
    }
    if (newest?.isVerified ?? false) {
      rows.add(
        this._factRow(
          context,
          icon: CupertinoIcons.checkmark_seal_fill,
          label: 'Verified',
        ),
      );
    }
    if (this._channelInfo?.publishedAt case final created?) {
      rows.add(
        this._factRow(
          context,
          icon: CupertinoIcons.calendar,
          label: 'Channel created on ${this._formatFactDate(created)}',
        ),
      );
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.xs),
          rows[i],
        ],
      ],
    );
  }

  Widget _factRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    Color? iconColor,
  }) => Row(
    children: [
      Icon(
        icon,
        size: 16.0,
        color:
            iconColor ??
            (Theme.of(context).extension<AppTextColors>() ??
                    AppTextColors.standard)
                .textTertiary,
      ),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Text(label, style: Theme.of(context).textTheme.bodySmall),
      ),
    ],
  );

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
