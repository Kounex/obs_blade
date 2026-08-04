// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'twitch_device_code.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TwitchDeviceCode {

 String get deviceCode; String get userCode; String get verificationUri; int get expiresIn; int get interval;
/// Create a copy of TwitchDeviceCode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TwitchDeviceCodeCopyWith<TwitchDeviceCode> get copyWith => _$TwitchDeviceCodeCopyWithImpl<TwitchDeviceCode>(this as TwitchDeviceCode, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TwitchDeviceCode&&(identical(other.deviceCode, deviceCode) || other.deviceCode == deviceCode)&&(identical(other.userCode, userCode) || other.userCode == userCode)&&(identical(other.verificationUri, verificationUri) || other.verificationUri == verificationUri)&&(identical(other.expiresIn, expiresIn) || other.expiresIn == expiresIn)&&(identical(other.interval, interval) || other.interval == interval));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,deviceCode,userCode,verificationUri,expiresIn,interval);

@override
String toString() {
  return 'TwitchDeviceCode(deviceCode: $deviceCode, userCode: $userCode, verificationUri: $verificationUri, expiresIn: $expiresIn, interval: $interval)';
}


}

/// @nodoc
abstract mixin class $TwitchDeviceCodeCopyWith<$Res>  {
  factory $TwitchDeviceCodeCopyWith(TwitchDeviceCode value, $Res Function(TwitchDeviceCode) _then) = _$TwitchDeviceCodeCopyWithImpl;
@useResult
$Res call({
 String deviceCode, String userCode, String verificationUri, int expiresIn, int interval
});




}
/// @nodoc
class _$TwitchDeviceCodeCopyWithImpl<$Res>
    implements $TwitchDeviceCodeCopyWith<$Res> {
  _$TwitchDeviceCodeCopyWithImpl(this._self, this._then);

  final TwitchDeviceCode _self;
  final $Res Function(TwitchDeviceCode) _then;

/// Create a copy of TwitchDeviceCode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? deviceCode = null,Object? userCode = null,Object? verificationUri = null,Object? expiresIn = null,Object? interval = null,}) {
  return _then(_self.copyWith(
deviceCode: null == deviceCode ? _self.deviceCode : deviceCode // ignore: cast_nullable_to_non_nullable
as String,userCode: null == userCode ? _self.userCode : userCode // ignore: cast_nullable_to_non_nullable
as String,verificationUri: null == verificationUri ? _self.verificationUri : verificationUri // ignore: cast_nullable_to_non_nullable
as String,expiresIn: null == expiresIn ? _self.expiresIn : expiresIn // ignore: cast_nullable_to_non_nullable
as int,interval: null == interval ? _self.interval : interval // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TwitchDeviceCode].
extension TwitchDeviceCodePatterns on TwitchDeviceCode {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TwitchDeviceCode value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TwitchDeviceCode() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TwitchDeviceCode value)  $default,){
final _that = this;
switch (_that) {
case _TwitchDeviceCode():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TwitchDeviceCode value)?  $default,){
final _that = this;
switch (_that) {
case _TwitchDeviceCode() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String deviceCode,  String userCode,  String verificationUri,  int expiresIn,  int interval)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TwitchDeviceCode() when $default != null:
return $default(_that.deviceCode,_that.userCode,_that.verificationUri,_that.expiresIn,_that.interval);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String deviceCode,  String userCode,  String verificationUri,  int expiresIn,  int interval)  $default,) {final _that = this;
switch (_that) {
case _TwitchDeviceCode():
return $default(_that.deviceCode,_that.userCode,_that.verificationUri,_that.expiresIn,_that.interval);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String deviceCode,  String userCode,  String verificationUri,  int expiresIn,  int interval)?  $default,) {final _that = this;
switch (_that) {
case _TwitchDeviceCode() when $default != null:
return $default(_that.deviceCode,_that.userCode,_that.verificationUri,_that.expiresIn,_that.interval);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class _TwitchDeviceCode implements TwitchDeviceCode {
  const _TwitchDeviceCode({required this.deviceCode, required this.userCode, required this.verificationUri, required this.expiresIn, required this.interval});
  factory _TwitchDeviceCode.fromJson(Map<String, dynamic> json) => _$TwitchDeviceCodeFromJson(json);

@override final  String deviceCode;
@override final  String userCode;
@override final  String verificationUri;
@override final  int expiresIn;
@override final  int interval;

/// Create a copy of TwitchDeviceCode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TwitchDeviceCodeCopyWith<_TwitchDeviceCode> get copyWith => __$TwitchDeviceCodeCopyWithImpl<_TwitchDeviceCode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TwitchDeviceCode&&(identical(other.deviceCode, deviceCode) || other.deviceCode == deviceCode)&&(identical(other.userCode, userCode) || other.userCode == userCode)&&(identical(other.verificationUri, verificationUri) || other.verificationUri == verificationUri)&&(identical(other.expiresIn, expiresIn) || other.expiresIn == expiresIn)&&(identical(other.interval, interval) || other.interval == interval));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,deviceCode,userCode,verificationUri,expiresIn,interval);

@override
String toString() {
  return 'TwitchDeviceCode(deviceCode: $deviceCode, userCode: $userCode, verificationUri: $verificationUri, expiresIn: $expiresIn, interval: $interval)';
}


}

/// @nodoc
abstract mixin class _$TwitchDeviceCodeCopyWith<$Res> implements $TwitchDeviceCodeCopyWith<$Res> {
  factory _$TwitchDeviceCodeCopyWith(_TwitchDeviceCode value, $Res Function(_TwitchDeviceCode) _then) = __$TwitchDeviceCodeCopyWithImpl;
@override @useResult
$Res call({
 String deviceCode, String userCode, String verificationUri, int expiresIn, int interval
});




}
/// @nodoc
class __$TwitchDeviceCodeCopyWithImpl<$Res>
    implements _$TwitchDeviceCodeCopyWith<$Res> {
  __$TwitchDeviceCodeCopyWithImpl(this._self, this._then);

  final _TwitchDeviceCode _self;
  final $Res Function(_TwitchDeviceCode) _then;

/// Create a copy of TwitchDeviceCode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? deviceCode = null,Object? userCode = null,Object? verificationUri = null,Object? expiresIn = null,Object? interval = null,}) {
  return _then(_TwitchDeviceCode(
deviceCode: null == deviceCode ? _self.deviceCode : deviceCode // ignore: cast_nullable_to_non_nullable
as String,userCode: null == userCode ? _self.userCode : userCode // ignore: cast_nullable_to_non_nullable
as String,verificationUri: null == verificationUri ? _self.verificationUri : verificationUri // ignore: cast_nullable_to_non_nullable
as String,expiresIn: null == expiresIn ? _self.expiresIn : expiresIn // ignore: cast_nullable_to_non_nullable
as int,interval: null == interval ? _self.interval : interval // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
