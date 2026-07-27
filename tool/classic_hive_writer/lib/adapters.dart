/// Hand-ported TypeAdapters matching obs_blade generated adapters (typeIds + fields).
library;

import 'package:hive/hive.dart';

import 'models.dart';

void registerAllClassicAdapters() {
  Hive.registerAdapter(ConnectionAdapter());
  Hive.registerAdapter(PastStreamDataAdapter());
  Hive.registerAdapter(CustomThemeAdapter());
  Hive.registerAdapter(HiddenSceneItemAdapter());
  Hive.registerAdapter(ChatTypeAdapter());
  Hive.registerAdapter(SceneItemTypeAdapter());
  Hive.registerAdapter(HiddenSceneAdapter());
  Hive.registerAdapter(AppLogAdapter());
  Hive.registerAdapter(LogLevelAdapter());
  Hive.registerAdapter(PurchasedTipAdapter());
  Hive.registerAdapter(PastRecordDataAdapter());
  Hive.registerAdapter(HotkeyAdapter());
  Hive.registerAdapter(DashboardElementAdapter());
}

class ConnectionAdapter extends TypeAdapter<Connection> {
  @override
  final typeId = 0;

  @override
  Connection read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Connection(
      fields[1] as String,
      (fields[3] as num?)?.toInt(),
      fields[4] as String?,
      fields[5] as bool?,
    )
      ..name = fields[0] as String?
      ..ssid = fields[2] as String?;
  }

  @override
  void write(BinaryWriter writer, Connection obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.host)
      ..writeByte(2)
      ..write(obj.ssid)
      ..writeByte(3)
      ..write(obj.port)
      ..writeByte(4)
      ..write(obj.pw)
      ..writeByte(5)
      ..write(obj.isDomain);
  }
}

class PastStreamDataAdapter extends TypeAdapter<PastStreamData> {
  @override
  final typeId = 1;

  @override
  PastStreamData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PastStreamData()
      ..kbitsPerSecList = (fields[0] as List).cast<int>()
      ..fpsList = (fields[1] as List).cast<double>()
      ..cpuUsageList = (fields[2] as List).cast<double>()
      ..strain = (fields[3] as num?)?.toDouble()
      ..totalTime = (fields[4] as num?)?.toInt()
      ..numTotalFrames = (fields[5] as num?)?.toInt()
      ..numDroppedFrames = (fields[6] as num?)?.toInt()
      ..renderTotalFrames = (fields[7] as num?)?.toInt()
      ..renderSkippedFrames = (fields[8] as num?)?.toInt()
      ..outputTotalFrames = (fields[9] as num?)?.toInt()
      ..outputSkippedFrames = (fields[10] as num?)?.toInt()
      ..averageFrameTime = (fields[11] as num?)?.toDouble()
      ..name = fields[13] as String?
      ..starred = fields[14] as bool?
      ..notes = fields[15] as String?
      ..memoryUsageList = (fields[17] as List).cast<double>()
      ..listEntryDateMS = (fields[18] as List).cast<int>();
  }

  @override
  void write(BinaryWriter writer, PastStreamData obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.kbitsPerSecList)
      ..writeByte(1)
      ..write(obj.fpsList)
      ..writeByte(2)
      ..write(obj.cpuUsageList)
      ..writeByte(3)
      ..write(obj.strain)
      ..writeByte(4)
      ..write(obj.totalTime)
      ..writeByte(5)
      ..write(obj.numTotalFrames)
      ..writeByte(6)
      ..write(obj.numDroppedFrames)
      ..writeByte(7)
      ..write(obj.renderTotalFrames)
      ..writeByte(8)
      ..write(obj.renderSkippedFrames)
      ..writeByte(9)
      ..write(obj.outputTotalFrames)
      ..writeByte(10)
      ..write(obj.outputSkippedFrames)
      ..writeByte(11)
      ..write(obj.averageFrameTime)
      ..writeByte(13)
      ..write(obj.name)
      ..writeByte(14)
      ..write(obj.starred)
      ..writeByte(15)
      ..write(obj.notes)
      ..writeByte(17)
      ..write(obj.memoryUsageList)
      ..writeByte(18)
      ..write(obj.listEntryDateMS);
  }
}

class CustomThemeAdapter extends TypeAdapter<CustomTheme> {
  @override
  final typeId = 2;

  @override
  CustomTheme read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CustomTheme(
      fields[1] as String?,
      fields[2] as String?,
      fields[3] as bool?,
      fields[4] as String,
      fields[5] as String,
      fields[6] as String,
      fields[7] as String,
      fields[8] as String,
      fields[9] as String,
      fields[10] as String?,
      fields[11] as bool,
      fields[0] as String?,
      (fields[12] as num?)?.toInt(),
    )
      ..dateUpdatedMS = (fields[13] as num?)?.toInt()
      ..customLogo = fields[14] as String?
      ..logoAppBarColorHex = fields[15] as String?
      ..dividerColorHex = fields[16] as String?
      ..cardBorderColorHex = fields[17] as String?;
  }

  @override
  void write(BinaryWriter writer, CustomTheme obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.uuid)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.starred)
      ..writeByte(4)
      ..write(obj.cardColorHex)
      ..writeByte(5)
      ..write(obj.appBarColorHex)
      ..writeByte(6)
      ..write(obj.tabBarColorHex)
      ..writeByte(7)
      ..write(obj.accentColorHex)
      ..writeByte(8)
      ..write(obj.highlightColorHex)
      ..writeByte(9)
      ..write(obj.backgroundColorHex)
      ..writeByte(10)
      ..write(obj.textColorHex)
      ..writeByte(11)
      ..write(obj.useLightBrightness)
      ..writeByte(12)
      ..write(obj.dateCreatedMS)
      ..writeByte(13)
      ..write(obj.dateUpdatedMS)
      ..writeByte(14)
      ..write(obj.customLogo)
      ..writeByte(15)
      ..write(obj.logoAppBarColorHex)
      ..writeByte(16)
      ..write(obj.dividerColorHex)
      ..writeByte(17)
      ..write(obj.cardBorderColorHex);
  }
}

class HiddenSceneItemAdapter extends TypeAdapter<HiddenSceneItem> {
  @override
  final typeId = 3;

  @override
  HiddenSceneItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiddenSceneItem(
      fields[0] as String,
      fields[1] as SceneItemType,
      (fields[2] as num?)?.toInt(),
      fields[3] as String,
      fields[4] as String?,
      fields[5] as String?,
      fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, HiddenSceneItem obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.sceneName)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.id)
      ..writeByte(3)
      ..write(obj.name)
      ..writeByte(4)
      ..write(obj.sourceType)
      ..writeByte(5)
      ..write(obj.connectionName)
      ..writeByte(6)
      ..write(obj.host);
  }
}

class ChatTypeAdapter extends TypeAdapter<ChatType> {
  @override
  final typeId = 4;

  @override
  ChatType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ChatType.Twitch;
      case 1:
        return ChatType.YouTube;
      case 2:
        return ChatType.Owncast;
      default:
        return ChatType.Twitch;
    }
  }

  @override
  void write(BinaryWriter writer, ChatType obj) {
    switch (obj) {
      case ChatType.Twitch:
        writer.writeByte(0);
        break;
      case ChatType.YouTube:
        writer.writeByte(1);
        break;
      case ChatType.Owncast:
        writer.writeByte(2);
        break;
    }
  }
}

class SceneItemTypeAdapter extends TypeAdapter<SceneItemType> {
  @override
  final typeId = 5;

  @override
  SceneItemType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SceneItemType.Source;
      case 1:
        return SceneItemType.Audio;
      default:
        return SceneItemType.Source;
    }
  }

  @override
  void write(BinaryWriter writer, SceneItemType obj) {
    switch (obj) {
      case SceneItemType.Source:
        writer.writeByte(0);
        break;
      case SceneItemType.Audio:
        writer.writeByte(1);
        break;
    }
  }
}

class HiddenSceneAdapter extends TypeAdapter<HiddenScene> {
  @override
  final typeId = 6;

  @override
  HiddenScene read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiddenScene(
      fields[0] as String,
      fields[1] as String?,
      fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, HiddenScene obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.sceneName)
      ..writeByte(1)
      ..write(obj.connectionName)
      ..writeByte(2)
      ..write(obj.host);
  }
}

class AppLogAdapter extends TypeAdapter<AppLog> {
  @override
  final typeId = 7;

  @override
  AppLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppLog(
      (fields[0] as num).toInt(),
      fields[1] as LogLevel,
      fields[2] as String,
      fields[3] as String?,
      fields[4] == null ? false : fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AppLog obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.timestampMS)
      ..writeByte(1)
      ..write(obj.level)
      ..writeByte(2)
      ..write(obj.entry)
      ..writeByte(3)
      ..write(obj.stackTrace)
      ..writeByte(4)
      ..write(obj.manually);
  }
}

class LogLevelAdapter extends TypeAdapter<LogLevel> {
  @override
  final typeId = 8;

  @override
  LogLevel read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return LogLevel.Info;
      case 1:
        return LogLevel.Warning;
      case 2:
        return LogLevel.Error;
      default:
        return LogLevel.Info;
    }
  }

  @override
  void write(BinaryWriter writer, LogLevel obj) {
    switch (obj) {
      case LogLevel.Info:
        writer.writeByte(0);
        break;
      case LogLevel.Warning:
        writer.writeByte(1);
        break;
      case LogLevel.Error:
        writer.writeByte(2);
        break;
    }
  }
}

class PurchasedTipAdapter extends TypeAdapter<PurchasedTip> {
  @override
  final typeId = 9;

  @override
  PurchasedTip read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PurchasedTip(
      (fields[0] as num).toInt(),
      fields[1] as String,
      fields[2] as String,
      fields[3] as String,
      fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, PurchasedTip obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.timestampMS)
      ..writeByte(1)
      ..write(obj.id)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.price)
      ..writeByte(4)
      ..write(obj.currencySymbol);
  }
}

class PastRecordDataAdapter extends TypeAdapter<PastRecordData> {
  @override
  final typeId = 10;

  @override
  PastRecordData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PastRecordData()
      ..kbitsPerSecList = (fields[0] as List).cast<int>()
      ..fpsList = (fields[1] as List).cast<double>()
      ..cpuUsageList = (fields[2] as List).cast<double>()
      ..memoryUsageList = (fields[3] as List).cast<double>()
      ..listEntryDateMS = (fields[4] as List).cast<int>()
      ..totalTime = (fields[5] as num?)?.toInt()
      ..renderTotalFrames = (fields[6] as num?)?.toInt()
      ..renderSkippedFrames = (fields[7] as num?)?.toInt()
      ..outputTotalFrames = (fields[8] as num?)?.toInt()
      ..outputSkippedFrames = (fields[9] as num?)?.toInt()
      ..averageFrameTime = (fields[10] as num?)?.toDouble()
      ..name = fields[11] as String?
      ..starred = fields[12] as bool?
      ..notes = fields[13] as String?;
  }

  @override
  void write(BinaryWriter writer, PastRecordData obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.kbitsPerSecList)
      ..writeByte(1)
      ..write(obj.fpsList)
      ..writeByte(2)
      ..write(obj.cpuUsageList)
      ..writeByte(3)
      ..write(obj.memoryUsageList)
      ..writeByte(4)
      ..write(obj.listEntryDateMS)
      ..writeByte(5)
      ..write(obj.totalTime)
      ..writeByte(6)
      ..write(obj.renderTotalFrames)
      ..writeByte(7)
      ..write(obj.renderSkippedFrames)
      ..writeByte(8)
      ..write(obj.outputTotalFrames)
      ..writeByte(9)
      ..write(obj.outputSkippedFrames)
      ..writeByte(10)
      ..write(obj.averageFrameTime)
      ..writeByte(11)
      ..write(obj.name)
      ..writeByte(12)
      ..write(obj.starred)
      ..writeByte(13)
      ..write(obj.notes);
  }
}

class HotkeyAdapter extends TypeAdapter<Hotkey> {
  @override
  final typeId = 11;

  @override
  Hotkey read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Hotkey(fields[0] as String);
  }

  @override
  void write(BinaryWriter writer, Hotkey obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.name);
  }
}

class DashboardElementAdapter extends TypeAdapter<DashboardElement> {
  @override
  final typeId = 12;

  @override
  DashboardElement read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DashboardElement.ExposedProfile;
      case 1:
        return DashboardElement.ExposedControls;
      case 2:
        return DashboardElement.SceneButtons;
      case 3:
        return DashboardElement.StudioModeTransition;
      case 4:
        return DashboardElement.StudioModeConfig;
      case 5:
        return DashboardElement.ScenePreview;
      case 6:
        return DashboardElement.SceneItems;
      case 7:
        return DashboardElement.SceneItemsAudio;
      case 8:
        return DashboardElement.StreamChat;
      case 9:
        return DashboardElement.OBSStats;
      default:
        return DashboardElement.ExposedProfile;
    }
  }

  @override
  void write(BinaryWriter writer, DashboardElement obj) {
    switch (obj) {
      case DashboardElement.ExposedProfile:
        writer.writeByte(0);
        break;
      case DashboardElement.ExposedControls:
        writer.writeByte(1);
        break;
      case DashboardElement.SceneButtons:
        writer.writeByte(2);
        break;
      case DashboardElement.StudioModeTransition:
        writer.writeByte(3);
        break;
      case DashboardElement.StudioModeConfig:
        writer.writeByte(4);
        break;
      case DashboardElement.ScenePreview:
        writer.writeByte(5);
        break;
      case DashboardElement.SceneItems:
        writer.writeByte(6);
        break;
      case DashboardElement.SceneItemsAudio:
        writer.writeByte(7);
        break;
      case DashboardElement.StreamChat:
        writer.writeByte(8);
        break;
      case DashboardElement.OBSStats:
        writer.writeByte(9);
        break;
    }
  }
}
