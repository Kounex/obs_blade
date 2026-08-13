import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import '../../../../../../shared/design/design.dart';
import '../../../../../../shared/dialogs/confirmation.dart';
import '../../../../../../stores/views/twitch_chat.dart';
import '../../../../../../types/classes/twitch/twitch_banned_user.dart';
import '../../../../../../utils/modal_handler.dart';
import '../../../../../../utils/styling_helper.dart';
import '../native_chat_chrome.dart';

/// Opens the ban inbox sheet (pending unban requests + banned users) for
/// the effective channel. Failures surface as a snackbar on the caller's
/// [context].
void showChannelBansSheet(BuildContext context) =>
    ModalHandler.showBaseBottomSheet(
      context: context,
      barrierDismissible: true,
      enableDrag: true,
      maxHeightFraction: 0.72,
      builder: (_) => ChannelBansSheet(
        onFailure: (message) => ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message))),
      ),
    );

/// Ban inbox: pending unban requests and (own channel only — Helix serves
/// no other) the banned/timed-out user list, each with an Unban action.
/// With the Wave 3 `moderator:manage:unban_requests` scope, request rows
/// also offer Approve (unbans + resolves) and Deny; pre-upgrade tokens
/// keep the plain Unban pill (a separate, already-held scope — unbanning
/// the requester resolves their request too).
class ChannelBansSheet extends StatefulWidget {
  /// Failure snackbar hook — hosted by the caller's context.
  final void Function(String message) onFailure;

  const ChannelBansSheet({super.key, required this.onFailure});

  @override
  State<ChannelBansSheet> createState() => _ChannelBansSheetState();
}

class _ChannelBansSheetState extends State<ChannelBansSheet> {
  /// Re-entrancy guard — the user id currently being unbanned.
  String? _runningUserId;

  TwitchChatStore get _store => GetIt.instance<TwitchChatStore>();

  @override
  void initState() {
    super.initState();
    this._refresh();
  }

  /// Same idiom as the channel mod sheet: await the store refresh, then
  /// rebuild via setState (no Observer — the sheet owns its refresh and
  /// unban lifecycles).
  Future<void> _refresh() async {
    await this._store.refreshBanInbox();
    if (this.mounted) this.setState(() {});
  }

  String _formatDate(DateTime date) => DateFormat.yMMMd().format(date.toLocal());

  Future<void> _confirmUnban(String userId, String userName) async {
    if (this._runningUserId != null) return;
    ModalHandler.showBaseDialog(
      context: context,
      dialogWidget: ConfirmationDialog(
        title: 'Unban $userName?',
        body: '$userName will be able to chat in this channel again '
            'immediately.',
        okText: 'Unban',
        noText: 'Cancel',
        onOk: (_) async {
          this.setState(() => this._runningUserId = userId);
          final ok = await this._store.unbanUser(userId);
          if (!this.mounted) return;
          this.setState(() => this._runningUserId = null);
          if (!ok) this.widget.onFailure('Could not unban $userName');
        },
      ),
    );
  }

  /// Approve/deny a pending unban request (Wave 3 manage scope). Same
  /// confirm + running-guard idiom as [_confirmUnban]; the request drops
  /// from the inbox optimistically on success (an approval also unbans).
  void _confirmResolve(TwitchUnbanRequest request, {required bool approved}) {
    if (this._runningUserId != null) return;
    ModalHandler.showBaseDialog(
      context: context,
      dialogWidget: ConfirmationDialog(
        title: approved
            ? 'Approve ${request.userName}\'s request?'
            : 'Deny ${request.userName}\'s request?',
        body: approved
            ? '${request.userName} is unbanned and the request is marked '
                'approved.'
            : 'The ban stays in place and the request is marked denied.',
        okText: approved ? 'Approve' : 'Deny',
        noText: 'Cancel',
        isYesDestructive: !approved,
        onOk: (_) async {
          this.setState(() => this._runningUserId = request.userId);
          final ok = await this._store.resolveUnbanRequest(
            request.id,
            approved: approved,
          );
          if (!this.mounted) return;
          this.setState(() => this._runningUserId = null);
          if (!ok) this.widget.onFailure('Could not update the request');
        },
      ),
    );
  }

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
          Row(
            children: [
              Expanded(
                child: Text(
                  'Bans & requests',
                  style: nativeChatSheetTitleStyle(context),
                ),
              ),
              Pressable(
                haptic: true,
                onTap: () => this._refresh(),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: Icon(
                    CupertinoIcons.arrow_clockwise,
                    size: 18.0,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxListHeight),
            child: SingleChildScrollView(
              child: this._buildBody(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final store = this._store;
    final requests = store.unbanRequests;
    final bans = store.bannedUsers;
    final ownChannel = store.selectedChannelId == null;

    if (store.banInboxLoading && requests.isEmpty && bans.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: StylingHelper.isApple(context)
              ? const CupertinoActivityIndicator()
              : const CircularProgressIndicator(),
        ),
      );
    }

    final error = store.banInboxError;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              error,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: (Theme.of(context).extension<AppStatusColors>() ??
                            AppStatusColors.standard)
                        .unreachable,
                  ),
            ),
          ),
        this._sectionHeader(context, 'Unban requests'),
        if (requests.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              'No pending unban requests',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )
        else
          for (final request in requests)
            this._requestRow(context, request),
        if (ownChannel) ...[
          this._sectionHeader(context, 'Banned users'),
          if (bans.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                'No banned users',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            )
          else
            for (final ban in bans) this._banRow(context, ban),
        ] else
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              'The full ban list is only available in your own channel.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
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

  Widget _requestRow(BuildContext context, TwitchUnbanRequest request) =>
      this._inboxRowCard(
        context,
        userId: request.userId,
        userName: request.userName,
        lines: [
          if (request.text.trim().isNotEmpty) request.text,
          if (request.createdAt != null)
            'Requested ${this._formatDate(request.createdAt!)}',
        ],
        request: request,
      );

  Widget _banRow(BuildContext context, TwitchBannedUser ban) =>
      this._inboxRowCard(
        context,
        userId: ban.userId,
        userName: ban.userName,
        lines: [
          if (ban.reason.trim().isNotEmpty) ban.reason,
          ban.isTimeout
              ? 'Timeout until ${this._formatDate(ban.expiresAt!)}'
              : 'Permanent ban',
          if (ban.moderatorName.isNotEmpty) 'by ${ban.moderatorName}',
        ],
      );

  /// Inbox row card: name + info lines, trailing action pill(s) — Unban
  /// everywhere; a request row with the Wave 3 manage scope gets
  /// Approve/Deny instead.
  Widget _inboxRowCard(
    BuildContext context, {
    required String userId,
    required String userName,
    required List<String> lines,
    TwitchUnbanRequest? request,
  }) {
    final running = this._runningUserId == userId;
    final busy = this._runningUserId != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: StylingHelper.lightenDarkenColor(Theme.of(context).cardColor),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
            width: 0.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  for (final line in lines)
                    Text(
                      line,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (running)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: StylingHelper.isApple(context)
                    ? const CupertinoActivityIndicator(radius: 7.0)
                    : const SizedBox(
                        width: 14.0,
                        height: 14.0,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          color: Colors.white,
                        ),
                      ),
              )
            else if (request != null && this._store.canManageUnbanRequests) ...[
              this._pill(
                context,
                label: 'Deny',
                filled: false,
                onTap: busy
                    ? null
                    : () =>
                        this._confirmResolve(request, approved: false),
              ),
              const SizedBox(width: AppSpacing.xs),
              this._pill(
                context,
                label: 'Approve',
                filled: true,
                onTap: busy
                    ? null
                    : () => this._confirmResolve(request, approved: true),
              ),
            ] else
              this._pill(
                context,
                label: 'Unban',
                filled: true,
                onTap: busy
                    ? null
                    : () => this._confirmUnban(userId, userName),
              ),
          ],
        ),
      ),
    );
  }

  /// Trailing pill button — filled = accent background (primary action),
  /// otherwise a bordered neutral pill (Deny).
  Widget _pill(
    BuildContext context, {
    required String label,
    required bool filled,
    required VoidCallback? onTap,
  }) {
    final accent = Theme.of(context).colorScheme.secondary;
    return Pressable(
      haptic: true,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: filled ? accent : Colors.transparent,
          borderRadius: AppRadius.pill,
          border: filled
              ? null
              : Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
                ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: filled
                    ? Colors.white
                    : Theme.of(context).textTheme.bodySmall?.color,
              ),
        ),
      ),
    );
  }
}
