// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'eventsub_envelope.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EventSubEnvelope {

 EventSubMetadata get metadata; Map<String, Object?> get payload;
/// Create a copy of EventSubEnvelope
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventSubEnvelopeCopyWith<EventSubEnvelope> get copyWith => _$EventSubEnvelopeCopyWithImpl<EventSubEnvelope>(this as EventSubEnvelope, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EventSubEnvelope&&(identical(other.metadata, metadata) || other.metadata == metadata)&&const DeepCollectionEquality().equals(other.payload, payload));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,metadata,const DeepCollectionEquality().hash(payload));

@override
String toString() {
  return 'EventSubEnvelope(metadata: $metadata, payload: $payload)';
}


}

/// @nodoc
abstract mixin class $EventSubEnvelopeCopyWith<$Res>  {
  factory $EventSubEnvelopeCopyWith(EventSubEnvelope value, $Res Function(EventSubEnvelope) _then) = _$EventSubEnvelopeCopyWithImpl;
@useResult
$Res call({
 EventSubMetadata metadata, Map<String, Object?> payload
});


$EventSubMetadataCopyWith<$Res> get metadata;

}
/// @nodoc
class _$EventSubEnvelopeCopyWithImpl<$Res>
    implements $EventSubEnvelopeCopyWith<$Res> {
  _$EventSubEnvelopeCopyWithImpl(this._self, this._then);

  final EventSubEnvelope _self;
  final $Res Function(EventSubEnvelope) _then;

/// Create a copy of EventSubEnvelope
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? metadata = null,Object? payload = null,}) {
  return _then(_self.copyWith(
metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as EventSubMetadata,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}
/// Create a copy of EventSubEnvelope
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EventSubMetadataCopyWith<$Res> get metadata {
  
  return $EventSubMetadataCopyWith<$Res>(_self.metadata, (value) {
    return _then(_self.copyWith(metadata: value));
  });
}
}


/// Adds pattern-matching-related methods to [EventSubEnvelope].
extension EventSubEnvelopePatterns on EventSubEnvelope {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EventSubEnvelope value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EventSubEnvelope() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EventSubEnvelope value)  $default,){
final _that = this;
switch (_that) {
case _EventSubEnvelope():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EventSubEnvelope value)?  $default,){
final _that = this;
switch (_that) {
case _EventSubEnvelope() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( EventSubMetadata metadata,  Map<String, Object?> payload)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EventSubEnvelope() when $default != null:
return $default(_that.metadata,_that.payload);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( EventSubMetadata metadata,  Map<String, Object?> payload)  $default,) {final _that = this;
switch (_that) {
case _EventSubEnvelope():
return $default(_that.metadata,_that.payload);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( EventSubMetadata metadata,  Map<String, Object?> payload)?  $default,) {final _that = this;
switch (_that) {
case _EventSubEnvelope() when $default != null:
return $default(_that.metadata,_that.payload);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class _EventSubEnvelope implements EventSubEnvelope {
  const _EventSubEnvelope({required this.metadata, required final  Map<String, Object?> payload}): _payload = payload;
  factory _EventSubEnvelope.fromJson(Map<String, dynamic> json) => _$EventSubEnvelopeFromJson(json);

@override final  EventSubMetadata metadata;
 final  Map<String, Object?> _payload;
@override Map<String, Object?> get payload {
  if (_payload is EqualUnmodifiableMapView) return _payload;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_payload);
}


/// Create a copy of EventSubEnvelope
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EventSubEnvelopeCopyWith<_EventSubEnvelope> get copyWith => __$EventSubEnvelopeCopyWithImpl<_EventSubEnvelope>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EventSubEnvelope&&(identical(other.metadata, metadata) || other.metadata == metadata)&&const DeepCollectionEquality().equals(other._payload, _payload));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,metadata,const DeepCollectionEquality().hash(_payload));

@override
String toString() {
  return 'EventSubEnvelope(metadata: $metadata, payload: $payload)';
}


}

/// @nodoc
abstract mixin class _$EventSubEnvelopeCopyWith<$Res> implements $EventSubEnvelopeCopyWith<$Res> {
  factory _$EventSubEnvelopeCopyWith(_EventSubEnvelope value, $Res Function(_EventSubEnvelope) _then) = __$EventSubEnvelopeCopyWithImpl;
@override @useResult
$Res call({
 EventSubMetadata metadata, Map<String, Object?> payload
});


@override $EventSubMetadataCopyWith<$Res> get metadata;

}
/// @nodoc
class __$EventSubEnvelopeCopyWithImpl<$Res>
    implements _$EventSubEnvelopeCopyWith<$Res> {
  __$EventSubEnvelopeCopyWithImpl(this._self, this._then);

  final _EventSubEnvelope _self;
  final $Res Function(_EventSubEnvelope) _then;

/// Create a copy of EventSubEnvelope
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? metadata = null,Object? payload = null,}) {
  return _then(_EventSubEnvelope(
metadata: null == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as EventSubMetadata,payload: null == payload ? _self._payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

/// Create a copy of EventSubEnvelope
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EventSubMetadataCopyWith<$Res> get metadata {
  
  return $EventSubMetadataCopyWith<$Res>(_self.metadata, (value) {
    return _then(_self.copyWith(metadata: value));
  });
}
}


/// @nodoc
mixin _$EventSubMetadata {

 String get messageId; String get messageType; String? get subscriptionType;
/// Create a copy of EventSubMetadata
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EventSubMetadataCopyWith<EventSubMetadata> get copyWith => _$EventSubMetadataCopyWithImpl<EventSubMetadata>(this as EventSubMetadata, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EventSubMetadata&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.messageType, messageType) || other.messageType == messageType)&&(identical(other.subscriptionType, subscriptionType) || other.subscriptionType == subscriptionType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,messageId,messageType,subscriptionType);

@override
String toString() {
  return 'EventSubMetadata(messageId: $messageId, messageType: $messageType, subscriptionType: $subscriptionType)';
}


}

/// @nodoc
abstract mixin class $EventSubMetadataCopyWith<$Res>  {
  factory $EventSubMetadataCopyWith(EventSubMetadata value, $Res Function(EventSubMetadata) _then) = _$EventSubMetadataCopyWithImpl;
@useResult
$Res call({
 String messageId, String messageType, String? subscriptionType
});




}
/// @nodoc
class _$EventSubMetadataCopyWithImpl<$Res>
    implements $EventSubMetadataCopyWith<$Res> {
  _$EventSubMetadataCopyWithImpl(this._self, this._then);

  final EventSubMetadata _self;
  final $Res Function(EventSubMetadata) _then;

/// Create a copy of EventSubMetadata
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? messageId = null,Object? messageType = null,Object? subscriptionType = freezed,}) {
  return _then(_self.copyWith(
messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,messageType: null == messageType ? _self.messageType : messageType // ignore: cast_nullable_to_non_nullable
as String,subscriptionType: freezed == subscriptionType ? _self.subscriptionType : subscriptionType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [EventSubMetadata].
extension EventSubMetadataPatterns on EventSubMetadata {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EventSubMetadata value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EventSubMetadata() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EventSubMetadata value)  $default,){
final _that = this;
switch (_that) {
case _EventSubMetadata():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EventSubMetadata value)?  $default,){
final _that = this;
switch (_that) {
case _EventSubMetadata() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String messageId,  String messageType,  String? subscriptionType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EventSubMetadata() when $default != null:
return $default(_that.messageId,_that.messageType,_that.subscriptionType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String messageId,  String messageType,  String? subscriptionType)  $default,) {final _that = this;
switch (_that) {
case _EventSubMetadata():
return $default(_that.messageId,_that.messageType,_that.subscriptionType);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String messageId,  String messageType,  String? subscriptionType)?  $default,) {final _that = this;
switch (_that) {
case _EventSubMetadata() when $default != null:
return $default(_that.messageId,_that.messageType,_that.subscriptionType);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class _EventSubMetadata implements EventSubMetadata {
  const _EventSubMetadata({required this.messageId, required this.messageType, this.subscriptionType});
  factory _EventSubMetadata.fromJson(Map<String, dynamic> json) => _$EventSubMetadataFromJson(json);

@override final  String messageId;
@override final  String messageType;
@override final  String? subscriptionType;

/// Create a copy of EventSubMetadata
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EventSubMetadataCopyWith<_EventSubMetadata> get copyWith => __$EventSubMetadataCopyWithImpl<_EventSubMetadata>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EventSubMetadata&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.messageType, messageType) || other.messageType == messageType)&&(identical(other.subscriptionType, subscriptionType) || other.subscriptionType == subscriptionType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,messageId,messageType,subscriptionType);

@override
String toString() {
  return 'EventSubMetadata(messageId: $messageId, messageType: $messageType, subscriptionType: $subscriptionType)';
}


}

/// @nodoc
abstract mixin class _$EventSubMetadataCopyWith<$Res> implements $EventSubMetadataCopyWith<$Res> {
  factory _$EventSubMetadataCopyWith(_EventSubMetadata value, $Res Function(_EventSubMetadata) _then) = __$EventSubMetadataCopyWithImpl;
@override @useResult
$Res call({
 String messageId, String messageType, String? subscriptionType
});




}
/// @nodoc
class __$EventSubMetadataCopyWithImpl<$Res>
    implements _$EventSubMetadataCopyWith<$Res> {
  __$EventSubMetadataCopyWithImpl(this._self, this._then);

  final _EventSubMetadata _self;
  final $Res Function(_EventSubMetadata) _then;

/// Create a copy of EventSubMetadata
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? messageId = null,Object? messageType = null,Object? subscriptionType = freezed,}) {
  return _then(_EventSubMetadata(
messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,messageType: null == messageType ? _self.messageType : messageType // ignore: cast_nullable_to_non_nullable
as String,subscriptionType: freezed == subscriptionType ? _self.subscriptionType : subscriptionType // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
