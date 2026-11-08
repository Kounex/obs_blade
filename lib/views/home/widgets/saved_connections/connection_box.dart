import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/overlay/base_result.dart';
import 'package:obs_blade/types/enums/remote_reach.dart';
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
import '../../../../shared/overlay/base_progress_indicator.dart';
import '../../../../stores/pro_store.dart';
import '../../../../stores/shared/network.dart';
import '../../../../stores/views/remote_access.dart';
import '../../../../utils/build_flavor.dart';
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
    this.height = 192.0,
    this.width = 320.0,
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
      if (closeCode == WebSocketCloseCode.RemoteObsNotRunning &&
          this.connection.relayBridgeKind == 'standalone' &&
          context.mounted) {
        this._offerStartObs(context);
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

  /// Journey 3 of the remote relay spec: the standalone OBS Blade Remote
  /// can start OBS when it isn't running; connect once it's up.
  Future<void> _offerStartObs(BuildContext context) async {
    await OverlayHandler.closeAnyOverlay(immediately: true);
    if (!context.mounted) return;
    final String pc = this.connection.relayBridgeName ?? 'your PC';
    ModalHandler.showBaseDialog(
      context: context,
      dialogWidget: ConfirmationDialog(
        title: 'OBS Isn\'t Running',
        body: 'OBS isn\'t running on $pc. Start it from here?',
        noText: 'Cancel',
        okText: 'Start OBS',
        onOk: (_) async {
          OverlayHandler.showStatusOverlay(
            context: context,
            showDuration: const Duration(seconds: 60),
            content: BaseProgressIndicator(text: 'Starting OBS on $pc…'),
          );
          final bool started = await RemoteAccessStore().startObsAndWait(
            this.connection,
          );
          if (!context.mounted) return;
          if (started) {
            this._connect(context);
          } else {
            OverlayHandler.showStatusOverlay(
              context: context,
              replaceIfActive: true,
              content: BaseResult(
                icon: BaseResultIcon.Negative,
                text: 'OBS didn\'t start on $pc.',
              ),
            );
          }
        },
      ),
    );
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
    /// Three states (user directive 2026-11-08): Online (green), the PC
    /// answering through remote access while OBS doesn't (amber, the
    /// reason as label - Connect can still start OBS on a standalone),
    /// Offline (red) only when nothing is reachable at all.
    final RemoteReach? reach = this.connection.remoteReach;
    final bool obsDownOnReachablePc =
        this.connection.reachable == false &&
        (reach == RemoteReach.obsNotRunning ||
            reach == RemoteReach.obsUnreachable);
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
    } else if (obsDownOnReachablePc) {
      reachabilityDotColor = statusColors.warning;
      reachabilityLabelColor = statusColors.warning;
      reachabilityFillColor = statusColors.warning.withValues(alpha: 0.13);
    } else {
      reachabilityDotColor = statusColors.unreachable;
      reachabilityLabelColor = statusColors.recordingText;
      reachabilityFillColor = statusColors.unreachable.withValues(alpha: 0.13);
    }

    final String reachabilityLabel = this.connection.reachable == null
        ? 'Checking'
        : this.connection.reachable!
        ? 'Online'
        : obsDownOnReachablePc
        ? reach!.pillLabel!
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

            /// Header, info lines and Connect spread evenly over the fixed
            /// card height: the same gap above and below the info lines,
            /// with or without the remote access line (user, 2026-11-08)
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                Align(
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
                      if (!kFoss &&
                          this.connection.hasRemote &&
                          GetIt.instance.isRegistered<ProStore>() &&
                          GetIt.instance<ProStore>().isPro) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            Icon(
                              CupertinoIcons.globe,
                              size: 14.0,
                              color: Theme.of(
                                context,
                              ).textTheme.bodySmall?.color,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Flexible(
                              child: Text(
                                [
                                  'Remote access',
                                  ?this.connection.remoteReach?.cardProblem,
                                ].join(' · '),
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xs),

                      /// Same icon column as the endpoint / remote rows
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.clock,
                            size: 14.0,
                            color: textColors.textTertiary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Text(
                              this.connection.lastConnectedMs != null
                                  ? 'Last used: ${relativeTimeAgo(DateTime.fromMillisecondsSinceEpoch(this.connection.lastConnectedMs!))}'
                                  : 'Never used',
                              style: Theme.of(context).textTheme.labelSmall!
                                  .copyWith(color: textColors.textTertiary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      /// Optical balance: the text's line box leaves ~2 pt
                      /// more air above the first line than below the last
                      const SizedBox(height: 2.0),
                    ],
                  ),
                ),
                Observer(
                  builder: (context) {
                    final bool connecting =
                        GetIt.instance<NetworkStore>().connectionInProgress;

                    /// [Connection.reachable] covers the relay for a
                    /// paired connection. When the relay didn't answer,
                    /// or a standalone can start OBS, Connect still
                    /// stays prominent - it may well work
                    final bool viaRemoteToo =
                        !kFoss &&
                        this.connection.hasRemote &&
                        GetIt.instance.isRegistered<ProStore>() &&
                        GetIt.instance<ProStore>().isPro;
                    final RemoteReach? reach = this.connection.remoteReach;
                    final bool prominent =
                        this.connection.reachable == true ||
                        (viaRemoteToo &&
                            (reach == null ||
                                (reach == RemoteReach.obsNotRunning &&
                                    this.connection.relayBridgeKind ==
                                        'standalone')));

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
                        key: ValueKey(prominent),
                        secondary: !prominent,
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
