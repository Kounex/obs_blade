// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transition.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Transition {

/// Name of the transition
 String get transitionName;/// Kind of the transition
 String get transitionKind;/// Whether the transition uses a fixed (unconfigurable) duration
 bool get transitionFixed;/// Configured transition duration in milliseconds. null if transition is fixed
 int? get transitionDuration;/// Whether the transition supports being configured
 bool get transitionConfigurable;/// Object of settings for the transition. null if transition is not configurable
 dynamic get transitionSettings;
/// Create a copy of Transition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransitionCopyWith<Transition> get copyWith => _$TransitionCopyWithImpl<Transition>(this as Transition, _$identity);

  /// Serializes this Transition to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Transition&&(identical(other.transitionName, transitionName) || other.transitionName == transitionName)&&(identical(other.transitionKind, transitionKind) || other.transitionKind == transitionKind)&&(identical(other.transitionFixed, transitionFixed) || other.transitionFixed == transitionFixed)&&(identical(other.transitionDuration, transitionDuration) || other.transitionDuration == transitionDuration)&&(identical(other.transitionConfigurable, transitionConfigurable) || other.transitionConfigurable == transitionConfigurable)&&const DeepCollectionEquality().equals(other.transitionSettings, transitionSettings));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,transitionName,transitionKind,transitionFixed,transitionDuration,transitionConfigurable,const DeepCollectionEquality().hash(transitionSettings));

@override
String toString() {
  return 'Transition(transitionName: $transitionName, transitionKind: $transitionKind, transitionFixed: $transitionFixed, transitionDuration: $transitionDuration, transitionConfigurable: $transitionConfigurable, transitionSettings: $transitionSettings)';
}


}

/// @nodoc
abstract mixin class $TransitionCopyWith<$Res>  {
  factory $TransitionCopyWith(Transition value, $Res Function(Transition) _then) = _$TransitionCopyWithImpl;
@useResult
$Res call({
 String transitionName, String transitionKind, bool transitionFixed, int? transitionDuration, bool transitionConfigurable, dynamic transitionSettings
});




}
/// @nodoc
class _$TransitionCopyWithImpl<$Res>
    implements $TransitionCopyWith<$Res> {
  _$TransitionCopyWithImpl(this._self, this._then);

  final Transition _self;
  final $Res Function(Transition) _then;

/// Create a copy of Transition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? transitionName = null,Object? transitionKind = null,Object? transitionFixed = null,Object? transitionDuration = freezed,Object? transitionConfigurable = null,Object? transitionSettings = freezed,}) {
  return _then(_self.copyWith(
transitionName: null == transitionName ? _self.transitionName : transitionName // ignore: cast_nullable_to_non_nullable
as String,transitionKind: null == transitionKind ? _self.transitionKind : transitionKind // ignore: cast_nullable_to_non_nullable
as String,transitionFixed: null == transitionFixed ? _self.transitionFixed : transitionFixed // ignore: cast_nullable_to_non_nullable
as bool,transitionDuration: freezed == transitionDuration ? _self.transitionDuration : transitionDuration // ignore: cast_nullable_to_non_nullable
as int?,transitionConfigurable: null == transitionConfigurable ? _self.transitionConfigurable : transitionConfigurable // ignore: cast_nullable_to_non_nullable
as bool,transitionSettings: freezed == transitionSettings ? _self.transitionSettings : transitionSettings // ignore: cast_nullable_to_non_nullable
as dynamic,
  ));
}

}


/// Adds pattern-matching-related methods to [Transition].
extension TransitionPatterns on Transition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Transition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Transition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Transition value)  $default,){
final _that = this;
switch (_that) {
case _Transition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Transition value)?  $default,){
final _that = this;
switch (_that) {
case _Transition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String transitionName,  String transitionKind,  bool transitionFixed,  int? transitionDuration,  bool transitionConfigurable,  dynamic transitionSettings)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Transition() when $default != null:
return $default(_that.transitionName,_that.transitionKind,_that.transitionFixed,_that.transitionDuration,_that.transitionConfigurable,_that.transitionSettings);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String transitionName,  String transitionKind,  bool transitionFixed,  int? transitionDuration,  bool transitionConfigurable,  dynamic transitionSettings)  $default,) {final _that = this;
switch (_that) {
case _Transition():
return $default(_that.transitionName,_that.transitionKind,_that.transitionFixed,_that.transitionDuration,_that.transitionConfigurable,_that.transitionSettings);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String transitionName,  String transitionKind,  bool transitionFixed,  int? transitionDuration,  bool transitionConfigurable,  dynamic transitionSettings)?  $default,) {final _that = this;
switch (_that) {
case _Transition() when $default != null:
return $default(_that.transitionName,_that.transitionKind,_that.transitionFixed,_that.transitionDuration,_that.transitionConfigurable,_that.transitionSettings);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Transition implements Transition {
  const _Transition({required this.transitionName, required this.transitionKind, required this.transitionFixed, required this.transitionDuration, required this.transitionConfigurable, required this.transitionSettings});
  factory _Transition.fromJson(Map<String, dynamic> json) => _$TransitionFromJson(json);

/// Name of the transition
@override final  String transitionName;
/// Kind of the transition
@override final  String transitionKind;
/// Whether the transition uses a fixed (unconfigurable) duration
@override final  bool transitionFixed;
/// Configured transition duration in milliseconds. null if transition is fixed
@override final  int? transitionDuration;
/// Whether the transition supports being configured
@override final  bool transitionConfigurable;
/// Object of settings for the transition. null if transition is not configurable
@override final  dynamic transitionSettings;

/// Create a copy of Transition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransitionCopyWith<_Transition> get copyWith => __$TransitionCopyWithImpl<_Transition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TransitionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Transition&&(identical(other.transitionName, transitionName) || other.transitionName == transitionName)&&(identical(other.transitionKind, transitionKind) || other.transitionKind == transitionKind)&&(identical(other.transitionFixed, transitionFixed) || other.transitionFixed == transitionFixed)&&(identical(other.transitionDuration, transitionDuration) || other.transitionDuration == transitionDuration)&&(identical(other.transitionConfigurable, transitionConfigurable) || other.transitionConfigurable == transitionConfigurable)&&const DeepCollectionEquality().equals(other.transitionSettings, transitionSettings));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,transitionName,transitionKind,transitionFixed,transitionDuration,transitionConfigurable,const DeepCollectionEquality().hash(transitionSettings));

@override
String toString() {
  return 'Transition(transitionName: $transitionName, transitionKind: $transitionKind, transitionFixed: $transitionFixed, transitionDuration: $transitionDuration, transitionConfigurable: $transitionConfigurable, transitionSettings: $transitionSettings)';
}


}

/// @nodoc
abstract mixin class _$TransitionCopyWith<$Res> implements $TransitionCopyWith<$Res> {
  factory _$TransitionCopyWith(_Transition value, $Res Function(_Transition) _then) = __$TransitionCopyWithImpl;
@override @useResult
$Res call({
 String transitionName, String transitionKind, bool transitionFixed, int? transitionDuration, bool transitionConfigurable, dynamic transitionSettings
});




}
/// @nodoc
class __$TransitionCopyWithImpl<$Res>
    implements _$TransitionCopyWith<$Res> {
  __$TransitionCopyWithImpl(this._self, this._then);

  final _Transition _self;
  final $Res Function(_Transition) _then;

/// Create a copy of Transition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? transitionName = null,Object? transitionKind = null,Object? transitionFixed = null,Object? transitionDuration = freezed,Object? transitionConfigurable = null,Object? transitionSettings = freezed,}) {
  return _then(_Transition(
transitionName: null == transitionName ? _self.transitionName : transitionName // ignore: cast_nullable_to_non_nullable
as String,transitionKind: null == transitionKind ? _self.transitionKind : transitionKind // ignore: cast_nullable_to_non_nullable
as String,transitionFixed: null == transitionFixed ? _self.transitionFixed : transitionFixed // ignore: cast_nullable_to_non_nullable
as bool,transitionDuration: freezed == transitionDuration ? _self.transitionDuration : transitionDuration // ignore: cast_nullable_to_non_nullable
as int?,transitionConfigurable: null == transitionConfigurable ? _self.transitionConfigurable : transitionConfigurable // ignore: cast_nullable_to_non_nullable
as bool,transitionSettings: freezed == transitionSettings ? _self.transitionSettings : transitionSettings // ignore: cast_nullable_to_non_nullable
as dynamic,
  ));
}


}

// dart format on
