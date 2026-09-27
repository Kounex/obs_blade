import 'dart:io';

import 'package:confetti/confetti.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobx/mobx.dart';
import 'package:obs_blade/shared/design/design.dart';
import 'package:obs_blade/stores/pro_store.dart';
import 'package:obs_blade/utils/pro_ids.dart';
import 'package:obs_blade/utils/pro_plan.dart';
import 'package:obs_blade/utils/pro_product.dart';
import 'package:obs_blade/utils/pro_purchase_service.dart';
import 'package:obs_blade/views/pro/widgets/pro_unlocked.dart';

import '../persistence/support/hive_test_harness.dart';
import 'support/fake_pro_purchase_backend.dart';

ThemeData _theme() => ThemeData(
  brightness: Brightness.dark,
  cupertinoOverrideTheme: const CupertinoThemeData(),
  buttonTheme: ButtonThemeData(
    colorScheme: ColorScheme.fromSwatch(accentColor: Colors.redAccent),
  ),
  extensions: const [AppStatusColors.standard, AppTextColors.standard],
);

const ProPlanState _monthly = ProPlanState(
  currentPlan: kProMonthlyId,
  renewingSubscription: kProMonthlyId,
  renewingSubscriptionStoreId: 'pro:pro-monthly',
);

void main() {
  late Directory tempDir;
  late HiveTestHarness harness;
  late FakeProPurchaseBackend backend;
  late ConfettiController confetti;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pro_plan_switch_test');
    harness = HiveTestHarness(tempDir);
    await harness.init();
    await harness.openAllBoxes();
    backend = FakeProPurchaseBackend();
    confetti = ConfettiController();
  });

  tearDown(() async {
    confetti.dispose();
    await backend.close();
    await harness.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<ProStore> pumpUnlocked(WidgetTester tester, ProPlanState plan) async {
    final ProStore store = ProStore(
      service: ProPurchaseService(backend: backend),
    );
    runInAction(() {
      store.plan = plan;
      store.products.addAll(const [
        ProProduct(id: kProYearlyId, title: 'Yearly', priceString: '€49.99'),
        ProProduct(id: kProMonthlyId, title: 'Monthly', priceString: '€4.99'),
        ProProduct(
          id: kProLifetimeId,
          title: 'Lifetime',
          priceString: '€99.99',
        ),
      ]);
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: _theme(),
        home: Scaffold(
          body: ProUnlockedView(store: store, confettiController: confetti),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    return store;
  }

  Finder switchTo(String plan) => find.byKey(Key('pro-switch-$plan'));
  final Finder cancelNotice = find.byKey(const Key('pro-cancel-subscription'));

  testWidgets('monthly subscribers can switch to yearly or lifetime', (
    tester,
  ) async {
    await pumpUnlocked(tester, _monthly);

    expect(switchTo(kProYearlyId), findsOneWidget);
    expect(switchTo(kProLifetimeId), findsOneWidget);
    expect(find.text('Switch to Yearly'), findsOneWidget);
    expect(find.text('Get Lifetime'), findsOneWidget);
    expect(
      find.textContaining('keeps renewing until you cancel it'),
      findsOneWidget,
    );
    expect(cancelNotice, findsNothing);
    expect(find.text('Manage subscription'), findsOneWidget);
  });

  testWidgets('yearly subscribers can only switch to lifetime', (tester) async {
    await pumpUnlocked(tester, const ProPlanState(currentPlan: kProYearlyId));

    expect(switchTo(kProYearlyId), findsNothing);
    expect(switchTo(kProLifetimeId), findsOneWidget);
  });

  testWidgets('lifetime with a renewing subscription says to cancel it', (
    tester,
  ) async {
    await pumpUnlocked(
      tester,
      const ProPlanState(
        currentPlan: kProLifetimeId,
        renewingSubscription: kProMonthlyId,
        renewingSubscriptionStoreId: kProMonthlyId,
      ),
    );

    expect(cancelNotice, findsOneWidget);
    expect(find.text('Cancel your monthly subscription'), findsOneWidget);
    expect(switchTo(kProLifetimeId), findsNothing);
    expect(find.text('Manage subscription'), findsOneWidget);
  });

  testWidgets('settled lifetime shows no switch and nothing to manage', (
    tester,
  ) async {
    await pumpUnlocked(tester, const ProPlanState(currentPlan: kProLifetimeId));

    expect(switchTo(kProYearlyId), findsNothing);
    expect(switchTo(kProLifetimeId), findsNothing);
    expect(cancelNotice, findsNothing);
    expect(find.text('Manage subscription'), findsNothing);
  });

  testWidgets('switching to yearly replaces the running subscription', (
    tester,
  ) async {
    /// A declined purchase skips the Hive mirror (real I/O never completes
    /// inside the fake-async zone) - the request itself is what counts
    backend.buyResult = false;
    await pumpUnlocked(tester, _monthly);

    await tester.ensureVisible(find.text('Switch to Yearly'));
    await tester.tap(find.text('Switch to Yearly'));
    await tester.pump();

    expect(backend.buyReplacing, ['pro:pro-monthly']);
  });
}
