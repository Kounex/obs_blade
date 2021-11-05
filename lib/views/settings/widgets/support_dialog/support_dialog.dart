import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:obs_blade/shared/general/base/button.dart';
import 'package:obs_blade/stores/shared/purchases.dart';
import 'package:obs_blade/stores/shared/tabs.dart';
import 'package:obs_blade/utils/routing_helper.dart';

import '../../../../shared/general/flutter_modified/non_scrollable_cupertino_dialog.dart';
import '../../../../shared/overlay/base_progress_indicator.dart';
import '../../../../types/extensions/list.dart';
import 'donate_button.dart';
import 'support_header.dart';

const double _kDialogEdgePadding = 20.0;

enum SupportType {
  Blacksmith,
  Tips,
}

class SupportDialog extends StatefulWidget {
  final String title;

  final IconData icon;

  final String? body;
  final Widget Function(BuildContext)? bodyWidget;
  final SupportType type;

  const SupportDialog({
    Key? key,
    required this.title,
    this.icon = CupertinoIcons.heart_solid,
    this.body,
    this.bodyWidget,
    required this.type,
  }) : super(key: key);

  @override
  State<SupportDialog> createState() => _SupportDialogState();
}

class _SupportDialogState extends State<SupportDialog> {
  Future<List<ProductDetails>>? _tips;
  String? _error;

  @override
  void initState() {
    super.initState();

    _tips = _getAvailableTips();
  }

  Future<List<ProductDetails>> _getAvailableTips() async {
    _error = null;
    final bool available = await InAppPurchase.instance.isAvailable();
    if (!available) {
      _error =
          'Connection to the App Store is not possible. Make sure you have a working internet connection.\n\nFeel free to let me know if this problem persists!';
    }
    Set<String> tipIDs = {};
    switch (this.widget.type) {
      case SupportType.Blacksmith:
        tipIDs = {'blacksmith'};
        break;
      case SupportType.Tips:
        tipIDs = {'tip_1', 'tip_2', 'tip_3'};
        break;
    }
    return (await InAppPurchase.instance.queryProductDetails(tipIDs))
        .productDetails;
  }

  String _sumTipped(
          Iterable<PurchaseDetails> tips, List<ProductDetails> products) =>
      '${tips.fold<int>(0, (sum, tip) => sum += products.firstWhere((tipData) => tipData.id == tip.productID).rawPrice.toInt())}${products.first.currencySymbol}';

  @override
  Widget build(BuildContext context) {
    PurchasesStore purchasesStore = GetIt.instance<PurchasesStore>();

    return Dismissible(
      key: const Key('support'),
      direction: DismissDirection.vertical,
      onDismissed: (_) => Navigator.of(context).pop(),
      dismissThresholds: const {DismissDirection.vertical: 0.2},
      child: Material(
        type: MaterialType.transparency,
        child: NonScrollableCupertinoAlertDialog(
          content: Stack(
            children: [
              SupportHeader(
                title: this.widget.title,
                icon: this.widget.icon,
              ),
              DefaultTextStyle(
                style: Theme.of(context).textTheme.bodyText1!,
                textAlign: TextAlign.center,
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 64.0,
                    left: _kDialogEdgePadding,
                    right: _kDialogEdgePadding,
                    bottom: _kDialogEdgePadding,
                  ),
                  child: FutureBuilder<List<ProductDetails>>(
                    future: _tips,
                    builder: (context, tipsSnapshot) {
                      if (tipsSnapshot.connectionState ==
                          ConnectionState.done) {
                        if (tipsSnapshot.hasData &&
                            tipsSnapshot.data!.isNotEmpty) {
                          return SingleChildScrollView(
                            child: Column(
                              children: [
                                if (this.widget.bodyWidget != null ||
                                    this.widget.body != null) ...[
                                  this.widget.body != null
                                      ? Text(this.widget.body!)
                                      : this.widget.bodyWidget!(context),
                                  const SizedBox(
                                    height: 12.0,
                                  ),
                                ],
                                if (this.widget.type == SupportType.Tips) ...[
                                  ...tipsSnapshot.data!
                                      .mapIndexed(
                                        (tip, index) => DonateButton(
                                          text: tip.title.isNotEmpty
                                              ? tip.title
                                              : '${(tip.rawPrice).toInt()} Energy Drink${((tip.rawPrice).toInt() > 1 ? "s" : "")}',
                                          price: tip.price,
                                          purchaseParam: PurchaseParam(
                                              productDetails: tip),
                                        ),
                                      )
                                      .toList(),
                                  Observer(builder: (_) {
                                    Iterable<PurchaseDetails> tips =
                                        purchasesStore.purchases.where(
                                            (purchase) =>
                                                purchase.productID !=
                                                'blacksmith');
                                    if (tips.isNotEmpty) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(top: 12.0),
                                        child: Text(
                                            'You tipped ${_sumTipped(tips, tipsSnapshot.data!)} so far\nYou are awesome :)'),
                                      );
                                    }
                                    return Container();
                                  }),
                                ],
                                if (this.widget.type == SupportType.Blacksmith)
                                  Observer(
                                    builder: (_) {
                                      if (!purchasesStore.purchases.any(
                                          (purchase) =>
                                              purchase.productID ==
                                              'blacksmith')) {
                                        return DonateButton(
                                          price: tipsSnapshot.data![0].price,
                                          purchaseParam: PurchaseParam(
                                              productDetails:
                                                  tipsSnapshot.data![0]),
                                        );
                                      }
                                      return Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          BaseButton(
                                            text: 'Forge Theme',
                                            secondary: true,
                                            onPressed: () {
                                              Navigator.of(context).pop(true);
                                              TabsStore tabsStore =
                                                  GetIt.instance<TabsStore>();

                                              if (tabsStore
                                                          .activeRoutePerNavigator[
                                                      Tabs.Settings] !=
                                                  SettingsTabRoutingKeys
                                                      .CustomTheme.route) {
                                                Future.delayed(
                                                  const Duration(
                                                      milliseconds: 500),
                                                  () => tabsStore
                                                      .navigatorKeys[
                                                          Tabs.Settings]
                                                      ?.currentState
                                                      ?.pushNamed(
                                                    SettingsTabRoutingKeys
                                                        .CustomTheme.route,
                                                    arguments: {
                                                      'blacksmith': true
                                                    },
                                                  ),
                                                );
                                              }
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                              ],
                            ),
                          );
                        }
                        return Text(_error ??
                            'There was an error retrieving available options! It seems like there are no options available currently.\n\nFeel free to let me know if this problem persists!');
                      }
                      return Center(
                        child: BaseProgressIndicator(
                          text: 'Fetching...',
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

        // Transform(
        //   transform: Matrix4.identity()..translate(110.0, 110.0),
        //   child: CupertinoButton(
        //     child: Text('...'),
        //     onPressed: () => Navigator.of(context).pop(),
        //   ),
        // ),
      ),
    );
  }
}
