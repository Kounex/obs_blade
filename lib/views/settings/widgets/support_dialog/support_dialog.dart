import 'package:flutter/cupertino.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:obs_blade/models/enums/log_level.dart';
import 'package:obs_blade/utils/general_helper.dart';

import '../../../../shared/general/custom_cupertino_dialog.dart';
import '../../../../shared/overlay/base_progress_indicator.dart';
import 'blacksmith_content/blacksmith_content.dart';
import 'support_header.dart';
import 'tips_content.dart';

enum SupportType {
  Blacksmith,
  Tips,
}

class SupportDialog extends StatefulWidget {
  final String title;
  final IconData icon;

  final SupportType type;

  const SupportDialog({
    Key? key,
    required this.title,
    this.icon = CupertinoIcons.heart_solid,
    required this.type,
  }) : super(key: key);

  @override
  State<SupportDialog> createState() => _SupportDialogState();
}

class _SupportDialogState extends State<SupportDialog> {
  Future<List<ProductDetails>>? _inAppPurchases;
  String? _error;

  @override
  void initState() {
    super.initState();

    _inAppPurchases = _getAvailableInAppPurchases();
  }

  Future<List<ProductDetails>> _getAvailableInAppPurchases() async {
    _error = null;
    final bool available = await InAppPurchase.instance.isAvailable();
    if (!available) {
      _error =
          'Connection to the App Store is not possible. Make sure you have a working internet connection.\n\nFeel free to let me know if this problem persists!';
      GeneralHelper.advLog(_error, includeInLogs: true, level: LogLevel.Error);
    }
    Set<String> inAppPurchasesIDs = {};
    switch (this.widget.type) {
      case SupportType.Blacksmith:
        inAppPurchasesIDs = {'blacksmith'};
        break;
      case SupportType.Tips:
        inAppPurchasesIDs = {'tip_1', 'tip_2', 'tip_3'};
        break;
    }

    ProductDetailsResponse productDetailsResponse =
        await InAppPurchase.instance.queryProductDetails(inAppPurchasesIDs);

    return productDetailsResponse.productDetails;
  }

  @override
  Widget build(BuildContext context) {
    return CustomCupertinoDialog(
      paddingTop: 10.0,
      title: SupportHeader(
        title: this.widget.title,
        icon: this.widget.icon,
      ),
      content: FutureBuilder<List<ProductDetails>>(
        future: _inAppPurchases,
        builder: (context, inAppPurchasesSnapshot) {
          // if (inAppPurchasesSnapshot.connectionState == ConnectionState.done) {
          List<ProductDetails>? inAppPurchasesDetails =
              inAppPurchasesSnapshot.connectionState == ConnectionState.done
                  ? (inAppPurchasesSnapshot.data ?? [])
                  : inAppPurchasesSnapshot.data;
          return SingleChildScrollView(
            child: () {
              if (this.widget.type == SupportType.Tips) {
                return TipsContent(
                  tipsDetails: inAppPurchasesDetails,
                );
              } else {
                return BlacksmithContent(
                  blacksmithDetails: inAppPurchasesDetails,
                );
              }
            }(),
          );
          // }
          // return Container(
          //   height: 172.0,
          //   alignment: Alignment.center,
          //   child: BaseProgressIndicator(
          //     text: 'Fetching...',
          //   ),
          // );
        },
      ),
    );
  }
}
