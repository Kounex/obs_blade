import 'dart:io';

import 'package:confetti/confetti.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/purchase_base.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/stores/pro_store.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';
import 'package:obs_blade/types/enums/settings_keys.dart';
import 'package:obs_blade/utils/pro_ids.dart';
import 'package:obs_blade/utils/pro_purchase_service.dart';
import 'package:obs_blade/views/pro/pro_paywall.dart';
import 'package:obs_blade/views/pro/widgets/pro_hero.dart';
import 'package:obs_blade/views/settings/widgets/support_dialog/support_skeleton.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_pro_purchase_gateway.dart';

/// Minimal app-shaped theme: the paywall widgets read
/// `buttonTheme.colorScheme.secondary` (accent), a non-null app bar
/// background (transculent nav bar) and a divider color (skeleton/dots)
ThemeData _testTheme() => ThemeData(
      brightness: Brightness.dark,
      cupertinoOverrideTheme: const CupertinoThemeData(),
      appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
      buttonTheme: ButtonThemeData(
        colorScheme: ColorScheme.fromSwatch(accentColor: Colors.redAccent),
      ),
      dividerTheme: const DividerThemeData(color: Colors.grey),

      /// Design-system extensions the migrated widgets force-unwrap
      /// (registered by `App._getCurrentTheme` in real runs)
      extensions: const [
        AppStatusColors.standard,
        AppTextColors.standard,
      ],
    );

Widget wrap(Widget child, {double width = 400.0}) => MediaQuery(
      data: MediaQueryData(size: Size(width, 900.0)),
      child: MaterialApp(
        theme: _testTheme(),
        home: child,
      ),
    );

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late FakeProPurchaseGateway gateway;
  late List<ProStore> stores;

  Box<dynamic> settingsBox() => Hive.box(HiveKeys.Settings.name);

  ProStore newStore() {
    final ProStore store = ProStore(
      service: ProPurchaseService(gateway: gateway),
    );
    stores.add(store);
    return store;
  }

  /// Variant whose debug override skips the Hive put - real I/O started
  /// from a gesture handler never completes inside the fake-async zone
  /// (the Hive-writing path itself is covered by pro_store_test.dart)
  ProStore newNoIoDebugStore() {
    final ProStore store = _NoIoDebugProStore(
      service: ProPurchaseService(gateway: gateway),
    );
    stores.add(store);
    return store;
  }

  /// Bounded pumps only: the skeleton breathes and confetti loops on
  /// timers, so pumpAndSettle would never finish
  Future<void> pumpPaywall(
    WidgetTester tester,
    ProStore store, {
    double width = 400.0,
  }) async {
    await tester.pumpWidget(wrap(ProPaywallView(store: store), width: width));

    /// loadProducts() microtasks + staggered-entrance timers (120ms max
    /// delay + 400ms duration)
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  /// SnackBars run on a 4s timer which fails test teardown if still pending
  Future<void> flushSnackBar(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 300));
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pro_paywall_test');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await Hive.openBox(HiveKeys.Settings.name);

    /// Skip the cold-start restore - gateway counters should only see
    /// what each test triggers
    await settingsBox()
        .put(SettingsKeys.ProColdStartRestoreDone.name, true);

    gateway = FakeProPurchaseGateway();
    stores = [];
    PurchaseBase.restoreTriggeredExplicitly = false;
  });

  tearDown(() async {
    PurchaseBase.restoreTriggeredExplicitly = false;
    for (final ProStore store in stores) {
      store.dispose();
    }
    await gateway.close();
    await harness.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets(
      'placeholder state (no store products) renders benefits, the '
      'free-forever line and disabled placeholder pricing', (tester) async {
    await pumpPaywall(tester, newStore()..init());

    /// Benefits browser (first carousel page is built eagerly)
    expect(find.text('Native Twitch Chat'), findsOneWidget);
    expect(find.byType(SmoothPageIndicator), findsOneWidget);

    /// The honest free-core line
    expect(find.textContaining('stays free'), findsOneWidget);

    /// All three offers in placeholder form
    expect(find.text('Price shown at purchase'), findsNWidgets(3));
    expect(find.text('Not live yet'), findsNWidgets(3));
    expect(find.text('BEST VALUE'), findsOneWidget);
  });

  testWidgets('placeholder buy explains instead of charging', (tester) async {
    await pumpPaywall(tester, newStore()..init());

    await tester.ensureVisible(find.text('Not live yet').first);
    await tester.pump();
    await tester.tap(find.text('Not live yet').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('isn\'t live in the store yet'), findsOneWidget);
    expect(gateway.buyCalls, 0);

    await flushSnackBar(tester);
  });

  testWidgets('loaded pricing renders live prices and yearly as the hero',
      (tester) async {
    gateway.storeProducts = [
      fakeProduct(kProYearlyId, price: '€19.99', rawPrice: 19.99),
      fakeProduct(kProMonthlyId, price: '€2.99', rawPrice: 2.99),
      fakeProduct(kProLifetimeId, price: '€59.99', rawPrice: 59.99),
    ];

    await pumpPaywall(tester, newStore()..init());

    expect(find.text('€19.99'), findsOneWidget);
    expect(find.text('€2.99'), findsOneWidget);
    expect(find.text('€59.99'), findsOneWidget);
    expect(find.text('Price shown at purchase'), findsNothing);
    expect(find.text('BEST VALUE'), findsOneWidget);
    expect(find.text('Choose Yearly'), findsOneWidget);
    expect(find.text('Choose Monthly'), findsOneWidget);
    expect(find.text('Choose Lifetime'), findsOneWidget);
  });

  testWidgets('buy tap calls ProStore.buy with the tapped product',
      (tester) async {
    gateway.storeProducts = [
      fakeProduct(kProYearlyId, price: '€19.99', rawPrice: 19.99),
      fakeProduct(kProMonthlyId, price: '€2.99', rawPrice: 2.99),
    ];

    await pumpPaywall(tester, newStore()..init());

    await tester.ensureVisible(find.text('Choose Yearly'));
    await tester.pump();
    await tester.tap(find.text('Choose Yearly'));
    await tester.pump();

    expect(gateway.buyCalls, 1);
    expect(gateway.lastBoughtProduct, isNotNull);
    expect(gateway.lastBoughtProduct!.id, kProYearlyId);
  });

  testWidgets('restore keeps the placeholder cards instead of swapping '
      'to skeleton rows', (tester) async {
    /// Restore hangs in flight so the pending state is observable - the
    /// pricing section must keep its cards (skeletons are reserved for
    /// the initial product load)
    final ProStore store = _HangingRestoreProStore(
      service: ProPurchaseService(gateway: gateway),
    );
    stores.add(store);
    await pumpPaywall(tester, store..init());

    expect(find.text('Price shown at purchase'), findsNWidgets(3));

    await tester.ensureVisible(find.text('Restore purchases'));
    await tester.pump();
    await tester.tap(find.text('Restore purchases'));
    await tester.pump();

    expect(store.pending, isTrue);
    expect(find.byType(SupportSkeleton), findsNothing);
    expect(find.text('Price shown at purchase'), findsNWidgets(3));
  });

  testWidgets('restore tap triggers an explicit restore', (tester) async {
    /// The dialog flag is armed only while the restore call is in flight
    /// (disarmed on completion when no pro event consumes it) — capture it
    /// mid-flight via the gateway hook.
    bool? armedInFlight;
    gateway.onRestore = () =>
        armedInFlight = PurchaseBase.restoreTriggeredExplicitly;

    await pumpPaywall(tester, newStore()..init());

    await tester.ensureVisible(find.text('Restore purchases'));
    await tester.pump();
    await tester.tap(find.text('Restore purchases'));
    await tester.pump();

    expect(gateway.restoreCalls, 1);
    expect(armedInFlight, isTrue);
    expect(PurchaseBase.restoreTriggeredExplicitly, isFalse);
  });

  testWidgets('purchase event flips the paywall to the unlocked state',
      (tester) async {
    final ProStore store = newStore()..init();
    await pumpPaywall(tester, store);

    expect(find.text('Welcome to Pro'), findsNothing);

    /// What PurchaseBase does when the purchase stream reports
    /// purchased/restored. Real I/O via runAsync - an awaited Hive put
    /// never completes inside the fake-async zone
    await tester.runAsync(
      () => settingsBox().put(SettingsKeys.BoughtPro.name, true),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(store.isPro, isTrue);
    expect(find.text('Welcome to Pro'), findsOneWidget);
    expect(find.byType(ConfettiWidget), findsOneWidget);
    expect(find.text('Manage subscription'), findsOneWidget);
  });

  testWidgets('already-Pro renders the thank-you / manage state',
      (tester) async {
    await tester.runAsync(
      () => settingsBox().put(SettingsKeys.BoughtPro.name, true),
    );
    await pumpPaywall(tester, newStore()..init());

    expect(find.text('Welcome to Pro'), findsOneWidget);
    expect(find.text('Manage subscription'), findsOneWidget);

    /// No sales content in the unlocked state
    expect(find.text('Price shown at purchase'), findsNothing);
    expect(find.text('Restore purchases'), findsNothing);
  });

  testWidgets('long-press on the hero logo toggles the debug override '
      '(kDebugMode only - the gesture is not attached in release builds)',
      (tester) async {
    final ProStore store = newNoIoDebugStore()..init();
    await pumpPaywall(tester, store);

    /// The hero logo (the only GestureDetector inside the hero) carries
    /// the debug toggle
    await tester.longPress(
      find.descendant(
        of: find.byType(ProHero),
        matching: find.byType(GestureDetector),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(store.debugOverride, isTrue);
    expect(find.byType(SnackBar), findsOneWidget);

    /// The override flips the paywall to the unlocked state
    await tester.pump(const Duration(milliseconds: 600));
    expect(store.isPro, isTrue);
    expect(find.text('Welcome to Pro'), findsOneWidget);

    await flushSnackBar(tester);
  });

  testWidgets('tablet width composes the benefit grid instead of the '
      'carousel', (tester) async {
    await pumpPaywall(tester, newStore()..init(), width: 900.0);

    expect(find.byType(SmoothPageIndicator), findsNothing);
    expect(find.text('Native Twitch Chat'), findsOneWidget);
    expect(find.text('Native YouTube Chat'), findsOneWidget);
    expect(find.text('Phone-Native Moderation'), findsOneWidget);
    expect(find.text('What\'s Next'), findsOneWidget);
  });
}

/// [ProStore] whose debug override flips the observable directly instead
/// of going through the Hive put - that write is fire-and-forget real I/O
/// which never completes inside a testWidgets fake-async zone (the store's
/// Hive-writing path is covered by pro_store_test.dart)
class _NoIoDebugProStore extends ProStore {
  _NoIoDebugProStore({super.service});

  @override
  void setDebugOverride(bool value) {
    runInAction(() => this.debugOverride = value);
  }
}

/// [ProStore] whose restore never completes - keeps the paywall in the
/// restoring (pending) state so the pricing section's behavior during a
/// restore is assertable
class _HangingRestoreProStore extends ProStore {
  _HangingRestoreProStore({super.service});

  @override
  Future<void> restore({required bool explicit}) async {
    runInAction(() => this.pending = true);
  }
}
