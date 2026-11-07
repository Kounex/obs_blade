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
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Connection(
        fields[1] as String,
        (fields[3] as num?)?.toInt(),
        fields[4] as String?,
        fields[5] as bool?,
      )
      ..name = fields[0] as String?
      ..ssid = fields[2] as String?
      ..lastConnectedMs = (fields[6] as num?)?.toInt()
      ..relayBridgeId = fields[7] as String?
      ..relayAppToken = fields[8] as String?
      ..relayDeviceId = fields[9] as String?
      ..relayBridgeName = fields[10] as String?
      ..relayBridgeKind = fields[11] as String?;
  }

  @override
  void write(BinaryWriter writer, Connection obj) {
    writer
      ..writeByte(12)
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
      ..write(obj.isDomain)
      ..writeByte(6)
      ..write(obj.lastConnectedMs)
      ..writeByte(7)
      ..write(obj.relayBridgeId)
      ..writeByte(8)
      ..write(obj.relayAppToken)
      ..writeByte(9)
      ..write(obj.relayDeviceId)
      ..writeByte(10)
      ..write(obj.relayBridgeName)
      ..writeByte(11)
      ..write(obj.relayBridgeKind);
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
