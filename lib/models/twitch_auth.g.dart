// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'twitch_auth.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TwitchAuthAdapter extends TypeAdapter<TwitchAuth> {
  @override
  final typeId = 13;

  @override
  TwitchAuth read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TwitchAuth(
      accessToken: fields[0] as String,
      refreshToken: fields[1] as String,
      expiresAtMs: (fields[2] as num).toInt(),
      scopes: (fields[3] as List).cast<String>(),
      userId: fields[4] as String?,
      userLogin: fields[5] as String?,
      userDisplayName: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TwitchAuth obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.accessToken)
      ..writeByte(1)
      ..write(obj.refreshToken)
      ..writeByte(2)
      ..write(obj.expiresAtMs)
      ..writeByte(3)
      ..write(obj.scopes)
      ..writeByte(4)
      ..write(obj.userId)
      ..writeByte(5)
      ..write(obj.userLogin)
      ..writeByte(6)
      ..write(obj.userDisplayName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TwitchAuthAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
