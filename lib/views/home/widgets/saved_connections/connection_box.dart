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
import '../../../../utils/styling_helper.dart';
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
      dialogWidget: EditConnectionDialog(
        connection: this.connection,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppStatusColors statusColors =
        Theme.of(context).extension<AppStatusColors>()!;

    final Color reachabilityColor = this.connection.reachable == null
        ? Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey
        : this.connection.reachable!
            ? statusColors.reachable
            : statusColors.unreachable;

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
                      color: reachabilityColor,
                      label: reachabilityLabel,
                    ),
                    Pressable(
                      onTap: () => this._edit(context),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: Icon(
                          CupertinoIcons.pencil,
                          size: 18.0,
                          color: Theme.of(context).textTheme.bodySmall?.color,
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
                            color:
                                Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            this._endpoint,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall!
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

                    return BaseButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      onPressed:
                          connecting ? null : () => this._connect(context),
                      child: AnimatedSwitcher(
                        duration: AppMotion.fast,
                        child: connecting
                            ? SizedBox(
                                key: const ValueKey('connecting'),
                                width: 20.0,
                                height: 20.0,
                                child: CupertinoActivityIndicator(
                                  color:
                                      StylingHelper.surroundingAwareAccent(
                                    surroundingColor: Theme.of(context)
                                        .buttonTheme
                                        .colorScheme!
                                        .secondary,
                                  ),
                                ),
                              )
                            : const Text(
                                key: ValueKey('idle'),
                                'Connect',
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
  final Color color;
  final String label;

  const _ReachabilityPill({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: this.color),
      duration: AppMotion.medium,
      curve: AppMotion.standard,
      builder: (context, color, child) {
        final resolved = color ?? this.color;
        return Container(
          margin: const EdgeInsets.only(top: AppSpacing.xs),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: resolved.withValues(alpha: 0.16),
            borderRadius: AppRadius.pill,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              StatusDot(
                size: 6.0,
                color: resolved,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                this.label,
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                      color: resolved,
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
