// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'input_channel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_InputChannel _$InputChannelFromJson(Map<String, dynamic> json) =>
    _InputChannel(
      current: (json['current'] as num?)?.toDouble(),
      average: (json['average'] as num?)?.toDouble(),
      potential: (json['potential'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$InputChannelToJson(_InputChannel instance) =>
    <String, dynamic>{
      'current': instance.current,
      'average': instance.average,
      'potential': instance.potential,
    };
