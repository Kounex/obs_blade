import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:obs_blade/utils/routing_helper.dart';

import 'models/enums/log_level.dart';
import 'models/purchased_tip.dart';
import 'shared/dialogs/info.dart';
import 'shared/overlay/base_progress_indicator.dart';
import 'types/enums/hive_keys.dart';
import 'types/enums/settings_keys.dart';
import 'utils/general_helper.dart';
import 'utils/modal_handler.dart';
import 'utils/overlay_handler.dart';
import 'utils/pro_ids.dart';
import 'utils/revenuecat_config.dart';

/// Applies a pro purchase/restored event to the settings box. Returns
/// true when the caller should surface the restored InfoDialog — only on
/// an explicit (paywall-button) restore; the cold-start restore and fresh
/// purchases stay silent.
@visibleForTesting
bool applyProPurchaseToSettings({
  required PurchaseDetails purchaseDetails,
  required Box<dynamic> settingsBox,
  required bool explicitRestore,
}) {
  settingsBox.put(SettingsKeys.BoughtPro.name, true);
  return purchaseDetails.status == PurchaseStatus.restored && explicitRestore;
}

/// The "Pro restored" InfoDialog — shown on an explicit (paywall-button)
/// restore that surfaced an active entitlement. Legacy path: called from
/// [_PurchaseBaseState._handlePurchase] when a restored pro event arrives
/// armed; RevenueCat path: called directly by `ProStore.restore` (no
/// purchase-stream events exist there).
void showProRestoredDialog() {
  Future.delayed(
    const Duration(seconds: 1),
    () {
      /// Null in unit tests / headless states — skip the dialog rather
      /// than crash.
      if (RoutingHelper.tabBaseKey.currentContext == null) return;
      OverlayHandler.closeAnyOverlay();
      ModalHandler.showBaseDialog(
        context: RoutingHelper.tabBaseKey.currentContext!,
        barrierDismissible: true,
        dialogWidget: const InfoDialog(
          body: 'Your Pro purchase has been restored!\n\nEnjoy!',
        ),
      );
    },
  );
}

class PurchaseBase extends StatefulWidget {
  final Widget child;

  /// Set via [ProStore.restore] when the user explicitly tapped "Restore
  /// purchases" so the restored handler knows to show the success
  /// InfoDialog; cold-start restores leave this false and stay silent.
  /// Armed only while an explicit restore call is in flight — consumed by
  /// a restored pro event, disarmed by [ProStore.restore] otherwise.
  static bool restoreTriggeredExplicitly = false;

  const PurchaseBase({
    super.key,
    required this.child,
  });

  @override
  _PurchaseBaseState createState() => _PurchaseBaseState();
}

class _PurchaseBaseState extends State<PurchaseBase> {
  late StreamSubscription<List<PurchaseDetails>> _subscription;

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
    super.initState();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  void _handlePurchase(
      PurchaseDetails purchaseDetails, ProductDetails? inAppDetails) {
    /// If a purchase contains tip in its productID, it is a consumable
    /// and therefore not persistent. The App Stores will only persist
    /// non-consumables (one time "upgrades"). Thats why it will be persisted
    /// manually in Hive so it's at least possible to retrieve them
    /// from an app installation
    if (purchaseDetails.productID.contains('tip') && inAppDetails != null) {
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
      /// If a purchase is a pro product (subscription or lifetime), set the
      /// entitlement flag in the settings box. The store products don't
      /// exist store-side yet, so this branch must work with
      /// [inAppDetails] being null (empty productDetails).
      ///
      /// Dead while RevenueCat is configured: RC's CustomerInfo is the
      /// single source of truth for the pro entitlement then, and pro
      /// purchases no longer ride this IAP stream. Tips and blacksmith
      /// below stay on direct IAP regardless.
      if (isProProductId(purchaseDetails.productID) &&
          !revenueCatConfigured) {
        bool showRestoredDialog = applyProPurchaseToSettings(
          purchaseDetails: purchaseDetails,
          settingsBox: Hive.box<dynamic>(HiveKeys.Settings.name),
          explicitRestore: PurchaseBase.restoreTriggeredExplicitly,
        );
        PurchaseBase.restoreTriggeredExplicitly = false;

        /// Same idiom as the blacksmith restored branch below: the user
        /// tapped Restore, the restore worked — inform them via dialog.
        if (showRestoredDialog) {
          showProRestoredDialog();
        }
      } else if (purchaseDetails.productID.contains('blacksmith')) {
        /// If a purchase is explicily blacksmith, set the flag in the settings box
        /// to true to be able to check that offline as well later on
        if (purchaseDetails.status == PurchaseStatus.restored) {
          /// If we get the restored status from the purchase stream, it means
          /// that the user clicked on restore and therefore called the restorePurchases
          /// function and it worked - therefore we show an info dialog to inform
          /// the user that it worked!
          Future.delayed(
            const Duration(seconds: 1),
            () {
              Hive.box<dynamic>(HiveKeys.Settings.name).put(
                SettingsKeys.BoughtBlacksmith.name,
                true,
              );
              OverlayHandler.closeAnyOverlay();
              ModalHandler.showBaseDialog(
                context: RoutingHelper.tabBaseKey.currentContext!,
                barrierDismissible: true,
                dialogWidget: const InfoDialog(
                  body: 'Your theme purchase has been restored!\n\nEnjoy!',
                ),
              );
            },
          );
        } else {
          Hive.box<dynamic>(HiveKeys.Settings.name).put(
            SettingsKeys.BoughtBlacksmith.name,
            true,
          );
        }
      }
    }
  }

  void _showPendingUI() {
    OverlayHandler.showStatusOverlay(
      context: RoutingHelper.tabBaseKey.currentContext!,
      showDuration: const Duration(seconds: 10),
      content: BaseProgressIndicator(
        text: 'Pending...',
      ),
    );
  }

  Future<void> _listenToPurchaseUpdated(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchaseDetails in purchaseDetailsList) {
      GeneralHelper.advLog(
          '${purchaseDetails.productID} - ${purchaseDetails.status}');
      try {
        /// Product ids which don't exist store-side (pro ids right now)
        /// yield an empty productDetails list — `.first` would throw and the
        /// entitlement flag would silently never set, so guard for it.
        List<ProductDetails> productDetails = (await InAppPurchase.instance
                .queryProductDetails({purchaseDetails.productID}))
            .productDetails;
        if (purchaseDetails.status == PurchaseStatus.pending) {
          _showPendingUI();
        } else {
          OverlayHandler.closeAnyOverlay();
          if (purchaseDetails.status == PurchaseStatus.error) {
            // _handleError(purchaseDetails.error!);
          } else if (purchaseDetails.status == PurchaseStatus.purchased) {
            _handlePurchase(purchaseDetails,
                productDetails.isEmpty ? null : productDetails.first);
          } else if (purchaseDetails.status == PurchaseStatus.restored) {
            _handlePurchase(purchaseDetails,
                productDetails.isEmpty ? null : productDetails.first);
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
        const SizedBox(),
      ],
    );
  }
}
