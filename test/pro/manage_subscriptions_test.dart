import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/utils/manage_subscriptions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<Uri> launched = [];
  Future<bool> launch(Uri uri) async {
    launched.add(uri);
    return true;
  }

  void answer(Object? Function(MethodCall call) handler) =>
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            kManageSubscriptionsChannel,
            (call) async => handler(call),
          );

  setUp(launched.clear);
  tearDown(() => answer((_) => null));

  test('iOS: StoreKit sheet, no web page', () async {
    final List<String> calls = [];
    answer((call) {
      calls.add(call.method);
      return true;
    });

    expect(
      await openManageSubscriptions(ios: true, launch: launch),
      ManageSubscriptionsResult.sheetClosed,
    );
    expect(calls, ['showManageSubscriptions']);
    expect(launched, isEmpty);
  });

  test('iOS: sheet unavailable (iPad app on Mac) opens the web page', () async {
    answer((_) => false);

    expect(
      await openManageSubscriptions(ios: true, launch: launch),
      ManageSubscriptionsResult.pageOpened,
    );
    expect(
      launched.single.toString(),
      'https://apps.apple.com/account/subscriptions',
    );
  });

  test('iOS: channel error falls back to the web page', () async {
    answer((_) => throw PlatformException(code: 'boom'));

    expect(
      await openManageSubscriptions(ios: true, launch: launch),
      ManageSubscriptionsResult.pageOpened,
    );
    expect(launched, hasLength(1));
  });

  test('Android: Play page of the Pro subscription, no channel', () async {
    final List<String> calls = [];
    answer((call) {
      calls.add(call.method);
      return true;
    });

    expect(
      await openManageSubscriptions(ios: false, launch: launch),
      ManageSubscriptionsResult.pageOpened,
    );
    expect(calls, isEmpty);
    expect(
      launched.single.toString(),
      'https://play.google.com/store/account/subscriptions'
      '?sku=pro&package=com.kounex.obsBlade',
    );
  });

  test('nothing opens: failed', () async {
    expect(
      await openManageSubscriptions(
        ios: false,
        launch: (_) async => throw Exception('no browser'),
      ),
      ManageSubscriptionsResult.failed,
    );
  });
}
