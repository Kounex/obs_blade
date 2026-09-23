// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'kick_emote.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$KickEmote {

 int get id; String get name;@JsonKey(name: 'subscribers_only') bool get subscribersOnly;
/// Create a copy of KickEmote
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KickEmoteCopyWith<KickEmote> get copyWith => _$KickEmoteCopyWithImpl<KickEmote>(this as KickEmote, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KickEmote&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.subscribersOnly, subscribersOnly) || other.subscribersOnly == subscribersOnly));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,subscribersOnly);

@override
String toString() {
  return 'KickEmote(id: $id, name: $name, subscribersOnly: $subscribersOnly)';
}


}

/// @nodoc
abstract mixin class $KickEmoteCopyWith<$Res>  {
  factory $KickEmoteCopyWith(KickEmote value, $Res Function(KickEmote) _then) = _$KickEmoteCopyWithImpl;
@useResult
$Res call({
 int id, String name,@JsonKey(name: 'subscribers_only') bool subscribersOnly
});




}
/// @nodoc
class _$KickEmoteCopyWithImpl<$Res>
    implements $KickEmoteCopyWith<$Res> {
  _$KickEmoteCopyWithImpl(this._self, this._then);

  final KickEmote _self;
  final $Res Function(KickEmote) _then;

/// Create a copy of KickEmote
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? subscribersOnly = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,subscribersOnly: null == subscribersOnly ? _self.subscribersOnly : subscribersOnly // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [KickEmote].
extension KickEmotePatterns on KickEmote {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _KickEmote value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _KickEmote() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _KickEmote value)  $default,){
final _that = this;
switch (_that) {
case _KickEmote():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _KickEmote value)?  $default,){
final _that = this;
switch (_that) {
case _KickEmote() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name, @JsonKey(name: 'subscribers_only')  bool subscribersOnly)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _KickEmote() when $default != null:
return $default(_that.id,_that.name,_that.subscribersOnly);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name, @JsonKey(name: 'subscribers_only')  bool subscribersOnly)  $default,) {final _that = this;
switch (_that) {
case _KickEmote():
return $default(_that.id,_that.name,_that.subscribersOnly);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name, @JsonKey(name: 'subscribers_only')  bool subscribersOnly)?  $default,) {final _that = this;
switch (_that) {
case _KickEmote() when $default != null:
return $default(_that.id,_that.name,_that.subscribersOnly);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable(createToJson: false)

class _KickEmote implements KickEmote {
  const _KickEmote({required this.id, required this.name, @JsonKey(name: 'subscribers_only') this.subscribersOnly = false});
  factory _KickEmote.fromJson(Map<String, dynamic> json) => _$KickEmoteFromJson(json);

@override final  int id;
@override final  String name;
@override@JsonKey(name: 'subscribers_only') final  bool subscribersOnly;

/// Create a copy of KickEmote
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$KickEmoteCopyWith<_KickEmote> get copyWith => __$KickEmoteCopyWithImpl<_KickEmote>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _KickEmote&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.subscribersOnly, subscribersOnly) || other.subscribersOnly == subscribersOnly));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,subscribersOnly);

@override
String toString() {
  return 'KickEmote(id: $id, name: $name, subscribersOnly: $subscribersOnly)';
}


}

/// @nodoc
abstract mixin class _$KickEmoteCopyWith<$Res> implements $KickEmoteCopyWith<$Res> {
  factory _$KickEmoteCopyWith(_KickEmote value, $Res Function(_KickEmote) _then) = __$KickEmoteCopyWithImpl;
@override @useResult
$Res call({
 int id, String name,@JsonKey(name: 'subscribers_only') bool subscribersOnly
});




}
/// @nodoc
class __$KickEmoteCopyWithImpl<$Res>
    implements _$KickEmoteCopyWith<$Res> {
  __$KickEmoteCopyWithImpl(this._self, this._then);

  final _KickEmote _self;
  final $Res Function(_KickEmote) _then;

/// Create a copy of KickEmote
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? subscribersOnly = null,}) {
  return _then(_KickEmote(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,subscribersOnly: null == subscribersOnly ? _self.subscribersOnly : subscribersOnly // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
