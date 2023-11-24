// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'input_channel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$InputChannelImpl _$$InputChannelImplFromJson(Map<String, dynamic> json) =>
    _$InputChannelImpl(
      current: (json['current'] as num?)?.toDouble(),
      average: (json['average'] as num?)?.toDouble(),
      potential: (json['potential'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$$InputChannelImplToJson(_$InputChannelImpl instance) =>
    <String, dynamic>{
      'current': instance.current,
      'average': instance.average,
      'potential': instance.potential,
    };
