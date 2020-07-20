// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SettingsAdapter extends TypeAdapter<Settings> {
  @override
  final typeId = 2;

  @override
  Settings read(BinaryReader reader) {
    var numOfFields = reader.readByte();
    var fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Settings()
      ..trueDark = fields[0] as bool
      ..reduceSmearing = fields[1] as bool
      ..enforceTabletMode = fields[2] as bool;
  }

  @override
  void write(BinaryWriter writer, Settings obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.trueDark)
      ..writeByte(1)
      ..write(obj.reduceSmearing)
      ..writeByte(2)
      ..write(obj.enforceTabletMode);
  }
}
