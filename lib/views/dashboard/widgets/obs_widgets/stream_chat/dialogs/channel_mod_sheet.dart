import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../../../models/enums/chat_type.dart';
import '../../../../../../shared/design/design.dart';
import '../../../../../../shared/dialogs/confirmation.dart';
import '../../../../../../stores/views/twitch_chat.dart';
import '../../../../../../types/classes/twitch/chat_settings.dart';
import '../../../../../../utils/modal_handler.dart';
import '../../../../../../utils/styling_helper.dart';
import '../chat_notice_chrome.dart';
import '../chat_type_brand.dart';
import '../native_chat_chrome.dart';
import '../native_chat_text_field.dart';
import '../twitch_device_code_dialog.dart';
import 'automod_queue_sheet.dart';
import 'channel_bans_sheet.dart';

/// Opens the channel-level Mod actions sheet (clear / modes / shield /
/// announce). Failures surface as a snackbar on the caller's [context].
void showChannelModSheet(BuildContext context) =>
    ModalHandler.showBaseBottomSheet(
      context: context,
      barrierDismissible: true,
      enableDrag: true,
      maxHeightFraction: 0.72,
      builder: (_) => ChannelModSheet(
        onFailure: (message) => ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message))),
      ),
    );

/// Follower wait presets (label → minutes). Twitch max is 129600.
const List<(String, int)> kFollowerWaitPresets = [
  ('Any follower', 0),
  ('10 minutes', 10),
  ('30 minutes', 30),
  ('1 hour', 60),
  ('1 day', 1440),
  ('1 week', 10080),
  ('1 month', 43200),
];

/// Slow mode delay presets (label → seconds). Helix allows 3–120.
const List<(String, int)> kSlowModePresets = [
  ('3 seconds', 3),
  ('5 seconds', 5),
  ('10 seconds', 10),
  ('30 seconds', 30),
  ('1 minute', 60),
  ('2 minutes', 120),
];

/// Announce color chips (Helix `color` values).
const List<String> kAnnounceColors = [
  'primary',
  'blue',
  'green',
  'orange',
  'purple',
];

const int kAnnounceMaxLength = 500;

enum _ChannelModStep { root, followerPresets, slowPresets, announceCompose }

/// Room Mod actions: clear chat, chat modes, Shield Mode, announce.
/// Final Helix mutations confirm first (except Announce **Send**, which
/// is itself the confirm). Missing manage scopes keep the rows visible;
/// tapping them starts the re-login device-code flow.
class ChannelModSheet extends StatefulWidget {
  /// Failure snackbar hook — hosted by the caller's context.
  final void Function(String message) onFailure;

  const ChannelModSheet({
    super.key,
    required this.onFailure,
  });

  @override
  State<ChannelModSheet> createState() => _ChannelModSheetState();
}

class _ChannelModSheetState extends State<ChannelModSheet> {
  _ChannelModStep _step = _ChannelModStep.root;

  /// Re-entrancy guard — a double-tap must not fire two Helix calls.
  bool _running = false;

  final TextEditingController _announceController = TextEditingController();
  String _announceColor = 'primary';

  TwitchChatStore get _store => GetIt.instance<TwitchChatStore>();

  @override
  void initState() {
    super.initState();
    this._refresh();
  }

  Future<void> _refresh() async {
    await this._store.refreshRoomModState();
    if (this.mounted) this.setState(() {});
  }

  @override
  void dispose() {
    this._announceController.dispose();
    super.dispose();
  }

  Future<void> _run(
    Future<bool> Function() action,
    String failureText, {
    bool closeSheet = false,
    bool returnToRoot = false,
  }) async {
    if (this._running) return;
    this.setState(() => this._running = true);
    final ok = await action();
    if (!this.mounted) return;
    this.setState(() {
      this._running = false;
      if (ok && returnToRoot) this._step = _ChannelModStep.root;
    });
    if (closeSheet) {
      Navigator.of(context).pop();
    }
    if (!ok) this.widget.onFailure(failureText);
  }

  /// Confirm before a Helix mutation — cancel leaves the sheet open.
  void _confirmThenRun({
    required String title,
    required String body,
    required String okText,
    required Future<bool> Function() action,
    required String failureText,
    bool closeSheet = false,
    bool returnToRoot = false,
  }) {
    if (this._running) return;
    ModalHandler.showBaseDialog(
      context: context,
      dialogWidget: ConfirmationDialog(
        title: title,
        body: body,
        okText: okText,
        noText: 'Cancel',
        isYesDestructive: true,
        onOk: (_) {
          this._run(
            action,
            failureText,
            closeSheet: closeSheet,
            returnToRoot: returnToRoot,
          );
        },
      ),
    );
  }

  void _requireScopeOr(bool can, VoidCallback whenAllowed) {
    if (!can) {
      startTwitchLogin(context);
      return;
    }
    whenAllowed();
  }

  String get _channelTitle {
    final login = this._store.effectiveBroadcasterLogin;
    return 'Moderate #$login';
  }

  TwitchChatSettings get _settings =>
      this._store.roomChatSettings ??
      const TwitchChatSettings(
        emoteMode: false,
        followerMode: false,
        followerModeDurationMinutes: null,
        subscriberMode: false,
        slowMode: false,
        slowModeWaitTimeSeconds: null,
        uniqueChatMode: false,
      );

  @override
  Widget build(BuildContext context) {
    final maxListHeight = MediaQuery.sizeOf(context).height * 0.55;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          nativeChatSheetDragHandle(context),
          this._titleRow(context),
          const SizedBox(height: AppSpacing.sm),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxListHeight),
            child: SingleChildScrollView(
              child: switch (this._step) {
                _ChannelModStep.root => this._buildRoot(context),
                _ChannelModStep.followerPresets =>
                  this._buildFollowerPresets(context),
                _ChannelModStep.slowPresets => this._buildSlowPresets(context),
                _ChannelModStep.announceCompose =>
                  this._buildAnnounceCompose(context),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _titleRow(BuildContext context) {
    final isRoot = this._step == _ChannelModStep.root;
    final title = switch (this._step) {
      _ChannelModStep.root => this._channelTitle,
      _ChannelModStep.followerPresets => 'Followers-only wait',
      _ChannelModStep.slowPresets => 'Slow mode delay',
      _ChannelModStep.announceCompose => 'Announce',
    };
    if (isRoot) {
      return Text(title, style: nativeChatSheetTitleStyle(context));
    }
    return Row(
      children: [
        Pressable(
          haptic: true,
          onTap: this._running
              ? null
              : () => this.setState(() => this._step = _ChannelModStep.root),
          child: const Padding(
            padding: EdgeInsets.only(right: AppSpacing.sm),
            child: Icon(CupertinoIcons.chevron_back, size: 20.0),
          ),
        ),
        Expanded(
          child: Text(title, style: nativeChatSheetTitleStyle(context)),
        ),
      ],
    );
  }

  Widget _sectionHeader(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.only(
          top: AppSpacing.sm,
          bottom: AppSpacing.xs,
        ),
        child: Text(title, style: nativeChatSheetSectionStyle(context)),
      );

  Widget _buildRoot(BuildContext context) {
    final settings = this._settings;
    final shieldOn = this._store.roomShieldModeActive ?? false;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        this._sectionHeader(context, 'Chat'),
        this._actionRow(
          context,
          icon: CupertinoIcons.clear_circled,
          label: 'Clear chat',
          destructive: true,
          onTap: () => this._confirmThenRun(
            title: 'Clear chat?',
            body:
                'Remove all messages from this channel\'s chat? '
                'This can\'t be undone.',
            okText: 'Clear',
            closeSheet: true,
            action: () => this._store.clearSelectedChannelChat(),
            failureText: 'Could not clear chat',
          ),
        ),
        this._sectionHeader(context, 'Modes'),
        this._modeToggleRow(
          context,
          icon: CupertinoIcons.smiley,
          label: 'Emote-only',
          active: settings.emoteMode,
          can: this._store.canManageChatSettings,
          onEnable: () => this._confirmThenRun(
            title: 'Enable emote-only?',
            body: 'Only emotes will be allowed in chat.',
            okText: 'Enable',
            action: () =>
                this._store.updateSelectedChatSettings(emoteMode: true),
            failureText: 'Could not update chat settings',
          ),
          onDisable: () => this._confirmThenRun(
            title: 'Disable emote-only?',
            body: 'Viewers will be able to send regular text again.',
            okText: 'Disable',
            action: () =>
                this._store.updateSelectedChatSettings(emoteMode: false),
            failureText: 'Could not update chat settings',
          ),
        ),
        this._modeToggleRow(
          context,
          icon: CupertinoIcons.star,
          label: 'Subs-only',
          active: settings.subscriberMode,
          can: this._store.canManageChatSettings,
          onEnable: () => this._confirmThenRun(
            title: 'Enable subs-only?',
            body: 'Only subscribers will be able to chat.',
            okText: 'Enable',
            action: () =>
                this._store.updateSelectedChatSettings(subscriberMode: true),
            failureText: 'Could not update chat settings',
          ),
          onDisable: () => this._confirmThenRun(
            title: 'Disable subs-only?',
            body: 'All viewers will be able to chat again.',
            okText: 'Disable',
            action: () =>
                this._store.updateSelectedChatSettings(subscriberMode: false),
            failureText: 'Could not update chat settings',
          ),
        ),
        this._modeToggleRow(
          context,
          icon: CupertinoIcons.textformat,
          label: 'Unique chat',
          active: settings.uniqueChatMode,
          can: this._store.canManageChatSettings,
          onEnable: () => this._confirmThenRun(
            title: 'Enable unique chat?',
            body: 'Viewers can\'t send the same message twice.',
            okText: 'Enable',
            action: () =>
                this._store.updateSelectedChatSettings(uniqueChatMode: true),
            failureText: 'Could not update chat settings',
          ),
          onDisable: () => this._confirmThenRun(
            title: 'Disable unique chat?',
            body: 'Viewers can repeat messages again.',
            okText: 'Disable',
            action: () =>
                this._store.updateSelectedChatSettings(uniqueChatMode: false),
            failureText: 'Could not update chat settings',
          ),
        ),
        this._modeToggleRow(
          context,
          icon: CupertinoIcons.person_2,
          label: 'Followers-only',
          active: settings.followerMode,
          can: this._store.canManageChatSettings,
          onEnable: () =>
              this.setState(() => this._step = _ChannelModStep.followerPresets),
          onDisable: () => this._confirmThenRun(
            title: 'Disable followers-only?',
            body: 'Anyone will be able to chat again.',
            okText: 'Disable',
            action: () =>
                this._store.updateSelectedChatSettings(followerMode: false),
            failureText: 'Could not update chat settings',
          ),
        ),
        this._modeToggleRow(
          context,
          icon: CupertinoIcons.timer,
          label: 'Slow mode',
          active: settings.slowMode,
          can: this._store.canManageChatSettings,
          onEnable: () =>
              this.setState(() => this._step = _ChannelModStep.slowPresets),
          onDisable: () => this._confirmThenRun(
            title: 'Disable slow mode?',
            body: 'Viewers will be able to chat at full speed again.',
            okText: 'Disable',
            action: () =>
                this._store.updateSelectedChatSettings(slowMode: false),
            failureText: 'Could not update chat settings',
          ),
        ),
        this._sectionHeader(context, 'Shield'),
        this._modeToggleRow(
          context,
          icon: CupertinoIcons.shield,
          label: 'Shield Mode',
          active: shieldOn,
          can: this._store.canManageShieldMode,
          onEnable: () => this._confirmThenRun(
            title: 'Enable Shield Mode?',
            body:
                'Turn on Shield Mode for this channel? Followers-only and '
                'other protections apply until you turn it off.',
            okText: 'Enable',
            action: () => this._store.setShieldMode(true),
            failureText: 'Could not update Shield Mode',
          ),
          onDisable: () => this._confirmThenRun(
            title: 'Disable Shield Mode?',
            body: 'Turn off Shield Mode for this channel?',
            okText: 'Disable',
            action: () => this._store.setShieldMode(false),
            failureText: 'Could not update Shield Mode',
          ),
        ),
        this._sectionHeader(context, 'Bans'),
        this._actionRow(
          context,
          icon: CupertinoIcons.person_badge_minus,
          label: 'Bans & requests…',
          onTap: () => this._requireScopeOr(
            this._store.canReadModeration || this._store.canModerateChats,
            () => showChannelBansSheet(context),
          ),
        ),

        /// Wave 3: the queue only exists with the manage scope (the
        /// EventSub pair requires it) — pre-upgrade tokens never see the
        /// row. The count live-updates while the sheet is open.
        if (this._store.canManageAutoMod) ...[
          this._sectionHeader(context, 'AutoMod'),
          Observer(
            builder: (context) => this._actionRow(
              context,
              icon: CupertinoIcons.exclamationmark_shield,
              label: this._store.autoModQueue.isEmpty
                  ? 'AutoMod queue…'
                  : 'AutoMod queue (${this._store.autoModQueue.length})…',
              onTap: () => showAutoModQueueSheet(context),
            ),
          ),
        ],
        this._sectionHeader(context, 'Announce'),
        this._actionRow(
          context,
          icon: CupertinoIcons.speaker_2,
          label: 'Announce…',
          onTap: () => this._requireScopeOr(
            this._store.canSendAnnouncements,
            () => this
                .setState(() => this._step = _ChannelModStep.announceCompose),
          ),
        ),
      ],
    );
  }

  Widget _buildFollowerPresets(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final preset in kFollowerWaitPresets)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: this._actionRow(
              context,
              icon: CupertinoIcons.person_2,
              label: preset.$1,
              onTap: () => this._confirmThenRun(
                title: 'Enable followers-only?',
                body: preset.$2 == 0
                    ? 'Only followers can chat.'
                    : 'Only followers who have followed for at least '
                        '${preset.$1.toLowerCase()} can chat.',
                okText: 'Enable',
                returnToRoot: true,
                action: () => this._store.updateSelectedChatSettings(
                      followerMode: true,
                      followerModeDurationMinutes: preset.$2,
                    ),
                failureText: 'Could not update chat settings',
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSlowPresets(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final preset in kSlowModePresets)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: this._actionRow(
              context,
              icon: CupertinoIcons.timer,
              label: preset.$1,
              onTap: () => this._confirmThenRun(
                title: 'Enable slow mode?',
                body:
                    'Viewers must wait ${preset.$1} between messages.',
                okText: 'Enable',
                returnToRoot: true,
                action: () => this._store.updateSelectedChatSettings(
                      slowMode: true,
                      slowModeWaitTimeSeconds: preset.$2,
                    ),
                failureText: 'Could not update chat settings',
              ),
            ),
          ),
      ],
    );
  }

  /// Helix announce highlight → chip paint (matches chat rail solid).
  Color _announceChipColor(String helixColor) =>
      chatAnnouncementHighlight(helixColor).solid;

  Widget _buildAnnounceCompose(BuildContext context) {
    final text = this._announceController.text;
    final canSend = !this._running &&
        text.trim().isNotEmpty &&
        text.length <= kAnnounceMaxLength;
    final accent = ChatType.Twitch.brandColor ??
        Theme.of(context).cupertinoOverrideTheme?.primaryColor ??
        Theme.of(context).colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final color in kAnnounceColors)
              this._announceColorChip(context, color),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: NativeChatTextField(
                controller: this._announceController,
                hintText: 'Send an announcement…',
                minLines: 1,
                maxLines: 5,
                maxLength: kAnnounceMaxLength,
                textInputAction: TextInputAction.send,
                focusBorderColor: accent,
                onChanged: (_) => this.setState(() {}),
                onSubmitted: canSend
                    ? (_) => this._sendAnnouncement()
                    : null,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Pressable(
              haptic: true,
              onTap: canSend ? this._sendAnnouncement : null,
              child: Container(
                constraints: const BoxConstraints(
                  minWidth: kMinInteractiveDimensionCupertino,
                  minHeight: kMinInteractiveDimensionCupertino,
                ),
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: kNativeChatDockControlSize,
                  height: kNativeChatDockControlSize,
                  decoration: BoxDecoration(
                    color: canSend
                        ? accent
                        : accent.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: this._running
                      ? (StylingHelper.isApple(context)
                          ? const CupertinoActivityIndicator(radius: 8.0)
                          : const SizedBox(
                              width: 16.0,
                              height: 16.0,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                                color: Colors.white,
                              ),
                            ))
                      : const Icon(
                          CupertinoIcons.paperplane_fill,
                          size: 17.0,
                          color: Colors.white,
                        ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _announceColorChip(BuildContext context, String color) {
    final chipColor = this._announceChipColor(color);
    final selected = this._announceColor == color;
    final label = switch (color) {
      'primary' => 'Primary',
      'blue' => 'Blue',
      'green' => 'Green',
      'orange' => 'Orange',
      'purple' => 'Purple',
      _ => color,
    };
    return Pressable(
      haptic: true,
      onTap: () => this.setState(() => this._announceColor = color),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: selected
              ? chipColor
              : chipColor.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: chipColor.withValues(alpha: selected ? 1.0 : 0.55),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: selected ? Colors.white : chipColor,
                fontWeight: selected ? FontWeight.w600 : null,
              ),
        ),
      ),
    );
  }

  void _sendAnnouncement() {
    this._run(
      () => this._store.sendAnnouncement(
            this._announceController.text.trim(),
            this._announceColor,
          ),
      'Could not send announcement',
      closeSheet: true,
    );
  }

  /// Boolean mode/shield row — missing [can] starts re-login instead.
  Widget _modeToggleRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool active,
    required bool can,
    required VoidCallback onEnable,
    required VoidCallback onDisable,
  }) {
    final status = active ? 'On' : 'Off';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: this._actionRow(
        context,
        icon: icon,
        label: '$label · $status',
        onTap: () => this._requireScopeOr(
          can,
          () => active ? onDisable() : onEnable(),
        ),
      ),
    );
  }

  Widget _actionRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool destructive = false,
    bool enabled = true,
  }) {
    final Color color = destructive
        ? (Theme.of(context).extension<AppStatusColors>() ??
                AppStatusColors.standard)
            .unreachable
        : Theme.of(context).textTheme.bodyMedium?.color ??
            CupertinoColors.label;
    return Pressable(
      haptic: true,
      onTap: this._running || !enabled ? null : onTap,
      child: Container(
        constraints: const BoxConstraints(
          minHeight: kMinInteractiveDimensionCupertino,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: StylingHelper.lightenDarkenColor(Theme.of(context).cardColor),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
            width: 0.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18.0, color: color),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
