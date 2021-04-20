// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hidden_scene.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiddenSceneAdapter extends TypeAdapter<HiddenScene> {
  @override
  final int typeId = 6;

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
      ..write(obj.ipAddress);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiddenSceneAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
