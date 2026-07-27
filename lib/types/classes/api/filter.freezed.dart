// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'filter.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Filter {

 bool get filterEnabled; int get filterIndex; String get filterKind; String get filterName; Map<String, dynamic> get filterSettings;
/// Create a copy of Filter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FilterCopyWith<Filter> get copyWith => _$FilterCopyWithImpl<Filter>(this as Filter, _$identity);

  /// Serializes this Filter to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Filter&&(identical(other.filterEnabled, filterEnabled) || other.filterEnabled == filterEnabled)&&(identical(other.filterIndex, filterIndex) || other.filterIndex == filterIndex)&&(identical(other.filterKind, filterKind) || other.filterKind == filterKind)&&(identical(other.filterName, filterName) || other.filterName == filterName)&&const DeepCollectionEquality().equals(other.filterSettings, filterSettings));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,filterEnabled,filterIndex,filterKind,filterName,const DeepCollectionEquality().hash(filterSettings));

@override
String toString() {
  return 'Filter(filterEnabled: $filterEnabled, filterIndex: $filterIndex, filterKind: $filterKind, filterName: $filterName, filterSettings: $filterSettings)';
}


}

/// @nodoc
abstract mixin class $FilterCopyWith<$Res>  {
  factory $FilterCopyWith(Filter value, $Res Function(Filter) _then) = _$FilterCopyWithImpl;
@useResult
$Res call({
 bool filterEnabled, int filterIndex, String filterKind, String filterName, Map<String, dynamic> filterSettings
});




}
/// @nodoc
class _$FilterCopyWithImpl<$Res>
    implements $FilterCopyWith<$Res> {
  _$FilterCopyWithImpl(this._self, this._then);

  final Filter _self;
  final $Res Function(Filter) _then;

/// Create a copy of Filter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? filterEnabled = null,Object? filterIndex = null,Object? filterKind = null,Object? filterName = null,Object? filterSettings = null,}) {
  return _then(_self.copyWith(
filterEnabled: null == filterEnabled ? _self.filterEnabled : filterEnabled // ignore: cast_nullable_to_non_nullable
as bool,filterIndex: null == filterIndex ? _self.filterIndex : filterIndex // ignore: cast_nullable_to_non_nullable
as int,filterKind: null == filterKind ? _self.filterKind : filterKind // ignore: cast_nullable_to_non_nullable
as String,filterName: null == filterName ? _self.filterName : filterName // ignore: cast_nullable_to_non_nullable
as String,filterSettings: null == filterSettings ? _self.filterSettings : filterSettings // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [Filter].
extension FilterPatterns on Filter {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Filter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Filter() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Filter value)  $default,){
final _that = this;
switch (_that) {
case _Filter():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Filter value)?  $default,){
final _that = this;
switch (_that) {
case _Filter() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool filterEnabled,  int filterIndex,  String filterKind,  String filterName,  Map<String, dynamic> filterSettings)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Filter() when $default != null:
return $default(_that.filterEnabled,_that.filterIndex,_that.filterKind,_that.filterName,_that.filterSettings);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool filterEnabled,  int filterIndex,  String filterKind,  String filterName,  Map<String, dynamic> filterSettings)  $default,) {final _that = this;
switch (_that) {
case _Filter():
return $default(_that.filterEnabled,_that.filterIndex,_that.filterKind,_that.filterName,_that.filterSettings);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool filterEnabled,  int filterIndex,  String filterKind,  String filterName,  Map<String, dynamic> filterSettings)?  $default,) {final _that = this;
switch (_that) {
case _Filter() when $default != null:
return $default(_that.filterEnabled,_that.filterIndex,_that.filterKind,_that.filterName,_that.filterSettings);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Filter implements Filter {
  const _Filter({required this.filterEnabled, required this.filterIndex, required this.filterKind, required this.filterName, required final  Map<String, dynamic> filterSettings}): _filterSettings = filterSettings;
  factory _Filter.fromJson(Map<String, dynamic> json) => _$FilterFromJson(json);

@override final  bool filterEnabled;
@override final  int filterIndex;
@override final  String filterKind;
@override final  String filterName;
 final  Map<String, dynamic> _filterSettings;
@override Map<String, dynamic> get filterSettings {
  if (_filterSettings is EqualUnmodifiableMapView) return _filterSettings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_filterSettings);
}


/// Create a copy of Filter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FilterCopyWith<_Filter> get copyWith => __$FilterCopyWithImpl<_Filter>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FilterToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Filter&&(identical(other.filterEnabled, filterEnabled) || other.filterEnabled == filterEnabled)&&(identical(other.filterIndex, filterIndex) || other.filterIndex == filterIndex)&&(identical(other.filterKind, filterKind) || other.filterKind == filterKind)&&(identical(other.filterName, filterName) || other.filterName == filterName)&&const DeepCollectionEquality().equals(other._filterSettings, _filterSettings));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,filterEnabled,filterIndex,filterKind,filterName,const DeepCollectionEquality().hash(_filterSettings));

@override
String toString() {
  return 'Filter(filterEnabled: $filterEnabled, filterIndex: $filterIndex, filterKind: $filterKind, filterName: $filterName, filterSettings: $filterSettings)';
}


}

/// @nodoc
abstract mixin class _$FilterCopyWith<$Res> implements $FilterCopyWith<$Res> {
  factory _$FilterCopyWith(_Filter value, $Res Function(_Filter) _then) = __$FilterCopyWithImpl;
@override @useResult
$Res call({
 bool filterEnabled, int filterIndex, String filterKind, String filterName, Map<String, dynamic> filterSettings
});




}
/// @nodoc
class __$FilterCopyWithImpl<$Res>
    implements _$FilterCopyWith<$Res> {
  __$FilterCopyWithImpl(this._self, this._then);

  final _Filter _self;
  final $Res Function(_Filter) _then;

/// Create a copy of Filter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? filterEnabled = null,Object? filterIndex = null,Object? filterKind = null,Object? filterName = null,Object? filterSettings = null,}) {
  return _then(_Filter(
filterEnabled: null == filterEnabled ? _self.filterEnabled : filterEnabled // ignore: cast_nullable_to_non_nullable
as bool,filterIndex: null == filterIndex ? _self.filterIndex : filterIndex // ignore: cast_nullable_to_non_nullable
as int,filterKind: null == filterKind ? _self.filterKind : filterKind // ignore: cast_nullable_to_non_nullable
as String,filterName: null == filterName ? _self.filterName : filterName // ignore: cast_nullable_to_non_nullable
as String,filterSettings: null == filterSettings ? _self._filterSettings : filterSettings // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

// dart format on
