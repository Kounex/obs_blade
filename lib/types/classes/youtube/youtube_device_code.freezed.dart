// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'youtube_device_code.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$YouTubeDeviceCode {

 String get deviceCode; String get userCode; String get verificationUrl; int get expiresIn; int get interval;
/// Create a copy of YouTubeDeviceCode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$YouTubeDeviceCodeCopyWith<YouTubeDeviceCode> get copyWith => _$YouTubeDeviceCodeCopyWithImpl<YouTubeDeviceCode>(this as YouTubeDeviceCode, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is YouTubeDeviceCode&&(identical(other.deviceCode, deviceCode) || other.deviceCode == deviceCode)&&(identical(other.userCode, userCode) || other.userCode == userCode)&&(identical(other.verificationUrl, verificationUrl) || other.verificationUrl == verificationUrl)&&(identical(other.expiresIn, expiresIn) || other.expiresIn == expiresIn)&&(identical(other.interval, interval) || other.interval == interval));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,deviceCode,userCode,verificationUrl,expiresIn,interval);

@override
String toString() {
  return 'YouTubeDeviceCode(deviceCode: $deviceCode, userCode: $userCode, verificationUrl: $verificationUrl, expiresIn: $expiresIn, interval: $interval)';
}


}

/// @nodoc
abstract mixin class $YouTubeDeviceCodeCopyWith<$Res>  {
  factory $YouTubeDeviceCodeCopyWith(YouTubeDeviceCode value, $Res Function(YouTubeDeviceCode) _then) = _$YouTubeDeviceCodeCopyWithImpl;
@useResult
$Res call({
 String deviceCode, String userCode, String verificationUrl, int expiresIn, int interval
});




}
/// @nodoc
class _$YouTubeDeviceCodeCopyWithImpl<$Res>
    implements $YouTubeDeviceCodeCopyWith<$Res> {
  _$YouTubeDeviceCodeCopyWithImpl(this._self, this._then);

  final YouTubeDeviceCode _self;
  final $Res Function(YouTubeDeviceCode) _then;

/// Create a copy of YouTubeDeviceCode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? deviceCode = null,Object? userCode = null,Object? verificationUrl = null,Object? expiresIn = null,Object? interval = null,}) {
  return _then(_self.copyWith(
deviceCode: null == deviceCode ? _self.deviceCode : deviceCode // ignore: cast_nullable_to_non_nullable
as String,userCode: null == userCode ? _self.userCode : userCode // ignore: cast_nullable_to_non_nullable
as String,verificationUrl: null == verificationUrl ? _self.verificationUrl : verificationUrl // ignore: cast_nullable_to_non_nullable
as String,expiresIn: null == expiresIn ? _self.expiresIn : expiresIn // ignore: cast_nullable_to_non_nullable
as int,interval: null == interval ? _self.interval : interval // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [YouTubeDeviceCode].
extension YouTubeDeviceCodePatterns on YouTubeDeviceCode {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _YouTubeDeviceCode value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _YouTubeDeviceCode() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _YouTubeDeviceCode value)  $default,){
final _that = this;
switch (_that) {
case _YouTubeDeviceCode():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _YouTubeDeviceCode value)?  $default,){
final _that = this;
switch (_that) {
case _YouTubeDeviceCode() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String deviceCode,  String userCode,  String verificationUrl,  int expiresIn,  int interval)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _YouTubeDeviceCode() when $default != null:
return $default(_that.deviceCode,_that.userCode,_that.verificationUrl,_that.expiresIn,_that.interval);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String deviceCode,  String userCode,  String verificationUrl,  int expiresIn,  int interval)  $default,) {final _that = this;
switch (_that) {
case _YouTubeDeviceCode():
return $default(_that.deviceCode,_that.userCode,_that.verificationUrl,_that.expiresIn,_that.interval);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String deviceCode,  String userCode,  String verificationUrl,  int expiresIn,  int interval)?  $default,) {final _that = this;
switch (_that) {
case _YouTubeDeviceCode() when $default != null:
return $default(_that.deviceCode,_that.userCode,_that.verificationUrl,_that.expiresIn,_that.interval);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class _YouTubeDeviceCode implements YouTubeDeviceCode {
  const _YouTubeDeviceCode({required this.deviceCode, required this.userCode, required this.verificationUrl, required this.expiresIn, required this.interval});
  factory _YouTubeDeviceCode.fromJson(Map<String, dynamic> json) => _$YouTubeDeviceCodeFromJson(json);

@override final  String deviceCode;
@override final  String userCode;
@override final  String verificationUrl;
@override final  int expiresIn;
@override final  int interval;

/// Create a copy of YouTubeDeviceCode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$YouTubeDeviceCodeCopyWith<_YouTubeDeviceCode> get copyWith => __$YouTubeDeviceCodeCopyWithImpl<_YouTubeDeviceCode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _YouTubeDeviceCode&&(identical(other.deviceCode, deviceCode) || other.deviceCode == deviceCode)&&(identical(other.userCode, userCode) || other.userCode == userCode)&&(identical(other.verificationUrl, verificationUrl) || other.verificationUrl == verificationUrl)&&(identical(other.expiresIn, expiresIn) || other.expiresIn == expiresIn)&&(identical(other.interval, interval) || other.interval == interval));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,deviceCode,userCode,verificationUrl,expiresIn,interval);

@override
String toString() {
  return 'YouTubeDeviceCode(deviceCode: $deviceCode, userCode: $userCode, verificationUrl: $verificationUrl, expiresIn: $expiresIn, interval: $interval)';
}


}

/// @nodoc
abstract mixin class _$YouTubeDeviceCodeCopyWith<$Res> implements $YouTubeDeviceCodeCopyWith<$Res> {
  factory _$YouTubeDeviceCodeCopyWith(_YouTubeDeviceCode value, $Res Function(_YouTubeDeviceCode) _then) = __$YouTubeDeviceCodeCopyWithImpl;
@override @useResult
$Res call({
 String deviceCode, String userCode, String verificationUrl, int expiresIn, int interval
});




}
/// @nodoc
class __$YouTubeDeviceCodeCopyWithImpl<$Res>
    implements _$YouTubeDeviceCodeCopyWith<$Res> {
  __$YouTubeDeviceCodeCopyWithImpl(this._self, this._then);

  final _YouTubeDeviceCode _self;
  final $Res Function(_YouTubeDeviceCode) _then;

/// Create a copy of YouTubeDeviceCode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? deviceCode = null,Object? userCode = null,Object? verificationUrl = null,Object? expiresIn = null,Object? interval = null,}) {
  return _then(_YouTubeDeviceCode(
deviceCode: null == deviceCode ? _self.deviceCode : deviceCode // ignore: cast_nullable_to_non_nullable
as String,userCode: null == userCode ? _self.userCode : userCode // ignore: cast_nullable_to_non_nullable
as String,verificationUrl: null == verificationUrl ? _self.verificationUrl : verificationUrl // ignore: cast_nullable_to_non_nullable
as String,expiresIn: null == expiresIn ? _self.expiresIn : expiresIn // ignore: cast_nullable_to_non_nullable
as int,interval: null == interval ? _self.interval : interval // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
