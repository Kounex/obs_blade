// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'filter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Filter _$FilterFromJson(Map<String, dynamic> json) => _Filter(
  filterEnabled: json['filterEnabled'] as bool,
  filterIndex: (json['filterIndex'] as num).toInt(),
  filterKind: json['filterKind'] as String,
  filterName: json['filterName'] as String,
  filterSettings: json['filterSettings'] as Map<String, dynamic>,
);

Map<String, dynamic> _$FilterToJson(_Filter instance) => <String, dynamic>{
  'filterEnabled': instance.filterEnabled,
  'filterIndex': instance.filterIndex,
  'filterKind': instance.filterKind,
  'filterName': instance.filterName,
  'filterSettings': instance.filterSettings,
};
