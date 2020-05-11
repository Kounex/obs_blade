// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ConnectionAdapter extends TypeAdapter<Connection> {
  @override
  final typeId = 0;

  @override
  Connection read(BinaryReader reader) {
    var numOfFields = reader.readByte();
    var fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Connection(
      fields[1] as String,
      fields[3] as int,
      fields[4] as String,
    )
      ..name = fields[0] as String
      ..ssid = fields[2] as String;
  }

  @override
  void write(BinaryWriter writer, Connection obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.ip)
      ..writeByte(2)
      ..write(obj.ssid)
      ..writeByte(3)
      ..write(obj.port)
      ..writeByte(4)
      ..write(obj.pw);
  }
}
