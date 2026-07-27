// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Input _$InputFromJson(Map<String, dynamic> json) => _Input(
  inputKind: json['inputKind'] as String?,
  inputName: json['inputName'] as String?,
  unversionedInputKind: json['unversionedInputKind'] as String?,
  inputVolumeMul: (json['inputVolumeMul'] as num?)?.toDouble(),
  inputVolumeDb: (json['inputVolumeDb'] as num?)?.toDouble(),
  inputLevelsMul: (json['inputLevelsMul'] as List<dynamic>?)
      ?.map((e) => InputChannel.fromJson(e as Map<String, dynamic>))
      .toList(),
  syncOffset: (json['syncOffset'] as num?)?.toInt(),
  inputMuted: json['inputMuted'] as bool? ?? false,
);

Map<String, dynamic> _$InputToJson(_Input instance) => <String, dynamic>{
  'inputKind': instance.inputKind,
  'inputName': instance.inputName,
  'unversionedInputKind': instance.unversionedInputKind,
  'inputVolumeMul': instance.inputVolumeMul,
  'inputVolumeDb': instance.inputVolumeDb,
  'inputLevelsMul': instance.inputLevelsMul,
  'syncOffset': instance.syncOffset,
  'inputMuted': instance.inputMuted,
};
