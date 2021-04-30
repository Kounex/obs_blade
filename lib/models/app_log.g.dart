// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppLogAdapter extends TypeAdapter<AppLog> {
  @override
  final int typeId = 7;

  @override
  AppLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppLog(
      fields[0] as int,
      fields[1] as LogLevel,
      fields[2] as String,
      fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AppLog obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.timestampMS)
      ..writeByte(1)
      ..write(obj.level)
      ..writeByte(2)
      ..write(obj.entry)
      ..writeByte(3)
      ..write(obj.stackTrace);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
