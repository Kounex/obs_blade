// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scene_item_transform.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SceneItemTransformImpl _$$SceneItemTransformImplFromJson(
        Map<String, dynamic> json) =>
    _$SceneItemTransformImpl(
      alignment: (json['alignment'] as num?)?.toInt(),
      boundsAlignment: (json['boundsAlignment'] as num?)?.toInt(),
      boundsHeight: (json['boundsHeight'] as num?)?.toDouble(),
      boundsType: json['boundsType'] as String?,
      boundsWidth: (json['boundsWidth'] as num?)?.toDouble(),
      cropBottom: (json['cropBottom'] as num?)?.toInt(),
      cropLeft: (json['cropLeft'] as num?)?.toInt(),
      cropRight: (json['cropRight'] as num?)?.toInt(),
      cropTop: (json['cropTop'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toDouble(),
      positionX: (json['positionX'] as num?)?.toDouble(),
      positionY: (json['positionY'] as num?)?.toDouble(),
      rotation: (json['rotation'] as num?)?.toDouble(),
      scaleX: (json['scaleX'] as num?)?.toDouble(),
      scaleY: (json['scaleY'] as num?)?.toDouble(),
      sourceHeight: (json['sourceHeight'] as num?)?.toDouble(),
      sourceWidth: (json['sourceWidth'] as num?)?.toDouble(),
      width: (json['width'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$$SceneItemTransformImplToJson(
        _$SceneItemTransformImpl instance) =>
    <String, dynamic>{
      'alignment': instance.alignment,
      'boundsAlignment': instance.boundsAlignment,
      'boundsHeight': instance.boundsHeight,
      'boundsType': instance.boundsType,
      'boundsWidth': instance.boundsWidth,
      'cropBottom': instance.cropBottom,
      'cropLeft': instance.cropLeft,
      'cropRight': instance.cropRight,
      'cropTop': instance.cropTop,
      'height': instance.height,
      'positionX': instance.positionX,
      'positionY': instance.positionY,
      'rotation': instance.rotation,
      'scaleX': instance.scaleX,
      'scaleY': instance.scaleY,
      'sourceHeight': instance.sourceHeight,
      'sourceWidth': instance.sourceWidth,
      'width': instance.width,
    };
