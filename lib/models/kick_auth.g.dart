// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kick_auth.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class KickAuthAdapter extends TypeAdapter<KickAuth> {
  @override
  final typeId = 16;

  @override
  KickAuth read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return KickAuth(
      accessToken: fields[0] as String,
      refreshToken: fields[1] as String,
      expiresAtMs: (fields[2] as num).toInt(),
      scopes: (fields[3] as List).cast<String>(),
      userId: (fields[4] as num?)?.toInt(),
      username: fields[5] as String?,
      profilePicture: fields[6] as String?,
      channelSlug: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, KickAuth obj) {
    writer
      ..writeByte(8)
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
      ..write(obj.username)
      ..writeByte(6)
      ..write(obj.profilePicture)
      ..writeByte(7)
      ..write(obj.channelSlug);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KickAuthAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
