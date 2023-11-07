// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hotkey.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HotkeyAdapter extends TypeAdapter<Hotkey> {
  @override
  final int typeId = 11;

  @override
  Hotkey read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Hotkey(
      fields[0] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Hotkey obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.name);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HotkeyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
