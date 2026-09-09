import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:mobx/mobx.dart';

import '../models/enums/log_level.dart';
import '../purchase_base.dart';
import '../types/enums/hive_keys.dart';
import '../types/enums/settings_keys.dart';
import '../utils/general_helper.dart';
import '../utils/pro_product.dart';
import '../utils/pro_purchase_service.dart';

part 'pro_store.g.dart';

class ProStore = _ProStore with _$ProStore;

/// Entitlement store for "Pro" (subscription pair + lifetime buy-out).
///
/// Two purchase backends sit behind [ProPurchaseService] (selection:
/// RevenueCat when configured — keys in `revenuecat_config.dart` — else
/// the legacy direct-`in_app_purchase` path):
///
/// - **RevenueCat (handlesEntitlement):** truth is the `pro` entitlement
///   in RevenueCat's `CustomerInfo` — expiry/renewal tracked server-side,
///   closing the legacy path's documented lapsed-subscription blind spot.
///   The state is mirrored into the `BoughtPro` settings flag for
///   offline/fast boot (RC's cached CustomerInfo stays the truth and
///   overwrites the mirror on every fetch/update). Reinstall recovery is
///   RC's job (CustomerInfo cache + restore) — the cold-start restore
///   below does NOT run on this path.
/// - **Legacy:** truth = the `BoughtPro` flag in the settings box,
///   written by [PurchaseBase] on purchased/restored purchase-stream
///   events (plus a once-per-install cold-start restore fired from
///   [init]). Lapsed subscription enforcement is NOT solvable here —
///   server-side receipt validation (or flipping on RevenueCat) is the
///   answer.
abstract class _ProStore with Store {
  final ProPurchaseService _service;

  StreamSubscription<BoxEvent>? _settingsSubscription;

  StreamSubscription<bool>? _entitlementSubscription;

  _ProStore({ProPurchaseService? service})
    : this._service = service ?? ProPurchaseService();

  @observable
  bool boughtPro = false;

  /// Debug-only unlock (settings key `ProDebugOverride`) — consumed ONLY
  /// under `kDebugMode` so it can never grant the entitlement in release.
  @observable
  bool debugOverride = false;

  @computed
  bool get isPro => this.boughtPro || (kDebugMode && this.debugOverride);

  /// Live store products for the paywall — empty while the products don't
  /// exist store-side (graceful placeholder state), loaded lazily via
  /// [loadProducts].
  final ObservableList<ProProduct> products = ObservableList();

  @observable
  bool pending = false;

  @observable
  String? lastError;

  /// True once the first [loadProducts] completed — distinguishes the
  /// initial product load (paywall shows skeleton rows) from later pending
  /// states like a restore, where the current pricing cards stay put.
  @observable
  bool productsLoaded = false;

  /// Fire-and-forget — backend init / cold-start restore must not block
  /// store creation.
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
    /// `BoughtPro` from the purchase stream on the legacy path; the
    /// RevenueCat path mirrors its entitlement into the same key).
    this._settingsSubscription = settingsBox.watch().listen((event) {
      if (event.key == SettingsKeys.BoughtPro.name) {
        runInAction(() => this.boughtPro = event.value as bool? ?? false);
      } else if (event.key == SettingsKeys.ProDebugOverride.name) {
        runInAction(() => this.debugOverride = event.value as bool? ?? false);
      }
    });

    if (this._service.handlesEntitlement) {
      this._initRevenueCat();
    } else {
      this._coldStartRestore();
    }
  }

  void dispose() {
    this._settingsSubscription?.cancel();
    this._entitlementSubscription?.cancel();
  }

  /// RevenueCat path: configure the SDK, then fetch + subscribe the
  /// entitlement, mirroring every result into the `BoughtPro` flag so
  /// [isPro] (and the offline/fast-boot state) rides one mechanism on
  /// both paths. RC's CustomerInfo is the truth — the mirror never
  /// outranks a fetch/update.
  Future<void> _initRevenueCat() async {
    try {
      await this._service.init();
      await this._mirrorEntitlement();
      this._entitlementSubscription = this._service.proEntitlementStream.listen(
        (bool active) {
          Hive.box<dynamic>(
            HiveKeys.Settings.name,
          ).put(SettingsKeys.BoughtPro.name, active);
        },
      );
    } catch (e) {
      GeneralHelper.advLog(
        'RevenueCat pro init failed — $e',
        includeInLogs: true,
        level: LogLevel.Error,
      );
    }
  }

  Future<void> _mirrorEntitlement() async {
    try {
      final bool? active = await this._service.fetchProEntitlement();
      if (active == null) return;
      await Hive.box<dynamic>(
        HiveKeys.Settings.name,
      ).put(SettingsKeys.BoughtPro.name, active);
    } catch (e) {
      /// Offline before RC's cache warmed, SDK error mid-session — keep
      /// the last mirrored state, the next update retries.
      GeneralHelper.advLog(
        'RevenueCat entitlement fetch failed — $e',
        includeInLogs: true,
        level: LogLevel.Error,
      );
    }
  }

  /// LEGACY path only (RevenueCat recovers reinstalls itself).
  ///
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
  Future<bool> buy(ProProduct product) async {
    this.pending = true;
    this.lastError = null;
    try {
      final bool bought = await this._service.buy(product);

      /// RevenueCat reports the entitlement synchronously on purchase —
      /// mirror it now instead of waiting for the CustomerInfo listener.
      /// (Legacy path: the purchase stream event sets the flag.)
      if (bought && this._service.handlesEntitlement) {
        await Hive.box<dynamic>(
          HiveKeys.Settings.name,
        ).put(SettingsKeys.BoughtPro.name, true);
      }
      return bought;
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
  /// to show the restored InfoDialog on the LEGACY path (the restored pro
  /// event consumes it). The flag is armed only for the duration of the
  /// restore call — if the restore completes without one (nothing to
  /// restore), it is disarmed here so a later spontaneous `restored` event
  /// can't show the dialog unprovoked.
  ///
  /// RevenueCat path: no purchase-stream event exists, so an explicit
  /// restore that comes back with an active entitlement shows the same
  /// dialog directly. The explicit restore also fires a direct-IAP
  /// plugin restore alongside — blacksmith (legacy, restore-only) is not
  /// part of the RC entitlement and its restored events only surface on
  /// the plugin stream handled by [PurchaseBase].
  @action
  Future<void> restore({required bool explicit}) async {
    this.pending = true;
    this.lastError = null;
    if (explicit) {
      PurchaseBase.restoreTriggeredExplicitly = true;
    }
    try {
      final bool restoredActive = await this._service.restore();
      if (explicit && this._service.handlesEntitlement) {
        /// RC's restore syncs only the pro entitlement — blacksmith (no
        /// longer sold, restore-only for legacy buyers) restores arrive
        /// on the direct IAP stream, so fire the plugin restore
        /// alongside. [PurchaseBase] picks the restored event up, sets
        /// `BoughtBlacksmith` and shows its own restored dialog. A
        /// failing plugin restore must not mask the pro restore result.
        try {
          await this._service.restoreLegacyPurchases();
        } catch (e) {
          GeneralHelper.advLog(
            'Legacy IAP restore failed — $e',
            includeInLogs: true,
            level: LogLevel.Error,
          );
        }
        if (restoredActive) {
          await Hive.box<dynamic>(
            HiveKeys.Settings.name,
          ).put(SettingsKeys.BoughtPro.name, true);
          showProRestoredDialog();
        }
      }
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
    Hive.box<dynamic>(
      HiveKeys.Settings.name,
    ).put(SettingsKeys.ProDebugOverride.name, value);
  }
}
