import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/shared/general/base/divider.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/views/home/widgets/connect_box/quick_connect/qr_scan.dart';

import '../../../../../models/connection.dart';
import '../../../../../shared/general/base/button.dart';
import '../../../../../utils/modal_handler.dart';

class QuickConnect extends StatelessWidget {
  const QuickConnect({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              children: [
                const Text(
                    'Scan the “Connect QR” of the WebSocket plugin to connect to OBS instantly.'),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'This feature only works when connecting to an OBS instance which is in the same network as this device!',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          /// Full-bleed divider - same rule as the autodiscovery and
          /// manual connect cards
          const BaseDivider(),
          const SizedBox(height: AppSpacing.lg),
          BaseButton(
            onPressed: () =>
                ModalHandler.showBaseCupertinoBottomSheet<Connection?>(
              context: context,
              includeCloseButton: false,
              modalWidgetBuilder: (context, controller) => const QRScan(),
            ).then(
              (connection) {
                if (connection != null) {
                  Future.delayed(
                    const Duration(milliseconds: 500),
                    () => GetIt.instance<NetworkStore>()
                        .setOBSWebSocket(connection),
                  );
                }
              },
            ),
            icon: const Icon(CupertinoIcons.qrcode_viewfinder),
            text: 'Scan',
          ),
        ],
      ),
    );
  }
}
