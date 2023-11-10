// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transition.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TransitionImpl _$$TransitionImplFromJson(Map<String, dynamic> json) =>
    _$TransitionImpl(
      transitionName: json['transitionName'] as String,
      transitionKind: json['transitionKind'] as String,
      transitionFixed: json['transitionFixed'] as bool,
      transitionDuration: json['transitionDuration'] as int?,
      transitionConfigurable: json['transitionConfigurable'] as bool,
      transitionSettings: json['transitionSettings'],
    );

Map<String, dynamic> _$$TransitionImplToJson(_$TransitionImpl instance) =>
    <String, dynamic>{
      'transitionName': instance.transitionName,
      'transitionKind': instance.transitionKind,
      'transitionFixed': instance.transitionFixed,
      'transitionDuration': instance.transitionDuration,
      'transitionConfigurable': instance.transitionConfigurable,
      'transitionSettings': instance.transitionSettings,
    };
