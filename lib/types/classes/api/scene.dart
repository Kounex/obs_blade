import 'package:freezed_annotation/freezed_annotation.dart';

part 'scene.freezed.dart';
part 'scene.g.dart';

@freezed
class Scene with _$Scene {
  const factory Scene({
    /// Name of the currently active scene
    required String sceneName,

    /// Ordered list of the current scene's source items
    required int sceneIndex,
  }) = _Scene;

  factory Scene.fromJson(Map<String, Object?> json) => _$SceneFromJson(json);
}
