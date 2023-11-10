import 'package:freezed_annotation/freezed_annotation.dart';

part 'scene_item_transform.freezed.dart';
part 'scene_item_transform.g.dart';

@freezed
class SceneItemTransform with _$SceneItemTransform {
  const factory SceneItemTransform({
    required int? alignment,
    required int? boundsAlignment,
    required double? boundsHeight,
    required String? boundsType,
    required double? boundsWidth,
    required int? cropBottom,
    required int? cropLeft,
    required int? cropRight,
    required int? cropTop,
    required double? height,
    required double? positionX,
    required double? positionY,
    required double? rotation,
    required double? scaleX,
    required double? scaleY,
    required double? sourceHeight,
    required double? sourceWidth,
    required double? width,
  }) = _SceneItemTransform;

  factory SceneItemTransform.fromJson(Map<String, Object?> json) =>
      _$SceneItemTransformFromJson(json);
}
