import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/overlay/base_result.dart';
import 'package:obs_blade/types/enums/web_socket_codes/web_socket_close_code.dart';
import 'package:obs_blade/utils/overlay_handler.dart';

import '../../../../models/connection.dart';
import '../../../../shared/animator/status_dot.dart';
import '../../../../shared/general/base/button.dart';
import '../../../../shared/general/base/card.dart';
import '../../../../stores/shared/network.dart';
import '../../../../utils/modal_handler.dart';
import 'edit_dialog.dart';

class ConnectionBox extends StatelessWidget {
  final Connection connection;
  final double height;
  final double width;

  const ConnectionBox(
      {Key? key,
      required this.connection,
      this.height = 200.0,
      this.width = 250.0})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    NetworkStore networkStore = GetIt.instance<NetworkStore>();

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
                      style: Theme.of(context).textTheme.headline6,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  // Text(
                  //   '(${this.connection.ssid})',
                  //   style: Theme.of(context).textTheme.caption,
                  // ),
                  Text(
                    '${this.connection.host}${this.connection.port != null ? (":" + this.connection.port.toString()) : ""}',
                    style: Theme.of(context).textTheme.caption!.copyWith(
                      fontFeatures: const [
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                ],
              ),
              Center(
                child: StatusDot(
                  size: 10.0,
                  color: this.connection.reachable == null
                      ? Colors.grey
                      : this.connection.reachable!
                          ? CupertinoColors.activeGreen
                          : CupertinoColors.destructiveRed,
                  text: this.connection.reachable == null
                      ? 'Checking...'
                      : this.connection.reachable!
                          ? 'Reachable'
                          : 'Not reachable',
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 24.0),
                  Expanded(
                    child: BaseButton(
                      text: 'Connect',
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        networkStore
                            .setOBSWebSocket(this.connection)
                            .then((closeCode) {
                          if (closeCode ==
                              WebSocketCloseCode.AuthenticationFailed) {
                            OverlayHandler.showStatusOverlay(
                              context: context,
                              content: const BaseResult(
                                icon: BaseResultIcon.Negative,
                                text: 'Wrong password!',
                              ),
                            );
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 24.0),
                  Expanded(
                    child: BaseButton(
                      // shrinkWidth: true,
                      // padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      // child: const Icon(
                      //   Icons.edit,
                      //   size: 20.0,
                      // ),
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
                  const SizedBox(width: 24.0),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
