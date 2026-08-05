// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'twitch_drop_reason.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TwitchDropReason {

 String get code; String? get message;
/// Create a copy of TwitchDropReason
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TwitchDropReasonCopyWith<TwitchDropReason> get copyWith => _$TwitchDropReasonCopyWithImpl<TwitchDropReason>(this as TwitchDropReason, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TwitchDropReason&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message);

@override
String toString() {
  return 'TwitchDropReason(code: $code, message: $message)';
}


}

/// @nodoc
abstract mixin class $TwitchDropReasonCopyWith<$Res>  {
  factory $TwitchDropReasonCopyWith(TwitchDropReason value, $Res Function(TwitchDropReason) _then) = _$TwitchDropReasonCopyWithImpl;
@useResult
$Res call({
 String code, String? message
});




}
/// @nodoc
class _$TwitchDropReasonCopyWithImpl<$Res>
    implements $TwitchDropReasonCopyWith<$Res> {
  _$TwitchDropReasonCopyWithImpl(this._self, this._then);

  final TwitchDropReason _self;
  final $Res Function(TwitchDropReason) _then;

/// Create a copy of TwitchDropReason
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? message = freezed,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TwitchDropReason].
extension TwitchDropReasonPatterns on TwitchDropReason {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TwitchDropReason value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TwitchDropReason() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TwitchDropReason value)  $default,){
final _that = this;
switch (_that) {
case _TwitchDropReason():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TwitchDropReason value)?  $default,){
final _that = this;
switch (_that) {
case _TwitchDropReason() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  String? message)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TwitchDropReason() when $default != null:
return $default(_that.code,_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  String? message)  $default,) {final _that = this;
switch (_that) {
case _TwitchDropReason():
return $default(_that.code,_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  String? message)?  $default,) {final _that = this;
switch (_that) {
case _TwitchDropReason() when $default != null:
return $default(_that.code,_that.message);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class _TwitchDropReason implements TwitchDropReason {
  const _TwitchDropReason({required this.code, this.message});
  factory _TwitchDropReason.fromJson(Map<String, dynamic> json) => _$TwitchDropReasonFromJson(json);

@override final  String code;
@override final  String? message;

/// Create a copy of TwitchDropReason
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TwitchDropReasonCopyWith<_TwitchDropReason> get copyWith => __$TwitchDropReasonCopyWithImpl<_TwitchDropReason>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TwitchDropReason&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message);

@override
String toString() {
  return 'TwitchDropReason(code: $code, message: $message)';
}


}

/// @nodoc
abstract mixin class _$TwitchDropReasonCopyWith<$Res> implements $TwitchDropReasonCopyWith<$Res> {
  factory _$TwitchDropReasonCopyWith(_TwitchDropReason value, $Res Function(_TwitchDropReason) _then) = __$TwitchDropReasonCopyWithImpl;
@override @useResult
$Res call({
 String code, String? message
});




}
/// @nodoc
class __$TwitchDropReasonCopyWithImpl<$Res>
    implements _$TwitchDropReasonCopyWith<$Res> {
  __$TwitchDropReasonCopyWithImpl(this._self, this._then);

  final _TwitchDropReason _self;
  final $Res Function(_TwitchDropReason) _then;

/// Create a copy of TwitchDropReason
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? message = freezed,}) {
  return _then(_TwitchDropReason(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
