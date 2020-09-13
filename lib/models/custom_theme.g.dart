// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_theme.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CustomThemeAdapter extends TypeAdapter<CustomTheme> {
  @override
  final int typeId = 2;

  @override
  CustomTheme read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CustomTheme(
      fields[1] as String,
      fields[2] as String,
      fields[3] as bool,
      fields[4] as String,
      fields[5] as String,
      fields[6] as String,
      fields[7] as String,
      fields[8] as String,
      fields[9] as bool,
    )..uuid = fields[0] as String;
  }

  @override
  void write(BinaryWriter writer, CustomTheme obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.uuid)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.starred)
      ..writeByte(4)
      ..write(obj.primaryColorHex)
      ..writeByte(5)
      ..write(obj.accentColorHex)
      ..writeByte(6)
      ..write(obj.highlightColorHex)
      ..writeByte(7)
      ..write(obj.backgroundColorHex)
      ..writeByte(8)
      ..write(obj.textColorHex)
      ..writeByte(9)
      ..write(obj.useLightBrightness);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomThemeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
