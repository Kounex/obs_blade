import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'pro_ids.dart';

const MethodChannel kManageSubscriptionsChannel = MethodChannel(
  'com.kounex.obsBlade/subscriptions',
);

const String kAndroidPackageName = 'com.kounex.obsBlade';

/// The store's subscription page: the App Store account page, or Play's
/// page for the Pro subscription itself (Play's documented deep link)
Uri manageSubscriptionsUri({required bool ios}) => ios
    ? Uri.parse('https://apps.apple.com/account/subscriptions')
    : Uri.https('play.google.com', '/store/account/subscriptions', {
        'sku': kPlayProSubscriptionId,
        'package': kAndroidPackageName,
      });

/// How [openManageSubscriptions] ended
enum ManageSubscriptionsResult {
  /// StoreKit's sheet was shown and is closed again - re-read the plan
  sheetClosed,

  /// The store's page opened outside the app
  pageOpened,

  /// Nothing could open
  failed,
}

/// Opens the store's subscription management. iOS shows StoreKit's sheet
/// in the app (it also lists sandbox / TestFlight subscriptions, the web
/// page doesn't) and falls back to the web page where the sheet can't show
/// (iPad app on a Mac); Android opens Play's page for the Pro subscription.
Future<ManageSubscriptionsResult> openManageSubscriptions({
  bool? ios,
  MethodChannel channel = kManageSubscriptionsChannel,
  Future<bool> Function(Uri uri)? launch,
}) async {
  final bool isIOS =
      ios ?? (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS);
  if (isIOS) {
    try {
      final bool? shown = await channel.invokeMethod<bool>(
        'showManageSubscriptions',
      );
      if (shown == true) return ManageSubscriptionsResult.sheetClosed;
    } catch (_) {
      /// PlatformException / MissingPluginException - the page below
    }
  }
  try {
    final bool opened = await (launch ?? _launchExternal)(
      manageSubscriptionsUri(ios: isIOS),
    );
    return opened
        ? ManageSubscriptionsResult.pageOpened
        : ManageSubscriptionsResult.failed;
  } catch (_) {
    return ManageSubscriptionsResult.failed;
  }
}

Future<bool> _launchExternal(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);
