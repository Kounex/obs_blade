import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:obs_blade/views/settings/widgets/support_dialog/blacksmith_content.dart';
import 'package:obs_blade/views/settings/widgets/support_dialog/tips_content.dart';

import '../../../../shared/general/flutter_modified/non_scrollable_cupertino_dialog.dart';
import '../../../../shared/overlay/base_progress_indicator.dart';
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
    return (await InAppPurchase.instance.queryProductDetails(inAppPurchasesIDs))
        .productDetails;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: NonScrollableCupertinoAlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SupportHeader(
              title: this.widget.title,
              icon: this.widget.icon,
            ),
            Flexible(
              child: DefaultTextStyle(
                style: Theme.of(context).textTheme.bodyText1!,
                textAlign: TextAlign.center,
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: _kDialogEdgePadding,
                    right: _kDialogEdgePadding,
                    bottom: _kDialogEdgePadding,
                  ),
                  child: FutureBuilder<List<ProductDetails>>(
                    future: _inAppPurchases,
                    builder: (context, inAppPurchasesSnapshot) {
                      if (inAppPurchasesSnapshot.connectionState ==
                          ConnectionState.done) {
                        if (inAppPurchasesSnapshot.hasData &&
                            inAppPurchasesSnapshot.data!.isNotEmpty) {
                          List<ProductDetails> inAppPurchasesSnapshotDetails =
                              inAppPurchasesSnapshot.data!;
                          return SingleChildScrollView(
                            child: Column(
                              children: [
                                this.widget.bodyWidget != null
                                    ? this.widget.bodyWidget!(context)
                                    : Text(this.widget.body ?? ''),
                                const SizedBox(
                                  height: 12.0,
                                ),
                                if (this.widget.type == SupportType.Tips)
                                  TipsContent(
                                    tipsDetails: inAppPurchasesSnapshotDetails,
                                  ),
                                if (this.widget.type == SupportType.Blacksmith)
                                  BlacksmithContent(
                                    blacksmithDetails:
                                        inAppPurchasesSnapshotDetails,
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
            ),
          ],
        ),
      ),
    );
  }
}
