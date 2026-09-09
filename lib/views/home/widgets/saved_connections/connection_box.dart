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
import '../../../../shared/general/base/button.dart';
import '../../../../shared/general/base/card.dart';
import '../../../../stores/shared/network.dart';
import '../../../../utils/modal_handler.dart';
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

  @override
  Widget build(BuildContext context) {
    final AppStatusColors statusColors = Theme.of(
      context,
    ).extension<AppStatusColors>()!;
    final AppTextColors textColors = Theme.of(
      context,
    ).extension<AppTextColors>()!;

    /// Reachability badge (grammar rule 7 + mock token notes): "Online" is
    /// NEUTRAL (white-50% dot, dim label, 8% white pill) - green is
    /// reserved for streaming-live. "Offline" keeps the red signal: dot in
    /// [AppStatusColors.unreachable], label in [AppStatusColors.recordingText]
    /// on a 13% same-hue tint
    final Color reachabilityDotColor;
    final Color reachabilityLabelColor;
    final Color reachabilityFillColor;
    if (this.connection.reachable == null) {
      reachabilityDotColor = textColors.textOrnament;
      reachabilityLabelColor = textColors.textTertiary;
      reachabilityFillColor = Colors.white.withValues(alpha: 0.08);
    } else if (this.connection.reachable!) {
      reachabilityDotColor = Colors.white.withValues(alpha: 0.5);
      reachabilityLabelColor = textColors.textSecondary;
      reachabilityFillColor = Colors.white.withValues(alpha: 0.08);
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
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    ),
                    Pressable(
                      onTap: () => this._edit(context),

                      /// 44x44 hit area (token-delta §5) - visual glyph
                      /// stays small, transparent expansion carries the
                      /// floor
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: 44.0,
                          minHeight: 44.0,
                        ),
                        child: Center(
                          widthFactor: 1.0,
                          heightFactor: 1.0,
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            child: Icon(
                              CupertinoIcons.pencil,
                              size: 18.0,
                              color: Theme.of(
                                context,
                              ).textTheme.bodySmall?.color,
                            ),
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
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 1.0),
                          child: Icon(
                            this._hasPassword
                                ? CupertinoIcons.lock_fill
                                : CupertinoIcons.lock_slash,
                            size: 14.0,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            this._endpoint,
                            style: Theme.of(context).textTheme.bodySmall!
                                .copyWith(
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Observer(
                  builder: (context) {
                    final bool connecting =
                        GetIt.instance<NetworkStore>().connectionInProgress;

                    /// Ghost Connect (mock token notes: saved-card buttons
                    /// are demoted to ghosts - the filled Connect CTA in
                    /// the connect card is the screen's one accent moment)
                    return BaseButton(
                      secondary: true,
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

  const _ReachabilityPill({
    required this.dotColor,
    required this.labelColor,
    required this.fillColor,
    required this.label,
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
          margin: const EdgeInsets.only(top: AppSpacing.xs),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(color: fill, borderRadius: AppRadius.pill),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              StatusDot(size: 6.0, color: this.dotColor),
              const SizedBox(width: AppSpacing.xs),
              Text(
                this.label,
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: this.labelColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
