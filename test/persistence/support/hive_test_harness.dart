import 'dart:io';

import 'package:hive_ce/hive.dart';
import 'package:obs_blade/models/app_log.dart';
import 'package:obs_blade/models/connection.dart';
import 'package:obs_blade/models/custom_theme.dart';
import 'package:obs_blade/models/enums/chat_engine.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/models/enums/dashboard_element.dart';
import 'package:obs_blade/models/enums/log_level.dart';
import 'package:obs_blade/models/enums/scene_item_type.dart';
import 'package:obs_blade/models/hidden_scene.dart';
import 'package:obs_blade/models/hidden_scene_item.dart';
import 'package:obs_blade/models/hotkey.dart';
import 'package:obs_blade/models/past_record_data.dart';
import 'package:obs_blade/models/past_stream_data.dart';
import 'package:obs_blade/models/purchased_tip.dart';
import 'package:obs_blade/models/twitch_auth.dart';
import 'package:obs_blade/models/type_ids.dart';
import 'package:obs_blade/types/enums/hive_keys.dart';

import '../fixtures/foundation_data.dart';

/// Shared Hive setup for persistence tests (mirrors production box names).
class HiveTestHarness {
  HiveTestHarness(this.rootDir);

  final Directory rootDir;

  static void registerAllAdapters() {
    if (!Hive.isAdapterRegistered(TypeIDs.Connection)) {
      Hive.registerAdapter<Connection>(ConnectionAdapter());
    }
    if (!Hive.isAdapterRegistered(TypeIDs.PastStreamData)) {
      Hive.registerAdapter<PastStreamData>(PastStreamDataAdapter());
    }
    if (!Hive.isAdapterRegistered(TypeIDs.CustomTheme)) {
      Hive.registerAdapter<CustomTheme>(CustomThemeAdapter());
    }
    if (!Hive.isAdapterRegistered(TypeIDs.HiddenSceneItem)) {
      Hive.registerAdapter<HiddenSceneItem>(HiddenSceneItemAdapter());
    }
    if (!Hive.isAdapterRegistered(TypeIDs.ChatType)) {
      Hive.registerAdapter<ChatType>(ChatTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(TypeIDs.ChatEngine)) {
      Hive.registerAdapter<ChatEngine>(ChatEngineAdapter());
    }
    if (!Hive.isAdapterRegistered(TypeIDs.SceneItemType)) {
      Hive.registerAdapter<SceneItemType>(SceneItemTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(TypeIDs.HiddenScene)) {
      Hive.registerAdapter<HiddenScene>(HiddenSceneAdapter());
    }
    if (!Hive.isAdapterRegistered(TypeIDs.AppLog)) {
      Hive.registerAdapter<AppLog>(AppLogAdapter());
    }
    if (!Hive.isAdapterRegistered(TypeIDs.LogLevel)) {
      Hive.registerAdapter<LogLevel>(LogLevelAdapter());
    }
    if (!Hive.isAdapterRegistered(TypeIDs.PurchasedTip)) {
      Hive.registerAdapter<PurchasedTip>(PurchasedTipAdapter());
    }
    if (!Hive.isAdapterRegistered(TypeIDs.PastRecordData)) {
      Hive.registerAdapter<PastRecordData>(PastRecordDataAdapter());
    }
    if (!Hive.isAdapterRegistered(TypeIDs.Hotkey)) {
      Hive.registerAdapter<Hotkey>(HotkeyAdapter());
    }
    if (!Hive.isAdapterRegistered(TypeIDs.DashboardElement)) {
      Hive.registerAdapter<DashboardElement>(DashboardElementAdapter());
    }
    if (!Hive.isAdapterRegistered(TypeIDs.TwitchAuth)) {
      Hive.registerAdapter<TwitchAuth>(TwitchAuthAdapter());
    }
  }

  Future<void> init() async {
    if (!rootDir.existsSync()) {
      rootDir.createSync(recursive: true);
    }
    Hive.init(rootDir.path);
    registerAllAdapters();
  }

  Future<void> close() async {
    await Hive.close();
  }

  Future<void> openAllBoxes() async {
    await Hive.openBox<Connection>(HiveKeys.SavedConnections.name);
    await Hive.openBox<PastStreamData>(HiveKeys.PastStreamData.name);
    await Hive.openBox<PastRecordData>(HiveKeys.PastRecordData.name);
    await Hive.openBox<CustomTheme>(HiveKeys.CustomTheme.name);
    await Hive.openBox<HiddenSceneItem>(HiveKeys.HiddenSceneItem.name);
    await Hive.openBox<HiddenScene>(HiveKeys.HiddenScene.name);
    await Hive.openBox<AppLog>(HiveKeys.AppLog.name);
    await Hive.openBox<PurchasedTip>(HiveKeys.PurchasedTip.name);
    await Hive.openBox<Hotkey>(HiveKeys.Hotkey.name);
    await Hive.openBox(HiveKeys.Settings.name);
    await Hive.openBox<TwitchAuth>(HiveKeys.TwitchAuth.name);
  }

  /// Writes [data] into the production box names (clears existing entries).
  Future<void> seed(HiveFoundationData data) async {
    await openAllBoxes();

    Future<void> replaceAll<T>(String name, List<T> items) async {
      final box = Hive.box<T>(name);
      await box.clear();
      await box.addAll(items);
    }

    await replaceAll(HiveKeys.SavedConnections.name, data.connections);
    await replaceAll(HiveKeys.PastStreamData.name, data.pastStreams);
    await replaceAll(HiveKeys.PastRecordData.name, data.pastRecords);
    await replaceAll(HiveKeys.CustomTheme.name, data.themes);
    await replaceAll(HiveKeys.HiddenScene.name, data.hiddenScenes);
    await replaceAll(HiveKeys.HiddenSceneItem.name, data.hiddenSceneItems);
    await replaceAll(HiveKeys.AppLog.name, data.appLogs);
    await replaceAll(HiveKeys.PurchasedTip.name, data.purchasedTips);
    await replaceAll(HiveKeys.Hotkey.name, data.hotkeys);

    final settings = Hive.box(HiveKeys.Settings.name);
    await settings.clear();
    await settings.putAll(data.settings);

    // Force flush to disk so cold-open tests see durable files.
    await Future.wait([
      Hive.box<Connection>(HiveKeys.SavedConnections.name).flush(),
      Hive.box<PastStreamData>(HiveKeys.PastStreamData.name).flush(),
      Hive.box<PastRecordData>(HiveKeys.PastRecordData.name).flush(),
      Hive.box<CustomTheme>(HiveKeys.CustomTheme.name).flush(),
      Hive.box<HiddenScene>(HiveKeys.HiddenScene.name).flush(),
      Hive.box<HiddenSceneItem>(HiveKeys.HiddenSceneItem.name).flush(),
      Hive.box<AppLog>(HiveKeys.AppLog.name).flush(),
      Hive.box<PurchasedTip>(HiveKeys.PurchasedTip.name).flush(),
      Hive.box<Hotkey>(HiveKeys.Hotkey.name).flush(),
      Hive.box(HiveKeys.Settings.name).flush(),
    ]);
  }

  /// Close, re-init on the same directory, open all boxes again.
  Future<void> reopenFromDisk() async {
    await close();
    Hive.init(rootDir.path);
    registerAllAdapters();
    await openAllBoxes();
  }
}
