import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mobx/mobx.dart';

import '../models/enums/log_level.dart';
import '../purchase_base.dart';
import '../types/enums/hive_keys.dart';
import '../types/enums/settings_keys.dart';
import '../utils/general_helper.dart';
import '../utils/pro_purchase_service.dart';

part 'pro_store.g.dart';

class ProStore = _ProStore with _$ProStore;

/// Entitlement store for "Pro" (subscription pair + lifetime buy-out).
///
/// Truth = the `BoughtPro` flag in the settings box, written by
/// [PurchaseBase] on purchased/restored purchase-stream events (plus a
/// once-per-install cold-start restore fired from [init]). Lapsed
/// subscription enforcement is NOT solvable client-side with
/// `in_app_purchase` — documented limitation; server-side receipt
/// validation is the backend wave's job.
abstract class _ProStore with Store {
  final ProPurchaseService _service;

  StreamSubscription<BoxEvent>? _settingsSubscription;

  _ProStore({ProPurchaseService? service})
      : this._service = service ?? ProPurchaseService();

  @observable
  bool boughtPro = false;

  /// Debug-only unlock (settings key `ProDebugOverride`) — consumed ONLY
  /// under `kDebugMode` so it can never grant the entitlement in release.
  @observable
  bool debugOverride = false;

  @computed
  bool get isPro =>
      this.boughtPro || (kDebugMode && this.debugOverride);

  /// Live store products for the paywall — empty while the products don't
  /// exist store-side (graceful placeholder state), loaded lazily via
  /// [loadProducts].
  final ObservableList<ProductDetails> products = ObservableList();

  @observable
  bool pending = false;

  @observable
  String? lastError;

  /// True once the first [loadProducts] completed — distinguishes the
  /// initial product load (paywall shows skeleton rows) from later pending
  /// states like a restore, where the current pricing cards stay put.
  @observable
  bool productsLoaded = false;

  /// Fire-and-forget — cold-start restore must not block store creation.
  void init() {
    Box<dynamic> settingsBox = Hive.box<dynamic>(HiveKeys.Settings.name);
    this.boughtPro = settingsBox.get(
      SettingsKeys.BoughtPro.name,
      defaultValue: false,
    );
    this.debugOverride = settingsBox.get(
      SettingsKeys.ProDebugOverride.name,
      defaultValue: false,
    );

    /// Keep the observables in sync with box writes ([PurchaseBase] sets
    /// `BoughtPro` from the purchase stream).
    this._settingsSubscription = settingsBox.watch().listen((event) {
      if (event.key == SettingsKeys.BoughtPro.name) {
        runInAction(
            () => this.boughtPro = event.value as bool? ?? false);
      } else if (event.key == SettingsKeys.ProDebugOverride.name) {
        runInAction(
            () => this.debugOverride = event.value as bool? ?? false);
      }
    });

    this._coldStartRestore();
  }

  void dispose() {
    this._settingsSubscription?.cancel();
  }

  /// Reinstall recovery: `queryPastPurchases` was removed in
  /// in_app_purchase 3.3.0, so the only way to pick up past purchases on a
  /// fresh install is one guarded `restorePurchases()` per install. The
  /// restored events arrive on the purchase stream and set `BoughtPro`
  /// silently (no dialog — that's reserved for the explicit restore).
  Future<void> _coldStartRestore() async {
    Box<dynamic> settingsBox = Hive.box<dynamic>(HiveKeys.Settings.name);
    if (settingsBox.get(
      SettingsKeys.ProColdStartRestoreDone.name,
      defaultValue: false,
    )) {
      return;
    }

    try {
      /// Don't burn the one shot while the store is unreachable (desktop,
      /// no network) — the next launch retries.
      if (!await this._service.isStoreAvailable()) return;

      await this._service.restore();

      /// Mark the shot spent only AFTER a successful restore — a transient
      /// restore error must not burn the once-per-install recovery this
      /// exists for; the next launch retries.
      await settingsBox.put(SettingsKeys.ProColdStartRestoreDone.name, true);
    } catch (e) {
      GeneralHelper.advLog(
        'Pro cold-start restore failed — $e',
        includeInLogs: true,
        level: LogLevel.Error,
      );
    }
  }

  @action
  Future<void> loadProducts() async {
    this.pending = true;
    this.lastError = null;
    try {
      if (!await this._service.isStoreAvailable()) {
        this.lastError = 'store-unavailable';
        return;
      }
      this.products
        ..clear()
        ..addAll(await this._service.queryProProducts());
    } catch (e) {
      GeneralHelper.advLog(
        'Pro product query failed — $e',
        includeInLogs: true,
        level: LogLevel.Error,
      );
      this.lastError = e.toString();
    } finally {
      this.productsLoaded = true;
      this.pending = false;
    }
  }

  @action
  Future<bool> buy(ProductDetails product) async {
    this.pending = true;
    this.lastError = null;
    try {
      return await this._service.buy(product);
    } catch (e) {
      GeneralHelper.advLog(
        'Pro purchase failed — $e',
        includeInLogs: true,
        level: LogLevel.Error,
      );
      this.lastError = e.toString();
      return false;
    } finally {
      this.pending = false;
    }
  }

  /// Explicit restore (paywall button): sets the flag [PurchaseBase] reads
  /// to show the restored InfoDialog. The cold-start restore never sets it.
  /// The flag is armed only for the duration of the restore call — a
  /// restored pro event consumes it ([PurchaseBase._handlePurchase]), and
  /// if the restore completes without one (nothing to restore), it is
  /// disarmed here so a later spontaneous `restored` event can't show the
  /// dialog unprovoked.
  @action
  Future<void> restore({required bool explicit}) async {
    this.pending = true;
    this.lastError = null;
    if (explicit) {
      PurchaseBase.restoreTriggeredExplicitly = true;
    }
    try {
      await this._service.restore();
    } catch (e) {
      GeneralHelper.advLog(
        'Pro restore failed — $e',
        includeInLogs: true,
        level: LogLevel.Error,
      );
      this.lastError = e.toString();
    } finally {
      if (explicit) {
        PurchaseBase.restoreTriggeredExplicitly = false;
      }
      this.pending = false;
    }
  }

  /// Hidden debug toggle (paywall long-press / settings) — no-op in
  /// release builds.
  @action
  void setDebugOverride(bool value) {
    if (!kDebugMode) return;
    Hive.box<dynamic>(HiveKeys.Settings.name).put(
      SettingsKeys.ProDebugOverride.name,
      value,
    );
  }
}
