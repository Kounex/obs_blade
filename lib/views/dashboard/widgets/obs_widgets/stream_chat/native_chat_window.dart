import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../models/enums/chat_type.dart';
import '../../../../../shared/design/design.dart';
import '../../../../../shared/general/base/divider.dart';
import '../../../../../utils/modal_handler.dart';
import '../../../../../utils/styling_helper.dart';
import 'native_chat_chrome.dart';

/// Platform-agnostic connection state of a native chat engine, rendered by
/// [NativeChatWindow]'s status row. Each native engine maps its own store
/// state onto this (the Twitch mapping lives in `stream_chat.dart`).
enum NativeChatConnectionStatus {
  /// No account connected / engine not running
  offline,
  connecting,
  live,
  reconnecting,
  failed,
}

/// Compact uptime for the connection sheet: `m:ss` under an hour,
/// `h:mm:ss` beyond.
String formatChatUptime(Duration uptime) {
  final String minutes =
      uptime.inMinutes.remainder(60).toString().padLeft(2, '0');
  final String seconds =
      uptime.inSeconds.remainder(60).toString().padLeft(2, '0');
  return uptime.inHours > 0
      ? '${uptime.inHours}:$minutes:$seconds'
      : '${uptime.inMinutes}:$seconds';
}

/// Window chrome for the native chat engines: an inset pane (same visual
/// idiom as the chat bar's control containers) wrapping the engine's
/// content, with a slim status row on top. The row shows the connection
/// state and is always tappable — it opens a connection sheet (account +
/// uptime when healthy, diagnostics + actions when degraded, connect
/// action when offline). An optional [input] dock sits at the pane's
/// bottom edge (hairline-separated).
///
/// Deliberately generic: everything Twitch-specific arrives as plain
/// params, so a future native engine (e.g. YouTube) reuses the window with
/// its own branding and state mapping.
class NativeChatWindow extends StatelessWidget {
  final ChatType chatType;
  final NativeChatConnectionStatus status;

  /// Engine's last error, shown in the sheet for degraded states
  final String? statusDetail;

  /// Connected account's display name, when logged in
  final String? accountLabel;

  /// When the current session went live — feeds the sheet's uptime line
  final DateTime? connectedAt;

  /// Sheet actions; a null callback hides the action
  final VoidCallback? onRetry;
  final VoidCallback? onLogout;
  final VoidCallback? onConnect;

  /// The engine's content (message view or connect prompt)
  final Widget child;

  /// Optional dock rendered below the content (input field, read-only
  /// hint) — the reserved bottom slot of the pane.
  final Widget? input;

  /// Effective channel is currently live (header LIVE chip).
  final bool channelIsLive;

  /// User can moderate the effective channel (header Mod chip).
  final bool channelIsMod;

  const NativeChatWindow({
    super.key,
    required this.chatType,
    required this.status,
    required this.child,
    this.input,
    this.statusDetail,
    this.accountLabel,
    this.connectedAt,
    this.onRetry,
    this.onLogout,
    this.onConnect,
    this.channelIsLive = false,
    this.channelIsMod = false,
  });

  (String, Color) _statusMeta(BuildContext context) {
    final AppStatusColors statusColors =
        Theme.of(context).extension<AppStatusColors>() ??
            AppStatusColors.standard;
    final Color muted =
        Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;
    return switch (this.status) {
      NativeChatConnectionStatus.live => ('connected', statusColors.live),
      NativeChatConnectionStatus.connecting =>
        ('connecting…', statusColors.warning),
      NativeChatConnectionStatus.reconnecting =>
        ('reconnecting…', statusColors.warning),
      NativeChatConnectionStatus.failed =>
        ('failed', statusColors.unreachable),
      NativeChatConnectionStatus.offline => ('offline', muted),
    };
  }

  @override
  Widget build(BuildContext context) {
    final (String statusLabel, Color statusColor) = this._statusMeta(context);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
          width: 0.0,
        ),
      ),
      child: Column(
        children: [
          Pressable(
            haptic: true,
            onTap: () => ModalHandler.showBaseBottomSheet(
              context: context,
              barrierDismissible: true,
              enableDrag: true,
              maxHeightFraction: 0.72,
              builder: (context) => _NativeChatConnectionSheet(
                chatType: this.chatType,
                status: this.status,
                statusLabel: statusLabel,
                statusColor: statusColor,
                statusDetail: this.statusDetail,
                accountLabel: this.accountLabel,
                connectedAt: this.connectedAt,
                onRetry: this.onRetry,
                onLogout: this.onLogout,
                onConnect: this.onConnect,
              ),
            ),
            child: Container(
              constraints: const BoxConstraints(
                minHeight: kMinInteractiveDimensionCupertino,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Text(
                    'Stream Chat',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  if (this.channelIsLive) ...[
                    const SizedBox(width: AppSpacing.sm),
                    NativeChatStatusChip.live(
                      key: const Key('chat-header-live'),
                      color: (Theme.of(context).extension<AppStatusColors>() ??
                              AppStatusColors.standard)
                          .live,
                    ),
                  ],
                  if (this.channelIsMod) ...[
                    const SizedBox(width: AppSpacing.xs),
                    NativeChatStatusChip.mod(
                      key: const Key('chat-header-mod'),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                  const Spacer(),
                  Container(
                    width: 8.0,
                    height: 8.0,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    statusLabel,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: statusColor),
                  ),
                ],
              ),
            ),
          ),
          const BaseDivider(),
          Expanded(child: this.child),
          if (this.input != null) ...[
            const BaseDivider(),
            this.input!,
          ],
        ],
      ),
    );
  }
}

/// Connection sheet of [NativeChatWindow]: account + uptime when healthy,
/// diagnostics + retry/logout when degraded, connect action when offline.
/// Actions pop the sheet and delegate to the call site's callbacks
/// (confirmation dialogs etc. live there, not here).
class _NativeChatConnectionSheet extends StatelessWidget {
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

  const _NativeChatConnectionSheet({
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

  void _popThen(BuildContext context, VoidCallback? action) {
    Navigator.of(context).pop();
    action?.call();
  }

  Widget _actionRow(
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
      onTap: onTap == null ? null : () => this._popThen(context, onTap),
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

  @override
  Widget build(BuildContext context) {
    final bool degraded =
        this.status == NativeChatConnectionStatus.connecting ||
            this.status == NativeChatConnectionStatus.reconnecting ||
            this.status == NativeChatConnectionStatus.failed;

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
                  '${this.chatType.text} chat',
                  style: nativeChatSheetTitleStyle(context),
                ),
              ),
              Container(
                width: 8.0,
                height: 8.0,
                decoration: BoxDecoration(
                  color: this.statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                this.statusLabel,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: this.statusColor),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (this.status == NativeChatConnectionStatus.live) ...[
            Text(
              'Connected as ${this.accountLabel ?? this.chatType.text}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (this.connectedAt != null) ...[
              const SizedBox(height: AppSpacing.xs),
              _UptimeLine(connectedAt: this.connectedAt!),
            ],
          ],
          if (degraded) ...[
            if (this.statusDetail != null) ...[
              Text(
                this.statusDetail!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            this._actionRow(
              context,
              icon: CupertinoIcons.arrow_clockwise,
              label: 'Retry',
              onTap: this.onRetry,
            ),
            const SizedBox(height: AppSpacing.xs),
            this._actionRow(
              context,
              icon: CupertinoIcons.square_arrow_right,
              label: 'Log out',
              destructive: true,
              onTap: this.onLogout,
            ),
          ],
          if (this.status == NativeChatConnectionStatus.offline) ...[
            Text(
              'Not connected — connect your ${this.chatType.text} account to see chat natively.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            this._actionRow(
              context,
              icon: CupertinoIcons.link,
              label: 'Connect ${this.chatType.text}',
              onTap: this.onConnect,
            ),
          ],
        ],
      ),
    );
  }
}

/// Ticking "Connected for m:ss" line for the live sheet — recomputes the
/// uptime once per second while the sheet is open.
class _UptimeLine extends StatefulWidget {
  final DateTime connectedAt;

  const _UptimeLine({required this.connectedAt});

  @override
  State<_UptimeLine> createState() => _UptimeLineState();
}

class _UptimeLineState extends State<_UptimeLine> {
  late final Timer _ticker;

  /// Uptime captured when the sheet opens — each tick advances it by a
  /// second, so the line also moves under fake test clocks
  /// (`DateTime.now()` is not zone-aware) and is immune to wall-clock jumps.
  late Duration _uptime =
      DateTime.now().difference(this.widget.connectedAt);

  @override
  void initState() {
    super.initState();
    this._ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (this.mounted) {
          this.setState(() {
            this._uptime += const Duration(seconds: 1);
          });
        }
      },
    );
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
