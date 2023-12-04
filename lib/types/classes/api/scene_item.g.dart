// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scene_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SceneItemImpl _$$SceneItemImplFromJson(Map<String, dynamic> json) =>
    _$SceneItemImpl(
      inputKind: json['inputKind'] as String?,
      isGroup: json['isGroup'] as bool?,
      sceneItemBlendMode: json['sceneItemBlendMode'] as String?,
      sceneItemEnabled: json['sceneItemEnabled'] as bool?,
      sceneItemId: json['sceneItemId'] as int?,
      sceneItemIndex: json['sceneItemIndex'] as int?,
      sceneItemLocked: json['sceneItemLocked'] as bool?,
      sceneItemTransform: json['sceneItemTransform'] == null
          ? null
          : SceneItemTransform.fromJson(
              json['sceneItemTransform'] as Map<String, dynamic>),
      sourceName: json['sourceName'] as String?,
      sourceType: json['sourceType'] as String?,
      filters: (json['filters'] as List<dynamic>?)
              ?.map((e) => Filter.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      parentGroupName: json['parentGroupName'] as String?,
      groupChildren: (json['groupChildren'] as List<dynamic>?)
          ?.map((e) => SceneItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      displayGroup: json['displayGroup'] as bool? ?? false,
    );

Map<String, dynamic> _$$SceneItemImplToJson(_$SceneItemImpl instance) =>
    <String, dynamic>{
      'inputKind': instance.inputKind,
      'isGroup': instance.isGroup,
      'sceneItemBlendMode': instance.sceneItemBlendMode,
      'sceneItemEnabled': instance.sceneItemEnabled,
      'sceneItemId': instance.sceneItemId,
      'sceneItemIndex': instance.sceneItemIndex,
      'sceneItemLocked': instance.sceneItemLocked,
      'sceneItemTransform': instance.sceneItemTransform,
      'sourceName': instance.sourceName,
      'sourceType': instance.sourceType,
      'filters': instance.filters,
      'parentGroupName': instance.parentGroupName,
      'groupChildren': instance.groupChildren,
      'displayGroup': instance.displayGroup,
    };
