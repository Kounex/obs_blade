// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'past_stream_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PastStreamDataAdapter extends TypeAdapter<PastStreamData> {
  @override
  final int typeId = 1;

  @override
  PastStreamData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PastStreamData()
      ..kbitsPerSecList = (fields[0] as List)?.cast<int>()
      ..fpsList = (fields[1] as List)?.cast<double>()
      ..cpuUsageList = (fields[2] as List)?.cast<double>()
      ..strain = fields[3] as double
      ..totalStreamTime = fields[4] as int
      ..numTotalFrames = fields[5] as int
      ..numDroppedFrames = fields[6] as int
      ..renderTotalFrames = fields[7] as int
      ..renderMissedFrames = fields[8] as int
      ..outputTotalFrames = fields[9] as int
      ..outputSkippedFrames = fields[10] as int
      ..averageFrameTime = fields[11] as double
      ..streamEndedMS = fields[12] as int;
  }

  @override
  void write(BinaryWriter writer, PastStreamData obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.kbitsPerSecList)
      ..writeByte(1)
      ..write(obj.fpsList)
      ..writeByte(2)
      ..write(obj.cpuUsageList)
      ..writeByte(3)
      ..write(obj.strain)
      ..writeByte(4)
      ..write(obj.totalStreamTime)
      ..writeByte(5)
      ..write(obj.numTotalFrames)
      ..writeByte(6)
      ..write(obj.numDroppedFrames)
      ..writeByte(7)
      ..write(obj.renderTotalFrames)
      ..writeByte(8)
      ..write(obj.renderMissedFrames)
      ..writeByte(9)
      ..write(obj.outputTotalFrames)
      ..writeByte(10)
      ..write(obj.outputSkippedFrames)
      ..writeByte(11)
      ..write(obj.averageFrameTime)
      ..writeByte(12)
      ..write(obj.streamEndedMS);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PastStreamDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
