// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'youtube_auth.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class YouTubeAuthAdapter extends TypeAdapter<YouTubeAuth> {
  @override
  final typeId = 15;

  @override
  YouTubeAuth read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return YouTubeAuth(
      accessToken: fields[0] as String,
      refreshToken: fields[1] as String,
      expiresAtMs: (fields[2] as num).toInt(),
      scopes: (fields[3] as List).cast<String>(),
      channelTitle: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, YouTubeAuth obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.accessToken)
      ..writeByte(1)
      ..write(obj.refreshToken)
      ..writeByte(2)
      ..write(obj.expiresAtMs)
      ..writeByte(3)
      ..write(obj.scopes)
      ..writeByte(4)
      ..write(obj.channelTitle);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is YouTubeAuthAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
