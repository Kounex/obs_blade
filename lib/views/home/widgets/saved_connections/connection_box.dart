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

  const ConnectionBox(
      {super.key,
      required this.connection,
      this.height = 200.0,
      this.width = 250.0});

  void _connect(BuildContext context) {
    NetworkStore networkStore = GetIt.instance<NetworkStore>();

    FocusScope.of(context).unfocus();
    networkStore.setOBSWebSocket(this.connection).then((closeCode) {
      if (closeCode == WebSocketCloseCode.AuthenticationFailed) {
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

  @override
  Widget build(BuildContext context) {
    final AppStatusColors statusColors =
        Theme.of(context).extension<AppStatusColors>()!;

    final Color reachabilityColor = this.connection.reachable == null
        ? Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey
        : this.connection.reachable!
            ? statusColors.reachable
            : statusColors.unreachable;

    return SizedBox(
      width: this.width,
      child: BaseCard(
        topPadding: 0.0,
        rightPadding: 0.0,
        bottomPadding: 0.0,
        leftPadding: 0.0,
        paddingChild: const EdgeInsets.all(0),
        child: SizedBox(
          height: this.height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  if (this.connection.name != null)
                    Text(
                      this.connection.name!,
                      style: Theme.of(context).textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  // Text(
                  //   '(${this.connection.ssid})',
                  //   style: Theme.of(context).textTheme.bodySmall,
                  // ),
                  Text(
                    '${this.connection.host}${this.connection.port != null ? (":${this.connection.port}") : ""}',
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      fontFeatures: const [
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                ],
              ),
              Center(
                /// Ambient reachability: color morphs between states instead
                /// of hard swapping (semantic colors via [AppStatusColors])
                child: TweenAnimationBuilder<Color?>(
                  tween: ColorTween(end: reachabilityColor),
                  duration: AppMotion.medium,
                  curve: AppMotion.standard,
                  builder: (context, color, child) => StatusDot(
                    size: 10.0,
                    color: color ?? reachabilityColor,
                    text: this.connection.reachable == null
                        ? 'Checking...'
                        : this.connection.reachable!
                            ? 'Reachable'
                            : 'Not reachable',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: AppSpacing.xl),
                    Expanded(
                      child: Observer(
                        builder: (context) {
                          final bool connecting = GetIt.instance<NetworkStore>()
                              .connectionInProgress;

                          /// Physical press feedback (ripples are disabled
                          /// app-wide); the button keeps owning the tap so
                          /// [Pressable.onTap] never double-fires
                          return Pressable(
                            onTap: () => _connect(context),
                            child: BaseButton(
                              /// Reduced padding + scale-down fit so
                              /// 'Connect' never wraps in the narrow slot
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md),
                              onPressed: () => _connect(context),
                              child: AnimatedSwitcher(
                                duration: AppMotion.fast,
                                child: connecting
                                    ? SizedBox(
                                        key: const ValueKey('connecting'),
                                        width: 20.0,
                                        height: 20.0,
                                        child: CupertinoActivityIndicator(
                                          color: StylingHelper
                                              .surroundingAwareAccent(
                                            surroundingColor: Theme.of(context)
                                                .buttonTheme
                                                .colorScheme!
                                                .secondary,
                                          ),
                                        ),
                                      )
                                    : const FittedBox(
                                        key: ValueKey('idle'),
                                        fit: BoxFit.scaleDown,
                                        child: Text('Connect'),
                                      ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xl),
                    Expanded(
                      child: Pressable(
                        onTap: () => ModalHandler.showBaseDialog(
                          context: context,
                          dialogWidget: EditConnectionDialog(
                            connection: this.connection,
                          ),
                        ),
                        child: BaseButton(
                          text: 'Edit',
                          secondary: true,
                          onPressed: () => ModalHandler.showBaseDialog(
                            context: context,
                            dialogWidget: EditConnectionDialog(
                              connection: this.connection,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xl),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
