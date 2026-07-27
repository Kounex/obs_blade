// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'input.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Input {

 String? get inputKind; String? get inputName; String? get unversionedInputKind; double? get inputVolumeMul; double? get inputVolumeDb; List<InputChannel>? get inputLevelsMul; int? get syncOffset; bool get inputMuted;
/// Create a copy of Input
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InputCopyWith<Input> get copyWith => _$InputCopyWithImpl<Input>(this as Input, _$identity);

  /// Serializes this Input to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Input&&(identical(other.inputKind, inputKind) || other.inputKind == inputKind)&&(identical(other.inputName, inputName) || other.inputName == inputName)&&(identical(other.unversionedInputKind, unversionedInputKind) || other.unversionedInputKind == unversionedInputKind)&&(identical(other.inputVolumeMul, inputVolumeMul) || other.inputVolumeMul == inputVolumeMul)&&(identical(other.inputVolumeDb, inputVolumeDb) || other.inputVolumeDb == inputVolumeDb)&&const DeepCollectionEquality().equals(other.inputLevelsMul, inputLevelsMul)&&(identical(other.syncOffset, syncOffset) || other.syncOffset == syncOffset)&&(identical(other.inputMuted, inputMuted) || other.inputMuted == inputMuted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,inputKind,inputName,unversionedInputKind,inputVolumeMul,inputVolumeDb,const DeepCollectionEquality().hash(inputLevelsMul),syncOffset,inputMuted);

@override
String toString() {
  return 'Input(inputKind: $inputKind, inputName: $inputName, unversionedInputKind: $unversionedInputKind, inputVolumeMul: $inputVolumeMul, inputVolumeDb: $inputVolumeDb, inputLevelsMul: $inputLevelsMul, syncOffset: $syncOffset, inputMuted: $inputMuted)';
}


}

/// @nodoc
abstract mixin class $InputCopyWith<$Res>  {
  factory $InputCopyWith(Input value, $Res Function(Input) _then) = _$InputCopyWithImpl;
@useResult
$Res call({
 String? inputKind, String? inputName, String? unversionedInputKind, double? inputVolumeMul, double? inputVolumeDb, List<InputChannel>? inputLevelsMul, int? syncOffset, bool inputMuted
});




}
/// @nodoc
class _$InputCopyWithImpl<$Res>
    implements $InputCopyWith<$Res> {
  _$InputCopyWithImpl(this._self, this._then);

  final Input _self;
  final $Res Function(Input) _then;

/// Create a copy of Input
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? inputKind = freezed,Object? inputName = freezed,Object? unversionedInputKind = freezed,Object? inputVolumeMul = freezed,Object? inputVolumeDb = freezed,Object? inputLevelsMul = freezed,Object? syncOffset = freezed,Object? inputMuted = null,}) {
  return _then(_self.copyWith(
inputKind: freezed == inputKind ? _self.inputKind : inputKind // ignore: cast_nullable_to_non_nullable
as String?,inputName: freezed == inputName ? _self.inputName : inputName // ignore: cast_nullable_to_non_nullable
as String?,unversionedInputKind: freezed == unversionedInputKind ? _self.unversionedInputKind : unversionedInputKind // ignore: cast_nullable_to_non_nullable
as String?,inputVolumeMul: freezed == inputVolumeMul ? _self.inputVolumeMul : inputVolumeMul // ignore: cast_nullable_to_non_nullable
as double?,inputVolumeDb: freezed == inputVolumeDb ? _self.inputVolumeDb : inputVolumeDb // ignore: cast_nullable_to_non_nullable
as double?,inputLevelsMul: freezed == inputLevelsMul ? _self.inputLevelsMul : inputLevelsMul // ignore: cast_nullable_to_non_nullable
as List<InputChannel>?,syncOffset: freezed == syncOffset ? _self.syncOffset : syncOffset // ignore: cast_nullable_to_non_nullable
as int?,inputMuted: null == inputMuted ? _self.inputMuted : inputMuted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Input].
extension InputPatterns on Input {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Input value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Input() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Input value)  $default,){
final _that = this;
switch (_that) {
case _Input():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Input value)?  $default,){
final _that = this;
switch (_that) {
case _Input() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? inputKind,  String? inputName,  String? unversionedInputKind,  double? inputVolumeMul,  double? inputVolumeDb,  List<InputChannel>? inputLevelsMul,  int? syncOffset,  bool inputMuted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Input() when $default != null:
return $default(_that.inputKind,_that.inputName,_that.unversionedInputKind,_that.inputVolumeMul,_that.inputVolumeDb,_that.inputLevelsMul,_that.syncOffset,_that.inputMuted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? inputKind,  String? inputName,  String? unversionedInputKind,  double? inputVolumeMul,  double? inputVolumeDb,  List<InputChannel>? inputLevelsMul,  int? syncOffset,  bool inputMuted)  $default,) {final _that = this;
switch (_that) {
case _Input():
return $default(_that.inputKind,_that.inputName,_that.unversionedInputKind,_that.inputVolumeMul,_that.inputVolumeDb,_that.inputLevelsMul,_that.syncOffset,_that.inputMuted);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? inputKind,  String? inputName,  String? unversionedInputKind,  double? inputVolumeMul,  double? inputVolumeDb,  List<InputChannel>? inputLevelsMul,  int? syncOffset,  bool inputMuted)?  $default,) {final _that = this;
switch (_that) {
case _Input() when $default != null:
return $default(_that.inputKind,_that.inputName,_that.unversionedInputKind,_that.inputVolumeMul,_that.inputVolumeDb,_that.inputLevelsMul,_that.syncOffset,_that.inputMuted);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Input implements Input {
  const _Input({required this.inputKind, required this.inputName, required this.unversionedInputKind, this.inputVolumeMul, this.inputVolumeDb, final  List<InputChannel>? inputLevelsMul, this.syncOffset, this.inputMuted = false}): _inputLevelsMul = inputLevelsMul;
  factory _Input.fromJson(Map<String, dynamic> json) => _$InputFromJson(json);

@override final  String? inputKind;
@override final  String? inputName;
@override final  String? unversionedInputKind;
@override final  double? inputVolumeMul;
@override final  double? inputVolumeDb;
 final  List<InputChannel>? _inputLevelsMul;
@override List<InputChannel>? get inputLevelsMul {
  final value = _inputLevelsMul;
  if (value == null) return null;
  if (_inputLevelsMul is EqualUnmodifiableListView) return _inputLevelsMul;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  int? syncOffset;
@override@JsonKey() final  bool inputMuted;

/// Create a copy of Input
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InputCopyWith<_Input> get copyWith => __$InputCopyWithImpl<_Input>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InputToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Input&&(identical(other.inputKind, inputKind) || other.inputKind == inputKind)&&(identical(other.inputName, inputName) || other.inputName == inputName)&&(identical(other.unversionedInputKind, unversionedInputKind) || other.unversionedInputKind == unversionedInputKind)&&(identical(other.inputVolumeMul, inputVolumeMul) || other.inputVolumeMul == inputVolumeMul)&&(identical(other.inputVolumeDb, inputVolumeDb) || other.inputVolumeDb == inputVolumeDb)&&const DeepCollectionEquality().equals(other._inputLevelsMul, _inputLevelsMul)&&(identical(other.syncOffset, syncOffset) || other.syncOffset == syncOffset)&&(identical(other.inputMuted, inputMuted) || other.inputMuted == inputMuted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,inputKind,inputName,unversionedInputKind,inputVolumeMul,inputVolumeDb,const DeepCollectionEquality().hash(_inputLevelsMul),syncOffset,inputMuted);

@override
String toString() {
  return 'Input(inputKind: $inputKind, inputName: $inputName, unversionedInputKind: $unversionedInputKind, inputVolumeMul: $inputVolumeMul, inputVolumeDb: $inputVolumeDb, inputLevelsMul: $inputLevelsMul, syncOffset: $syncOffset, inputMuted: $inputMuted)';
}


}

/// @nodoc
abstract mixin class _$InputCopyWith<$Res> implements $InputCopyWith<$Res> {
  factory _$InputCopyWith(_Input value, $Res Function(_Input) _then) = __$InputCopyWithImpl;
@override @useResult
$Res call({
 String? inputKind, String? inputName, String? unversionedInputKind, double? inputVolumeMul, double? inputVolumeDb, List<InputChannel>? inputLevelsMul, int? syncOffset, bool inputMuted
});




}
/// @nodoc
class __$InputCopyWithImpl<$Res>
    implements _$InputCopyWith<$Res> {
  __$InputCopyWithImpl(this._self, this._then);

  final _Input _self;
  final $Res Function(_Input) _then;

/// Create a copy of Input
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? inputKind = freezed,Object? inputName = freezed,Object? unversionedInputKind = freezed,Object? inputVolumeMul = freezed,Object? inputVolumeDb = freezed,Object? inputLevelsMul = freezed,Object? syncOffset = freezed,Object? inputMuted = null,}) {
  return _then(_Input(
inputKind: freezed == inputKind ? _self.inputKind : inputKind // ignore: cast_nullable_to_non_nullable
as String?,inputName: freezed == inputName ? _self.inputName : inputName // ignore: cast_nullable_to_non_nullable
as String?,unversionedInputKind: freezed == unversionedInputKind ? _self.unversionedInputKind : unversionedInputKind // ignore: cast_nullable_to_non_nullable
as String?,inputVolumeMul: freezed == inputVolumeMul ? _self.inputVolumeMul : inputVolumeMul // ignore: cast_nullable_to_non_nullable
as double?,inputVolumeDb: freezed == inputVolumeDb ? _self.inputVolumeDb : inputVolumeDb // ignore: cast_nullable_to_non_nullable
as double?,inputLevelsMul: freezed == inputLevelsMul ? _self._inputLevelsMul : inputLevelsMul // ignore: cast_nullable_to_non_nullable
as List<InputChannel>?,syncOffset: freezed == syncOffset ? _self.syncOffset : syncOffset // ignore: cast_nullable_to_non_nullable
as int?,inputMuted: null == inputMuted ? _self.inputMuted : inputMuted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
