// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'youtube_token.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$YouTubeToken {

 String get accessToken; String? get refreshToken; int get expiresIn;@JsonKey(fromJson: _scopesFromJson) List<String> get scope; String? get tokenType;
/// Create a copy of YouTubeToken
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$YouTubeTokenCopyWith<YouTubeToken> get copyWith => _$YouTubeTokenCopyWithImpl<YouTubeToken>(this as YouTubeToken, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is YouTubeToken&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken)&&(identical(other.expiresIn, expiresIn) || other.expiresIn == expiresIn)&&const DeepCollectionEquality().equals(other.scope, scope)&&(identical(other.tokenType, tokenType) || other.tokenType == tokenType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accessToken,refreshToken,expiresIn,const DeepCollectionEquality().hash(scope),tokenType);

@override
String toString() {
  return 'YouTubeToken(accessToken: $accessToken, refreshToken: $refreshToken, expiresIn: $expiresIn, scope: $scope, tokenType: $tokenType)';
}


}

/// @nodoc
abstract mixin class $YouTubeTokenCopyWith<$Res>  {
  factory $YouTubeTokenCopyWith(YouTubeToken value, $Res Function(YouTubeToken) _then) = _$YouTubeTokenCopyWithImpl;
@useResult
$Res call({
 String accessToken, String? refreshToken, int expiresIn,@JsonKey(fromJson: _scopesFromJson) List<String> scope, String? tokenType
});




}
/// @nodoc
class _$YouTubeTokenCopyWithImpl<$Res>
    implements $YouTubeTokenCopyWith<$Res> {
  _$YouTubeTokenCopyWithImpl(this._self, this._then);

  final YouTubeToken _self;
  final $Res Function(YouTubeToken) _then;

/// Create a copy of YouTubeToken
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


/// Adds pattern-matching-related methods to [YouTubeToken].
extension YouTubeTokenPatterns on YouTubeToken {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _YouTubeToken value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _YouTubeToken() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _YouTubeToken value)  $default,){
final _that = this;
switch (_that) {
case _YouTubeToken():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _YouTubeToken value)?  $default,){
final _that = this;
switch (_that) {
case _YouTubeToken() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String accessToken,  String? refreshToken,  int expiresIn, @JsonKey(fromJson: _scopesFromJson)  List<String> scope,  String? tokenType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _YouTubeToken() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String accessToken,  String? refreshToken,  int expiresIn, @JsonKey(fromJson: _scopesFromJson)  List<String> scope,  String? tokenType)  $default,) {final _that = this;
switch (_that) {
case _YouTubeToken():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String accessToken,  String? refreshToken,  int expiresIn, @JsonKey(fromJson: _scopesFromJson)  List<String> scope,  String? tokenType)?  $default,) {final _that = this;
switch (_that) {
case _YouTubeToken() when $default != null:
return $default(_that.accessToken,_that.refreshToken,_that.expiresIn,_that.scope,_that.tokenType);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class _YouTubeToken implements YouTubeToken {
  const _YouTubeToken({required this.accessToken, this.refreshToken, required this.expiresIn, @JsonKey(fromJson: _scopesFromJson) final  List<String> scope = const <String>[], this.tokenType}): _scope = scope;
  factory _YouTubeToken.fromJson(Map<String, dynamic> json) => _$YouTubeTokenFromJson(json);

@override final  String accessToken;
@override final  String? refreshToken;
@override final  int expiresIn;
 final  List<String> _scope;
@override@JsonKey(fromJson: _scopesFromJson) List<String> get scope {
  if (_scope is EqualUnmodifiableListView) return _scope;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_scope);
}

@override final  String? tokenType;

/// Create a copy of YouTubeToken
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$YouTubeTokenCopyWith<_YouTubeToken> get copyWith => __$YouTubeTokenCopyWithImpl<_YouTubeToken>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _YouTubeToken&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken)&&(identical(other.expiresIn, expiresIn) || other.expiresIn == expiresIn)&&const DeepCollectionEquality().equals(other._scope, _scope)&&(identical(other.tokenType, tokenType) || other.tokenType == tokenType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accessToken,refreshToken,expiresIn,const DeepCollectionEquality().hash(_scope),tokenType);

@override
String toString() {
  return 'YouTubeToken(accessToken: $accessToken, refreshToken: $refreshToken, expiresIn: $expiresIn, scope: $scope, tokenType: $tokenType)';
}


}

/// @nodoc
abstract mixin class _$YouTubeTokenCopyWith<$Res> implements $YouTubeTokenCopyWith<$Res> {
  factory _$YouTubeTokenCopyWith(_YouTubeToken value, $Res Function(_YouTubeToken) _then) = __$YouTubeTokenCopyWithImpl;
@override @useResult
$Res call({
 String accessToken, String? refreshToken, int expiresIn,@JsonKey(fromJson: _scopesFromJson) List<String> scope, String? tokenType
});




}
/// @nodoc
class __$YouTubeTokenCopyWithImpl<$Res>
    implements _$YouTubeTokenCopyWith<$Res> {
  __$YouTubeTokenCopyWithImpl(this._self, this._then);

  final _YouTubeToken _self;
  final $Res Function(_YouTubeToken) _then;

/// Create a copy of YouTubeToken
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? accessToken = null,Object? refreshToken = freezed,Object? expiresIn = null,Object? scope = null,Object? tokenType = freezed,}) {
  return _then(_YouTubeToken(
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
