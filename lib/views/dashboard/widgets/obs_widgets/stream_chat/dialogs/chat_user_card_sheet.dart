import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:intl/intl.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/models/twitch_auth.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/stores/views/twitch_badges.dart';
import 'package:obs_blade/stores/views/twitch_chat.dart';
import 'package:obs_blade/types/classes/twitch/eventsub/channel_chat_message.dart';
import 'package:obs_blade/types/classes/twitch/twitch_chat_badges.dart';
import 'package:obs_blade/types/classes/twitch/twitch_user.dart';
import 'package:obs_blade/types/classes/twitch/twitch_warning.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/utils/modal_handler.dart';
import 'package:obs_blade/utils/styling_helper.dart';
import 'package:obs_blade/utils/twitch/twitch_user_service.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/chat_message_display.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_appearance.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_chrome.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/native_chat_window.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/twitch_chat_message_row.dart';

/// Connection footer params for the merged self user card.
class ChatUserCardConnection {
  final ChatType chatType;
  final NativeChatConnectionStatus status;
  final String statusLabel;
  final Color statusColor;
  final String? statusDetail;
  final String? accountLabel;
  final DateTime? connectedAt;
  final VoidCallback? onRetry;
  final VoidCallback? onLogout;
  final VoidCallback? onConnect;

  const ChatUserCardConnection({
    required this.chatType,
    required this.status,
    required this.statusLabel,
    required this.statusColor,
    this.statusDetail,
    this.accountLabel,
    this.connectedAt,
    this.onRetry,
    this.onLogout,
    this.onConnect,
  });
}

/// Opens the native chat user card for [userId]. Pass [connection] when
/// showing the logged-in user's merged self sheet (status + actions).
void showChatUserCardSheet(
  BuildContext context, {
  required String userId,
  ChatUserCardConnection? connection,
  TwitchUserService? userService,
}) =>
    ModalHandler.showBaseBottomSheet(
      context: context,
      barrierDismissible: true,
      enableDrag: true,
      maxHeightFraction: 0.85,
      builder: (_) => ChatUserCardSheet(
        userId: userId,
        connection: connection,
        userService: userService ??
            (GetIt.instance.isRegistered<TwitchUserService>()
                ? GetIt.instance<TwitchUserService>()
                : TwitchUserService()),
      ),
    );

/// Twitch-style viewer card: avatar, identity, Helix facts, recent chat.
class ChatUserCardSheet extends StatefulWidget {
  final String userId;
  final ChatUserCardConnection? connection;
  final TwitchUserService userService;

  const ChatUserCardSheet({
    super.key,
    required this.userId,
    this.connection,
    required this.userService,
  });

  @override
  State<ChatUserCardSheet> createState() => _ChatUserCardSheetState();
}

class _ChatUserCardSheetState extends State<ChatUserCardSheet> {
  TwitchChatStore get _store => GetIt.instance<TwitchChatStore>();

  bool _loadingFacts = true;
  TwitchUser? _helixUser;
  DateTime? _followedAt;
  TwitchSelfSubscription? _selfSub;

  /// Warnings issued to this user in the effective channel (mod-only read
  /// surface; the read scope is in the always-held bundle). Null = hidden
  /// (not a mod, or the fetch failed).
  List<TwitchWarning>? _warnings;

  List<ChatMessageEvent> get _bufferedMessages =>
      this._store.messagesForChatter(this.widget.userId);

  ChatMessageEvent? get _newestBuffered =>
      this._bufferedMessages.isEmpty ? null : this._bufferedMessages.first;

  bool get _isSelf => this._store.user?.id == this.widget.userId;

  @override
  void initState() {
    super.initState();
    unawaited(this._loadFacts());
  }

  Future<void> _loadFacts() async {
    try {
      final auth =
          Hive.box<TwitchAuth>(HiveKeys.TwitchAuth.name).get(TwitchAuth.kBoxKey);
      if (auth == null) return;

      final service = this.widget.userService;
      final broadcasterId = this._store.user == null
          ? null
          : this._store.effectiveBroadcasterId;
      final scopes = auth.scopes.toSet();

      final userFuture = service.fetchUser(
        accessToken: auth.accessToken,
        userId: this.widget.userId,
      );

      Future<DateTime?> followFuture = Future<DateTime?>.value(null);
      if (broadcasterId != null) {
        if (this._isSelf && scopes.contains('user:read:follows')) {
          followFuture = service.selfFollowedAt(
            accessToken: auth.accessToken,
            userId: this.widget.userId,
            broadcasterId: broadcasterId,
          );
        } else if (!this._isSelf &&
            scopes.contains('moderator:read:followers')) {
          followFuture = service.followerSince(
            accessToken: auth.accessToken,
            broadcasterId: broadcasterId,
            userId: this.widget.userId,
          );
        }
      }

      Future<TwitchSelfSubscription?> subFuture =
          Future<TwitchSelfSubscription?>.value(null);
      if (this._isSelf &&
          broadcasterId != null &&
          scopes.contains('user:read:subscriptions')) {
        subFuture = service.selfSubscription(
          accessToken: auth.accessToken,
          broadcasterId: broadcasterId,
        );
      }

      /// Mod-only: warnings for this user in the effective channel (the
      /// store gates role + read bundle; failure/not-a-mod → null → the
      /// section hides).
      Future<List<TwitchWarning>?> warningsFuture =
          Future<List<TwitchWarning>?>.value(null);
      if (!this._isSelf && broadcasterId != null) {
        warningsFuture =
            this._store.fetchUserWarnings(this.widget.userId);
      }

      final results = await Future.wait<Object?>([
        userFuture,
        followFuture,
        subFuture,
        warningsFuture,
      ]);

      if (!mounted) return;
      this.setState(() {
        this._helixUser = results[0] as TwitchUser?;
        this._followedAt = results[1] as DateTime?;
        this._selfSub = results[2] as TwitchSelfSubscription?;
        this._warnings = results[3] as List<TwitchWarning>?;
      });
    } catch (_) {
      // Omit Helix rows — buffer/header still render.
    } finally {
      if (mounted) this.setState(() => this._loadingFacts = false);
    }
  }

  Color _displayNameColor(BuildContext context) {
    final hex = this._store.newestChatterColor(this.widget.userId) ??
        this._newestBuffered?.color;
    if (hex != null && hex.length == 7) {
      final value = int.tryParse(hex.substring(1), radix: 16);
      if (value != null) return Color(0xFF000000 | value);
    }
    return Theme.of(context).colorScheme.primary;
  }

  String _displayName() =>
      this._helixUser?.displayName ??
      this._newestBuffered?.chatterUserName ??
      this._helixUser?.login ??
      'Chatter';

  String? _loginLabel() {
    final login =
        this._helixUser?.login ?? this._newestBuffered?.chatterUserLogin;
    if (login == null) return null;
    final display = this._displayName();
    if (login.toLowerCase() == display.toLowerCase()) return null;
    return '@$login';
  }

  String _formatFactDate(DateTime date) =>
      DateFormat.yMMMMd().format(date.toLocal());

  String _tierLabel(String tier) {
    final value = int.tryParse(tier);
    if (value == null) return tier;
    return 'Tier ${value ~/ 1000}';
  }

  String _monthsLabel(int months) =>
      months == 1 ? '1 month' : '$months months';

  @override
  Widget build(BuildContext context) {
    final settingsBox = Hive.box(HiveKeys.Settings.name);
    final newest = this._newestBuffered;

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
            this._header(context, newest),
            const SizedBox(height: AppSpacing.lg),
            this._factsBlock(context),
            const SizedBox(height: AppSpacing.lg),
            this._liveDivider(context),
            const SizedBox(height: AppSpacing.sm),
            if (this._bufferedMessages.isEmpty)
              Text(
                'No messages in this chat yet',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else ...[
              for (var i = 0; i < this._bufferedMessages.length; i++) ...[
                if (i > 0 && NativeChatAppearance.separators(settingsBox))
                  nativeChatHairline(context),
                TwitchChatMessageRow(
                  key: ValueKey(
                    'card-msg-${this._bufferedMessages[i].messageId}',
                  ),
                  event: this._bufferedMessages[i],
                  settingsBox: settingsBox,
                  showTimestamp: true,
                ),
              ],
            ],
            if (this.widget.connection != null) ...[
              const SizedBox(height: AppSpacing.lg),
              nativeChatHairline(context),
              const SizedBox(height: AppSpacing.lg),
              this._connectionFooter(context, this.widget.connection!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, ChatMessageEvent? newest) {
    final avatarUrl = this._helixUser?.profileImageUrl;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 28.0,
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerHighest,
          backgroundImage:
              avatarUrl == null ? null : NetworkImage(avatarUrl),
          child: avatarUrl == null
              ? Icon(
                  CupertinoIcons.person_fill,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                )
              : null,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                this._displayName(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: this._displayNameColor(context),
                    ),
              ),
              if (this._loginLabel() case final login?)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs / 2),
                  child: Text(
                    login,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              if (newest != null && newest.badges.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                this._headerBadges(context, newest),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _headerBadges(BuildContext context, ChatMessageEvent newest) {
    final badgeStore = GetIt.instance<TwitchBadgeStore>();
    final badges = <Widget>[];
    for (final badge in newest.badges) {
      if (!settingsBoxGet(newest, badge)) continue;
      final version = badgeStore.badgeVersion(
        newest.broadcasterUserId,
        badge.setId,
        badge.id,
      );
      if (version == null) continue;
      badges.add(
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.xs / 2),
          child: Image.network(
            version.imageUrl2x,
            height: 18.0,
            width: 18.0,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      );
    }
    if (badges.isEmpty) return const SizedBox.shrink();
    return Row(children: badges);
  }

  bool settingsBoxGet(ChatMessageEvent newest, ChatMessageBadge badge) {
    final settingsBox = Hive.box(HiveKeys.Settings.name);
    return settingsBox.get(
      settingsKeyForBadgeSetId(badge.setId).name,
      defaultValue: true,
    );
  }

  Widget _factsBlock(BuildContext context) {
    if (this._loadingFacts) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Center(
          child: SizedBox(
            width: 20.0,
            height: 20.0,
            child: CircularProgressIndicator(strokeWidth: 2.0),
          ),
        ),
      );
    }

    final rows = <Widget>[];
    if (this._helixUser?.createdAt case final created?) {
      rows.add(this._factRow(
        context,
        icon: CupertinoIcons.calendar,
        label: 'Account created on ${this._formatFactDate(created)}',
      ));
    }
    if (this._followedAt case final followed?) {
      rows.add(this._factRow(
        context,
        icon: CupertinoIcons.heart,
        label: 'Following since ${this._formatFactDate(followed)}',
      ));
    }
    if (this._selfSub case final sub?) {
      rows.add(this._factRow(
        context,
        icon: CupertinoIcons.star_fill,
        label:
            '${this._tierLabel(sub.tier)} — Subscribed for ${this._monthsLabel(sub.months)}',
      ));
    }
    if (this._warnings case final warnings?) {
      for (final warning in warnings.take(3)) {
        final when = warning.warnedAt;
        rows.add(this._factRow(
          context,
          icon: CupertinoIcons.exclamationmark_triangle,
          label: 'Warned'
              '${when != null ? ' ${this._formatFactDate(when)}' : ''}'
              '${warning.reason.isNotEmpty ? ' — ${warning.reason}' : ''}',
        ));
      }
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
  }) =>
      Row(
        children: [
          Icon(icon, size: 16.0, color: Theme.of(context).colorScheme.primary),
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
                    color: kChatViewerCountColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
            ),
          ),
          Expanded(child: nativeChatHairline(context)),
        ],
      );

  Widget _connectionFooter(
    BuildContext context,
    ChatUserCardConnection connection,
  ) {
    final degraded =
        connection.status == NativeChatConnectionStatus.connecting ||
            connection.status == NativeChatConnectionStatus.reconnecting ||
            connection.status == NativeChatConnectionStatus.failed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8.0,
              height: 8.0,
              decoration: BoxDecoration(
                color: connection.statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              connection.statusLabel,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: connection.statusColor),
            ),
          ],
        ),
        if (connection.status == NativeChatConnectionStatus.live) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Connected as ${connection.accountLabel ?? connection.chatType.text}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (connection.connectedAt != null) ...[
            const SizedBox(height: AppSpacing.xs),
            _ChatUserCardUptimeLine(connectedAt: connection.connectedAt!),
          ],
        ],
        if (degraded) ...[
          if (connection.statusDetail != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              connection.statusDetail!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          this._connectionAction(
            context,
            icon: CupertinoIcons.arrow_clockwise,
            label: 'Retry',
            onTap: connection.onRetry,
          ),
          const SizedBox(height: AppSpacing.xs),
          this._connectionAction(
            context,
            icon: CupertinoIcons.square_arrow_right,
            label: 'Log out',
            destructive: true,
            onTap: connection.onLogout,
          ),
        ],
        if (connection.status == NativeChatConnectionStatus.offline) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Not connected — connect your ${connection.chatType.text} account to see chat natively.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          this._connectionAction(
            context,
            icon: CupertinoIcons.link,
            label: 'Connect ${connection.chatType.text}',
            onTap: connection.onConnect,
          ),
        ],
      ],
    );
  }

  Widget _connectionAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    bool destructive = false,
  }) {
    final Color color = destructive
        ? (Theme.of(context).extension<AppStatusColors>() ??
                AppStatusColors.standard)
            .unreachable
        : Theme.of(context).textTheme.bodyMedium?.color ??
            CupertinoColors.label;
    return Pressable(
      haptic: true,
      onTap: onTap == null
          ? null
          : () {
              Navigator.of(context).pop();
              onTap();
            },
      child: Container(
        constraints: const BoxConstraints(
          minHeight: kMinInteractiveDimensionCupertino,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color:
              StylingHelper.lightenDarkenColor(Theme.of(context).cardColor),
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
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatUserCardUptimeLine extends StatefulWidget {
  final DateTime connectedAt;

  const _ChatUserCardUptimeLine({required this.connectedAt});

  @override
  State<_ChatUserCardUptimeLine> createState() =>
      _ChatUserCardUptimeLineState();
}

class _ChatUserCardUptimeLineState extends State<_ChatUserCardUptimeLine> {
  late final Timer _ticker;
  late Duration _uptime =
      DateTime.now().difference(this.widget.connectedAt);

  @override
  void initState() {
    super.initState();
    this._ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (this.mounted) {
        this.setState(() => this._uptime += const Duration(seconds: 1));
      }
    });
  }

  @override
  void dispose() {
    this._ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text(
        'Connected for ${formatChatUptime(this._uptime)}',
        style: Theme.of(context).textTheme.bodySmall,
      );
}
