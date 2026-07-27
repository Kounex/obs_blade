// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ConnectionAdapter extends TypeAdapter<Connection> {
  @override
  final int typeId = 0;

  @override
  Connection read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Connection(
      fields[1] as String,
      fields[3] as int?,
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

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
