import 'package:flutter/cupertino.dart';
import 'package:get_it/get_it.dart';
import 'package:obs_blade/shared/general/base/divider.dart';
import 'package:obs_blade/stores/shared/network.dart';
import 'package:obs_blade/views/home/widgets/connect_box/quick_connect/qr_scan.dart';

import '../../../../../models/connection.dart';
import '../../../../../shared/general/base/button.dart';
import '../../../../../utils/modal_handler.dart';

class QuickConnect extends StatelessWidget {
  const QuickConnect({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const Text(
              'Scan the "Connect QR" of the WebSocket plugin to connect to OBS instantly.\n\nThis feature only works when connecting to an OBS instance which is in the same network as this device!'),
          const SizedBox(height: 20.0),
          const BaseDivider(),
          const SizedBox(height: 18.0),
          BaseButton(
            onPressed: () =>
                ModalHandler.showBaseCupertinoBottomSheet<Connection?>(
              context: context,
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
