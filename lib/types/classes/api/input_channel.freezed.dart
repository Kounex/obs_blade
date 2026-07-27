// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'input_channel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InputChannel {

 double? get current; double? get average; double? get potential;
/// Create a copy of InputChannel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InputChannelCopyWith<InputChannel> get copyWith => _$InputChannelCopyWithImpl<InputChannel>(this as InputChannel, _$identity);

  /// Serializes this InputChannel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InputChannel&&(identical(other.current, current) || other.current == current)&&(identical(other.average, average) || other.average == average)&&(identical(other.potential, potential) || other.potential == potential));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,current,average,potential);

@override
String toString() {
  return 'InputChannel(current: $current, average: $average, potential: $potential)';
}


}

/// @nodoc
abstract mixin class $InputChannelCopyWith<$Res>  {
  factory $InputChannelCopyWith(InputChannel value, $Res Function(InputChannel) _then) = _$InputChannelCopyWithImpl;
@useResult
$Res call({
 double? current, double? average, double? potential
});




}
/// @nodoc
class _$InputChannelCopyWithImpl<$Res>
    implements $InputChannelCopyWith<$Res> {
  _$InputChannelCopyWithImpl(this._self, this._then);

  final InputChannel _self;
  final $Res Function(InputChannel) _then;

/// Create a copy of InputChannel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? current = freezed,Object? average = freezed,Object? potential = freezed,}) {
  return _then(_self.copyWith(
current: freezed == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as double?,average: freezed == average ? _self.average : average // ignore: cast_nullable_to_non_nullable
as double?,potential: freezed == potential ? _self.potential : potential // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [InputChannel].
extension InputChannelPatterns on InputChannel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InputChannel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InputChannel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InputChannel value)  $default,){
final _that = this;
switch (_that) {
case _InputChannel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InputChannel value)?  $default,){
final _that = this;
switch (_that) {
case _InputChannel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double? current,  double? average,  double? potential)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InputChannel() when $default != null:
return $default(_that.current,_that.average,_that.potential);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double? current,  double? average,  double? potential)  $default,) {final _that = this;
switch (_that) {
case _InputChannel():
return $default(_that.current,_that.average,_that.potential);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double? current,  double? average,  double? potential)?  $default,) {final _that = this;
switch (_that) {
case _InputChannel() when $default != null:
return $default(_that.current,_that.average,_that.potential);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InputChannel implements InputChannel {
  const _InputChannel({required this.current, required this.average, required this.potential});
  factory _InputChannel.fromJson(Map<String, dynamic> json) => _$InputChannelFromJson(json);

@override final  double? current;
@override final  double? average;
@override final  double? potential;

/// Create a copy of InputChannel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InputChannelCopyWith<_InputChannel> get copyWith => __$InputChannelCopyWithImpl<_InputChannel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InputChannelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InputChannel&&(identical(other.current, current) || other.current == current)&&(identical(other.average, average) || other.average == average)&&(identical(other.potential, potential) || other.potential == potential));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,current,average,potential);

@override
String toString() {
  return 'InputChannel(current: $current, average: $average, potential: $potential)';
}


}

/// @nodoc
abstract mixin class _$InputChannelCopyWith<$Res> implements $InputChannelCopyWith<$Res> {
  factory _$InputChannelCopyWith(_InputChannel value, $Res Function(_InputChannel) _then) = __$InputChannelCopyWithImpl;
@override @useResult
$Res call({
 double? current, double? average, double? potential
});




}
/// @nodoc
class __$InputChannelCopyWithImpl<$Res>
    implements _$InputChannelCopyWith<$Res> {
  __$InputChannelCopyWithImpl(this._self, this._then);

  final _InputChannel _self;
  final $Res Function(_InputChannel) _then;

/// Create a copy of InputChannel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? current = freezed,Object? average = freezed,Object? potential = freezed,}) {
  return _then(_InputChannel(
current: freezed == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as double?,average: freezed == average ? _self.average : average // ignore: cast_nullable_to_non_nullable
as double?,potential: freezed == potential ? _self.potential : potential // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
