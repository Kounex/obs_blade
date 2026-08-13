// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'automod_events.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AutoModMessageHoldEvent {

 String get messageId; String get userId; String get userLogin; String get userName; AutoModMessageContent get message;/// `automod` or `blocked_term` — which filter caught the message.
 String get reason;/// AutoMod classification — null when [reason] is `blocked_term`.
 AutoModClassification? get automod; DateTime? get heldAt;
/// Create a copy of AutoModMessageHoldEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AutoModMessageHoldEventCopyWith<AutoModMessageHoldEvent> get copyWith => _$AutoModMessageHoldEventCopyWithImpl<AutoModMessageHoldEvent>(this as AutoModMessageHoldEvent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AutoModMessageHoldEvent&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.userLogin, userLogin) || other.userLogin == userLogin)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.message, message) || other.message == message)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.automod, automod) || other.automod == automod)&&(identical(other.heldAt, heldAt) || other.heldAt == heldAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,messageId,userId,userLogin,userName,message,reason,automod,heldAt);

@override
String toString() {
  return 'AutoModMessageHoldEvent(messageId: $messageId, userId: $userId, userLogin: $userLogin, userName: $userName, message: $message, reason: $reason, automod: $automod, heldAt: $heldAt)';
}


}

/// @nodoc
abstract mixin class $AutoModMessageHoldEventCopyWith<$Res>  {
  factory $AutoModMessageHoldEventCopyWith(AutoModMessageHoldEvent value, $Res Function(AutoModMessageHoldEvent) _then) = _$AutoModMessageHoldEventCopyWithImpl;
@useResult
$Res call({
 String messageId, String userId, String userLogin, String userName, AutoModMessageContent message, String reason, AutoModClassification? automod, DateTime? heldAt
});


$AutoModMessageContentCopyWith<$Res> get message;$AutoModClassificationCopyWith<$Res>? get automod;

}
/// @nodoc
class _$AutoModMessageHoldEventCopyWithImpl<$Res>
    implements $AutoModMessageHoldEventCopyWith<$Res> {
  _$AutoModMessageHoldEventCopyWithImpl(this._self, this._then);

  final AutoModMessageHoldEvent _self;
  final $Res Function(AutoModMessageHoldEvent) _then;

/// Create a copy of AutoModMessageHoldEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? messageId = null,Object? userId = null,Object? userLogin = null,Object? userName = null,Object? message = null,Object? reason = null,Object? automod = freezed,Object? heldAt = freezed,}) {
  return _then(_self.copyWith(
messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,userLogin: null == userLogin ? _self.userLogin : userLogin // ignore: cast_nullable_to_non_nullable
as String,userName: null == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as AutoModMessageContent,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,automod: freezed == automod ? _self.automod : automod // ignore: cast_nullable_to_non_nullable
as AutoModClassification?,heldAt: freezed == heldAt ? _self.heldAt : heldAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of AutoModMessageHoldEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AutoModMessageContentCopyWith<$Res> get message {
  
  return $AutoModMessageContentCopyWith<$Res>(_self.message, (value) {
    return _then(_self.copyWith(message: value));
  });
}/// Create a copy of AutoModMessageHoldEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AutoModClassificationCopyWith<$Res>? get automod {
    if (_self.automod == null) {
    return null;
  }

  return $AutoModClassificationCopyWith<$Res>(_self.automod!, (value) {
    return _then(_self.copyWith(automod: value));
  });
}
}


/// Adds pattern-matching-related methods to [AutoModMessageHoldEvent].
extension AutoModMessageHoldEventPatterns on AutoModMessageHoldEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AutoModMessageHoldEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AutoModMessageHoldEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AutoModMessageHoldEvent value)  $default,){
final _that = this;
switch (_that) {
case _AutoModMessageHoldEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AutoModMessageHoldEvent value)?  $default,){
final _that = this;
switch (_that) {
case _AutoModMessageHoldEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String messageId,  String userId,  String userLogin,  String userName,  AutoModMessageContent message,  String reason,  AutoModClassification? automod,  DateTime? heldAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AutoModMessageHoldEvent() when $default != null:
return $default(_that.messageId,_that.userId,_that.userLogin,_that.userName,_that.message,_that.reason,_that.automod,_that.heldAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String messageId,  String userId,  String userLogin,  String userName,  AutoModMessageContent message,  String reason,  AutoModClassification? automod,  DateTime? heldAt)  $default,) {final _that = this;
switch (_that) {
case _AutoModMessageHoldEvent():
return $default(_that.messageId,_that.userId,_that.userLogin,_that.userName,_that.message,_that.reason,_that.automod,_that.heldAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String messageId,  String userId,  String userLogin,  String userName,  AutoModMessageContent message,  String reason,  AutoModClassification? automod,  DateTime? heldAt)?  $default,) {final _that = this;
switch (_that) {
case _AutoModMessageHoldEvent() when $default != null:
return $default(_that.messageId,_that.userId,_that.userLogin,_that.userName,_that.message,_that.reason,_that.automod,_that.heldAt);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class _AutoModMessageHoldEvent implements AutoModMessageHoldEvent {
  const _AutoModMessageHoldEvent({required this.messageId, required this.userId, required this.userLogin, required this.userName, required this.message, required this.reason, this.automod, this.heldAt});
  factory _AutoModMessageHoldEvent.fromJson(Map<String, dynamic> json) => _$AutoModMessageHoldEventFromJson(json);

@override final  String messageId;
@override final  String userId;
@override final  String userLogin;
@override final  String userName;
@override final  AutoModMessageContent message;
/// `automod` or `blocked_term` — which filter caught the message.
@override final  String reason;
/// AutoMod classification — null when [reason] is `blocked_term`.
@override final  AutoModClassification? automod;
@override final  DateTime? heldAt;

/// Create a copy of AutoModMessageHoldEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AutoModMessageHoldEventCopyWith<_AutoModMessageHoldEvent> get copyWith => __$AutoModMessageHoldEventCopyWithImpl<_AutoModMessageHoldEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AutoModMessageHoldEvent&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.userLogin, userLogin) || other.userLogin == userLogin)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.message, message) || other.message == message)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.automod, automod) || other.automod == automod)&&(identical(other.heldAt, heldAt) || other.heldAt == heldAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,messageId,userId,userLogin,userName,message,reason,automod,heldAt);

@override
String toString() {
  return 'AutoModMessageHoldEvent(messageId: $messageId, userId: $userId, userLogin: $userLogin, userName: $userName, message: $message, reason: $reason, automod: $automod, heldAt: $heldAt)';
}


}

/// @nodoc
abstract mixin class _$AutoModMessageHoldEventCopyWith<$Res> implements $AutoModMessageHoldEventCopyWith<$Res> {
  factory _$AutoModMessageHoldEventCopyWith(_AutoModMessageHoldEvent value, $Res Function(_AutoModMessageHoldEvent) _then) = __$AutoModMessageHoldEventCopyWithImpl;
@override @useResult
$Res call({
 String messageId, String userId, String userLogin, String userName, AutoModMessageContent message, String reason, AutoModClassification? automod, DateTime? heldAt
});


@override $AutoModMessageContentCopyWith<$Res> get message;@override $AutoModClassificationCopyWith<$Res>? get automod;

}
/// @nodoc
class __$AutoModMessageHoldEventCopyWithImpl<$Res>
    implements _$AutoModMessageHoldEventCopyWith<$Res> {
  __$AutoModMessageHoldEventCopyWithImpl(this._self, this._then);

  final _AutoModMessageHoldEvent _self;
  final $Res Function(_AutoModMessageHoldEvent) _then;

/// Create a copy of AutoModMessageHoldEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? messageId = null,Object? userId = null,Object? userLogin = null,Object? userName = null,Object? message = null,Object? reason = null,Object? automod = freezed,Object? heldAt = freezed,}) {
  return _then(_AutoModMessageHoldEvent(
messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,userLogin: null == userLogin ? _self.userLogin : userLogin // ignore: cast_nullable_to_non_nullable
as String,userName: null == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as AutoModMessageContent,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,automod: freezed == automod ? _self.automod : automod // ignore: cast_nullable_to_non_nullable
as AutoModClassification?,heldAt: freezed == heldAt ? _self.heldAt : heldAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of AutoModMessageHoldEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AutoModMessageContentCopyWith<$Res> get message {
  
  return $AutoModMessageContentCopyWith<$Res>(_self.message, (value) {
    return _then(_self.copyWith(message: value));
  });
}/// Create a copy of AutoModMessageHoldEvent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AutoModClassificationCopyWith<$Res>? get automod {
    if (_self.automod == null) {
    return null;
  }

  return $AutoModClassificationCopyWith<$Res>(_self.automod!, (value) {
    return _then(_self.copyWith(automod: value));
  });
}
}


/// @nodoc
mixin _$AutoModMessageContent {

 String get text;
/// Create a copy of AutoModMessageContent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AutoModMessageContentCopyWith<AutoModMessageContent> get copyWith => _$AutoModMessageContentCopyWithImpl<AutoModMessageContent>(this as AutoModMessageContent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AutoModMessageContent&&(identical(other.text, text) || other.text == text));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,text);

@override
String toString() {
  return 'AutoModMessageContent(text: $text)';
}


}

/// @nodoc
abstract mixin class $AutoModMessageContentCopyWith<$Res>  {
  factory $AutoModMessageContentCopyWith(AutoModMessageContent value, $Res Function(AutoModMessageContent) _then) = _$AutoModMessageContentCopyWithImpl;
@useResult
$Res call({
 String text
});




}
/// @nodoc
class _$AutoModMessageContentCopyWithImpl<$Res>
    implements $AutoModMessageContentCopyWith<$Res> {
  _$AutoModMessageContentCopyWithImpl(this._self, this._then);

  final AutoModMessageContent _self;
  final $Res Function(AutoModMessageContent) _then;

/// Create a copy of AutoModMessageContent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? text = null,}) {
  return _then(_self.copyWith(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AutoModMessageContent].
extension AutoModMessageContentPatterns on AutoModMessageContent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AutoModMessageContent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AutoModMessageContent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AutoModMessageContent value)  $default,){
final _that = this;
switch (_that) {
case _AutoModMessageContent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AutoModMessageContent value)?  $default,){
final _that = this;
switch (_that) {
case _AutoModMessageContent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String text)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AutoModMessageContent() when $default != null:
return $default(_that.text);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String text)  $default,) {final _that = this;
switch (_that) {
case _AutoModMessageContent():
return $default(_that.text);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String text)?  $default,) {final _that = this;
switch (_that) {
case _AutoModMessageContent() when $default != null:
return $default(_that.text);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class _AutoModMessageContent implements AutoModMessageContent {
  const _AutoModMessageContent({required this.text});
  factory _AutoModMessageContent.fromJson(Map<String, dynamic> json) => _$AutoModMessageContentFromJson(json);

@override final  String text;

/// Create a copy of AutoModMessageContent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AutoModMessageContentCopyWith<_AutoModMessageContent> get copyWith => __$AutoModMessageContentCopyWithImpl<_AutoModMessageContent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AutoModMessageContent&&(identical(other.text, text) || other.text == text));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,text);

@override
String toString() {
  return 'AutoModMessageContent(text: $text)';
}


}

/// @nodoc
abstract mixin class _$AutoModMessageContentCopyWith<$Res> implements $AutoModMessageContentCopyWith<$Res> {
  factory _$AutoModMessageContentCopyWith(_AutoModMessageContent value, $Res Function(_AutoModMessageContent) _then) = __$AutoModMessageContentCopyWithImpl;
@override @useResult
$Res call({
 String text
});




}
/// @nodoc
class __$AutoModMessageContentCopyWithImpl<$Res>
    implements _$AutoModMessageContentCopyWith<$Res> {
  __$AutoModMessageContentCopyWithImpl(this._self, this._then);

  final _AutoModMessageContent _self;
  final $Res Function(_AutoModMessageContent) _then;

/// Create a copy of AutoModMessageContent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = null,}) {
  return _then(_AutoModMessageContent(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$AutoModClassification {

 String? get category; int? get level;
/// Create a copy of AutoModClassification
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AutoModClassificationCopyWith<AutoModClassification> get copyWith => _$AutoModClassificationCopyWithImpl<AutoModClassification>(this as AutoModClassification, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AutoModClassification&&(identical(other.category, category) || other.category == category)&&(identical(other.level, level) || other.level == level));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,category,level);

@override
String toString() {
  return 'AutoModClassification(category: $category, level: $level)';
}


}

/// @nodoc
abstract mixin class $AutoModClassificationCopyWith<$Res>  {
  factory $AutoModClassificationCopyWith(AutoModClassification value, $Res Function(AutoModClassification) _then) = _$AutoModClassificationCopyWithImpl;
@useResult
$Res call({
 String? category, int? level
});




}
/// @nodoc
class _$AutoModClassificationCopyWithImpl<$Res>
    implements $AutoModClassificationCopyWith<$Res> {
  _$AutoModClassificationCopyWithImpl(this._self, this._then);

  final AutoModClassification _self;
  final $Res Function(AutoModClassification) _then;

/// Create a copy of AutoModClassification
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? category = freezed,Object? level = freezed,}) {
  return _then(_self.copyWith(
category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,level: freezed == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [AutoModClassification].
extension AutoModClassificationPatterns on AutoModClassification {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AutoModClassification value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AutoModClassification() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AutoModClassification value)  $default,){
final _that = this;
switch (_that) {
case _AutoModClassification():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AutoModClassification value)?  $default,){
final _that = this;
switch (_that) {
case _AutoModClassification() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? category,  int? level)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AutoModClassification() when $default != null:
return $default(_that.category,_that.level);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? category,  int? level)  $default,) {final _that = this;
switch (_that) {
case _AutoModClassification():
return $default(_that.category,_that.level);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? category,  int? level)?  $default,) {final _that = this;
switch (_that) {
case _AutoModClassification() when $default != null:
return $default(_that.category,_that.level);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class _AutoModClassification implements AutoModClassification {
  const _AutoModClassification({this.category, this.level});
  factory _AutoModClassification.fromJson(Map<String, dynamic> json) => _$AutoModClassificationFromJson(json);

@override final  String? category;
@override final  int? level;

/// Create a copy of AutoModClassification
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AutoModClassificationCopyWith<_AutoModClassification> get copyWith => __$AutoModClassificationCopyWithImpl<_AutoModClassification>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AutoModClassification&&(identical(other.category, category) || other.category == category)&&(identical(other.level, level) || other.level == level));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,category,level);

@override
String toString() {
  return 'AutoModClassification(category: $category, level: $level)';
}


}

/// @nodoc
abstract mixin class _$AutoModClassificationCopyWith<$Res> implements $AutoModClassificationCopyWith<$Res> {
  factory _$AutoModClassificationCopyWith(_AutoModClassification value, $Res Function(_AutoModClassification) _then) = __$AutoModClassificationCopyWithImpl;
@override @useResult
$Res call({
 String? category, int? level
});




}
/// @nodoc
class __$AutoModClassificationCopyWithImpl<$Res>
    implements _$AutoModClassificationCopyWith<$Res> {
  __$AutoModClassificationCopyWithImpl(this._self, this._then);

  final _AutoModClassification _self;
  final $Res Function(_AutoModClassification) _then;

/// Create a copy of AutoModClassification
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? category = freezed,Object? level = freezed,}) {
  return _then(_AutoModClassification(
category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,level: freezed == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$AutoModMessageUpdateEvent {

 String get messageId; String get status;
/// Create a copy of AutoModMessageUpdateEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AutoModMessageUpdateEventCopyWith<AutoModMessageUpdateEvent> get copyWith => _$AutoModMessageUpdateEventCopyWithImpl<AutoModMessageUpdateEvent>(this as AutoModMessageUpdateEvent, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AutoModMessageUpdateEvent&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,messageId,status);

@override
String toString() {
  return 'AutoModMessageUpdateEvent(messageId: $messageId, status: $status)';
}


}

/// @nodoc
abstract mixin class $AutoModMessageUpdateEventCopyWith<$Res>  {
  factory $AutoModMessageUpdateEventCopyWith(AutoModMessageUpdateEvent value, $Res Function(AutoModMessageUpdateEvent) _then) = _$AutoModMessageUpdateEventCopyWithImpl;
@useResult
$Res call({
 String messageId, String status
});




}
/// @nodoc
class _$AutoModMessageUpdateEventCopyWithImpl<$Res>
    implements $AutoModMessageUpdateEventCopyWith<$Res> {
  _$AutoModMessageUpdateEventCopyWithImpl(this._self, this._then);

  final AutoModMessageUpdateEvent _self;
  final $Res Function(AutoModMessageUpdateEvent) _then;

/// Create a copy of AutoModMessageUpdateEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? messageId = null,Object? status = null,}) {
  return _then(_self.copyWith(
messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AutoModMessageUpdateEvent].
extension AutoModMessageUpdateEventPatterns on AutoModMessageUpdateEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AutoModMessageUpdateEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AutoModMessageUpdateEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AutoModMessageUpdateEvent value)  $default,){
final _that = this;
switch (_that) {
case _AutoModMessageUpdateEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AutoModMessageUpdateEvent value)?  $default,){
final _that = this;
switch (_that) {
case _AutoModMessageUpdateEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String messageId,  String status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AutoModMessageUpdateEvent() when $default != null:
return $default(_that.messageId,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String messageId,  String status)  $default,) {final _that = this;
switch (_that) {
case _AutoModMessageUpdateEvent():
return $default(_that.messageId,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String messageId,  String status)?  $default,) {final _that = this;
switch (_that) {
case _AutoModMessageUpdateEvent() when $default != null:
return $default(_that.messageId,_that.status);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class _AutoModMessageUpdateEvent implements AutoModMessageUpdateEvent {
  const _AutoModMessageUpdateEvent({required this.messageId, required this.status});
  factory _AutoModMessageUpdateEvent.fromJson(Map<String, dynamic> json) => _$AutoModMessageUpdateEventFromJson(json);

@override final  String messageId;
@override final  String status;

/// Create a copy of AutoModMessageUpdateEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AutoModMessageUpdateEventCopyWith<_AutoModMessageUpdateEvent> get copyWith => __$AutoModMessageUpdateEventCopyWithImpl<_AutoModMessageUpdateEvent>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AutoModMessageUpdateEvent&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,messageId,status);

@override
String toString() {
  return 'AutoModMessageUpdateEvent(messageId: $messageId, status: $status)';
}


}

/// @nodoc
abstract mixin class _$AutoModMessageUpdateEventCopyWith<$Res> implements $AutoModMessageUpdateEventCopyWith<$Res> {
  factory _$AutoModMessageUpdateEventCopyWith(_AutoModMessageUpdateEvent value, $Res Function(_AutoModMessageUpdateEvent) _then) = __$AutoModMessageUpdateEventCopyWithImpl;
@override @useResult
$Res call({
 String messageId, String status
});




}
/// @nodoc
class __$AutoModMessageUpdateEventCopyWithImpl<$Res>
    implements _$AutoModMessageUpdateEventCopyWith<$Res> {
  __$AutoModMessageUpdateEventCopyWithImpl(this._self, this._then);

  final _AutoModMessageUpdateEvent _self;
  final $Res Function(_AutoModMessageUpdateEvent) _then;

/// Create a copy of AutoModMessageUpdateEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? messageId = null,Object? status = null,}) {
  return _then(_AutoModMessageUpdateEvent(
messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
