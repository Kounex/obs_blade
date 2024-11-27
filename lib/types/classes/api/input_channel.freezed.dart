// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'input_channel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

InputChannel _$InputChannelFromJson(Map<String, dynamic> json) {
  return _InputChannel.fromJson(json);
}

/// @nodoc
mixin _$InputChannel {
  double? get current => throw _privateConstructorUsedError;
  double? get average => throw _privateConstructorUsedError;
  double? get potential => throw _privateConstructorUsedError;

  /// Serializes this InputChannel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of InputChannel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $InputChannelCopyWith<InputChannel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InputChannelCopyWith<$Res> {
  factory $InputChannelCopyWith(
          InputChannel value, $Res Function(InputChannel) then) =
      _$InputChannelCopyWithImpl<$Res, InputChannel>;
  @useResult
  $Res call({double? current, double? average, double? potential});
}

/// @nodoc
class _$InputChannelCopyWithImpl<$Res, $Val extends InputChannel>
    implements $InputChannelCopyWith<$Res> {
  _$InputChannelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of InputChannel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? current = freezed,
    Object? average = freezed,
    Object? potential = freezed,
  }) {
    return _then(_value.copyWith(
      current: freezed == current
          ? _value.current
          : current // ignore: cast_nullable_to_non_nullable
              as double?,
      average: freezed == average
          ? _value.average
          : average // ignore: cast_nullable_to_non_nullable
              as double?,
      potential: freezed == potential
          ? _value.potential
          : potential // ignore: cast_nullable_to_non_nullable
              as double?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$InputChannelImplCopyWith<$Res>
    implements $InputChannelCopyWith<$Res> {
  factory _$$InputChannelImplCopyWith(
          _$InputChannelImpl value, $Res Function(_$InputChannelImpl) then) =
      __$$InputChannelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double? current, double? average, double? potential});
}

/// @nodoc
class __$$InputChannelImplCopyWithImpl<$Res>
    extends _$InputChannelCopyWithImpl<$Res, _$InputChannelImpl>
    implements _$$InputChannelImplCopyWith<$Res> {
  __$$InputChannelImplCopyWithImpl(
      _$InputChannelImpl _value, $Res Function(_$InputChannelImpl) _then)
      : super(_value, _then);

  /// Create a copy of InputChannel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? current = freezed,
    Object? average = freezed,
    Object? potential = freezed,
  }) {
    return _then(_$InputChannelImpl(
      current: freezed == current
          ? _value.current
          : current // ignore: cast_nullable_to_non_nullable
              as double?,
      average: freezed == average
          ? _value.average
          : average // ignore: cast_nullable_to_non_nullable
              as double?,
      potential: freezed == potential
          ? _value.potential
          : potential // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$InputChannelImpl implements _InputChannel {
  const _$InputChannelImpl(
      {required this.current, required this.average, required this.potential});

  factory _$InputChannelImpl.fromJson(Map<String, dynamic> json) =>
      _$$InputChannelImplFromJson(json);

  @override
  final double? current;
  @override
  final double? average;
  @override
  final double? potential;

  @override
  String toString() {
    return 'InputChannel(current: $current, average: $average, potential: $potential)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InputChannelImpl &&
            (identical(other.current, current) || other.current == current) &&
            (identical(other.average, average) || other.average == average) &&
            (identical(other.potential, potential) ||
                other.potential == potential));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, current, average, potential);

  /// Create a copy of InputChannel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InputChannelImplCopyWith<_$InputChannelImpl> get copyWith =>
      __$$InputChannelImplCopyWithImpl<_$InputChannelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$InputChannelImplToJson(
      this,
    );
  }
}

abstract class _InputChannel implements InputChannel {
  const factory _InputChannel(
      {required final double? current,
      required final double? average,
      required final double? potential}) = _$InputChannelImpl;

  factory _InputChannel.fromJson(Map<String, dynamic> json) =
      _$InputChannelImpl.fromJson;

  @override
  double? get current;
  @override
  double? get average;
  @override
  double? get potential;

  /// Create a copy of InputChannel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InputChannelImplCopyWith<_$InputChannelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
