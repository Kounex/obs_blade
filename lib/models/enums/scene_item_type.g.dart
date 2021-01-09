// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scene_item_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SceneItemTypeAdapter extends TypeAdapter<SceneItemType> {
  @override
  final int typeId = 5;

  @override
  SceneItemType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SceneItemType.Source;
      case 1:
        return SceneItemType.Audio;
      default:
        return null;
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

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneItemTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
