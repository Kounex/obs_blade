// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'twitch_chat_badges.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TwitchBadgeSet {

 String get setId; List<TwitchBadgeVersion> get versions;
/// Create a copy of TwitchBadgeSet
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TwitchBadgeSetCopyWith<TwitchBadgeSet> get copyWith => _$TwitchBadgeSetCopyWithImpl<TwitchBadgeSet>(this as TwitchBadgeSet, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TwitchBadgeSet&&(identical(other.setId, setId) || other.setId == setId)&&const DeepCollectionEquality().equals(other.versions, versions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,setId,const DeepCollectionEquality().hash(versions));

@override
String toString() {
  return 'TwitchBadgeSet(setId: $setId, versions: $versions)';
}


}

/// @nodoc
abstract mixin class $TwitchBadgeSetCopyWith<$Res>  {
  factory $TwitchBadgeSetCopyWith(TwitchBadgeSet value, $Res Function(TwitchBadgeSet) _then) = _$TwitchBadgeSetCopyWithImpl;
@useResult
$Res call({
 String setId, List<TwitchBadgeVersion> versions
});




}
/// @nodoc
class _$TwitchBadgeSetCopyWithImpl<$Res>
    implements $TwitchBadgeSetCopyWith<$Res> {
  _$TwitchBadgeSetCopyWithImpl(this._self, this._then);

  final TwitchBadgeSet _self;
  final $Res Function(TwitchBadgeSet) _then;

/// Create a copy of TwitchBadgeSet
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? setId = null,Object? versions = null,}) {
  return _then(_self.copyWith(
setId: null == setId ? _self.setId : setId // ignore: cast_nullable_to_non_nullable
as String,versions: null == versions ? _self.versions : versions // ignore: cast_nullable_to_non_nullable
as List<TwitchBadgeVersion>,
  ));
}

}


/// Adds pattern-matching-related methods to [TwitchBadgeSet].
extension TwitchBadgeSetPatterns on TwitchBadgeSet {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TwitchBadgeSet value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TwitchBadgeSet() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TwitchBadgeSet value)  $default,){
final _that = this;
switch (_that) {
case _TwitchBadgeSet():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TwitchBadgeSet value)?  $default,){
final _that = this;
switch (_that) {
case _TwitchBadgeSet() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String setId,  List<TwitchBadgeVersion> versions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TwitchBadgeSet() when $default != null:
return $default(_that.setId,_that.versions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String setId,  List<TwitchBadgeVersion> versions)  $default,) {final _that = this;
switch (_that) {
case _TwitchBadgeSet():
return $default(_that.setId,_that.versions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String setId,  List<TwitchBadgeVersion> versions)?  $default,) {final _that = this;
switch (_that) {
case _TwitchBadgeSet() when $default != null:
return $default(_that.setId,_that.versions);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class _TwitchBadgeSet implements TwitchBadgeSet {
  const _TwitchBadgeSet({required this.setId, final  List<TwitchBadgeVersion> versions = const <TwitchBadgeVersion>[]}): _versions = versions;
  factory _TwitchBadgeSet.fromJson(Map<String, dynamic> json) => _$TwitchBadgeSetFromJson(json);

@override final  String setId;
 final  List<TwitchBadgeVersion> _versions;
@override@JsonKey() List<TwitchBadgeVersion> get versions {
  if (_versions is EqualUnmodifiableListView) return _versions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_versions);
}


/// Create a copy of TwitchBadgeSet
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TwitchBadgeSetCopyWith<_TwitchBadgeSet> get copyWith => __$TwitchBadgeSetCopyWithImpl<_TwitchBadgeSet>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TwitchBadgeSet&&(identical(other.setId, setId) || other.setId == setId)&&const DeepCollectionEquality().equals(other._versions, _versions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,setId,const DeepCollectionEquality().hash(_versions));

@override
String toString() {
  return 'TwitchBadgeSet(setId: $setId, versions: $versions)';
}


}

/// @nodoc
abstract mixin class _$TwitchBadgeSetCopyWith<$Res> implements $TwitchBadgeSetCopyWith<$Res> {
  factory _$TwitchBadgeSetCopyWith(_TwitchBadgeSet value, $Res Function(_TwitchBadgeSet) _then) = __$TwitchBadgeSetCopyWithImpl;
@override @useResult
$Res call({
 String setId, List<TwitchBadgeVersion> versions
});




}
/// @nodoc
class __$TwitchBadgeSetCopyWithImpl<$Res>
    implements _$TwitchBadgeSetCopyWith<$Res> {
  __$TwitchBadgeSetCopyWithImpl(this._self, this._then);

  final _TwitchBadgeSet _self;
  final $Res Function(_TwitchBadgeSet) _then;

/// Create a copy of TwitchBadgeSet
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? setId = null,Object? versions = null,}) {
  return _then(_TwitchBadgeSet(
setId: null == setId ? _self.setId : setId // ignore: cast_nullable_to_non_nullable
as String,versions: null == versions ? _self._versions : versions // ignore: cast_nullable_to_non_nullable
as List<TwitchBadgeVersion>,
  ));
}


}


/// @nodoc
mixin _$TwitchBadgeVersion {

 String get id;@JsonKey(name: 'image_url_1x') String get imageUrl1x;@JsonKey(name: 'image_url_2x') String get imageUrl2x;@JsonKey(name: 'image_url_4x') String get imageUrl4x; String? get title;
/// Create a copy of TwitchBadgeVersion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TwitchBadgeVersionCopyWith<TwitchBadgeVersion> get copyWith => _$TwitchBadgeVersionCopyWithImpl<TwitchBadgeVersion>(this as TwitchBadgeVersion, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TwitchBadgeVersion&&(identical(other.id, id) || other.id == id)&&(identical(other.imageUrl1x, imageUrl1x) || other.imageUrl1x == imageUrl1x)&&(identical(other.imageUrl2x, imageUrl2x) || other.imageUrl2x == imageUrl2x)&&(identical(other.imageUrl4x, imageUrl4x) || other.imageUrl4x == imageUrl4x)&&(identical(other.title, title) || other.title == title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,imageUrl1x,imageUrl2x,imageUrl4x,title);

@override
String toString() {
  return 'TwitchBadgeVersion(id: $id, imageUrl1x: $imageUrl1x, imageUrl2x: $imageUrl2x, imageUrl4x: $imageUrl4x, title: $title)';
}


}

/// @nodoc
abstract mixin class $TwitchBadgeVersionCopyWith<$Res>  {
  factory $TwitchBadgeVersionCopyWith(TwitchBadgeVersion value, $Res Function(TwitchBadgeVersion) _then) = _$TwitchBadgeVersionCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(name: 'image_url_1x') String imageUrl1x,@JsonKey(name: 'image_url_2x') String imageUrl2x,@JsonKey(name: 'image_url_4x') String imageUrl4x, String? title
});




}
/// @nodoc
class _$TwitchBadgeVersionCopyWithImpl<$Res>
    implements $TwitchBadgeVersionCopyWith<$Res> {
  _$TwitchBadgeVersionCopyWithImpl(this._self, this._then);

  final TwitchBadgeVersion _self;
  final $Res Function(TwitchBadgeVersion) _then;

/// Create a copy of TwitchBadgeVersion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? imageUrl1x = null,Object? imageUrl2x = null,Object? imageUrl4x = null,Object? title = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,imageUrl1x: null == imageUrl1x ? _self.imageUrl1x : imageUrl1x // ignore: cast_nullable_to_non_nullable
as String,imageUrl2x: null == imageUrl2x ? _self.imageUrl2x : imageUrl2x // ignore: cast_nullable_to_non_nullable
as String,imageUrl4x: null == imageUrl4x ? _self.imageUrl4x : imageUrl4x // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TwitchBadgeVersion].
extension TwitchBadgeVersionPatterns on TwitchBadgeVersion {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TwitchBadgeVersion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TwitchBadgeVersion() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TwitchBadgeVersion value)  $default,){
final _that = this;
switch (_that) {
case _TwitchBadgeVersion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TwitchBadgeVersion value)?  $default,){
final _that = this;
switch (_that) {
case _TwitchBadgeVersion() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'image_url_1x')  String imageUrl1x, @JsonKey(name: 'image_url_2x')  String imageUrl2x, @JsonKey(name: 'image_url_4x')  String imageUrl4x,  String? title)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TwitchBadgeVersion() when $default != null:
return $default(_that.id,_that.imageUrl1x,_that.imageUrl2x,_that.imageUrl4x,_that.title);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(name: 'image_url_1x')  String imageUrl1x, @JsonKey(name: 'image_url_2x')  String imageUrl2x, @JsonKey(name: 'image_url_4x')  String imageUrl4x,  String? title)  $default,) {final _that = this;
switch (_that) {
case _TwitchBadgeVersion():
return $default(_that.id,_that.imageUrl1x,_that.imageUrl2x,_that.imageUrl4x,_that.title);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(name: 'image_url_1x')  String imageUrl1x, @JsonKey(name: 'image_url_2x')  String imageUrl2x, @JsonKey(name: 'image_url_4x')  String imageUrl4x,  String? title)?  $default,) {final _that = this;
switch (_that) {
case _TwitchBadgeVersion() when $default != null:
return $default(_that.id,_that.imageUrl1x,_that.imageUrl2x,_that.imageUrl4x,_that.title);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class _TwitchBadgeVersion implements TwitchBadgeVersion {
  const _TwitchBadgeVersion({required this.id, @JsonKey(name: 'image_url_1x') required this.imageUrl1x, @JsonKey(name: 'image_url_2x') required this.imageUrl2x, @JsonKey(name: 'image_url_4x') required this.imageUrl4x, this.title});
  factory _TwitchBadgeVersion.fromJson(Map<String, dynamic> json) => _$TwitchBadgeVersionFromJson(json);

@override final  String id;
@override@JsonKey(name: 'image_url_1x') final  String imageUrl1x;
@override@JsonKey(name: 'image_url_2x') final  String imageUrl2x;
@override@JsonKey(name: 'image_url_4x') final  String imageUrl4x;
@override final  String? title;

/// Create a copy of TwitchBadgeVersion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TwitchBadgeVersionCopyWith<_TwitchBadgeVersion> get copyWith => __$TwitchBadgeVersionCopyWithImpl<_TwitchBadgeVersion>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TwitchBadgeVersion&&(identical(other.id, id) || other.id == id)&&(identical(other.imageUrl1x, imageUrl1x) || other.imageUrl1x == imageUrl1x)&&(identical(other.imageUrl2x, imageUrl2x) || other.imageUrl2x == imageUrl2x)&&(identical(other.imageUrl4x, imageUrl4x) || other.imageUrl4x == imageUrl4x)&&(identical(other.title, title) || other.title == title));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,imageUrl1x,imageUrl2x,imageUrl4x,title);

@override
String toString() {
  return 'TwitchBadgeVersion(id: $id, imageUrl1x: $imageUrl1x, imageUrl2x: $imageUrl2x, imageUrl4x: $imageUrl4x, title: $title)';
}


}

/// @nodoc
abstract mixin class _$TwitchBadgeVersionCopyWith<$Res> implements $TwitchBadgeVersionCopyWith<$Res> {
  factory _$TwitchBadgeVersionCopyWith(_TwitchBadgeVersion value, $Res Function(_TwitchBadgeVersion) _then) = __$TwitchBadgeVersionCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(name: 'image_url_1x') String imageUrl1x,@JsonKey(name: 'image_url_2x') String imageUrl2x,@JsonKey(name: 'image_url_4x') String imageUrl4x, String? title
});




}
/// @nodoc
class __$TwitchBadgeVersionCopyWithImpl<$Res>
    implements _$TwitchBadgeVersionCopyWith<$Res> {
  __$TwitchBadgeVersionCopyWithImpl(this._self, this._then);

  final _TwitchBadgeVersion _self;
  final $Res Function(_TwitchBadgeVersion) _then;

/// Create a copy of TwitchBadgeVersion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? imageUrl1x = null,Object? imageUrl2x = null,Object? imageUrl4x = null,Object? title = freezed,}) {
  return _then(_TwitchBadgeVersion(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,imageUrl1x: null == imageUrl1x ? _self.imageUrl1x : imageUrl1x // ignore: cast_nullable_to_non_nullable
as String,imageUrl2x: null == imageUrl2x ? _self.imageUrl2x : imageUrl2x // ignore: cast_nullable_to_non_nullable
as String,imageUrl4x: null == imageUrl4x ? _self.imageUrl4x : imageUrl4x // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
