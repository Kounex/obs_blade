// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scene_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SceneItem {

 String? get inputKind; bool? get isGroup; String? get sceneItemBlendMode; bool? get sceneItemEnabled; int? get sceneItemId; int? get sceneItemIndex; bool? get sceneItemLocked; SceneItemTransform? get sceneItemTransform; String? get sourceName; String? get sourceType; List<Filter> get filters;/// OPTIONAL - Name of the item's parent (if this item belongs to a group)
 String? get parentGroupName;/// OPTIONAL - List of children (if this item is a group)
 List<SceneItem>? get groupChildren;/// CUSTOM - added myself to handle stuff internally
/// Indicate whether we want to display the children of this group
/// (if this [SceneItem] is a group)
 bool get displayGroup;
/// Create a copy of SceneItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SceneItemCopyWith<SceneItem> get copyWith => _$SceneItemCopyWithImpl<SceneItem>(this as SceneItem, _$identity);

  /// Serializes this SceneItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SceneItem&&(identical(other.inputKind, inputKind) || other.inputKind == inputKind)&&(identical(other.isGroup, isGroup) || other.isGroup == isGroup)&&(identical(other.sceneItemBlendMode, sceneItemBlendMode) || other.sceneItemBlendMode == sceneItemBlendMode)&&(identical(other.sceneItemEnabled, sceneItemEnabled) || other.sceneItemEnabled == sceneItemEnabled)&&(identical(other.sceneItemId, sceneItemId) || other.sceneItemId == sceneItemId)&&(identical(other.sceneItemIndex, sceneItemIndex) || other.sceneItemIndex == sceneItemIndex)&&(identical(other.sceneItemLocked, sceneItemLocked) || other.sceneItemLocked == sceneItemLocked)&&(identical(other.sceneItemTransform, sceneItemTransform) || other.sceneItemTransform == sceneItemTransform)&&(identical(other.sourceName, sourceName) || other.sourceName == sourceName)&&(identical(other.sourceType, sourceType) || other.sourceType == sourceType)&&const DeepCollectionEquality().equals(other.filters, filters)&&(identical(other.parentGroupName, parentGroupName) || other.parentGroupName == parentGroupName)&&const DeepCollectionEquality().equals(other.groupChildren, groupChildren)&&(identical(other.displayGroup, displayGroup) || other.displayGroup == displayGroup));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,inputKind,isGroup,sceneItemBlendMode,sceneItemEnabled,sceneItemId,sceneItemIndex,sceneItemLocked,sceneItemTransform,sourceName,sourceType,const DeepCollectionEquality().hash(filters),parentGroupName,const DeepCollectionEquality().hash(groupChildren),displayGroup);

@override
String toString() {
  return 'SceneItem(inputKind: $inputKind, isGroup: $isGroup, sceneItemBlendMode: $sceneItemBlendMode, sceneItemEnabled: $sceneItemEnabled, sceneItemId: $sceneItemId, sceneItemIndex: $sceneItemIndex, sceneItemLocked: $sceneItemLocked, sceneItemTransform: $sceneItemTransform, sourceName: $sourceName, sourceType: $sourceType, filters: $filters, parentGroupName: $parentGroupName, groupChildren: $groupChildren, displayGroup: $displayGroup)';
}


}

/// @nodoc
abstract mixin class $SceneItemCopyWith<$Res>  {
  factory $SceneItemCopyWith(SceneItem value, $Res Function(SceneItem) _then) = _$SceneItemCopyWithImpl;
@useResult
$Res call({
 String? inputKind, bool? isGroup, String? sceneItemBlendMode, bool? sceneItemEnabled, int? sceneItemId, int? sceneItemIndex, bool? sceneItemLocked, SceneItemTransform? sceneItemTransform, String? sourceName, String? sourceType, List<Filter> filters, String? parentGroupName, List<SceneItem>? groupChildren, bool displayGroup
});


$SceneItemTransformCopyWith<$Res>? get sceneItemTransform;

}
/// @nodoc
class _$SceneItemCopyWithImpl<$Res>
    implements $SceneItemCopyWith<$Res> {
  _$SceneItemCopyWithImpl(this._self, this._then);

  final SceneItem _self;
  final $Res Function(SceneItem) _then;

/// Create a copy of SceneItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? inputKind = freezed,Object? isGroup = freezed,Object? sceneItemBlendMode = freezed,Object? sceneItemEnabled = freezed,Object? sceneItemId = freezed,Object? sceneItemIndex = freezed,Object? sceneItemLocked = freezed,Object? sceneItemTransform = freezed,Object? sourceName = freezed,Object? sourceType = freezed,Object? filters = null,Object? parentGroupName = freezed,Object? groupChildren = freezed,Object? displayGroup = null,}) {
  return _then(_self.copyWith(
inputKind: freezed == inputKind ? _self.inputKind : inputKind // ignore: cast_nullable_to_non_nullable
as String?,isGroup: freezed == isGroup ? _self.isGroup : isGroup // ignore: cast_nullable_to_non_nullable
as bool?,sceneItemBlendMode: freezed == sceneItemBlendMode ? _self.sceneItemBlendMode : sceneItemBlendMode // ignore: cast_nullable_to_non_nullable
as String?,sceneItemEnabled: freezed == sceneItemEnabled ? _self.sceneItemEnabled : sceneItemEnabled // ignore: cast_nullable_to_non_nullable
as bool?,sceneItemId: freezed == sceneItemId ? _self.sceneItemId : sceneItemId // ignore: cast_nullable_to_non_nullable
as int?,sceneItemIndex: freezed == sceneItemIndex ? _self.sceneItemIndex : sceneItemIndex // ignore: cast_nullable_to_non_nullable
as int?,sceneItemLocked: freezed == sceneItemLocked ? _self.sceneItemLocked : sceneItemLocked // ignore: cast_nullable_to_non_nullable
as bool?,sceneItemTransform: freezed == sceneItemTransform ? _self.sceneItemTransform : sceneItemTransform // ignore: cast_nullable_to_non_nullable
as SceneItemTransform?,sourceName: freezed == sourceName ? _self.sourceName : sourceName // ignore: cast_nullable_to_non_nullable
as String?,sourceType: freezed == sourceType ? _self.sourceType : sourceType // ignore: cast_nullable_to_non_nullable
as String?,filters: null == filters ? _self.filters : filters // ignore: cast_nullable_to_non_nullable
as List<Filter>,parentGroupName: freezed == parentGroupName ? _self.parentGroupName : parentGroupName // ignore: cast_nullable_to_non_nullable
as String?,groupChildren: freezed == groupChildren ? _self.groupChildren : groupChildren // ignore: cast_nullable_to_non_nullable
as List<SceneItem>?,displayGroup: null == displayGroup ? _self.displayGroup : displayGroup // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of SceneItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SceneItemTransformCopyWith<$Res>? get sceneItemTransform {
    if (_self.sceneItemTransform == null) {
    return null;
  }

  return $SceneItemTransformCopyWith<$Res>(_self.sceneItemTransform!, (value) {
    return _then(_self.copyWith(sceneItemTransform: value));
  });
}
}


/// Adds pattern-matching-related methods to [SceneItem].
extension SceneItemPatterns on SceneItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SceneItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SceneItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SceneItem value)  $default,){
final _that = this;
switch (_that) {
case _SceneItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SceneItem value)?  $default,){
final _that = this;
switch (_that) {
case _SceneItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? inputKind,  bool? isGroup,  String? sceneItemBlendMode,  bool? sceneItemEnabled,  int? sceneItemId,  int? sceneItemIndex,  bool? sceneItemLocked,  SceneItemTransform? sceneItemTransform,  String? sourceName,  String? sourceType,  List<Filter> filters,  String? parentGroupName,  List<SceneItem>? groupChildren,  bool displayGroup)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SceneItem() when $default != null:
return $default(_that.inputKind,_that.isGroup,_that.sceneItemBlendMode,_that.sceneItemEnabled,_that.sceneItemId,_that.sceneItemIndex,_that.sceneItemLocked,_that.sceneItemTransform,_that.sourceName,_that.sourceType,_that.filters,_that.parentGroupName,_that.groupChildren,_that.displayGroup);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? inputKind,  bool? isGroup,  String? sceneItemBlendMode,  bool? sceneItemEnabled,  int? sceneItemId,  int? sceneItemIndex,  bool? sceneItemLocked,  SceneItemTransform? sceneItemTransform,  String? sourceName,  String? sourceType,  List<Filter> filters,  String? parentGroupName,  List<SceneItem>? groupChildren,  bool displayGroup)  $default,) {final _that = this;
switch (_that) {
case _SceneItem():
return $default(_that.inputKind,_that.isGroup,_that.sceneItemBlendMode,_that.sceneItemEnabled,_that.sceneItemId,_that.sceneItemIndex,_that.sceneItemLocked,_that.sceneItemTransform,_that.sourceName,_that.sourceType,_that.filters,_that.parentGroupName,_that.groupChildren,_that.displayGroup);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? inputKind,  bool? isGroup,  String? sceneItemBlendMode,  bool? sceneItemEnabled,  int? sceneItemId,  int? sceneItemIndex,  bool? sceneItemLocked,  SceneItemTransform? sceneItemTransform,  String? sourceName,  String? sourceType,  List<Filter> filters,  String? parentGroupName,  List<SceneItem>? groupChildren,  bool displayGroup)?  $default,) {final _that = this;
switch (_that) {
case _SceneItem() when $default != null:
return $default(_that.inputKind,_that.isGroup,_that.sceneItemBlendMode,_that.sceneItemEnabled,_that.sceneItemId,_that.sceneItemIndex,_that.sceneItemLocked,_that.sceneItemTransform,_that.sourceName,_that.sourceType,_that.filters,_that.parentGroupName,_that.groupChildren,_that.displayGroup);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SceneItem implements SceneItem {
  const _SceneItem({required this.inputKind, required this.isGroup, required this.sceneItemBlendMode, required this.sceneItemEnabled, required this.sceneItemId, required this.sceneItemIndex, required this.sceneItemLocked, required this.sceneItemTransform, required this.sourceName, required this.sourceType, final  List<Filter> filters = const [], this.parentGroupName, final  List<SceneItem>? groupChildren, this.displayGroup = false}): _filters = filters,_groupChildren = groupChildren;
  factory _SceneItem.fromJson(Map<String, dynamic> json) => _$SceneItemFromJson(json);

@override final  String? inputKind;
@override final  bool? isGroup;
@override final  String? sceneItemBlendMode;
@override final  bool? sceneItemEnabled;
@override final  int? sceneItemId;
@override final  int? sceneItemIndex;
@override final  bool? sceneItemLocked;
@override final  SceneItemTransform? sceneItemTransform;
@override final  String? sourceName;
@override final  String? sourceType;
 final  List<Filter> _filters;
@override@JsonKey() List<Filter> get filters {
  if (_filters is EqualUnmodifiableListView) return _filters;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_filters);
}

/// OPTIONAL - Name of the item's parent (if this item belongs to a group)
@override final  String? parentGroupName;
/// OPTIONAL - List of children (if this item is a group)
 final  List<SceneItem>? _groupChildren;
/// OPTIONAL - List of children (if this item is a group)
@override List<SceneItem>? get groupChildren {
  final value = _groupChildren;
  if (value == null) return null;
  if (_groupChildren is EqualUnmodifiableListView) return _groupChildren;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// CUSTOM - added myself to handle stuff internally
/// Indicate whether we want to display the children of this group
/// (if this [SceneItem] is a group)
@override@JsonKey() final  bool displayGroup;

/// Create a copy of SceneItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SceneItemCopyWith<_SceneItem> get copyWith => __$SceneItemCopyWithImpl<_SceneItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SceneItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SceneItem&&(identical(other.inputKind, inputKind) || other.inputKind == inputKind)&&(identical(other.isGroup, isGroup) || other.isGroup == isGroup)&&(identical(other.sceneItemBlendMode, sceneItemBlendMode) || other.sceneItemBlendMode == sceneItemBlendMode)&&(identical(other.sceneItemEnabled, sceneItemEnabled) || other.sceneItemEnabled == sceneItemEnabled)&&(identical(other.sceneItemId, sceneItemId) || other.sceneItemId == sceneItemId)&&(identical(other.sceneItemIndex, sceneItemIndex) || other.sceneItemIndex == sceneItemIndex)&&(identical(other.sceneItemLocked, sceneItemLocked) || other.sceneItemLocked == sceneItemLocked)&&(identical(other.sceneItemTransform, sceneItemTransform) || other.sceneItemTransform == sceneItemTransform)&&(identical(other.sourceName, sourceName) || other.sourceName == sourceName)&&(identical(other.sourceType, sourceType) || other.sourceType == sourceType)&&const DeepCollectionEquality().equals(other._filters, _filters)&&(identical(other.parentGroupName, parentGroupName) || other.parentGroupName == parentGroupName)&&const DeepCollectionEquality().equals(other._groupChildren, _groupChildren)&&(identical(other.displayGroup, displayGroup) || other.displayGroup == displayGroup));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,inputKind,isGroup,sceneItemBlendMode,sceneItemEnabled,sceneItemId,sceneItemIndex,sceneItemLocked,sceneItemTransform,sourceName,sourceType,const DeepCollectionEquality().hash(_filters),parentGroupName,const DeepCollectionEquality().hash(_groupChildren),displayGroup);

@override
String toString() {
  return 'SceneItem(inputKind: $inputKind, isGroup: $isGroup, sceneItemBlendMode: $sceneItemBlendMode, sceneItemEnabled: $sceneItemEnabled, sceneItemId: $sceneItemId, sceneItemIndex: $sceneItemIndex, sceneItemLocked: $sceneItemLocked, sceneItemTransform: $sceneItemTransform, sourceName: $sourceName, sourceType: $sourceType, filters: $filters, parentGroupName: $parentGroupName, groupChildren: $groupChildren, displayGroup: $displayGroup)';
}


}

/// @nodoc
abstract mixin class _$SceneItemCopyWith<$Res> implements $SceneItemCopyWith<$Res> {
  factory _$SceneItemCopyWith(_SceneItem value, $Res Function(_SceneItem) _then) = __$SceneItemCopyWithImpl;
@override @useResult
$Res call({
 String? inputKind, bool? isGroup, String? sceneItemBlendMode, bool? sceneItemEnabled, int? sceneItemId, int? sceneItemIndex, bool? sceneItemLocked, SceneItemTransform? sceneItemTransform, String? sourceName, String? sourceType, List<Filter> filters, String? parentGroupName, List<SceneItem>? groupChildren, bool displayGroup
});


@override $SceneItemTransformCopyWith<$Res>? get sceneItemTransform;

}
/// @nodoc
class __$SceneItemCopyWithImpl<$Res>
    implements _$SceneItemCopyWith<$Res> {
  __$SceneItemCopyWithImpl(this._self, this._then);

  final _SceneItem _self;
  final $Res Function(_SceneItem) _then;

/// Create a copy of SceneItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? inputKind = freezed,Object? isGroup = freezed,Object? sceneItemBlendMode = freezed,Object? sceneItemEnabled = freezed,Object? sceneItemId = freezed,Object? sceneItemIndex = freezed,Object? sceneItemLocked = freezed,Object? sceneItemTransform = freezed,Object? sourceName = freezed,Object? sourceType = freezed,Object? filters = null,Object? parentGroupName = freezed,Object? groupChildren = freezed,Object? displayGroup = null,}) {
  return _then(_SceneItem(
inputKind: freezed == inputKind ? _self.inputKind : inputKind // ignore: cast_nullable_to_non_nullable
as String?,isGroup: freezed == isGroup ? _self.isGroup : isGroup // ignore: cast_nullable_to_non_nullable
as bool?,sceneItemBlendMode: freezed == sceneItemBlendMode ? _self.sceneItemBlendMode : sceneItemBlendMode // ignore: cast_nullable_to_non_nullable
as String?,sceneItemEnabled: freezed == sceneItemEnabled ? _self.sceneItemEnabled : sceneItemEnabled // ignore: cast_nullable_to_non_nullable
as bool?,sceneItemId: freezed == sceneItemId ? _self.sceneItemId : sceneItemId // ignore: cast_nullable_to_non_nullable
as int?,sceneItemIndex: freezed == sceneItemIndex ? _self.sceneItemIndex : sceneItemIndex // ignore: cast_nullable_to_non_nullable
as int?,sceneItemLocked: freezed == sceneItemLocked ? _self.sceneItemLocked : sceneItemLocked // ignore: cast_nullable_to_non_nullable
as bool?,sceneItemTransform: freezed == sceneItemTransform ? _self.sceneItemTransform : sceneItemTransform // ignore: cast_nullable_to_non_nullable
as SceneItemTransform?,sourceName: freezed == sourceName ? _self.sourceName : sourceName // ignore: cast_nullable_to_non_nullable
as String?,sourceType: freezed == sourceType ? _self.sourceType : sourceType // ignore: cast_nullable_to_non_nullable
as String?,filters: null == filters ? _self._filters : filters // ignore: cast_nullable_to_non_nullable
as List<Filter>,parentGroupName: freezed == parentGroupName ? _self.parentGroupName : parentGroupName // ignore: cast_nullable_to_non_nullable
as String?,groupChildren: freezed == groupChildren ? _self._groupChildren : groupChildren // ignore: cast_nullable_to_non_nullable
as List<SceneItem>?,displayGroup: null == displayGroup ? _self.displayGroup : displayGroup // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of SceneItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SceneItemTransformCopyWith<$Res>? get sceneItemTransform {
    if (_self.sceneItemTransform == null) {
    return null;
  }

  return $SceneItemTransformCopyWith<$Res>(_self.sceneItemTransform!, (value) {
    return _then(_self.copyWith(sceneItemTransform: value));
  });
}
}

// dart format on
