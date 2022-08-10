// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'past_record_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PastRecordDataAdapter extends TypeAdapter<PastRecordData> {
  @override
  final int typeId = 10;

  @override
  PastRecordData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PastRecordData()
      ..kbitsPerSecList = (fields[0] as List).cast<int>()
      ..fpsList = (fields[1] as List).cast<double>()
      ..cpuUsageList = (fields[2] as List).cast<double>()
      ..memoryUsageList = (fields[3] as List).cast<double>()
      ..listEntryDateMS = (fields[4] as List).cast<int>()
      ..totalRecordTime = fields[5] as int?
      ..renderTotalFrames = fields[6] as int?
      ..renderMissedFrames = fields[7] as int?
      ..averageFrameTime = fields[8] as double?
      ..name = fields[9] as String?
      ..starred = fields[10] as bool?
      ..notes = fields[11] as String?;
  }

  @override
  void write(BinaryWriter writer, PastRecordData obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.kbitsPerSecList)
      ..writeByte(1)
      ..write(obj.fpsList)
      ..writeByte(2)
      ..write(obj.cpuUsageList)
      ..writeByte(3)
      ..write(obj.memoryUsageList)
      ..writeByte(4)
      ..write(obj.listEntryDateMS)
      ..writeByte(5)
      ..write(obj.totalRecordTime)
      ..writeByte(6)
      ..write(obj.renderTotalFrames)
      ..writeByte(7)
      ..write(obj.renderMissedFrames)
      ..writeByte(8)
      ..write(obj.averageFrameTime)
      ..writeByte(9)
      ..write(obj.name)
      ..writeByte(10)
      ..write(obj.starred)
      ..writeByte(11)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PastRecordDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
