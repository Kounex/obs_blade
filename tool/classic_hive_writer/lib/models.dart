/// Minimal models mirroring OBS Blade Hive types (classic hive 2.2.3 only).
/// Field layouts must stay wire-compatible with production adapters.
library;

import 'package:hive/hive.dart';

enum ChatType { Twitch, YouTube, Owncast }

enum LogLevel { Info, Warning, Error }

enum SceneItemType { Source, Audio }

enum DashboardElement {
  ExposedProfile,
  ExposedControls,
  SceneButtons,
  StudioModeTransition,
  StudioModeConfig,
  ScenePreview,
  SceneItems,
  SceneItemsAudio,
  StreamChat,
  OBSStats,
}

class Connection extends HiveObject {
  String? name;
  String host;
  String? ssid;
  int? port;
  String? pw;
  bool? isDomain;

  Connection(this.host, this.port, [this.pw, this.isDomain]);
}

class PastStreamData extends HiveObject {
  List<int> kbitsPerSecList = [];
  List<double> fpsList = [];
  List<double> cpuUsageList = [];
  List<double> memoryUsageList = [];
  List<int> listEntryDateMS = [];
  double? strain;
  int? totalTime;
  int? numTotalFrames;
  int? numDroppedFrames;
  int? renderTotalFrames;
  int? renderSkippedFrames;
  int? outputTotalFrames;
  int? outputSkippedFrames;
  double? averageFrameTime;
  String? name;
  bool? starred;
  String? notes;
}

class PastRecordData extends HiveObject {
  List<int> kbitsPerSecList = [];
  List<double> fpsList = [];
  List<double> cpuUsageList = [];
  List<double> memoryUsageList = [];
  List<int> listEntryDateMS = [];
  int? totalTime;
  int? renderTotalFrames;
  int? renderSkippedFrames;
  int? outputTotalFrames;
  int? outputSkippedFrames;
  double? averageFrameTime;
  String? name;
  bool? starred;
  String? notes;
}

class CustomTheme extends HiveObject {
  String uuid;
  String? name;
  String? description;
  bool? starred;
  String cardColorHex;
  String appBarColorHex;
  String tabBarColorHex;
  String accentColorHex;
  String highlightColorHex;
  String backgroundColorHex;
  String? textColorHex;
  bool useLightBrightness;
  int dateCreatedMS;
  int? dateUpdatedMS;
  String? customLogo;
  String? logoAppBarColorHex;
  String? dividerColorHex;
  String? cardBorderColorHex;

  CustomTheme(
    this.name,
    this.description,
    this.starred,
    this.cardColorHex,
    this.appBarColorHex,
    this.tabBarColorHex,
    this.accentColorHex,
    this.highlightColorHex,
    this.backgroundColorHex,
    this.textColorHex,
    this.useLightBrightness, [
    String? uuid,
    int? dateCreatedMS,
  ])  : uuid = uuid ?? 'unset',
        dateCreatedMS = dateCreatedMS ?? 0;
}

class HiddenScene extends HiveObject {
  String sceneName;
  String? connectionName;
  String host;

  HiddenScene(this.sceneName, this.connectionName, this.host);
}

class HiddenSceneItem extends HiveObject {
  String sceneName;
  SceneItemType type;
  int? id;
  String name;
  String? sourceType;
  String? connectionName;
  String? host;

  HiddenSceneItem(
    this.sceneName,
    this.type,
    this.id,
    this.name,
    this.sourceType,
    this.connectionName,
    this.host,
  );
}

class AppLog extends HiveObject {
  int timestampMS;
  LogLevel level;
  String entry;
  String? stackTrace;
  bool manually;

  AppLog(this.timestampMS, this.level, this.entry,
      [this.stackTrace, this.manually = false]);
}

class PurchasedTip extends HiveObject {
  int timestampMS;
  String id;
  String name;
  String price;
  String currencySymbol;

  PurchasedTip(
      this.timestampMS, this.id, this.name, this.price, this.currencySymbol);
}

class Hotkey extends HiveObject {
  String name;

  Hotkey(this.name);
}

/// Production box names (must match obs_blade HiveKeys.name).
class BoxNames {
  static const savedConnections = 'saved-connections';
  static const pastStreamData = 'past-stream-data';
  static const pastRecordData = 'past-record-data';
  static const customTheme = 'custom-theme';
  static const hiddenSceneItem = 'hidden-scene-item';
  static const hiddenScene = 'hidden-scene';
  static const appLog = 'app-log';
  static const purchasedTip = 'purchased-tip';
  static const hotkey = 'hotkey';
  static const settings = 'settings';
}
