// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_engine.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChatEngineAdapter extends TypeAdapter<ChatEngine> {
  @override
  final typeId = 14;

  @override
  ChatEngine read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ChatEngine.webView;
      case 1:
        return ChatEngine.native;
      default:
        return ChatEngine.webView;
    }
  }

  @override
  void write(BinaryWriter writer, ChatEngine obj) {
    switch (obj) {
      case ChatEngine.webView:
        writer.writeByte(0);
      case ChatEngine.native:
        writer.writeByte(1);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatEngineAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
