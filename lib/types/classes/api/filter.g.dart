// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'filter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FilterImpl _$$FilterImplFromJson(Map<String, dynamic> json) => _$FilterImpl(
      filterEnabled: json['filterEnabled'] as bool,
      filterIndex: (json['filterIndex'] as num).toInt(),
      filterKind: json['filterKind'] as String,
      filterName: json['filterName'] as String,
      filterSettings: json['filterSettings'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$$FilterImplToJson(_$FilterImpl instance) =>
    <String, dynamic>{
      'filterEnabled': instance.filterEnabled,
      'filterIndex': instance.filterIndex,
      'filterKind': instance.filterKind,
      'filterName': instance.filterName,
      'filterSettings': instance.filterSettings,
    };
