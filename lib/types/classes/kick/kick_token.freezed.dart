// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'kick_token.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$KickToken {

 String get accessToken; String? get refreshToken; int get expiresIn;@JsonKey(fromJson: _scopesFromJson) List<String> get scope; String? get tokenType;
/// Create a copy of KickToken
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KickTokenCopyWith<KickToken> get copyWith => _$KickTokenCopyWithImpl<KickToken>(this as KickToken, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KickToken&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken)&&(identical(other.expiresIn, expiresIn) || other.expiresIn == expiresIn)&&const DeepCollectionEquality().equals(other.scope, scope)&&(identical(other.tokenType, tokenType) || other.tokenType == tokenType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accessToken,refreshToken,expiresIn,const DeepCollectionEquality().hash(scope),tokenType);

@override
String toString() {
  return 'KickToken(accessToken: $accessToken, refreshToken: $refreshToken, expiresIn: $expiresIn, scope: $scope, tokenType: $tokenType)';
}


}

/// @nodoc
abstract mixin class $KickTokenCopyWith<$Res>  {
  factory $KickTokenCopyWith(KickToken value, $Res Function(KickToken) _then) = _$KickTokenCopyWithImpl;
@useResult
$Res call({
 String accessToken, String? refreshToken, int expiresIn,@JsonKey(fromJson: _scopesFromJson) List<String> scope, String? tokenType
});




}
/// @nodoc
class _$KickTokenCopyWithImpl<$Res>
    implements $KickTokenCopyWith<$Res> {
  _$KickTokenCopyWithImpl(this._self, this._then);

  final KickToken _self;
  final $Res Function(KickToken) _then;

/// Create a copy of KickToken
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


/// Adds pattern-matching-related methods to [KickToken].
extension KickTokenPatterns on KickToken {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _KickToken value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _KickToken() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _KickToken value)  $default,){
final _that = this;
switch (_that) {
case _KickToken():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _KickToken value)?  $default,){
final _that = this;
switch (_that) {
case _KickToken() when $default != null:
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
case _KickToken() when $default != null:
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
case _KickToken():
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
case _KickToken() when $default != null:
return $default(_that.accessToken,_that.refreshToken,_that.expiresIn,_that.scope,_that.tokenType);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class _KickToken implements KickToken {
  const _KickToken({required this.accessToken, this.refreshToken, required this.expiresIn, @JsonKey(fromJson: _scopesFromJson) final  List<String> scope = const <String>[], this.tokenType}): _scope = scope;
  factory _KickToken.fromJson(Map<String, dynamic> json) => _$KickTokenFromJson(json);

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

/// Create a copy of KickToken
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$KickTokenCopyWith<_KickToken> get copyWith => __$KickTokenCopyWithImpl<_KickToken>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _KickToken&&(identical(other.accessToken, accessToken) || other.accessToken == accessToken)&&(identical(other.refreshToken, refreshToken) || other.refreshToken == refreshToken)&&(identical(other.expiresIn, expiresIn) || other.expiresIn == expiresIn)&&const DeepCollectionEquality().equals(other._scope, _scope)&&(identical(other.tokenType, tokenType) || other.tokenType == tokenType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,accessToken,refreshToken,expiresIn,const DeepCollectionEquality().hash(_scope),tokenType);

@override
String toString() {
  return 'KickToken(accessToken: $accessToken, refreshToken: $refreshToken, expiresIn: $expiresIn, scope: $scope, tokenType: $tokenType)';
}


}

/// @nodoc
abstract mixin class _$KickTokenCopyWith<$Res> implements $KickTokenCopyWith<$Res> {
  factory _$KickTokenCopyWith(_KickToken value, $Res Function(_KickToken) _then) = __$KickTokenCopyWithImpl;
@override @useResult
$Res call({
 String accessToken, String? refreshToken, int expiresIn,@JsonKey(fromJson: _scopesFromJson) List<String> scope, String? tokenType
});




}
/// @nodoc
class __$KickTokenCopyWithImpl<$Res>
    implements _$KickTokenCopyWith<$Res> {
  __$KickTokenCopyWithImpl(this._self, this._then);

  final _KickToken _self;
  final $Res Function(_KickToken) _then;

/// Create a copy of KickToken
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? accessToken = null,Object? refreshToken = freezed,Object? expiresIn = null,Object? scope = null,Object? tokenType = freezed,}) {
  return _then(_KickToken(
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
