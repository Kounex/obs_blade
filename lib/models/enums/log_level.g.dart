// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_level.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LogLevelAdapter extends TypeAdapter<LogLevel> {
  @override
  final int typeId = 8;

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

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LogLevelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
