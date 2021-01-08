// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChatTypeAdapter extends TypeAdapter<ChatType> {
  @override
  final int typeId = 0;

  @override
  ChatType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ChatType.Twitch;
      case 1:
        return ChatType.YouTube;
      default:
        return null;
    }
  }

  @override
  void write(BinaryWriter writer, ChatType obj) {
    switch (obj) {
      case ChatType.Twitch:
        writer.writeByte(0);
        break;
      case ChatType.YouTube:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
