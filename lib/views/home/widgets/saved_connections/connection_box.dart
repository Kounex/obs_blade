import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/overlay/base_result.dart';
import 'package:obs_blade/types/enums/web_socket_codes/web_socket_close_code.dart';
import 'package:obs_blade/utils/overlay_handler.dart';

import '../../../../models/connection.dart';
import '../../../../shared/animator/status_dot.dart';
import '../../../../shared/design/design.dart';
import '../../../../shared/dialogs/confirmation.dart';
import '../../../../shared/general/app_bar_actions.dart';
import '../../../../shared/general/base/button.dart';
import '../../../../shared/general/base/card.dart';
import '../../../../shared/general/base/icon_button.dart';
import '../../../../stores/shared/network.dart';
import '../../../../utils/modal_handler.dart';
import '../../../../utils/relative_time.dart';
import 'edit_dialog.dart';

class ConnectionBox extends StatelessWidget {
  final Connection connection;
  final double height;
  final double width;

  const ConnectionBox({
    super.key,
    required this.connection,
    this.height = 172.0,
    this.width = 268.0,
  });

  String get _displayName {
    final name = this.connection.name?.trim();
    if (name != null && name.isNotEmpty) return name;
    return this.connection.host;
  }

  String get _endpoint =>
      '${this.connection.host}${this.connection.port != null ? ':${this.connection.port}' : ''}';

  bool get _hasPassword {
    final pw = this.connection.pw;
    return pw != null && pw.isNotEmpty;
  }

  void _connect(BuildContext context) {
    final networkStore = GetIt.instance<NetworkStore>();

    FocusScope.of(context).unfocus();
    networkStore.setOBSWebSocket(this.connection).then((closeCode) {
      /// "Last used" stamps on a fully established session only (DontClose
      /// is the handshake's success sentinel) - not on attempts
      if (closeCode == WebSocketCloseCode.DontClose) {
        this.connection.lastConnectedMs = DateTime.now().millisecondsSinceEpoch;
        this.connection.save();
      }
      if (closeCode == WebSocketCloseCode.AuthenticationFailed &&
          context.mounted) {
        OverlayHandler.showStatusOverlay(
          context: context,
          content: const BaseResult(
            icon: BaseResultIcon.Negative,
            text: 'Wrong password!',
          ),
        );
      }
    });
  }

  void _edit(BuildContext context) {
    ModalHandler.showBaseDialog(
      context: context,
      dialogWidget: EditConnectionDialog(connection: this.connection),
    );
  }

  void _delete(BuildContext context) {
    ModalHandler.showBaseDialog(
      context: context,
      dialogWidget: ConfirmationDialog(
        title: 'Delete Connection',
        body:
            'Are you sure you want to delete this connection? This action can\'t be undone!',
        isYesDestructive: true,
        onOk: (_) => this.connection.delete(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppStatusColors statusColors = Theme.of(
      context,
    ).extension<AppStatusColors>()!;
    final AppTextColors textColors = Theme.of(
      context,
    ).extension<AppTextColors>()!;

    /// Reachability badge (user directive 2026-09-20, supersedes the v12
    /// "online stays neutral, green is reserved for streaming-live"
    /// grammar note): "Online" is GREEN - dot and label in
    /// [AppStatusColors.reachable] on a 13% same-hue tint, the exact mirror
    /// of the Offline treatment. "Checking" stays neutral.
    final Color reachabilityDotColor;
    final Color reachabilityLabelColor;
    final Color reachabilityFillColor;
    if (this.connection.reachable == null) {
      reachabilityDotColor = textColors.textOrnament;
      reachabilityLabelColor = textColors.textTertiary;
      reachabilityFillColor = Colors.white.withValues(alpha: 0.08);
    } else if (this.connection.reachable!) {
      reachabilityDotColor = statusColors.reachable;
      reachabilityLabelColor = statusColors.reachable;
      reachabilityFillColor = statusColors.reachable.withValues(alpha: 0.13);
    } else {
      reachabilityDotColor = statusColors.unreachable;
      reachabilityLabelColor = statusColors.recordingText;
      reachabilityFillColor = statusColors.unreachable.withValues(alpha: 0.13);
    }

    final String reachabilityLabel = this.connection.reachable == null
        ? 'Checking'
        : this.connection.reachable!
        ? 'Online'
        : 'Offline';

    return SizedBox(
      width: this.width,
      child: BaseCard(
        topPadding: 0.0,
        rightPadding: 0.0,
        bottomPadding: 0.0,
        leftPadding: 0.0,
        paddingChild: EdgeInsets.zero,
        child: SizedBox(
          height: this.height,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        this._displayName,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _ReachabilityPill(
                      dotColor: reachabilityDotColor,
                      labelColor: reachabilityLabelColor,
                      fillColor: reachabilityFillColor,
                      label: reachabilityLabel,
                      pulsing: this.connection.reachable == null,
                    ),

                    /// Ellipsis menu (Edit / Delete) via the app's adaptive
                    /// action-sheet idiom. The OverflowBox keeps the
                    /// transparent 44pt hit floor without letting it
                    /// inflate the row - title, pill and glyph share one
                    /// optical centerline
                    SizedBox(
                      height: 28.0,
                      width: kBaseIconButtonMinHitArea,
                      child: OverflowBox(
                        minHeight: kBaseIconButtonMinHitArea,
                        maxHeight: kBaseIconButtonMinHitArea,
                        child: BaseIconButton(
                          icon: CupertinoIcons.ellipsis,
                          iconSize: 20.0,
                          backgroundColor: Colors.transparent,
                          foregroundColor: Theme.of(
                            context,
                          ).textTheme.bodySmall?.color,
                          onTap: () => AppBarActions.showActions(
                            context,
                            actions: [
                              AppBarActionEntry(
                                title: 'Edit',
                                leadingIcon: CupertinoIcons.pencil,
                                onAction: () => this._edit(context),
                              ),
                              AppBarActionEntry(
                                title: 'Delete',
                                leadingIcon: CupertinoIcons.trash,
                                isDestructive: true,
                                onAction: () => this._delete(context),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 1.0),
                              child: Icon(
                                this._hasPassword
                                    ? CupertinoIcons.lock_fill
                                    : CupertinoIcons.lock_slash,
                                size: 14.0,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.color,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                this._endpoint,
                                style: Theme.of(context).textTheme.bodySmall!
                                    .copyWith(fontFeatures: kTabularFigures),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          this.connection.lastConnectedMs != null
                              ? 'Last used: ${relativeTimeAgo(DateTime.fromMillisecondsSinceEpoch(this.connection.lastConnectedMs!))}'
                              : 'Never used',
                          style: Theme.of(context).textTheme.labelSmall!
                              .copyWith(color: textColors.textTertiary),
                        ),
                      ],
                    ),
                  ),
                ),
                Observer(
                  builder: (context) {
                    final bool connecting =
                        GetIt.instance<NetworkStore>().connectionInProgress;

                    /// Connect prominence follows reachability (user
                    /// directive 2026-09-20): online cards get the filled
                    /// accent CTA, checking/offline keep the ghost.
                    /// Supersedes the v12 note that demoted all saved-card
                    /// buttons to ghosts. The ghost <-> filled swap
                    /// crossfades so a card coming online morphs instead
                    /// of snapping
                    return AnimatedSwitcher(
                      duration: AppMotion.medium,
                      switchInCurve: AppMotion.emphasized,
                      switchOutCurve: AppMotion.emphasized,
                      child: BaseButton(
                        key: ValueKey(this.connection.reachable == true),
                        secondary: this.connection.reachable != true,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        onPressed: connecting
                            ? null
                            : () => this._connect(context),
                        child: AnimatedSwitcher(
                          duration: AppMotion.fast,
                          child: connecting
                              ? SizedBox(
                                  key: const ValueKey('connecting'),
                                  width: 20.0,
                                  height: 20.0,
                                  child: CupertinoActivityIndicator(
                                    color: Theme.of(
                                      context,
                                    ).extension<AppTextColors>()!.accentText,
                                  ),
                                )
                              : const Text(key: ValueKey('idle'), 'Connect'),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReachabilityPill extends StatelessWidget {
  final Color dotColor;
  final Color labelColor;
  final Color fillColor;
  final String label;

  /// The dot pulses only while the reachability check is in flight -
  /// settled Online/Offline states render the static dot
  final bool pulsing;

  const _ReachabilityPill({
    required this.dotColor,
    required this.labelColor,
    required this.fillColor,
    required this.label,
    required this.pulsing,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: this.fillColor),
      duration: AppMotion.medium,
      curve: AppMotion.standard,
      builder: (context, fillColor, child) {
        final Color fill = fillColor ?? this.fillColor;
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(color: fill, borderRadius: AppRadius.pill),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              StatusDot(size: 6.0, color: this.dotColor, pulsing: this.pulsing),
              const SizedBox(width: AppSpacing.xs),

              /// Label morph (medium/emphasized crossfade) - a card coming
              /// online reads as a transition, not a snap
              AnimatedSwitcher(
                duration: AppMotion.medium,
                switchInCurve: AppMotion.emphasized,
                switchOutCurve: AppMotion.emphasized,
                child: Text(
                  this.label,
                  key: ValueKey(this.label),
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    color: this.labelColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
