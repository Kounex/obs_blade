import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../../../shared/design/design.dart';
import '../../../../../../shared/dialogs/confirmation.dart';
import '../../../../../../stores/views/youtube_chat.dart';
import '../../../../../../types/classes/chat/chat_ban_entry.dart';
import '../../../../../../utils/modal_handler.dart';
import '../../../../../../utils/youtube/youtube_live_chat_service.dart';
import '../native_chat_chrome.dart';
import '../native_chat_text_field.dart';
import 'channel_mod_chrome.dart';

/// Opens the YouTube channel mod sheet on [context] (toasts land there).
void showYouTubeChannelModSheet(BuildContext context) =>
    ModalHandler.showBaseBottomSheet(
      context: context,
      barrierDismissible: true,
      enableDrag: true,
      maxHeightFraction: 0.85,
      builder: (_) => ChannelModSheetFrame(
        child: YouTubeChannelModPanel(
          onToast: (message) => showChannelModToast(context, message),
        ),
      ),
    );

/// YouTube allows 2–4 poll options.
const int kYouTubePollMinOptions = 2;
const int kYouTubePollMaxOptions = 4;

/// YouTube channel moderation — what the Data API allows: polls (start /
/// end), the bans seen this session (lift the ones issued here — YouTube
/// needs the ban's own id), and on the own channel the moderator list
/// (owner-only API). No chat modes / clear / announce: no API. Offered to
/// any signed-in account; a 403 toasts [chatNotModeratorText].
class YouTubeChannelModPanel extends StatefulWidget {
  final void Function(String message) onToast;
  final bool showTitle;

  const YouTubeChannelModPanel({
    super.key,
    required this.onToast,
    this.showTitle = true,
  });

  @override
  State<YouTubeChannelModPanel> createState() => _YouTubeChannelModPanelState();
}

class _YouTubeChannelModPanelState extends State<YouTubeChannelModPanel> {
  final TextEditingController _question = TextEditingController();
  final List<TextEditingController> _options = [
    TextEditingController(),
    TextEditingController(),
  ];
  bool _composing = false;
  bool _running = false;

  YouTubeChatStore get _store => GetIt.instance<YouTubeChatStore>();

  @override
  void initState() {
    super.initState();

    /// The moderator list is owner-only and needs a live chat — only ask
    /// where it can work.
    if (this._store.isViewingOwnChannel &&
        this._store.canWrite &&
        this._store.chatConnection == YouTubeChatConnectionState.connected) {
      this._store.loadModerators();
    }
  }

  @override
  void dispose() {
    this._question.dispose();
    for (final option in this._options) {
      option.dispose();
    }
    super.dispose();
  }

  Future<bool> _run(Future<bool> Function() action, String success) async {
    if (this._running) return false;
    this.setState(() => this._running = true);
    final ok = await action();
    if (!this.mounted) return ok;
    this.setState(() => this._running = false);
    this.widget.onToast(
      ok
          ? success
          : this._store.moderationForbidden
          ? chatNotModeratorText('YouTube')
          : this._store.moderationError ?? 'Something went wrong',
    );
    return ok;
  }

  void _confirm({
    required String title,
    required String body,
    required String okText,
    required VoidCallback onOk,
    bool destructive = false,
  }) => ModalHandler.showBaseDialog(
    context: this.context,
    dialogWidget: ConfirmationDialog(
      title: title,
      body: body,
      okText: okText,
      noText: 'Cancel',
      isYesDestructive: destructive,
      onOk: (_) => onOk(),
    ),
  );

  void _unban(ChatBanEntry ban) {
    final banId = ban.banId;
    if (banId == null) return;
    final name = ban.userName ?? 'this user';
    this._confirm(
      title: ban.isTimeout ? 'Lift timeout?' : 'Unban $name?',
      body: '$name can chat again right away.',
      okText: ban.isTimeout ? 'Lift' : 'Unban',
      onOk: () => this._run(
        () => this._store.unbanUser(banId),
        ban.isTimeout ? 'Timeout lifted for $name' : '$name was unbanned',
      ),
    );
  }

  List<String> get _optionTexts => [
    for (final option in this._options)
      if (option.text.trim().isNotEmpty) option.text.trim(),
  ];

  bool get _pollReady =>
      this._question.text.trim().isNotEmpty &&
      this._optionTexts.length >= kYouTubePollMinOptions;

  Future<void> _startPoll() async {
    if (!this._pollReady) return;
    final ok = await this._run(
      () =>
          this._store.createPoll(this._question.text.trim(), this._optionTexts),
      'Poll started',
    );
    if (ok && this.mounted) {
      this.setState(() {
        this._composing = false;
        this._question.clear();
        for (final option in this._options) {
          option.clear();
        }
      });
    }
  }

  void _removeModerator(YouTubeChatModerator moderator) {
    final name = moderator.displayName ?? 'this moderator';
    this._confirm(
      title: 'Remove $name?',
      body: '$name will no longer moderate your chat.',
      okText: 'Remove',
      destructive: true,
      onOk: () => this._run(
        () => this._store.removeModerator(moderator),
        '$name is no longer a moderator',
      ),
    );
  }

  Widget _pollSection(BuildContext context) {
    final poll = this._store.activePoll;
    if (poll != null) {
      final metadata = poll.snippet.pollDetails?.metadata;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            metadata?.questionText ?? 'Active poll',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          for (final option in metadata?.options ?? const [])
            ChannelModNote(
              option.tally == null
                  ? '• ${option.optionText ?? ''}'
                  : '• ${option.optionText ?? ''} - ${option.tally}',
            ),
          const SizedBox(height: AppSpacing.xs),
          ChannelModActionRow(
            key: const Key('youtube-end-poll'),
            icon: CupertinoIcons.stop_circle,
            label: 'End poll',
            destructive: true,
            onTap: this._running
                ? null
                : () => this._confirm(
                    title: 'End the poll?',
                    body: 'Voting closes for everyone.',
                    okText: 'End',
                    destructive: true,
                    onOk: () =>
                        this._run(this._store.closeActivePoll, 'Poll ended'),
                  ),
          ),
        ],
      );
    }
    if (!this._composing) {
      return ChannelModActionRow(
        key: const Key('youtube-new-poll'),
        icon: CupertinoIcons.chart_bar_alt_fill,
        label: 'Start a poll…',
        onTap: () => this.setState(() => this._composing = true),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NativeChatTextField(
          key: const Key('youtube-poll-question'),
          controller: this._question,
          hintText: 'Question',
          onChanged: (_) => this.setState(() {}),
        ),
        for (var i = 0; i < this._options.length; i++) ...[
          const SizedBox(height: AppSpacing.xs),
          NativeChatTextField(
            key: Key('youtube-poll-option-$i'),
            controller: this._options[i],
            hintText: 'Option ${i + 1}',
            onChanged: (_) => this.setState(() {}),
          ),
        ],
        Row(
          children: [
            if (this._options.length < kYouTubePollMaxOptions)
              ChannelModInlineButton(
                label: 'Add option',
                onTap: () => this.setState(
                  () => this._options.add(TextEditingController()),
                ),
              ),
            const Spacer(),
            ChannelModInlineButton(
              label: 'Cancel',
              onTap: () => this.setState(() => this._composing = false),
            ),
            ChannelModInlineButton(
              key: const Key('youtube-poll-start'),
              label: 'Start',
              onTap: this._pollReady && !this._running ? this._startPoll : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _moderatorSection(BuildContext context) {
    final moderators = this._store.moderators;
    if (!this._store.isViewingOwnChannel) {
      return const ChannelModNote(
        'YouTube only lets the channel owner manage moderators.',
      );
    }
    if (moderators == null) {
      return ChannelModNote(
        this._store.chatConnection == YouTubeChatConnectionState.connected
            ? 'Loading moderators…'
            : 'Moderators load while your chat is live.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (moderators.isEmpty)
          const ChannelModNote(
            'No moderators yet - long-press a message to make its author '
            'a moderator.',
          ),
        for (final moderator in moderators)
          Row(
            children: [
              const Icon(CupertinoIcons.shield_lefthalf_fill, size: 18.0),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  moderator.displayName ?? moderator.channelId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ChannelModInlineButton(
                key: Key('youtube-remove-mod-${moderator.channelId}'),
                label: 'Remove',
                onTap: this._running
                    ? null
                    : () => this._removeModerator(moderator),
              ),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        final bans = this._store.recentBans.toList();
        final live =
            this._store.chatConnection == YouTubeChatConnectionState.connected;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (this.widget.showTitle)
              Text('Moderate chat', style: nativeChatSheetTitleStyle(context)),
            const ChannelModSectionHeader('Poll'),
            if (live)
              this._pollSection(context)
            else
              const ChannelModNote('Polls need a live chat.'),
            const ChannelModSectionHeader('Bans this session'),
            if (bans.isEmpty)
              const ChannelModNote(
                'No bans or timeouts seen yet. YouTube has no ban list API, '
                'so this lists the ones that happen while you watch.',
              )
            else
              for (final ban in bans)
                ChannelModBanRow(
                  ban: ban,
                  onUnban: ban.banId == null || this._running
                      ? null
                      : () => this._unban(ban),
                  unavailableHint: ban.banId == null
                      ? 'lift it on youtube.com'
                      : null,
                ),
            const ChannelModSectionHeader('Moderators'),
            this._moderatorSection(context),
            const ChannelModNote(
              'YouTube\'s API has no chat modes, clear or announcements.',
            ),
          ],
        );
      },
    );
  }
}
