import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:obs_blade/stores/shared/purchases.dart';
import 'package:obs_blade/utils/general_helper.dart';

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

  Future<void> _listenToPurchaseUpdated(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchaseDetails in purchaseDetailsList) {
      _purchaseStatus = purchaseDetails.status;
      GeneralHelper.advLog(
          '${purchaseDetails.productID} - ${purchaseDetails.status}');
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // _showPendingUI();
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          // _handleError(purchaseDetails.error!);
        } else if (purchaseDetails.status == PurchaseStatus.purchased) {
          /// If a purchase contains tip in its productID, it is a consumable
          /// and therefore not persistent. The App Stores will only persist
          /// non-consumables (one time "upgrades")

          if (purchaseDetails.productID.contains('tip')) {
            try {
              ProductDetails tipDetails = (await InAppPurchase.instance
                      .queryProductDetails({purchaseDetails.productID}))
                  .productDetails
                  .first;

              GeneralHelper.advLog(purchaseDetails.transactionDate);
              GeneralHelper.advLog(purchaseDetails.productID);
              GeneralHelper.advLog(tipDetails.title);
              GeneralHelper.advLog(tipDetails.price);

              // Hive.box<PurchasedTip>(HiveKeys.PurchasedTip.name).add(
              //   PurchasedTip(
              //     int.parse(purchaseDetails.transactionDate!),
              //     purchaseDetails.productID,
              //     tipDetails.title,
              //     tipDetails.price,
              //   ),
              // );
            } catch (e) {}
          } else {
            GetIt.instance<PurchasesStore>().addPurchase(purchaseDetails);
          }
        } else if (purchaseDetails.status == PurchaseStatus.restored) {
          GetIt.instance<PurchasesStore>().addPurchase(purchaseDetails);
        }
        if (purchaseDetails.pendingCompletePurchase) {
          await InAppPurchase.instance.completePurchase(purchaseDetails);
        }
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
