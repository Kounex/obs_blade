// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchased_tip.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PurchasedTipAdapter extends TypeAdapter<PurchasedTip> {
  @override
  final int typeId = 9;

  @override
  PurchasedTip read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PurchasedTip(
      fields[0] as int,
      fields[1] as String,
      fields[2] as String,
      fields[3] as String,
      fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, PurchasedTip obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.timestampMS)
      ..writeByte(1)
      ..write(obj.id)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.price)
      ..writeByte(4)
      ..write(obj.currencySymbol);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchasedTipAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
