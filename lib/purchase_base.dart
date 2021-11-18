import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:obs_blade/models/enums/log_level.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/general_helper.dart';

import 'models/purchased_tip.dart';
import 'types/enums/hive_keys.dart';

class PurchaseBase extends StatefulWidget {
  final Widget child;

  const PurchaseBase({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  _PurchaseBaseState createState() => _PurchaseBaseState();
}

class _PurchaseBaseState extends State<PurchaseBase> {
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  PurchaseStatus? _purchaseStatus;
  final bool _showStatus = false;

  @override
  void initState() {
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        InAppPurchase.instance.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (error) {
      // handle error here.
    });

    /// Trigger stream to see made purchases
    InAppPurchase.instance.restorePurchases();
    super.initState();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  void _handlePurchase(
      PurchaseDetails purchaseDetails, ProductDetails inAppDetails) {
    /// If a purchase contains tip in its productID, it is a consumable
    /// and therefore not persistent. The App Stores will only persist
    /// non-consumables (one time "upgrades"). Thats why it will be persisted
    /// manually in Hive so it's at least possible to retrieve them
    /// from an app installation
    if (purchaseDetails.productID.contains('tip')) {
      Hive.box<PurchasedTip>(HiveKeys.PurchasedTip.name).put(
        purchaseDetails.purchaseID,
        PurchasedTip(
          int.parse(purchaseDetails.transactionDate!),
          purchaseDetails.productID,
          inAppDetails.title,
          inAppDetails.price,
          inAppDetails.currencySymbol,
        ),
      );
    } else {
      /// If a purchase is explicily blacksmith, set the flag in the settings box
      /// to true to be able to check that offline as well later on
      if (purchaseDetails.productID.contains('blacksmith')) {
        Hive.box(HiveKeys.Settings.name).put(
          SettingsKeys.BoughtBlacksmith.name,
          true,
        );
      }
    }
  }

  Future<void> _listenToPurchaseUpdated(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchaseDetails in purchaseDetailsList) {
      _purchaseStatus = purchaseDetails.status;
      GeneralHelper.advLog(
          '${purchaseDetails.productID} - ${purchaseDetails.status}');
      try {
        ProductDetails inAppDetails = (await InAppPurchase.instance
                .queryProductDetails({purchaseDetails.productID}))
            .productDetails
            .first;
        if (purchaseDetails.status == PurchaseStatus.pending) {
          // _showPendingUI();
        } else {
          if (purchaseDetails.status == PurchaseStatus.error) {
            // _handleError(purchaseDetails.error!);
          } else if (purchaseDetails.status == PurchaseStatus.purchased) {
            _handlePurchase(purchaseDetails, inAppDetails);
          } else if (purchaseDetails.status == PurchaseStatus.restored) {
            _handlePurchase(purchaseDetails, inAppDetails);
          }
          if (purchaseDetails.pendingCompletePurchase) {
            await InAppPurchase.instance.completePurchase(purchaseDetails);
          }
        }
      } catch (e) {
        GeneralHelper.advLog(e.toString(),
            includeInLogs: true, level: LogLevel.Error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        this.widget.child,
        Container(),
      ],
    );
  }
}
