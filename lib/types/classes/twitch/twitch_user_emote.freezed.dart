// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'twitch_user_emote.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TwitchUserEmote {

 String get id; String get name; String get ownerId; String get emoteType; String get emoteSetId;
/// Create a copy of TwitchUserEmote
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TwitchUserEmoteCopyWith<TwitchUserEmote> get copyWith => _$TwitchUserEmoteCopyWithImpl<TwitchUserEmote>(this as TwitchUserEmote, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TwitchUserEmote&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.emoteType, emoteType) || other.emoteType == emoteType)&&(identical(other.emoteSetId, emoteSetId) || other.emoteSetId == emoteSetId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,ownerId,emoteType,emoteSetId);

@override
String toString() {
  return 'TwitchUserEmote(id: $id, name: $name, ownerId: $ownerId, emoteType: $emoteType, emoteSetId: $emoteSetId)';
}


}

/// @nodoc
abstract mixin class $TwitchUserEmoteCopyWith<$Res>  {
  factory $TwitchUserEmoteCopyWith(TwitchUserEmote value, $Res Function(TwitchUserEmote) _then) = _$TwitchUserEmoteCopyWithImpl;
@useResult
$Res call({
 String id, String name, String ownerId, String emoteType, String emoteSetId
});




}
/// @nodoc
class _$TwitchUserEmoteCopyWithImpl<$Res>
    implements $TwitchUserEmoteCopyWith<$Res> {
  _$TwitchUserEmoteCopyWithImpl(this._self, this._then);

  final TwitchUserEmote _self;
  final $Res Function(TwitchUserEmote) _then;

/// Create a copy of TwitchUserEmote
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? ownerId = null,Object? emoteType = null,Object? emoteSetId = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String,emoteType: null == emoteType ? _self.emoteType : emoteType // ignore: cast_nullable_to_non_nullable
as String,emoteSetId: null == emoteSetId ? _self.emoteSetId : emoteSetId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TwitchUserEmote].
extension TwitchUserEmotePatterns on TwitchUserEmote {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TwitchUserEmote value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TwitchUserEmote() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TwitchUserEmote value)  $default,){
final _that = this;
switch (_that) {
case _TwitchUserEmote():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TwitchUserEmote value)?  $default,){
final _that = this;
switch (_that) {
case _TwitchUserEmote() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String ownerId,  String emoteType,  String emoteSetId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TwitchUserEmote() when $default != null:
return $default(_that.id,_that.name,_that.ownerId,_that.emoteType,_that.emoteSetId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String ownerId,  String emoteType,  String emoteSetId)  $default,) {final _that = this;
switch (_that) {
case _TwitchUserEmote():
return $default(_that.id,_that.name,_that.ownerId,_that.emoteType,_that.emoteSetId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String ownerId,  String emoteType,  String emoteSetId)?  $default,) {final _that = this;
switch (_that) {
case _TwitchUserEmote() when $default != null:
return $default(_that.id,_that.name,_that.ownerId,_that.emoteType,_that.emoteSetId);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class _TwitchUserEmote implements TwitchUserEmote {
  const _TwitchUserEmote({required this.id, required this.name, required this.ownerId, this.emoteType = '', this.emoteSetId = ''});
  factory _TwitchUserEmote.fromJson(Map<String, dynamic> json) => _$TwitchUserEmoteFromJson(json);

@override final  String id;
@override final  String name;
@override final  String ownerId;
@override@JsonKey() final  String emoteType;
@override@JsonKey() final  String emoteSetId;

/// Create a copy of TwitchUserEmote
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TwitchUserEmoteCopyWith<_TwitchUserEmote> get copyWith => __$TwitchUserEmoteCopyWithImpl<_TwitchUserEmote>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TwitchUserEmote&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.emoteType, emoteType) || other.emoteType == emoteType)&&(identical(other.emoteSetId, emoteSetId) || other.emoteSetId == emoteSetId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,ownerId,emoteType,emoteSetId);

@override
String toString() {
  return 'TwitchUserEmote(id: $id, name: $name, ownerId: $ownerId, emoteType: $emoteType, emoteSetId: $emoteSetId)';
}


}

/// @nodoc
abstract mixin class _$TwitchUserEmoteCopyWith<$Res> implements $TwitchUserEmoteCopyWith<$Res> {
  factory _$TwitchUserEmoteCopyWith(_TwitchUserEmote value, $Res Function(_TwitchUserEmote) _then) = __$TwitchUserEmoteCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String ownerId, String emoteType, String emoteSetId
});




}
/// @nodoc
class __$TwitchUserEmoteCopyWithImpl<$Res>
    implements _$TwitchUserEmoteCopyWith<$Res> {
  __$TwitchUserEmoteCopyWithImpl(this._self, this._then);

  final _TwitchUserEmote _self;
  final $Res Function(_TwitchUserEmote) _then;

/// Create a copy of TwitchUserEmote
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? ownerId = null,Object? emoteType = null,Object? emoteSetId = null,}) {
  return _then(_TwitchUserEmote(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String,emoteType: null == emoteType ? _self.emoteType : emoteType // ignore: cast_nullable_to_non_nullable
as String,emoteSetId: null == emoteSetId ? _self.emoteSetId : emoteSetId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
