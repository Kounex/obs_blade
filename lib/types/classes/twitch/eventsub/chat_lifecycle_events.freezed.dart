// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_lifecycle_events.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChatMessageDeleteEvent {

 String get messageId; String get targetUserId; String get userName;
/// Create a copy of ChatMessageDeleteEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatMessageDeleteEventCopyWith<ChatMessageDeleteEvent> get copyWith => _$ChatMessageDeleteEventCopyWithImpl<ChatMessageDeleteEvent>(this as ChatMessageDeleteEvent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMessageDeleteEvent&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.targetUserId, targetUserId) || other.targetUserId == targetUserId)&&(identical(other.userName, userName) || other.userName == userName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,messageId,targetUserId,userName);

@override
String toString() {
  return 'ChatMessageDeleteEvent(messageId: $messageId, targetUserId: $targetUserId, userName: $userName)';
}


}

/// @nodoc
abstract mixin class $ChatMessageDeleteEventCopyWith<$Res>  {
  factory $ChatMessageDeleteEventCopyWith(ChatMessageDeleteEvent value, $Res Function(ChatMessageDeleteEvent) _then) = _$ChatMessageDeleteEventCopyWithImpl;
@useResult
$Res call({
 String messageId, String targetUserId, String userName
});




}
/// @nodoc
class _$ChatMessageDeleteEventCopyWithImpl<$Res>
    implements $ChatMessageDeleteEventCopyWith<$Res> {
  _$ChatMessageDeleteEventCopyWithImpl(this._self, this._then);

  final ChatMessageDeleteEvent _self;
  final $Res Function(ChatMessageDeleteEvent) _then;

/// Create a copy of ChatMessageDeleteEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? messageId = null,Object? targetUserId = null,Object? userName = null,}) {
  return _then(_self.copyWith(
messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,targetUserId: null == targetUserId ? _self.targetUserId : targetUserId // ignore: cast_nullable_to_non_nullable
as String,userName: null == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatMessageDeleteEvent].
extension ChatMessageDeleteEventPatterns on ChatMessageDeleteEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatMessageDeleteEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatMessageDeleteEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatMessageDeleteEvent value)  $default,){
final _that = this;
switch (_that) {
case _ChatMessageDeleteEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatMessageDeleteEvent value)?  $default,){
final _that = this;
switch (_that) {
case _ChatMessageDeleteEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String messageId,  String targetUserId,  String userName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatMessageDeleteEvent() when $default != null:
return $default(_that.messageId,_that.targetUserId,_that.userName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String messageId,  String targetUserId,  String userName)  $default,) {final _that = this;
switch (_that) {
case _ChatMessageDeleteEvent():
return $default(_that.messageId,_that.targetUserId,_that.userName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String messageId,  String targetUserId,  String userName)?  $default,) {final _that = this;
switch (_that) {
case _ChatMessageDeleteEvent() when $default != null:
return $default(_that.messageId,_that.targetUserId,_that.userName);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class _ChatMessageDeleteEvent implements ChatMessageDeleteEvent {
  const _ChatMessageDeleteEvent({required this.messageId, required this.targetUserId, required this.userName});
  factory _ChatMessageDeleteEvent.fromJson(Map<String, dynamic> json) => _$ChatMessageDeleteEventFromJson(json);

@override final  String messageId;
@override final  String targetUserId;
@override final  String userName;

/// Create a copy of ChatMessageDeleteEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatMessageDeleteEventCopyWith<_ChatMessageDeleteEvent> get copyWith => __$ChatMessageDeleteEventCopyWithImpl<_ChatMessageDeleteEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatMessageDeleteEvent&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.targetUserId, targetUserId) || other.targetUserId == targetUserId)&&(identical(other.userName, userName) || other.userName == userName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,messageId,targetUserId,userName);

@override
String toString() {
  return 'ChatMessageDeleteEvent(messageId: $messageId, targetUserId: $targetUserId, userName: $userName)';
}


}

/// @nodoc
abstract mixin class _$ChatMessageDeleteEventCopyWith<$Res> implements $ChatMessageDeleteEventCopyWith<$Res> {
  factory _$ChatMessageDeleteEventCopyWith(_ChatMessageDeleteEvent value, $Res Function(_ChatMessageDeleteEvent) _then) = __$ChatMessageDeleteEventCopyWithImpl;
@override @useResult
$Res call({
 String messageId, String targetUserId, String userName
});




}
/// @nodoc
class __$ChatMessageDeleteEventCopyWithImpl<$Res>
    implements _$ChatMessageDeleteEventCopyWith<$Res> {
  __$ChatMessageDeleteEventCopyWithImpl(this._self, this._then);

  final _ChatMessageDeleteEvent _self;
  final $Res Function(_ChatMessageDeleteEvent) _then;

/// Create a copy of ChatMessageDeleteEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? messageId = null,Object? targetUserId = null,Object? userName = null,}) {
  return _then(_ChatMessageDeleteEvent(
messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,targetUserId: null == targetUserId ? _self.targetUserId : targetUserId // ignore: cast_nullable_to_non_nullable
as String,userName: null == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ChatClearUserMessagesEvent {

 String get targetUserId;
/// Create a copy of ChatClearUserMessagesEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatClearUserMessagesEventCopyWith<ChatClearUserMessagesEvent> get copyWith => _$ChatClearUserMessagesEventCopyWithImpl<ChatClearUserMessagesEvent>(this as ChatClearUserMessagesEvent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatClearUserMessagesEvent&&(identical(other.targetUserId, targetUserId) || other.targetUserId == targetUserId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,targetUserId);

@override
String toString() {
  return 'ChatClearUserMessagesEvent(targetUserId: $targetUserId)';
}


}

/// @nodoc
abstract mixin class $ChatClearUserMessagesEventCopyWith<$Res>  {
  factory $ChatClearUserMessagesEventCopyWith(ChatClearUserMessagesEvent value, $Res Function(ChatClearUserMessagesEvent) _then) = _$ChatClearUserMessagesEventCopyWithImpl;
@useResult
$Res call({
 String targetUserId
});




}
/// @nodoc
class _$ChatClearUserMessagesEventCopyWithImpl<$Res>
    implements $ChatClearUserMessagesEventCopyWith<$Res> {
  _$ChatClearUserMessagesEventCopyWithImpl(this._self, this._then);

  final ChatClearUserMessagesEvent _self;
  final $Res Function(ChatClearUserMessagesEvent) _then;

/// Create a copy of ChatClearUserMessagesEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? targetUserId = null,}) {
  return _then(_self.copyWith(
targetUserId: null == targetUserId ? _self.targetUserId : targetUserId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatClearUserMessagesEvent].
extension ChatClearUserMessagesEventPatterns on ChatClearUserMessagesEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatClearUserMessagesEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatClearUserMessagesEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatClearUserMessagesEvent value)  $default,){
final _that = this;
switch (_that) {
case _ChatClearUserMessagesEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatClearUserMessagesEvent value)?  $default,){
final _that = this;
switch (_that) {
case _ChatClearUserMessagesEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String targetUserId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatClearUserMessagesEvent() when $default != null:
return $default(_that.targetUserId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String targetUserId)  $default,) {final _that = this;
switch (_that) {
case _ChatClearUserMessagesEvent():
return $default(_that.targetUserId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String targetUserId)?  $default,) {final _that = this;
switch (_that) {
case _ChatClearUserMessagesEvent() when $default != null:
return $default(_that.targetUserId);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class _ChatClearUserMessagesEvent implements ChatClearUserMessagesEvent {
  const _ChatClearUserMessagesEvent({required this.targetUserId});
  factory _ChatClearUserMessagesEvent.fromJson(Map<String, dynamic> json) => _$ChatClearUserMessagesEventFromJson(json);

@override final  String targetUserId;

/// Create a copy of ChatClearUserMessagesEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatClearUserMessagesEventCopyWith<_ChatClearUserMessagesEvent> get copyWith => __$ChatClearUserMessagesEventCopyWithImpl<_ChatClearUserMessagesEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatClearUserMessagesEvent&&(identical(other.targetUserId, targetUserId) || other.targetUserId == targetUserId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,targetUserId);

@override
String toString() {
  return 'ChatClearUserMessagesEvent(targetUserId: $targetUserId)';
}


}

/// @nodoc
abstract mixin class _$ChatClearUserMessagesEventCopyWith<$Res> implements $ChatClearUserMessagesEventCopyWith<$Res> {
  factory _$ChatClearUserMessagesEventCopyWith(_ChatClearUserMessagesEvent value, $Res Function(_ChatClearUserMessagesEvent) _then) = __$ChatClearUserMessagesEventCopyWithImpl;
@override @useResult
$Res call({
 String targetUserId
});




}
/// @nodoc
class __$ChatClearUserMessagesEventCopyWithImpl<$Res>
    implements _$ChatClearUserMessagesEventCopyWith<$Res> {
  __$ChatClearUserMessagesEventCopyWithImpl(this._self, this._then);

  final _ChatClearUserMessagesEvent _self;
  final $Res Function(_ChatClearUserMessagesEvent) _then;

/// Create a copy of ChatClearUserMessagesEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? targetUserId = null,}) {
  return _then(_ChatClearUserMessagesEvent(
targetUserId: null == targetUserId ? _self.targetUserId : targetUserId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ChatClearEvent {

 String get broadcasterUserId;
/// Create a copy of ChatClearEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatClearEventCopyWith<ChatClearEvent> get copyWith => _$ChatClearEventCopyWithImpl<ChatClearEvent>(this as ChatClearEvent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatClearEvent&&(identical(other.broadcasterUserId, broadcasterUserId) || other.broadcasterUserId == broadcasterUserId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,broadcasterUserId);

@override
String toString() {
  return 'ChatClearEvent(broadcasterUserId: $broadcasterUserId)';
}


}

/// @nodoc
abstract mixin class $ChatClearEventCopyWith<$Res>  {
  factory $ChatClearEventCopyWith(ChatClearEvent value, $Res Function(ChatClearEvent) _then) = _$ChatClearEventCopyWithImpl;
@useResult
$Res call({
 String broadcasterUserId
});




}
/// @nodoc
class _$ChatClearEventCopyWithImpl<$Res>
    implements $ChatClearEventCopyWith<$Res> {
  _$ChatClearEventCopyWithImpl(this._self, this._then);

  final ChatClearEvent _self;
  final $Res Function(ChatClearEvent) _then;

/// Create a copy of ChatClearEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? broadcasterUserId = null,}) {
  return _then(_self.copyWith(
broadcasterUserId: null == broadcasterUserId ? _self.broadcasterUserId : broadcasterUserId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatClearEvent].
extension ChatClearEventPatterns on ChatClearEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatClearEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatClearEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatClearEvent value)  $default,){
final _that = this;
switch (_that) {
case _ChatClearEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatClearEvent value)?  $default,){
final _that = this;
switch (_that) {
case _ChatClearEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String broadcasterUserId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatClearEvent() when $default != null:
return $default(_that.broadcasterUserId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String broadcasterUserId)  $default,) {final _that = this;
switch (_that) {
case _ChatClearEvent():
return $default(_that.broadcasterUserId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String broadcasterUserId)?  $default,) {final _that = this;
switch (_that) {
case _ChatClearEvent() when $default != null:
return $default(_that.broadcasterUserId);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class _ChatClearEvent implements ChatClearEvent {
  const _ChatClearEvent({required this.broadcasterUserId});
  factory _ChatClearEvent.fromJson(Map<String, dynamic> json) => _$ChatClearEventFromJson(json);

@override final  String broadcasterUserId;

/// Create a copy of ChatClearEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatClearEventCopyWith<_ChatClearEvent> get copyWith => __$ChatClearEventCopyWithImpl<_ChatClearEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatClearEvent&&(identical(other.broadcasterUserId, broadcasterUserId) || other.broadcasterUserId == broadcasterUserId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,broadcasterUserId);

@override
String toString() {
  return 'ChatClearEvent(broadcasterUserId: $broadcasterUserId)';
}


}

/// @nodoc
abstract mixin class _$ChatClearEventCopyWith<$Res> implements $ChatClearEventCopyWith<$Res> {
  factory _$ChatClearEventCopyWith(_ChatClearEvent value, $Res Function(_ChatClearEvent) _then) = __$ChatClearEventCopyWithImpl;
@override @useResult
$Res call({
 String broadcasterUserId
});




}
/// @nodoc
class __$ChatClearEventCopyWithImpl<$Res>
    implements _$ChatClearEventCopyWith<$Res> {
  __$ChatClearEventCopyWithImpl(this._self, this._then);

  final _ChatClearEvent _self;
  final $Res Function(_ChatClearEvent) _then;

/// Create a copy of ChatClearEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? broadcasterUserId = null,}) {
  return _then(_ChatClearEvent(
broadcasterUserId: null == broadcasterUserId ? _self.broadcasterUserId : broadcasterUserId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
