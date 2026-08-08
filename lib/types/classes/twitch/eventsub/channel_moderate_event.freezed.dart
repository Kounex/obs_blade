// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'channel_moderate_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChannelModerateEvent {

 String get action; String get moderatorUserName; ModerateDeleteAction? get delete;
/// Create a copy of ChannelModerateEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChannelModerateEventCopyWith<ChannelModerateEvent> get copyWith => _$ChannelModerateEventCopyWithImpl<ChannelModerateEvent>(this as ChannelModerateEvent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChannelModerateEvent&&(identical(other.action, action) || other.action == action)&&(identical(other.moderatorUserName, moderatorUserName) || other.moderatorUserName == moderatorUserName)&&(identical(other.delete, delete) || other.delete == delete));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,action,moderatorUserName,delete);

@override
String toString() {
  return 'ChannelModerateEvent(action: $action, moderatorUserName: $moderatorUserName, delete: $delete)';
}


}

/// @nodoc
abstract mixin class $ChannelModerateEventCopyWith<$Res>  {
  factory $ChannelModerateEventCopyWith(ChannelModerateEvent value, $Res Function(ChannelModerateEvent) _then) = _$ChannelModerateEventCopyWithImpl;
@useResult
$Res call({
 String action, String moderatorUserName, ModerateDeleteAction? delete
});


$ModerateDeleteActionCopyWith<$Res>? get delete;

}
/// @nodoc
class _$ChannelModerateEventCopyWithImpl<$Res>
    implements $ChannelModerateEventCopyWith<$Res> {
  _$ChannelModerateEventCopyWithImpl(this._self, this._then);

  final ChannelModerateEvent _self;
  final $Res Function(ChannelModerateEvent) _then;

/// Create a copy of ChannelModerateEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? action = null,Object? moderatorUserName = null,Object? delete = freezed,}) {
  return _then(_self.copyWith(
action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,moderatorUserName: null == moderatorUserName ? _self.moderatorUserName : moderatorUserName // ignore: cast_nullable_to_non_nullable
as String,delete: freezed == delete ? _self.delete : delete // ignore: cast_nullable_to_non_nullable
as ModerateDeleteAction?,
  ));
}
/// Create a copy of ChannelModerateEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ModerateDeleteActionCopyWith<$Res>? get delete {
    if (_self.delete == null) {
    return null;
  }

  return $ModerateDeleteActionCopyWith<$Res>(_self.delete!, (value) {
    return _then(_self.copyWith(delete: value));
  });
}
}


/// Adds pattern-matching-related methods to [ChannelModerateEvent].
extension ChannelModerateEventPatterns on ChannelModerateEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChannelModerateEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChannelModerateEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChannelModerateEvent value)  $default,){
final _that = this;
switch (_that) {
case _ChannelModerateEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChannelModerateEvent value)?  $default,){
final _that = this;
switch (_that) {
case _ChannelModerateEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String action,  String moderatorUserName,  ModerateDeleteAction? delete)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChannelModerateEvent() when $default != null:
return $default(_that.action,_that.moderatorUserName,_that.delete);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String action,  String moderatorUserName,  ModerateDeleteAction? delete)  $default,) {final _that = this;
switch (_that) {
case _ChannelModerateEvent():
return $default(_that.action,_that.moderatorUserName,_that.delete);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String action,  String moderatorUserName,  ModerateDeleteAction? delete)?  $default,) {final _that = this;
switch (_that) {
case _ChannelModerateEvent() when $default != null:
return $default(_that.action,_that.moderatorUserName,_that.delete);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class _ChannelModerateEvent implements ChannelModerateEvent {
  const _ChannelModerateEvent({required this.action, required this.moderatorUserName, this.delete});
  factory _ChannelModerateEvent.fromJson(Map<String, dynamic> json) => _$ChannelModerateEventFromJson(json);

@override final  String action;
@override final  String moderatorUserName;
@override final  ModerateDeleteAction? delete;

/// Create a copy of ChannelModerateEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChannelModerateEventCopyWith<_ChannelModerateEvent> get copyWith => __$ChannelModerateEventCopyWithImpl<_ChannelModerateEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChannelModerateEvent&&(identical(other.action, action) || other.action == action)&&(identical(other.moderatorUserName, moderatorUserName) || other.moderatorUserName == moderatorUserName)&&(identical(other.delete, delete) || other.delete == delete));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,action,moderatorUserName,delete);

@override
String toString() {
  return 'ChannelModerateEvent(action: $action, moderatorUserName: $moderatorUserName, delete: $delete)';
}


}

/// @nodoc
abstract mixin class _$ChannelModerateEventCopyWith<$Res> implements $ChannelModerateEventCopyWith<$Res> {
  factory _$ChannelModerateEventCopyWith(_ChannelModerateEvent value, $Res Function(_ChannelModerateEvent) _then) = __$ChannelModerateEventCopyWithImpl;
@override @useResult
$Res call({
 String action, String moderatorUserName, ModerateDeleteAction? delete
});


@override $ModerateDeleteActionCopyWith<$Res>? get delete;

}
/// @nodoc
class __$ChannelModerateEventCopyWithImpl<$Res>
    implements _$ChannelModerateEventCopyWith<$Res> {
  __$ChannelModerateEventCopyWithImpl(this._self, this._then);

  final _ChannelModerateEvent _self;
  final $Res Function(_ChannelModerateEvent) _then;

/// Create a copy of ChannelModerateEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? action = null,Object? moderatorUserName = null,Object? delete = freezed,}) {
  return _then(_ChannelModerateEvent(
action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,moderatorUserName: null == moderatorUserName ? _self.moderatorUserName : moderatorUserName // ignore: cast_nullable_to_non_nullable
as String,delete: freezed == delete ? _self.delete : delete // ignore: cast_nullable_to_non_nullable
as ModerateDeleteAction?,
  ));
}

/// Create a copy of ChannelModerateEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ModerateDeleteActionCopyWith<$Res>? get delete {
    if (_self.delete == null) {
    return null;
  }

  return $ModerateDeleteActionCopyWith<$Res>(_self.delete!, (value) {
    return _then(_self.copyWith(delete: value));
  });
}
}


/// @nodoc
mixin _$ModerateDeleteAction {

 String get messageId; String? get userName;
/// Create a copy of ModerateDeleteAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModerateDeleteActionCopyWith<ModerateDeleteAction> get copyWith => _$ModerateDeleteActionCopyWithImpl<ModerateDeleteAction>(this as ModerateDeleteAction, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModerateDeleteAction&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.userName, userName) || other.userName == userName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,messageId,userName);

@override
String toString() {
  return 'ModerateDeleteAction(messageId: $messageId, userName: $userName)';
}


}

/// @nodoc
abstract mixin class $ModerateDeleteActionCopyWith<$Res>  {
  factory $ModerateDeleteActionCopyWith(ModerateDeleteAction value, $Res Function(ModerateDeleteAction) _then) = _$ModerateDeleteActionCopyWithImpl;
@useResult
$Res call({
 String messageId, String? userName
});




}
/// @nodoc
class _$ModerateDeleteActionCopyWithImpl<$Res>
    implements $ModerateDeleteActionCopyWith<$Res> {
  _$ModerateDeleteActionCopyWithImpl(this._self, this._then);

  final ModerateDeleteAction _self;
  final $Res Function(ModerateDeleteAction) _then;

/// Create a copy of ModerateDeleteAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? messageId = null,Object? userName = freezed,}) {
  return _then(_self.copyWith(
messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,userName: freezed == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ModerateDeleteAction].
extension ModerateDeleteActionPatterns on ModerateDeleteAction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ModerateDeleteAction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ModerateDeleteAction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ModerateDeleteAction value)  $default,){
final _that = this;
switch (_that) {
case _ModerateDeleteAction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ModerateDeleteAction value)?  $default,){
final _that = this;
switch (_that) {
case _ModerateDeleteAction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String messageId,  String? userName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ModerateDeleteAction() when $default != null:
return $default(_that.messageId,_that.userName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String messageId,  String? userName)  $default,) {final _that = this;
switch (_that) {
case _ModerateDeleteAction():
return $default(_that.messageId,_that.userName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String messageId,  String? userName)?  $default,) {final _that = this;
switch (_that) {
case _ModerateDeleteAction() when $default != null:
return $default(_that.messageId,_that.userName);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class _ModerateDeleteAction implements ModerateDeleteAction {
  const _ModerateDeleteAction({required this.messageId, this.userName});
  factory _ModerateDeleteAction.fromJson(Map<String, dynamic> json) => _$ModerateDeleteActionFromJson(json);

@override final  String messageId;
@override final  String? userName;

/// Create a copy of ModerateDeleteAction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ModerateDeleteActionCopyWith<_ModerateDeleteAction> get copyWith => __$ModerateDeleteActionCopyWithImpl<_ModerateDeleteAction>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ModerateDeleteAction&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.userName, userName) || other.userName == userName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,messageId,userName);

@override
String toString() {
  return 'ModerateDeleteAction(messageId: $messageId, userName: $userName)';
}


}

/// @nodoc
abstract mixin class _$ModerateDeleteActionCopyWith<$Res> implements $ModerateDeleteActionCopyWith<$Res> {
  factory _$ModerateDeleteActionCopyWith(_ModerateDeleteAction value, $Res Function(_ModerateDeleteAction) _then) = __$ModerateDeleteActionCopyWithImpl;
@override @useResult
$Res call({
 String messageId, String? userName
});




}
/// @nodoc
class __$ModerateDeleteActionCopyWithImpl<$Res>
    implements _$ModerateDeleteActionCopyWith<$Res> {
  __$ModerateDeleteActionCopyWithImpl(this._self, this._then);

  final _ModerateDeleteAction _self;
  final $Res Function(_ModerateDeleteAction) _then;

/// Create a copy of ModerateDeleteAction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? messageId = null,Object? userName = freezed,}) {
  return _then(_ModerateDeleteAction(
messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,userName: freezed == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
