// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hidden_scene_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiddenSceneItemAdapter extends TypeAdapter<HiddenSceneItem> {
  @override
  final int typeId = 0;

  @override
  HiddenSceneItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiddenSceneItem(
      fields[0] as String,
      fields[1] as int,
      fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, HiddenSceneItem obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.sceneName)
      ..writeByte(1)
      ..write(obj.id)
      ..writeByte(2)
      ..write(obj.name);
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
