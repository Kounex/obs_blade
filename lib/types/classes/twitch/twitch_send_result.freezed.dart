// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'twitch_send_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TwitchSendResult {

 String get messageId; bool get isSent; TwitchDropReason? get dropReason;
/// Create a copy of TwitchSendResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TwitchSendResultCopyWith<TwitchSendResult> get copyWith => _$TwitchSendResultCopyWithImpl<TwitchSendResult>(this as TwitchSendResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TwitchSendResult&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.isSent, isSent) || other.isSent == isSent)&&(identical(other.dropReason, dropReason) || other.dropReason == dropReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,messageId,isSent,dropReason);

@override
String toString() {
  return 'TwitchSendResult(messageId: $messageId, isSent: $isSent, dropReason: $dropReason)';
}


}

/// @nodoc
abstract mixin class $TwitchSendResultCopyWith<$Res>  {
  factory $TwitchSendResultCopyWith(TwitchSendResult value, $Res Function(TwitchSendResult) _then) = _$TwitchSendResultCopyWithImpl;
@useResult
$Res call({
 String messageId, bool isSent, TwitchDropReason? dropReason
});


$TwitchDropReasonCopyWith<$Res>? get dropReason;

}
/// @nodoc
class _$TwitchSendResultCopyWithImpl<$Res>
    implements $TwitchSendResultCopyWith<$Res> {
  _$TwitchSendResultCopyWithImpl(this._self, this._then);

  final TwitchSendResult _self;
  final $Res Function(TwitchSendResult) _then;

/// Create a copy of TwitchSendResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? messageId = null,Object? isSent = null,Object? dropReason = freezed,}) {
  return _then(_self.copyWith(
messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,isSent: null == isSent ? _self.isSent : isSent // ignore: cast_nullable_to_non_nullable
as bool,dropReason: freezed == dropReason ? _self.dropReason : dropReason // ignore: cast_nullable_to_non_nullable
as TwitchDropReason?,
  ));
}
/// Create a copy of TwitchSendResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TwitchDropReasonCopyWith<$Res>? get dropReason {
    if (_self.dropReason == null) {
    return null;
  }

  return $TwitchDropReasonCopyWith<$Res>(_self.dropReason!, (value) {
    return _then(_self.copyWith(dropReason: value));
  });
}
}


/// Adds pattern-matching-related methods to [TwitchSendResult].
extension TwitchSendResultPatterns on TwitchSendResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TwitchSendResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TwitchSendResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TwitchSendResult value)  $default,){
final _that = this;
switch (_that) {
case _TwitchSendResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TwitchSendResult value)?  $default,){
final _that = this;
switch (_that) {
case _TwitchSendResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String messageId,  bool isSent,  TwitchDropReason? dropReason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TwitchSendResult() when $default != null:
return $default(_that.messageId,_that.isSent,_that.dropReason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String messageId,  bool isSent,  TwitchDropReason? dropReason)  $default,) {final _that = this;
switch (_that) {
case _TwitchSendResult():
return $default(_that.messageId,_that.isSent,_that.dropReason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String messageId,  bool isSent,  TwitchDropReason? dropReason)?  $default,) {final _that = this;
switch (_that) {
case _TwitchSendResult() when $default != null:
return $default(_that.messageId,_that.isSent,_that.dropReason);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class _TwitchSendResult implements TwitchSendResult {
  const _TwitchSendResult({required this.messageId, required this.isSent, this.dropReason});
  factory _TwitchSendResult.fromJson(Map<String, dynamic> json) => _$TwitchSendResultFromJson(json);

@override final  String messageId;
@override final  bool isSent;
@override final  TwitchDropReason? dropReason;

/// Create a copy of TwitchSendResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TwitchSendResultCopyWith<_TwitchSendResult> get copyWith => __$TwitchSendResultCopyWithImpl<_TwitchSendResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TwitchSendResult&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.isSent, isSent) || other.isSent == isSent)&&(identical(other.dropReason, dropReason) || other.dropReason == dropReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,messageId,isSent,dropReason);

@override
String toString() {
  return 'TwitchSendResult(messageId: $messageId, isSent: $isSent, dropReason: $dropReason)';
}


}

/// @nodoc
abstract mixin class _$TwitchSendResultCopyWith<$Res> implements $TwitchSendResultCopyWith<$Res> {
  factory _$TwitchSendResultCopyWith(_TwitchSendResult value, $Res Function(_TwitchSendResult) _then) = __$TwitchSendResultCopyWithImpl;
@override @useResult
$Res call({
 String messageId, bool isSent, TwitchDropReason? dropReason
});


@override $TwitchDropReasonCopyWith<$Res>? get dropReason;

}
/// @nodoc
class __$TwitchSendResultCopyWithImpl<$Res>
    implements _$TwitchSendResultCopyWith<$Res> {
  __$TwitchSendResultCopyWithImpl(this._self, this._then);

  final _TwitchSendResult _self;
  final $Res Function(_TwitchSendResult) _then;

/// Create a copy of TwitchSendResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? messageId = null,Object? isSent = null,Object? dropReason = freezed,}) {
  return _then(_TwitchSendResult(
messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,isSent: null == isSent ? _self.isSent : isSent // ignore: cast_nullable_to_non_nullable
as bool,dropReason: freezed == dropReason ? _self.dropReason : dropReason // ignore: cast_nullable_to_non_nullable
as TwitchDropReason?,
  ));
}

/// Create a copy of TwitchSendResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TwitchDropReasonCopyWith<$Res>? get dropReason {
    if (_self.dropReason == null) {
    return null;
  }

  return $TwitchDropReasonCopyWith<$Res>(_self.dropReason!, (value) {
    return _then(_self.copyWith(dropReason: value));
  });
}
}

// dart format on
