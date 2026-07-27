// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transition.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Transition _$TransitionFromJson(Map<String, dynamic> json) => _Transition(
  transitionName: json['transitionName'] as String,
  transitionKind: json['transitionKind'] as String,
  transitionFixed: json['transitionFixed'] as bool,
  transitionDuration: (json['transitionDuration'] as num?)?.toInt(),
  transitionConfigurable: json['transitionConfigurable'] as bool,
  transitionSettings: json['transitionSettings'],
);

Map<String, dynamic> _$TransitionToJson(_Transition instance) =>
    <String, dynamic>{
      'transitionName': instance.transitionName,
      'transitionKind': instance.transitionKind,
      'transitionFixed': instance.transitionFixed,
      'transitionDuration': instance.transitionDuration,
      'transitionConfigurable': instance.transitionConfigurable,
      'transitionSettings': instance.transitionSettings,
    };
