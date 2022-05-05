// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hidden_scene_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiddenSceneItemAdapter extends TypeAdapter<HiddenSceneItem> {
  @override
  final int typeId = 3;

  @override
  HiddenSceneItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiddenSceneItem(
      fields[0] as String,
      fields[1] as SceneItemType,
      fields[2] as int?,
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

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiddenSceneItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
