// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'twitch_user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TwitchUser {

 String get id; String get login; String? get displayName; String? get profileImageUrl;@JsonKey(fromJson: _createdAtFromJson) DateTime? get createdAt;
/// Create a copy of TwitchUser
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TwitchUserCopyWith<TwitchUser> get copyWith => _$TwitchUserCopyWithImpl<TwitchUser>(this as TwitchUser, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TwitchUser&&(identical(other.id, id) || other.id == id)&&(identical(other.login, login) || other.login == login)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.profileImageUrl, profileImageUrl) || other.profileImageUrl == profileImageUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,login,displayName,profileImageUrl,createdAt);

@override
String toString() {
  return 'TwitchUser(id: $id, login: $login, displayName: $displayName, profileImageUrl: $profileImageUrl, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $TwitchUserCopyWith<$Res>  {
  factory $TwitchUserCopyWith(TwitchUser value, $Res Function(TwitchUser) _then) = _$TwitchUserCopyWithImpl;
@useResult
$Res call({
 String id, String login, String? displayName, String? profileImageUrl,@JsonKey(fromJson: _createdAtFromJson) DateTime? createdAt
});




}
/// @nodoc
class _$TwitchUserCopyWithImpl<$Res>
    implements $TwitchUserCopyWith<$Res> {
  _$TwitchUserCopyWithImpl(this._self, this._then);

  final TwitchUser _self;
  final $Res Function(TwitchUser) _then;

/// Create a copy of TwitchUser
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? login = null,Object? displayName = freezed,Object? profileImageUrl = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,login: null == login ? _self.login : login // ignore: cast_nullable_to_non_nullable
as String,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,profileImageUrl: freezed == profileImageUrl ? _self.profileImageUrl : profileImageUrl // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [TwitchUser].
extension TwitchUserPatterns on TwitchUser {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TwitchUser value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TwitchUser() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TwitchUser value)  $default,){
final _that = this;
switch (_that) {
case _TwitchUser():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TwitchUser value)?  $default,){
final _that = this;
switch (_that) {
case _TwitchUser() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String login,  String? displayName,  String? profileImageUrl, @JsonKey(fromJson: _createdAtFromJson)  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TwitchUser() when $default != null:
return $default(_that.id,_that.login,_that.displayName,_that.profileImageUrl,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String login,  String? displayName,  String? profileImageUrl, @JsonKey(fromJson: _createdAtFromJson)  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _TwitchUser():
return $default(_that.id,_that.login,_that.displayName,_that.profileImageUrl,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String login,  String? displayName,  String? profileImageUrl, @JsonKey(fromJson: _createdAtFromJson)  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _TwitchUser() when $default != null:
return $default(_that.id,_that.login,_that.displayName,_that.profileImageUrl,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class _TwitchUser implements TwitchUser {
  const _TwitchUser({required this.id, required this.login, this.displayName, this.profileImageUrl, @JsonKey(fromJson: _createdAtFromJson) this.createdAt});
  factory _TwitchUser.fromJson(Map<String, dynamic> json) => _$TwitchUserFromJson(json);

@override final  String id;
@override final  String login;
@override final  String? displayName;
@override final  String? profileImageUrl;
@override@JsonKey(fromJson: _createdAtFromJson) final  DateTime? createdAt;

/// Create a copy of TwitchUser
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TwitchUserCopyWith<_TwitchUser> get copyWith => __$TwitchUserCopyWithImpl<_TwitchUser>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TwitchUser&&(identical(other.id, id) || other.id == id)&&(identical(other.login, login) || other.login == login)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.profileImageUrl, profileImageUrl) || other.profileImageUrl == profileImageUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,login,displayName,profileImageUrl,createdAt);

@override
String toString() {
  return 'TwitchUser(id: $id, login: $login, displayName: $displayName, profileImageUrl: $profileImageUrl, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$TwitchUserCopyWith<$Res> implements $TwitchUserCopyWith<$Res> {
  factory _$TwitchUserCopyWith(_TwitchUser value, $Res Function(_TwitchUser) _then) = __$TwitchUserCopyWithImpl;
@override @useResult
$Res call({
 String id, String login, String? displayName, String? profileImageUrl,@JsonKey(fromJson: _createdAtFromJson) DateTime? createdAt
});




}
/// @nodoc
class __$TwitchUserCopyWithImpl<$Res>
    implements _$TwitchUserCopyWith<$Res> {
  __$TwitchUserCopyWithImpl(this._self, this._then);

  final _TwitchUser _self;
  final $Res Function(_TwitchUser) _then;

/// Create a copy of TwitchUser
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? login = null,Object? displayName = freezed,Object? profileImageUrl = freezed,Object? createdAt = freezed,}) {
  return _then(_TwitchUser(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,login: null == login ? _self.login : login // ignore: cast_nullable_to_non_nullable
as String,displayName: freezed == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String?,profileImageUrl: freezed == profileImageUrl ? _self.profileImageUrl : profileImageUrl // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
