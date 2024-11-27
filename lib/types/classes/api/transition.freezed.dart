// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transition.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Transition _$TransitionFromJson(Map<String, dynamic> json) {
  return _Transition.fromJson(json);
}

/// @nodoc
mixin _$Transition {
  /// Name of the transition
  String get transitionName => throw _privateConstructorUsedError;

  /// Kind of the transition
  String get transitionKind => throw _privateConstructorUsedError;

  /// Whether the transition uses a fixed (unconfigurable) duration
  bool get transitionFixed => throw _privateConstructorUsedError;

  /// Configured transition duration in milliseconds. null if transition is fixed
  int? get transitionDuration => throw _privateConstructorUsedError;

  /// Whether the transition supports being configured
  bool get transitionConfigurable => throw _privateConstructorUsedError;

  /// Object of settings for the transition. null if transition is not configurable
  dynamic get transitionSettings => throw _privateConstructorUsedError;

  /// Serializes this Transition to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Transition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TransitionCopyWith<Transition> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TransitionCopyWith<$Res> {
  factory $TransitionCopyWith(
          Transition value, $Res Function(Transition) then) =
      _$TransitionCopyWithImpl<$Res, Transition>;
  @useResult
  $Res call(
      {String transitionName,
      String transitionKind,
      bool transitionFixed,
      int? transitionDuration,
      bool transitionConfigurable,
      dynamic transitionSettings});
}

/// @nodoc
class _$TransitionCopyWithImpl<$Res, $Val extends Transition>
    implements $TransitionCopyWith<$Res> {
  _$TransitionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Transition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? transitionName = null,
    Object? transitionKind = null,
    Object? transitionFixed = null,
    Object? transitionDuration = freezed,
    Object? transitionConfigurable = null,
    Object? transitionSettings = freezed,
  }) {
    return _then(_value.copyWith(
      transitionName: null == transitionName
          ? _value.transitionName
          : transitionName // ignore: cast_nullable_to_non_nullable
              as String,
      transitionKind: null == transitionKind
          ? _value.transitionKind
          : transitionKind // ignore: cast_nullable_to_non_nullable
              as String,
      transitionFixed: null == transitionFixed
          ? _value.transitionFixed
          : transitionFixed // ignore: cast_nullable_to_non_nullable
              as bool,
      transitionDuration: freezed == transitionDuration
          ? _value.transitionDuration
          : transitionDuration // ignore: cast_nullable_to_non_nullable
              as int?,
      transitionConfigurable: null == transitionConfigurable
          ? _value.transitionConfigurable
          : transitionConfigurable // ignore: cast_nullable_to_non_nullable
              as bool,
      transitionSettings: freezed == transitionSettings
          ? _value.transitionSettings
          : transitionSettings // ignore: cast_nullable_to_non_nullable
              as dynamic,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TransitionImplCopyWith<$Res>
    implements $TransitionCopyWith<$Res> {
  factory _$$TransitionImplCopyWith(
          _$TransitionImpl value, $Res Function(_$TransitionImpl) then) =
      __$$TransitionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String transitionName,
      String transitionKind,
      bool transitionFixed,
      int? transitionDuration,
      bool transitionConfigurable,
      dynamic transitionSettings});
}

/// @nodoc
class __$$TransitionImplCopyWithImpl<$Res>
    extends _$TransitionCopyWithImpl<$Res, _$TransitionImpl>
    implements _$$TransitionImplCopyWith<$Res> {
  __$$TransitionImplCopyWithImpl(
      _$TransitionImpl _value, $Res Function(_$TransitionImpl) _then)
      : super(_value, _then);

  /// Create a copy of Transition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? transitionName = null,
    Object? transitionKind = null,
    Object? transitionFixed = null,
    Object? transitionDuration = freezed,
    Object? transitionConfigurable = null,
    Object? transitionSettings = freezed,
  }) {
    return _then(_$TransitionImpl(
      transitionName: null == transitionName
          ? _value.transitionName
          : transitionName // ignore: cast_nullable_to_non_nullable
              as String,
      transitionKind: null == transitionKind
          ? _value.transitionKind
          : transitionKind // ignore: cast_nullable_to_non_nullable
              as String,
      transitionFixed: null == transitionFixed
          ? _value.transitionFixed
          : transitionFixed // ignore: cast_nullable_to_non_nullable
              as bool,
      transitionDuration: freezed == transitionDuration
          ? _value.transitionDuration
          : transitionDuration // ignore: cast_nullable_to_non_nullable
              as int?,
      transitionConfigurable: null == transitionConfigurable
          ? _value.transitionConfigurable
          : transitionConfigurable // ignore: cast_nullable_to_non_nullable
              as bool,
      transitionSettings: freezed == transitionSettings
          ? _value.transitionSettings
          : transitionSettings // ignore: cast_nullable_to_non_nullable
              as dynamic,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TransitionImpl implements _Transition {
  const _$TransitionImpl(
      {required this.transitionName,
      required this.transitionKind,
      required this.transitionFixed,
      required this.transitionDuration,
      required this.transitionConfigurable,
      required this.transitionSettings});

  factory _$TransitionImpl.fromJson(Map<String, dynamic> json) =>
      _$$TransitionImplFromJson(json);

  /// Name of the transition
  @override
  final String transitionName;

  /// Kind of the transition
  @override
  final String transitionKind;

  /// Whether the transition uses a fixed (unconfigurable) duration
  @override
  final bool transitionFixed;

  /// Configured transition duration in milliseconds. null if transition is fixed
  @override
  final int? transitionDuration;

  /// Whether the transition supports being configured
  @override
  final bool transitionConfigurable;

  /// Object of settings for the transition. null if transition is not configurable
  @override
  final dynamic transitionSettings;

  @override
  String toString() {
    return 'Transition(transitionName: $transitionName, transitionKind: $transitionKind, transitionFixed: $transitionFixed, transitionDuration: $transitionDuration, transitionConfigurable: $transitionConfigurable, transitionSettings: $transitionSettings)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TransitionImpl &&
            (identical(other.transitionName, transitionName) ||
                other.transitionName == transitionName) &&
            (identical(other.transitionKind, transitionKind) ||
                other.transitionKind == transitionKind) &&
            (identical(other.transitionFixed, transitionFixed) ||
                other.transitionFixed == transitionFixed) &&
            (identical(other.transitionDuration, transitionDuration) ||
                other.transitionDuration == transitionDuration) &&
            (identical(other.transitionConfigurable, transitionConfigurable) ||
                other.transitionConfigurable == transitionConfigurable) &&
            const DeepCollectionEquality()
                .equals(other.transitionSettings, transitionSettings));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      transitionName,
      transitionKind,
      transitionFixed,
      transitionDuration,
      transitionConfigurable,
      const DeepCollectionEquality().hash(transitionSettings));

  /// Create a copy of Transition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TransitionImplCopyWith<_$TransitionImpl> get copyWith =>
      __$$TransitionImplCopyWithImpl<_$TransitionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TransitionImplToJson(
      this,
    );
  }
}

abstract class _Transition implements Transition {
  const factory _Transition(
      {required final String transitionName,
      required final String transitionKind,
      required final bool transitionFixed,
      required final int? transitionDuration,
      required final bool transitionConfigurable,
      required final dynamic transitionSettings}) = _$TransitionImpl;

  factory _Transition.fromJson(Map<String, dynamic> json) =
      _$TransitionImpl.fromJson;

  /// Name of the transition
  @override
  String get transitionName;

  /// Kind of the transition
  @override
  String get transitionKind;

  /// Whether the transition uses a fixed (unconfigurable) duration
  @override
  bool get transitionFixed;

  /// Configured transition duration in milliseconds. null if transition is fixed
  @override
  int? get transitionDuration;

  /// Whether the transition supports being configured
  @override
  bool get transitionConfigurable;

  /// Object of settings for the transition. null if transition is not configurable
  @override
  dynamic get transitionSettings;

  /// Create a copy of Transition
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TransitionImplCopyWith<_$TransitionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
