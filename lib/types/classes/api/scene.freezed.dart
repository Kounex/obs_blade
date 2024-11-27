// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scene.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Scene _$SceneFromJson(Map<String, dynamic> json) {
  return _Scene.fromJson(json);
}

/// @nodoc
mixin _$Scene {
  /// Name of the currently active scene
  String get sceneName => throw _privateConstructorUsedError;

  /// Ordered list of the current scene's source items
  int get sceneIndex => throw _privateConstructorUsedError;

  /// Serializes this Scene to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Scene
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SceneCopyWith<Scene> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SceneCopyWith<$Res> {
  factory $SceneCopyWith(Scene value, $Res Function(Scene) then) =
      _$SceneCopyWithImpl<$Res, Scene>;
  @useResult
  $Res call({String sceneName, int sceneIndex});
}

/// @nodoc
class _$SceneCopyWithImpl<$Res, $Val extends Scene>
    implements $SceneCopyWith<$Res> {
  _$SceneCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Scene
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sceneName = null,
    Object? sceneIndex = null,
  }) {
    return _then(_value.copyWith(
      sceneName: null == sceneName
          ? _value.sceneName
          : sceneName // ignore: cast_nullable_to_non_nullable
              as String,
      sceneIndex: null == sceneIndex
          ? _value.sceneIndex
          : sceneIndex // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SceneImplCopyWith<$Res> implements $SceneCopyWith<$Res> {
  factory _$$SceneImplCopyWith(
          _$SceneImpl value, $Res Function(_$SceneImpl) then) =
      __$$SceneImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String sceneName, int sceneIndex});
}

/// @nodoc
class __$$SceneImplCopyWithImpl<$Res>
    extends _$SceneCopyWithImpl<$Res, _$SceneImpl>
    implements _$$SceneImplCopyWith<$Res> {
  __$$SceneImplCopyWithImpl(
      _$SceneImpl _value, $Res Function(_$SceneImpl) _then)
      : super(_value, _then);

  /// Create a copy of Scene
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sceneName = null,
    Object? sceneIndex = null,
  }) {
    return _then(_$SceneImpl(
      sceneName: null == sceneName
          ? _value.sceneName
          : sceneName // ignore: cast_nullable_to_non_nullable
              as String,
      sceneIndex: null == sceneIndex
          ? _value.sceneIndex
          : sceneIndex // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SceneImpl implements _Scene {
  const _$SceneImpl({required this.sceneName, required this.sceneIndex});

  factory _$SceneImpl.fromJson(Map<String, dynamic> json) =>
      _$$SceneImplFromJson(json);

  /// Name of the currently active scene
  @override
  final String sceneName;

  /// Ordered list of the current scene's source items
  @override
  final int sceneIndex;

  @override
  String toString() {
    return 'Scene(sceneName: $sceneName, sceneIndex: $sceneIndex)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SceneImpl &&
            (identical(other.sceneName, sceneName) ||
                other.sceneName == sceneName) &&
            (identical(other.sceneIndex, sceneIndex) ||
                other.sceneIndex == sceneIndex));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, sceneName, sceneIndex);

  /// Create a copy of Scene
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SceneImplCopyWith<_$SceneImpl> get copyWith =>
      __$$SceneImplCopyWithImpl<_$SceneImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SceneImplToJson(
      this,
    );
  }
}

abstract class _Scene implements Scene {
  const factory _Scene(
      {required final String sceneName,
      required final int sceneIndex}) = _$SceneImpl;

  factory _Scene.fromJson(Map<String, dynamic> json) = _$SceneImpl.fromJson;

  /// Name of the currently active scene
  @override
  String get sceneName;

  /// Ordered list of the current scene's source items
  @override
  int get sceneIndex;

  /// Create a copy of Scene
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SceneImplCopyWith<_$SceneImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
