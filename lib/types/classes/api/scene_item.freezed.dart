// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scene_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

SceneItem _$SceneItemFromJson(Map<String, dynamic> json) {
  return _SceneItem.fromJson(json);
}

/// @nodoc
mixin _$SceneItem {
  String? get inputKind => throw _privateConstructorUsedError;
  bool? get isGroup => throw _privateConstructorUsedError;
  String? get sceneItemBlendMode => throw _privateConstructorUsedError;
  bool? get sceneItemEnabled => throw _privateConstructorUsedError;
  int? get sceneItemId => throw _privateConstructorUsedError;
  int? get sceneItemIndex => throw _privateConstructorUsedError;
  bool? get sceneItemLocked => throw _privateConstructorUsedError;
  SceneItemTransform? get sceneItemTransform =>
      throw _privateConstructorUsedError;
  String? get sourceName => throw _privateConstructorUsedError;
  String? get sourceType => throw _privateConstructorUsedError;
  List<Filter> get filters => throw _privateConstructorUsedError;

  /// OPTIONAL - Name of the item's parent (if this item belongs to a group)
  String? get parentGroupName => throw _privateConstructorUsedError;

  /// OPTIONAL - List of children (if this item is a group)
  List<SceneItem>? get groupChildren => throw _privateConstructorUsedError;

  /// CUSTOM - added myself to handle stuff internally
  /// Indicate whether we want to display the children of this group
  /// (if this [SceneItem] is a group)
  bool get displayGroup => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SceneItemCopyWith<SceneItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SceneItemCopyWith<$Res> {
  factory $SceneItemCopyWith(SceneItem value, $Res Function(SceneItem) then) =
      _$SceneItemCopyWithImpl<$Res, SceneItem>;
  @useResult
  $Res call(
      {String? inputKind,
      bool? isGroup,
      String? sceneItemBlendMode,
      bool? sceneItemEnabled,
      int? sceneItemId,
      int? sceneItemIndex,
      bool? sceneItemLocked,
      SceneItemTransform? sceneItemTransform,
      String? sourceName,
      String? sourceType,
      List<Filter> filters,
      String? parentGroupName,
      List<SceneItem>? groupChildren,
      bool displayGroup});

  $SceneItemTransformCopyWith<$Res>? get sceneItemTransform;
}

/// @nodoc
class _$SceneItemCopyWithImpl<$Res, $Val extends SceneItem>
    implements $SceneItemCopyWith<$Res> {
  _$SceneItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? inputKind = freezed,
    Object? isGroup = freezed,
    Object? sceneItemBlendMode = freezed,
    Object? sceneItemEnabled = freezed,
    Object? sceneItemId = freezed,
    Object? sceneItemIndex = freezed,
    Object? sceneItemLocked = freezed,
    Object? sceneItemTransform = freezed,
    Object? sourceName = freezed,
    Object? sourceType = freezed,
    Object? filters = null,
    Object? parentGroupName = freezed,
    Object? groupChildren = freezed,
    Object? displayGroup = null,
  }) {
    return _then(_value.copyWith(
      inputKind: freezed == inputKind
          ? _value.inputKind
          : inputKind // ignore: cast_nullable_to_non_nullable
              as String?,
      isGroup: freezed == isGroup
          ? _value.isGroup
          : isGroup // ignore: cast_nullable_to_non_nullable
              as bool?,
      sceneItemBlendMode: freezed == sceneItemBlendMode
          ? _value.sceneItemBlendMode
          : sceneItemBlendMode // ignore: cast_nullable_to_non_nullable
              as String?,
      sceneItemEnabled: freezed == sceneItemEnabled
          ? _value.sceneItemEnabled
          : sceneItemEnabled // ignore: cast_nullable_to_non_nullable
              as bool?,
      sceneItemId: freezed == sceneItemId
          ? _value.sceneItemId
          : sceneItemId // ignore: cast_nullable_to_non_nullable
              as int?,
      sceneItemIndex: freezed == sceneItemIndex
          ? _value.sceneItemIndex
          : sceneItemIndex // ignore: cast_nullable_to_non_nullable
              as int?,
      sceneItemLocked: freezed == sceneItemLocked
          ? _value.sceneItemLocked
          : sceneItemLocked // ignore: cast_nullable_to_non_nullable
              as bool?,
      sceneItemTransform: freezed == sceneItemTransform
          ? _value.sceneItemTransform
          : sceneItemTransform // ignore: cast_nullable_to_non_nullable
              as SceneItemTransform?,
      sourceName: freezed == sourceName
          ? _value.sourceName
          : sourceName // ignore: cast_nullable_to_non_nullable
              as String?,
      sourceType: freezed == sourceType
          ? _value.sourceType
          : sourceType // ignore: cast_nullable_to_non_nullable
              as String?,
      filters: null == filters
          ? _value.filters
          : filters // ignore: cast_nullable_to_non_nullable
              as List<Filter>,
      parentGroupName: freezed == parentGroupName
          ? _value.parentGroupName
          : parentGroupName // ignore: cast_nullable_to_non_nullable
              as String?,
      groupChildren: freezed == groupChildren
          ? _value.groupChildren
          : groupChildren // ignore: cast_nullable_to_non_nullable
              as List<SceneItem>?,
      displayGroup: null == displayGroup
          ? _value.displayGroup
          : displayGroup // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $SceneItemTransformCopyWith<$Res>? get sceneItemTransform {
    if (_value.sceneItemTransform == null) {
      return null;
    }

    return $SceneItemTransformCopyWith<$Res>(_value.sceneItemTransform!,
        (value) {
      return _then(_value.copyWith(sceneItemTransform: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SceneItemImplCopyWith<$Res>
    implements $SceneItemCopyWith<$Res> {
  factory _$$SceneItemImplCopyWith(
          _$SceneItemImpl value, $Res Function(_$SceneItemImpl) then) =
      __$$SceneItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? inputKind,
      bool? isGroup,
      String? sceneItemBlendMode,
      bool? sceneItemEnabled,
      int? sceneItemId,
      int? sceneItemIndex,
      bool? sceneItemLocked,
      SceneItemTransform? sceneItemTransform,
      String? sourceName,
      String? sourceType,
      List<Filter> filters,
      String? parentGroupName,
      List<SceneItem>? groupChildren,
      bool displayGroup});

  @override
  $SceneItemTransformCopyWith<$Res>? get sceneItemTransform;
}

/// @nodoc
class __$$SceneItemImplCopyWithImpl<$Res>
    extends _$SceneItemCopyWithImpl<$Res, _$SceneItemImpl>
    implements _$$SceneItemImplCopyWith<$Res> {
  __$$SceneItemImplCopyWithImpl(
      _$SceneItemImpl _value, $Res Function(_$SceneItemImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? inputKind = freezed,
    Object? isGroup = freezed,
    Object? sceneItemBlendMode = freezed,
    Object? sceneItemEnabled = freezed,
    Object? sceneItemId = freezed,
    Object? sceneItemIndex = freezed,
    Object? sceneItemLocked = freezed,
    Object? sceneItemTransform = freezed,
    Object? sourceName = freezed,
    Object? sourceType = freezed,
    Object? filters = null,
    Object? parentGroupName = freezed,
    Object? groupChildren = freezed,
    Object? displayGroup = null,
  }) {
    return _then(_$SceneItemImpl(
      inputKind: freezed == inputKind
          ? _value.inputKind
          : inputKind // ignore: cast_nullable_to_non_nullable
              as String?,
      isGroup: freezed == isGroup
          ? _value.isGroup
          : isGroup // ignore: cast_nullable_to_non_nullable
              as bool?,
      sceneItemBlendMode: freezed == sceneItemBlendMode
          ? _value.sceneItemBlendMode
          : sceneItemBlendMode // ignore: cast_nullable_to_non_nullable
              as String?,
      sceneItemEnabled: freezed == sceneItemEnabled
          ? _value.sceneItemEnabled
          : sceneItemEnabled // ignore: cast_nullable_to_non_nullable
              as bool?,
      sceneItemId: freezed == sceneItemId
          ? _value.sceneItemId
          : sceneItemId // ignore: cast_nullable_to_non_nullable
              as int?,
      sceneItemIndex: freezed == sceneItemIndex
          ? _value.sceneItemIndex
          : sceneItemIndex // ignore: cast_nullable_to_non_nullable
              as int?,
      sceneItemLocked: freezed == sceneItemLocked
          ? _value.sceneItemLocked
          : sceneItemLocked // ignore: cast_nullable_to_non_nullable
              as bool?,
      sceneItemTransform: freezed == sceneItemTransform
          ? _value.sceneItemTransform
          : sceneItemTransform // ignore: cast_nullable_to_non_nullable
              as SceneItemTransform?,
      sourceName: freezed == sourceName
          ? _value.sourceName
          : sourceName // ignore: cast_nullable_to_non_nullable
              as String?,
      sourceType: freezed == sourceType
          ? _value.sourceType
          : sourceType // ignore: cast_nullable_to_non_nullable
              as String?,
      filters: null == filters
          ? _value._filters
          : filters // ignore: cast_nullable_to_non_nullable
              as List<Filter>,
      parentGroupName: freezed == parentGroupName
          ? _value.parentGroupName
          : parentGroupName // ignore: cast_nullable_to_non_nullable
              as String?,
      groupChildren: freezed == groupChildren
          ? _value._groupChildren
          : groupChildren // ignore: cast_nullable_to_non_nullable
              as List<SceneItem>?,
      displayGroup: null == displayGroup
          ? _value.displayGroup
          : displayGroup // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SceneItemImpl implements _SceneItem {
  const _$SceneItemImpl(
      {required this.inputKind,
      required this.isGroup,
      required this.sceneItemBlendMode,
      required this.sceneItemEnabled,
      required this.sceneItemId,
      required this.sceneItemIndex,
      required this.sceneItemLocked,
      required this.sceneItemTransform,
      required this.sourceName,
      required this.sourceType,
      final List<Filter> filters = const [],
      this.parentGroupName,
      final List<SceneItem>? groupChildren,
      this.displayGroup = false})
      : _filters = filters,
        _groupChildren = groupChildren;

  factory _$SceneItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$SceneItemImplFromJson(json);

  @override
  final String? inputKind;
  @override
  final bool? isGroup;
  @override
  final String? sceneItemBlendMode;
  @override
  final bool? sceneItemEnabled;
  @override
  final int? sceneItemId;
  @override
  final int? sceneItemIndex;
  @override
  final bool? sceneItemLocked;
  @override
  final SceneItemTransform? sceneItemTransform;
  @override
  final String? sourceName;
  @override
  final String? sourceType;
  final List<Filter> _filters;
  @override
  @JsonKey()
  List<Filter> get filters {
    if (_filters is EqualUnmodifiableListView) return _filters;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_filters);
  }

  /// OPTIONAL - Name of the item's parent (if this item belongs to a group)
  @override
  final String? parentGroupName;

  /// OPTIONAL - List of children (if this item is a group)
  final List<SceneItem>? _groupChildren;

  /// OPTIONAL - List of children (if this item is a group)
  @override
  List<SceneItem>? get groupChildren {
    final value = _groupChildren;
    if (value == null) return null;
    if (_groupChildren is EqualUnmodifiableListView) return _groupChildren;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  /// CUSTOM - added myself to handle stuff internally
  /// Indicate whether we want to display the children of this group
  /// (if this [SceneItem] is a group)
  @override
  @JsonKey()
  final bool displayGroup;

  @override
  String toString() {
    return 'SceneItem(inputKind: $inputKind, isGroup: $isGroup, sceneItemBlendMode: $sceneItemBlendMode, sceneItemEnabled: $sceneItemEnabled, sceneItemId: $sceneItemId, sceneItemIndex: $sceneItemIndex, sceneItemLocked: $sceneItemLocked, sceneItemTransform: $sceneItemTransform, sourceName: $sourceName, sourceType: $sourceType, filters: $filters, parentGroupName: $parentGroupName, groupChildren: $groupChildren, displayGroup: $displayGroup)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SceneItemImpl &&
            (identical(other.inputKind, inputKind) ||
                other.inputKind == inputKind) &&
            (identical(other.isGroup, isGroup) || other.isGroup == isGroup) &&
            (identical(other.sceneItemBlendMode, sceneItemBlendMode) ||
                other.sceneItemBlendMode == sceneItemBlendMode) &&
            (identical(other.sceneItemEnabled, sceneItemEnabled) ||
                other.sceneItemEnabled == sceneItemEnabled) &&
            (identical(other.sceneItemId, sceneItemId) ||
                other.sceneItemId == sceneItemId) &&
            (identical(other.sceneItemIndex, sceneItemIndex) ||
                other.sceneItemIndex == sceneItemIndex) &&
            (identical(other.sceneItemLocked, sceneItemLocked) ||
                other.sceneItemLocked == sceneItemLocked) &&
            (identical(other.sceneItemTransform, sceneItemTransform) ||
                other.sceneItemTransform == sceneItemTransform) &&
            (identical(other.sourceName, sourceName) ||
                other.sourceName == sourceName) &&
            (identical(other.sourceType, sourceType) ||
                other.sourceType == sourceType) &&
            const DeepCollectionEquality().equals(other._filters, _filters) &&
            (identical(other.parentGroupName, parentGroupName) ||
                other.parentGroupName == parentGroupName) &&
            const DeepCollectionEquality()
                .equals(other._groupChildren, _groupChildren) &&
            (identical(other.displayGroup, displayGroup) ||
                other.displayGroup == displayGroup));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      inputKind,
      isGroup,
      sceneItemBlendMode,
      sceneItemEnabled,
      sceneItemId,
      sceneItemIndex,
      sceneItemLocked,
      sceneItemTransform,
      sourceName,
      sourceType,
      const DeepCollectionEquality().hash(_filters),
      parentGroupName,
      const DeepCollectionEquality().hash(_groupChildren),
      displayGroup);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SceneItemImplCopyWith<_$SceneItemImpl> get copyWith =>
      __$$SceneItemImplCopyWithImpl<_$SceneItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SceneItemImplToJson(
      this,
    );
  }
}

abstract class _SceneItem implements SceneItem {
  const factory _SceneItem(
      {required final String? inputKind,
      required final bool? isGroup,
      required final String? sceneItemBlendMode,
      required final bool? sceneItemEnabled,
      required final int? sceneItemId,
      required final int? sceneItemIndex,
      required final bool? sceneItemLocked,
      required final SceneItemTransform? sceneItemTransform,
      required final String? sourceName,
      required final String? sourceType,
      final List<Filter> filters,
      final String? parentGroupName,
      final List<SceneItem>? groupChildren,
      final bool displayGroup}) = _$SceneItemImpl;

  factory _SceneItem.fromJson(Map<String, dynamic> json) =
      _$SceneItemImpl.fromJson;

  @override
  String? get inputKind;
  @override
  bool? get isGroup;
  @override
  String? get sceneItemBlendMode;
  @override
  bool? get sceneItemEnabled;
  @override
  int? get sceneItemId;
  @override
  int? get sceneItemIndex;
  @override
  bool? get sceneItemLocked;
  @override
  SceneItemTransform? get sceneItemTransform;
  @override
  String? get sourceName;
  @override
  String? get sourceType;
  @override
  List<Filter> get filters;
  @override

  /// OPTIONAL - Name of the item's parent (if this item belongs to a group)
  String? get parentGroupName;
  @override

  /// OPTIONAL - List of children (if this item is a group)
  List<SceneItem>? get groupChildren;
  @override

  /// CUSTOM - added myself to handle stuff internally
  /// Indicate whether we want to display the children of this group
  /// (if this [SceneItem] is a group)
  bool get displayGroup;
  @override
  @JsonKey(ignore: true)
  _$$SceneItemImplCopyWith<_$SceneItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
