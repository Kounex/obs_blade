// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'twitch_token.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TwitchToken {

 String get accessToken; String? get refreshToken; int get expiresIn; List<String> get scope; String? get tokenType;
/// Create a copy of TwitchToken
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TwitchTokenCopyWith<TwitchToken> get copyWith => _$TwitchTokenCopyWithImpl<TwitchToken>(this as TwitchToken, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TwitchToken&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken)&&(identical(other.expiresIn, expiresIn) || other.expiresIn == expiresIn)&&const DeepCollectionEquality().equals(other.scope, scope)&&(identical(other.tokenType, tokenType) || other.tokenType == tokenType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accessToken,refreshToken,expiresIn,const DeepCollectionEquality().hash(scope),tokenType);

@override
String toString() {
  return 'TwitchToken(accessToken: $accessToken, refreshToken: $refreshToken, expiresIn: $expiresIn, scope: $scope, tokenType: $tokenType)';
}


}

/// @nodoc
abstract mixin class $TwitchTokenCopyWith<$Res>  {
  factory $TwitchTokenCopyWith(TwitchToken value, $Res Function(TwitchToken) _then) = _$TwitchTokenCopyWithImpl;
@useResult
$Res call({
 String accessToken, String? refreshToken, int expiresIn, List<String> scope, String? tokenType
});




}
/// @nodoc
class _$TwitchTokenCopyWithImpl<$Res>
    implements $TwitchTokenCopyWith<$Res> {
  _$TwitchTokenCopyWithImpl(this._self, this._then);

  final TwitchToken _self;
  final $Res Function(TwitchToken) _then;

/// Create a copy of TwitchToken
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? accessToken = null,Object? refreshToken = freezed,Object? expiresIn = null,Object? scope = null,Object? tokenType = freezed,}) {
  return _then(_self.copyWith(
accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,refreshToken: freezed == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String?,expiresIn: null == expiresIn ? _self.expiresIn : expiresIn // ignore: cast_nullable_to_non_nullable
as int,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as List<String>,tokenType: freezed == tokenType ? _self.tokenType : tokenType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TwitchToken].
extension TwitchTokenPatterns on TwitchToken {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TwitchToken value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TwitchToken() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TwitchToken value)  $default,){
final _that = this;
switch (_that) {
case _TwitchToken():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TwitchToken value)?  $default,){
final _that = this;
switch (_that) {
case _TwitchToken() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String accessToken,  String? refreshToken,  int expiresIn,  List<String> scope,  String? tokenType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TwitchToken() when $default != null:
return $default(_that.accessToken,_that.refreshToken,_that.expiresIn,_that.scope,_that.tokenType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String accessToken,  String? refreshToken,  int expiresIn,  List<String> scope,  String? tokenType)  $default,) {final _that = this;
switch (_that) {
case _TwitchToken():
return $default(_that.accessToken,_that.refreshToken,_that.expiresIn,_that.scope,_that.tokenType);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String accessToken,  String? refreshToken,  int expiresIn,  List<String> scope,  String? tokenType)?  $default,) {final _that = this;
switch (_that) {
case _TwitchToken() when $default != null:
return $default(_that.accessToken,_that.refreshToken,_that.expiresIn,_that.scope,_that.tokenType);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class _TwitchToken implements TwitchToken {
  const _TwitchToken({required this.accessToken, this.refreshToken, required this.expiresIn, final  List<String> scope = const <String>[], this.tokenType}): _scope = scope;
  factory _TwitchToken.fromJson(Map<String, dynamic> json) => _$TwitchTokenFromJson(json);

@override final  String accessToken;
@override final  String? refreshToken;
@override final  int expiresIn;
 final  List<String> _scope;
@override@JsonKey() List<String> get scope {
  if (_scope is EqualUnmodifiableListView) return _scope;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_scope);
}

@override final  String? tokenType;

/// Create a copy of TwitchToken
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TwitchTokenCopyWith<_TwitchToken> get copyWith => __$TwitchTokenCopyWithImpl<_TwitchToken>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TwitchToken&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken)&&(identical(other.expiresIn, expiresIn) || other.expiresIn == expiresIn)&&const DeepCollectionEquality().equals(other._scope, _scope)&&(identical(other.tokenType, tokenType) || other.tokenType == tokenType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accessToken,refreshToken,expiresIn,const DeepCollectionEquality().hash(_scope),tokenType);

@override
String toString() {
  return 'TwitchToken(accessToken: $accessToken, refreshToken: $refreshToken, expiresIn: $expiresIn, scope: $scope, tokenType: $tokenType)';
}


}

/// @nodoc
abstract mixin class _$TwitchTokenCopyWith<$Res> implements $TwitchTokenCopyWith<$Res> {
  factory _$TwitchTokenCopyWith(_TwitchToken value, $Res Function(_TwitchToken) _then) = __$TwitchTokenCopyWithImpl;
@override @useResult
$Res call({
 String accessToken, String? refreshToken, int expiresIn, List<String> scope, String? tokenType
});




}
/// @nodoc
class __$TwitchTokenCopyWithImpl<$Res>
    implements _$TwitchTokenCopyWith<$Res> {
  __$TwitchTokenCopyWithImpl(this._self, this._then);

  final _TwitchToken _self;
  final $Res Function(_TwitchToken) _then;

/// Create a copy of TwitchToken
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? accessToken = null,Object? refreshToken = freezed,Object? expiresIn = null,Object? scope = null,Object? tokenType = freezed,}) {
  return _then(_TwitchToken(
accessToken: null == accessToken ? _self.accessToken : accessToken // ignore: cast_nullable_to_non_nullable
as String,refreshToken: freezed == refreshToken ? _self.refreshToken : refreshToken // ignore: cast_nullable_to_non_nullable
as String?,expiresIn: null == expiresIn ? _self.expiresIn : expiresIn // ignore: cast_nullable_to_non_nullable
as int,scope: null == scope ? _self._scope : scope // ignore: cast_nullable_to_non_nullable
as List<String>,tokenType: freezed == tokenType ? _self.tokenType : tokenType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
