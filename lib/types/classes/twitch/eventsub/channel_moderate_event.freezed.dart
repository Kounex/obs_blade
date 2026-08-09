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

 String get action; String get moderatorUserName; ModerateDeleteAction? get delete; ModerateTimeoutAction? get timeout; ModerateBanAction? get ban; ModerateDeleteAction? get sharedChatDelete; ModerateTimeoutAction? get sharedChatTimeout; ModerateBanAction? get sharedChatBan;
/// Create a copy of ChannelModerateEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChannelModerateEventCopyWith<ChannelModerateEvent> get copyWith => _$ChannelModerateEventCopyWithImpl<ChannelModerateEvent>(this as ChannelModerateEvent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChannelModerateEvent&&(identical(other.action, action) || other.action == action)&&(identical(other.moderatorUserName, moderatorUserName) || other.moderatorUserName == moderatorUserName)&&(identical(other.delete, delete) || other.delete == delete)&&(identical(other.timeout, timeout) || other.timeout == timeout)&&(identical(other.ban, ban) || other.ban == ban)&&(identical(other.sharedChatDelete, sharedChatDelete) || other.sharedChatDelete == sharedChatDelete)&&(identical(other.sharedChatTimeout, sharedChatTimeout) || other.sharedChatTimeout == sharedChatTimeout)&&(identical(other.sharedChatBan, sharedChatBan) || other.sharedChatBan == sharedChatBan));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,action,moderatorUserName,delete,timeout,ban,sharedChatDelete,sharedChatTimeout,sharedChatBan);

@override
String toString() {
  return 'ChannelModerateEvent(action: $action, moderatorUserName: $moderatorUserName, delete: $delete, timeout: $timeout, ban: $ban, sharedChatDelete: $sharedChatDelete, sharedChatTimeout: $sharedChatTimeout, sharedChatBan: $sharedChatBan)';
}


}

/// @nodoc
abstract mixin class $ChannelModerateEventCopyWith<$Res>  {
  factory $ChannelModerateEventCopyWith(ChannelModerateEvent value, $Res Function(ChannelModerateEvent) _then) = _$ChannelModerateEventCopyWithImpl;
@useResult
$Res call({
 String action, String moderatorUserName, ModerateDeleteAction? delete, ModerateTimeoutAction? timeout, ModerateBanAction? ban, ModerateDeleteAction? sharedChatDelete, ModerateTimeoutAction? sharedChatTimeout, ModerateBanAction? sharedChatBan
});


$ModerateDeleteActionCopyWith<$Res>? get delete;$ModerateTimeoutActionCopyWith<$Res>? get timeout;$ModerateBanActionCopyWith<$Res>? get ban;$ModerateDeleteActionCopyWith<$Res>? get sharedChatDelete;$ModerateTimeoutActionCopyWith<$Res>? get sharedChatTimeout;$ModerateBanActionCopyWith<$Res>? get sharedChatBan;

}
/// @nodoc
class _$ChannelModerateEventCopyWithImpl<$Res>
    implements $ChannelModerateEventCopyWith<$Res> {
  _$ChannelModerateEventCopyWithImpl(this._self, this._then);

  final ChannelModerateEvent _self;
  final $Res Function(ChannelModerateEvent) _then;

/// Create a copy of ChannelModerateEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? action = null,Object? moderatorUserName = null,Object? delete = freezed,Object? timeout = freezed,Object? ban = freezed,Object? sharedChatDelete = freezed,Object? sharedChatTimeout = freezed,Object? sharedChatBan = freezed,}) {
  return _then(_self.copyWith(
action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,moderatorUserName: null == moderatorUserName ? _self.moderatorUserName : moderatorUserName // ignore: cast_nullable_to_non_nullable
as String,delete: freezed == delete ? _self.delete : delete // ignore: cast_nullable_to_non_nullable
as ModerateDeleteAction?,timeout: freezed == timeout ? _self.timeout : timeout // ignore: cast_nullable_to_non_nullable
as ModerateTimeoutAction?,ban: freezed == ban ? _self.ban : ban // ignore: cast_nullable_to_non_nullable
as ModerateBanAction?,sharedChatDelete: freezed == sharedChatDelete ? _self.sharedChatDelete : sharedChatDelete // ignore: cast_nullable_to_non_nullable
as ModerateDeleteAction?,sharedChatTimeout: freezed == sharedChatTimeout ? _self.sharedChatTimeout : sharedChatTimeout // ignore: cast_nullable_to_non_nullable
as ModerateTimeoutAction?,sharedChatBan: freezed == sharedChatBan ? _self.sharedChatBan : sharedChatBan // ignore: cast_nullable_to_non_nullable
as ModerateBanAction?,
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
}/// Create a copy of ChannelModerateEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ModerateTimeoutActionCopyWith<$Res>? get timeout {
    if (_self.timeout == null) {
    return null;
  }

  return $ModerateTimeoutActionCopyWith<$Res>(_self.timeout!, (value) {
    return _then(_self.copyWith(timeout: value));
  });
}/// Create a copy of ChannelModerateEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ModerateBanActionCopyWith<$Res>? get ban {
    if (_self.ban == null) {
    return null;
  }

  return $ModerateBanActionCopyWith<$Res>(_self.ban!, (value) {
    return _then(_self.copyWith(ban: value));
  });
}/// Create a copy of ChannelModerateEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ModerateDeleteActionCopyWith<$Res>? get sharedChatDelete {
    if (_self.sharedChatDelete == null) {
    return null;
  }

  return $ModerateDeleteActionCopyWith<$Res>(_self.sharedChatDelete!, (value) {
    return _then(_self.copyWith(sharedChatDelete: value));
  });
}/// Create a copy of ChannelModerateEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ModerateTimeoutActionCopyWith<$Res>? get sharedChatTimeout {
    if (_self.sharedChatTimeout == null) {
    return null;
  }

  return $ModerateTimeoutActionCopyWith<$Res>(_self.sharedChatTimeout!, (value) {
    return _then(_self.copyWith(sharedChatTimeout: value));
  });
}/// Create a copy of ChannelModerateEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ModerateBanActionCopyWith<$Res>? get sharedChatBan {
    if (_self.sharedChatBan == null) {
    return null;
  }

  return $ModerateBanActionCopyWith<$Res>(_self.sharedChatBan!, (value) {
    return _then(_self.copyWith(sharedChatBan: value));
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String action,  String moderatorUserName,  ModerateDeleteAction? delete,  ModerateTimeoutAction? timeout,  ModerateBanAction? ban,  ModerateDeleteAction? sharedChatDelete,  ModerateTimeoutAction? sharedChatTimeout,  ModerateBanAction? sharedChatBan)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChannelModerateEvent() when $default != null:
return $default(_that.action,_that.moderatorUserName,_that.delete,_that.timeout,_that.ban,_that.sharedChatDelete,_that.sharedChatTimeout,_that.sharedChatBan);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String action,  String moderatorUserName,  ModerateDeleteAction? delete,  ModerateTimeoutAction? timeout,  ModerateBanAction? ban,  ModerateDeleteAction? sharedChatDelete,  ModerateTimeoutAction? sharedChatTimeout,  ModerateBanAction? sharedChatBan)  $default,) {final _that = this;
switch (_that) {
case _ChannelModerateEvent():
return $default(_that.action,_that.moderatorUserName,_that.delete,_that.timeout,_that.ban,_that.sharedChatDelete,_that.sharedChatTimeout,_that.sharedChatBan);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String action,  String moderatorUserName,  ModerateDeleteAction? delete,  ModerateTimeoutAction? timeout,  ModerateBanAction? ban,  ModerateDeleteAction? sharedChatDelete,  ModerateTimeoutAction? sharedChatTimeout,  ModerateBanAction? sharedChatBan)?  $default,) {final _that = this;
switch (_that) {
case _ChannelModerateEvent() when $default != null:
return $default(_that.action,_that.moderatorUserName,_that.delete,_that.timeout,_that.ban,_that.sharedChatDelete,_that.sharedChatTimeout,_that.sharedChatBan);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class _ChannelModerateEvent implements ChannelModerateEvent {
  const _ChannelModerateEvent({required this.action, required this.moderatorUserName, this.delete, this.timeout, this.ban, this.sharedChatDelete, this.sharedChatTimeout, this.sharedChatBan});
  factory _ChannelModerateEvent.fromJson(Map<String, dynamic> json) => _$ChannelModerateEventFromJson(json);

@override final  String action;
@override final  String moderatorUserName;
@override final  ModerateDeleteAction? delete;
@override final  ModerateTimeoutAction? timeout;
@override final  ModerateBanAction? ban;
@override final  ModerateDeleteAction? sharedChatDelete;
@override final  ModerateTimeoutAction? sharedChatTimeout;
@override final  ModerateBanAction? sharedChatBan;

/// Create a copy of ChannelModerateEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChannelModerateEventCopyWith<_ChannelModerateEvent> get copyWith => __$ChannelModerateEventCopyWithImpl<_ChannelModerateEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChannelModerateEvent&&(identical(other.action, action) || other.action == action)&&(identical(other.moderatorUserName, moderatorUserName) || other.moderatorUserName == moderatorUserName)&&(identical(other.delete, delete) || other.delete == delete)&&(identical(other.timeout, timeout) || other.timeout == timeout)&&(identical(other.ban, ban) || other.ban == ban)&&(identical(other.sharedChatDelete, sharedChatDelete) || other.sharedChatDelete == sharedChatDelete)&&(identical(other.sharedChatTimeout, sharedChatTimeout) || other.sharedChatTimeout == sharedChatTimeout)&&(identical(other.sharedChatBan, sharedChatBan) || other.sharedChatBan == sharedChatBan));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,action,moderatorUserName,delete,timeout,ban,sharedChatDelete,sharedChatTimeout,sharedChatBan);

@override
String toString() {
  return 'ChannelModerateEvent(action: $action, moderatorUserName: $moderatorUserName, delete: $delete, timeout: $timeout, ban: $ban, sharedChatDelete: $sharedChatDelete, sharedChatTimeout: $sharedChatTimeout, sharedChatBan: $sharedChatBan)';
}


}

/// @nodoc
abstract mixin class _$ChannelModerateEventCopyWith<$Res> implements $ChannelModerateEventCopyWith<$Res> {
  factory _$ChannelModerateEventCopyWith(_ChannelModerateEvent value, $Res Function(_ChannelModerateEvent) _then) = __$ChannelModerateEventCopyWithImpl;
@override @useResult
$Res call({
 String action, String moderatorUserName, ModerateDeleteAction? delete, ModerateTimeoutAction? timeout, ModerateBanAction? ban, ModerateDeleteAction? sharedChatDelete, ModerateTimeoutAction? sharedChatTimeout, ModerateBanAction? sharedChatBan
});


@override $ModerateDeleteActionCopyWith<$Res>? get delete;@override $ModerateTimeoutActionCopyWith<$Res>? get timeout;@override $ModerateBanActionCopyWith<$Res>? get ban;@override $ModerateDeleteActionCopyWith<$Res>? get sharedChatDelete;@override $ModerateTimeoutActionCopyWith<$Res>? get sharedChatTimeout;@override $ModerateBanActionCopyWith<$Res>? get sharedChatBan;

}
/// @nodoc
class __$ChannelModerateEventCopyWithImpl<$Res>
    implements _$ChannelModerateEventCopyWith<$Res> {
  __$ChannelModerateEventCopyWithImpl(this._self, this._then);

  final _ChannelModerateEvent _self;
  final $Res Function(_ChannelModerateEvent) _then;

/// Create a copy of ChannelModerateEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? action = null,Object? moderatorUserName = null,Object? delete = freezed,Object? timeout = freezed,Object? ban = freezed,Object? sharedChatDelete = freezed,Object? sharedChatTimeout = freezed,Object? sharedChatBan = freezed,}) {
  return _then(_ChannelModerateEvent(
action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,moderatorUserName: null == moderatorUserName ? _self.moderatorUserName : moderatorUserName // ignore: cast_nullable_to_non_nullable
as String,delete: freezed == delete ? _self.delete : delete // ignore: cast_nullable_to_non_nullable
as ModerateDeleteAction?,timeout: freezed == timeout ? _self.timeout : timeout // ignore: cast_nullable_to_non_nullable
as ModerateTimeoutAction?,ban: freezed == ban ? _self.ban : ban // ignore: cast_nullable_to_non_nullable
as ModerateBanAction?,sharedChatDelete: freezed == sharedChatDelete ? _self.sharedChatDelete : sharedChatDelete // ignore: cast_nullable_to_non_nullable
as ModerateDeleteAction?,sharedChatTimeout: freezed == sharedChatTimeout ? _self.sharedChatTimeout : sharedChatTimeout // ignore: cast_nullable_to_non_nullable
as ModerateTimeoutAction?,sharedChatBan: freezed == sharedChatBan ? _self.sharedChatBan : sharedChatBan // ignore: cast_nullable_to_non_nullable
as ModerateBanAction?,
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
}/// Create a copy of ChannelModerateEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ModerateTimeoutActionCopyWith<$Res>? get timeout {
    if (_self.timeout == null) {
    return null;
  }

  return $ModerateTimeoutActionCopyWith<$Res>(_self.timeout!, (value) {
    return _then(_self.copyWith(timeout: value));
  });
}/// Create a copy of ChannelModerateEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ModerateBanActionCopyWith<$Res>? get ban {
    if (_self.ban == null) {
    return null;
  }

  return $ModerateBanActionCopyWith<$Res>(_self.ban!, (value) {
    return _then(_self.copyWith(ban: value));
  });
}/// Create a copy of ChannelModerateEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ModerateDeleteActionCopyWith<$Res>? get sharedChatDelete {
    if (_self.sharedChatDelete == null) {
    return null;
  }

  return $ModerateDeleteActionCopyWith<$Res>(_self.sharedChatDelete!, (value) {
    return _then(_self.copyWith(sharedChatDelete: value));
  });
}/// Create a copy of ChannelModerateEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ModerateTimeoutActionCopyWith<$Res>? get sharedChatTimeout {
    if (_self.sharedChatTimeout == null) {
    return null;
  }

  return $ModerateTimeoutActionCopyWith<$Res>(_self.sharedChatTimeout!, (value) {
    return _then(_self.copyWith(sharedChatTimeout: value));
  });
}/// Create a copy of ChannelModerateEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ModerateBanActionCopyWith<$Res>? get sharedChatBan {
    if (_self.sharedChatBan == null) {
    return null;
  }

  return $ModerateBanActionCopyWith<$Res>(_self.sharedChatBan!, (value) {
    return _then(_self.copyWith(sharedChatBan: value));
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


/// @nodoc
mixin _$ModerateTimeoutAction {

 String get userId; String? get userName; String? get reason; DateTime get expiresAt;
/// Create a copy of ModerateTimeoutAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModerateTimeoutActionCopyWith<ModerateTimeoutAction> get copyWith => _$ModerateTimeoutActionCopyWithImpl<ModerateTimeoutAction>(this as ModerateTimeoutAction, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModerateTimeoutAction&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,userName,reason,expiresAt);

@override
String toString() {
  return 'ModerateTimeoutAction(userId: $userId, userName: $userName, reason: $reason, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class $ModerateTimeoutActionCopyWith<$Res>  {
  factory $ModerateTimeoutActionCopyWith(ModerateTimeoutAction value, $Res Function(ModerateTimeoutAction) _then) = _$ModerateTimeoutActionCopyWithImpl;
@useResult
$Res call({
 String userId, String? userName, String? reason, DateTime expiresAt
});




}
/// @nodoc
class _$ModerateTimeoutActionCopyWithImpl<$Res>
    implements $ModerateTimeoutActionCopyWith<$Res> {
  _$ModerateTimeoutActionCopyWithImpl(this._self, this._then);

  final ModerateTimeoutAction _self;
  final $Res Function(ModerateTimeoutAction) _then;

/// Create a copy of ModerateTimeoutAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? userName = freezed,Object? reason = freezed,Object? expiresAt = null,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,userName: freezed == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String?,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ModerateTimeoutAction].
extension ModerateTimeoutActionPatterns on ModerateTimeoutAction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ModerateTimeoutAction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ModerateTimeoutAction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ModerateTimeoutAction value)  $default,){
final _that = this;
switch (_that) {
case _ModerateTimeoutAction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ModerateTimeoutAction value)?  $default,){
final _that = this;
switch (_that) {
case _ModerateTimeoutAction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String? userName,  String? reason,  DateTime expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ModerateTimeoutAction() when $default != null:
return $default(_that.userId,_that.userName,_that.reason,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String? userName,  String? reason,  DateTime expiresAt)  $default,) {final _that = this;
switch (_that) {
case _ModerateTimeoutAction():
return $default(_that.userId,_that.userName,_that.reason,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String? userName,  String? reason,  DateTime expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _ModerateTimeoutAction() when $default != null:
return $default(_that.userId,_that.userName,_that.reason,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class _ModerateTimeoutAction implements ModerateTimeoutAction {
  const _ModerateTimeoutAction({required this.userId, this.userName, this.reason, required this.expiresAt});
  factory _ModerateTimeoutAction.fromJson(Map<String, dynamic> json) => _$ModerateTimeoutActionFromJson(json);

@override final  String userId;
@override final  String? userName;
@override final  String? reason;
@override final  DateTime expiresAt;

/// Create a copy of ModerateTimeoutAction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ModerateTimeoutActionCopyWith<_ModerateTimeoutAction> get copyWith => __$ModerateTimeoutActionCopyWithImpl<_ModerateTimeoutAction>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ModerateTimeoutAction&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,userName,reason,expiresAt);

@override
String toString() {
  return 'ModerateTimeoutAction(userId: $userId, userName: $userName, reason: $reason, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$ModerateTimeoutActionCopyWith<$Res> implements $ModerateTimeoutActionCopyWith<$Res> {
  factory _$ModerateTimeoutActionCopyWith(_ModerateTimeoutAction value, $Res Function(_ModerateTimeoutAction) _then) = __$ModerateTimeoutActionCopyWithImpl;
@override @useResult
$Res call({
 String userId, String? userName, String? reason, DateTime expiresAt
});




}
/// @nodoc
class __$ModerateTimeoutActionCopyWithImpl<$Res>
    implements _$ModerateTimeoutActionCopyWith<$Res> {
  __$ModerateTimeoutActionCopyWithImpl(this._self, this._then);

  final _ModerateTimeoutAction _self;
  final $Res Function(_ModerateTimeoutAction) _then;

/// Create a copy of ModerateTimeoutAction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? userName = freezed,Object? reason = freezed,Object? expiresAt = null,}) {
  return _then(_ModerateTimeoutAction(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,userName: freezed == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String?,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$ModerateBanAction {

 String get userId; String? get userName; String? get reason;
/// Create a copy of ModerateBanAction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModerateBanActionCopyWith<ModerateBanAction> get copyWith => _$ModerateBanActionCopyWithImpl<ModerateBanAction>(this as ModerateBanAction, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModerateBanAction&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.reason, reason) || other.reason == reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,userName,reason);

@override
String toString() {
  return 'ModerateBanAction(userId: $userId, userName: $userName, reason: $reason)';
}


}

/// @nodoc
abstract mixin class $ModerateBanActionCopyWith<$Res>  {
  factory $ModerateBanActionCopyWith(ModerateBanAction value, $Res Function(ModerateBanAction) _then) = _$ModerateBanActionCopyWithImpl;
@useResult
$Res call({
 String userId, String? userName, String? reason
});




}
/// @nodoc
class _$ModerateBanActionCopyWithImpl<$Res>
    implements $ModerateBanActionCopyWith<$Res> {
  _$ModerateBanActionCopyWithImpl(this._self, this._then);

  final ModerateBanAction _self;
  final $Res Function(ModerateBanAction) _then;

/// Create a copy of ModerateBanAction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? userName = freezed,Object? reason = freezed,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,userName: freezed == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String?,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ModerateBanAction].
extension ModerateBanActionPatterns on ModerateBanAction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ModerateBanAction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ModerateBanAction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ModerateBanAction value)  $default,){
final _that = this;
switch (_that) {
case _ModerateBanAction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ModerateBanAction value)?  $default,){
final _that = this;
switch (_that) {
case _ModerateBanAction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String? userName,  String? reason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ModerateBanAction() when $default != null:
return $default(_that.userId,_that.userName,_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String? userName,  String? reason)  $default,) {final _that = this;
switch (_that) {
case _ModerateBanAction():
return $default(_that.userId,_that.userName,_that.reason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String? userName,  String? reason)?  $default,) {final _that = this;
switch (_that) {
case _ModerateBanAction() when $default != null:
return $default(_that.userId,_that.userName,_that.reason);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class _ModerateBanAction implements ModerateBanAction {
  const _ModerateBanAction({required this.userId, this.userName, this.reason});
  factory _ModerateBanAction.fromJson(Map<String, dynamic> json) => _$ModerateBanActionFromJson(json);

@override final  String userId;
@override final  String? userName;
@override final  String? reason;

/// Create a copy of ModerateBanAction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ModerateBanActionCopyWith<_ModerateBanAction> get copyWith => __$ModerateBanActionCopyWithImpl<_ModerateBanAction>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ModerateBanAction&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.reason, reason) || other.reason == reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,userName,reason);

@override
String toString() {
  return 'ModerateBanAction(userId: $userId, userName: $userName, reason: $reason)';
}


}

/// @nodoc
abstract mixin class _$ModerateBanActionCopyWith<$Res> implements $ModerateBanActionCopyWith<$Res> {
  factory _$ModerateBanActionCopyWith(_ModerateBanAction value, $Res Function(_ModerateBanAction) _then) = __$ModerateBanActionCopyWithImpl;
@override @useResult
$Res call({
 String userId, String? userName, String? reason
});




}
/// @nodoc
class __$ModerateBanActionCopyWithImpl<$Res>
    implements _$ModerateBanActionCopyWith<$Res> {
  __$ModerateBanActionCopyWithImpl(this._self, this._then);

  final _ModerateBanAction _self;
  final $Res Function(_ModerateBanAction) _then;

/// Create a copy of ModerateBanAction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? userName = freezed,Object? reason = freezed,}) {
  return _then(_ModerateBanAction(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,userName: freezed == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String?,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
