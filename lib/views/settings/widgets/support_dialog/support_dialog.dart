import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:obs_blade/models/enums/log_level.dart';
import 'package:obs_blade/utils/general_helper.dart';

import '../../../../shared/general/custom_cupertino_dialog.dart';
import 'support_header.dart';
import 'tips_content.dart';

/// The "Tip Jar" dialog — tips are the only products still sold here.
/// Blacksmith (the former second support type) is no longer sold; legacy
/// buyers restore it via the Pro paywall's Restore purchases, which also
/// fires the direct-IAP plugin restore (see `ProStore.restore`).
class SupportDialog extends StatefulWidget {
  final String title;
  final IconData icon;

  const SupportDialog({
    super.key,
    required this.title,
    this.icon = CupertinoIcons.heart_solid,
  });

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

    ProductDetailsResponse productDetailsResponse = await InAppPurchase
        .instance
        .queryProductDetails({'tip_1', 'tip_2', 'tip_3'});

    return productDetailsResponse.productDetails;
  }

  @override
  Widget build(BuildContext context) {
    return CustomCupertinoDialog(
      paddingTop: 10.0,
      title: SupportHeader(title: this.widget.title, icon: this.widget.icon),
      content: FutureBuilder<List<ProductDetails>>(
        future: _inAppPurchases,
        builder: (context, inAppPurchasesSnapshot) {
          List<ProductDetails>? inAppPurchasesDetails =
              inAppPurchasesSnapshot.connectionState == ConnectionState.done
              ? (inAppPurchasesSnapshot.data ?? [])
              : inAppPurchasesSnapshot.data;
          return DefaultTextStyle(
            style: Theme.of(context).textTheme.bodyMedium!,
            child: SingleChildScrollView(
              child: TipsContent(tipsDetails: inAppPurchasesDetails),
            ),
          );
        },
      ),
    );
  }
}
