import 'package:freezed_annotation/freezed_annotation.dart';

import 'scene_item_transform.dart';

part 'scene_item.freezed.dart';
part 'scene_item.g.dart';

@freezed
class SceneItem with _$SceneItem {
  const factory SceneItem({
    required String? inputKind,
    required bool? isGroup,
    required String? sceneItemBlendMode,
    required bool? sceneItemEnabled,
    required int? sceneItemId,
    required int? sceneItemIndex,
    required bool? sceneItemLocked,
    required SceneItemTransform? sceneItemTransform,
    required String? sourceName,
    required String? sourceType,

    /// OPTIONAL - Name of the item's parent (if this item belongs to a group)
    String? parentGroupName,

    /// OPTIONAL - List of children (if this item is a group)
    List<SceneItem>? groupChildren,

    /// CUSTOM - added myself to handle stuff internally

    /// Indicate whether we want to display the children of this group
    /// (if this [SceneItem] is a group)
    @Default(false) bool displayGroup,
  }) = _SceneItem;

  factory SceneItem.fromJson(Map<String, Object?> json) =>
      _$SceneItemFromJson(json);
}
