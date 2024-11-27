// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'filter.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Filter _$FilterFromJson(Map<String, dynamic> json) {
  return _Filter.fromJson(json);
}

/// @nodoc
mixin _$Filter {
  bool get filterEnabled => throw _privateConstructorUsedError;
  int get filterIndex => throw _privateConstructorUsedError;
  String get filterKind => throw _privateConstructorUsedError;
  String get filterName => throw _privateConstructorUsedError;
  Map<String, dynamic> get filterSettings => throw _privateConstructorUsedError;

  /// Serializes this Filter to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Filter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FilterCopyWith<Filter> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FilterCopyWith<$Res> {
  factory $FilterCopyWith(Filter value, $Res Function(Filter) then) =
      _$FilterCopyWithImpl<$Res, Filter>;
  @useResult
  $Res call(
      {bool filterEnabled,
      int filterIndex,
      String filterKind,
      String filterName,
      Map<String, dynamic> filterSettings});
}

/// @nodoc
class _$FilterCopyWithImpl<$Res, $Val extends Filter>
    implements $FilterCopyWith<$Res> {
  _$FilterCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Filter
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? filterEnabled = null,
    Object? filterIndex = null,
    Object? filterKind = null,
    Object? filterName = null,
    Object? filterSettings = null,
  }) {
    return _then(_value.copyWith(
      filterEnabled: null == filterEnabled
          ? _value.filterEnabled
          : filterEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      filterIndex: null == filterIndex
          ? _value.filterIndex
          : filterIndex // ignore: cast_nullable_to_non_nullable
              as int,
      filterKind: null == filterKind
          ? _value.filterKind
          : filterKind // ignore: cast_nullable_to_non_nullable
              as String,
      filterName: null == filterName
          ? _value.filterName
          : filterName // ignore: cast_nullable_to_non_nullable
              as String,
      filterSettings: null == filterSettings
          ? _value.filterSettings
          : filterSettings // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FilterImplCopyWith<$Res> implements $FilterCopyWith<$Res> {
  factory _$$FilterImplCopyWith(
          _$FilterImpl value, $Res Function(_$FilterImpl) then) =
      __$$FilterImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool filterEnabled,
      int filterIndex,
      String filterKind,
      String filterName,
      Map<String, dynamic> filterSettings});
}

/// @nodoc
class __$$FilterImplCopyWithImpl<$Res>
    extends _$FilterCopyWithImpl<$Res, _$FilterImpl>
    implements _$$FilterImplCopyWith<$Res> {
  __$$FilterImplCopyWithImpl(
      _$FilterImpl _value, $Res Function(_$FilterImpl) _then)
      : super(_value, _then);

  /// Create a copy of Filter
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? filterEnabled = null,
    Object? filterIndex = null,
    Object? filterKind = null,
    Object? filterName = null,
    Object? filterSettings = null,
  }) {
    return _then(_$FilterImpl(
      filterEnabled: null == filterEnabled
          ? _value.filterEnabled
          : filterEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      filterIndex: null == filterIndex
          ? _value.filterIndex
          : filterIndex // ignore: cast_nullable_to_non_nullable
              as int,
      filterKind: null == filterKind
          ? _value.filterKind
          : filterKind // ignore: cast_nullable_to_non_nullable
              as String,
      filterName: null == filterName
          ? _value.filterName
          : filterName // ignore: cast_nullable_to_non_nullable
              as String,
      filterSettings: null == filterSettings
          ? _value._filterSettings
          : filterSettings // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FilterImpl implements _Filter {
  const _$FilterImpl(
      {required this.filterEnabled,
      required this.filterIndex,
      required this.filterKind,
      required this.filterName,
      required final Map<String, dynamic> filterSettings})
      : _filterSettings = filterSettings;

  factory _$FilterImpl.fromJson(Map<String, dynamic> json) =>
      _$$FilterImplFromJson(json);

  @override
  final bool filterEnabled;
  @override
  final int filterIndex;
  @override
  final String filterKind;
  @override
  final String filterName;
  final Map<String, dynamic> _filterSettings;
  @override
  Map<String, dynamic> get filterSettings {
    if (_filterSettings is EqualUnmodifiableMapView) return _filterSettings;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_filterSettings);
  }

  @override
  String toString() {
    return 'Filter(filterEnabled: $filterEnabled, filterIndex: $filterIndex, filterKind: $filterKind, filterName: $filterName, filterSettings: $filterSettings)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FilterImpl &&
            (identical(other.filterEnabled, filterEnabled) ||
                other.filterEnabled == filterEnabled) &&
            (identical(other.filterIndex, filterIndex) ||
                other.filterIndex == filterIndex) &&
            (identical(other.filterKind, filterKind) ||
                other.filterKind == filterKind) &&
            (identical(other.filterName, filterName) ||
                other.filterName == filterName) &&
            const DeepCollectionEquality()
                .equals(other._filterSettings, _filterSettings));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      filterEnabled,
      filterIndex,
      filterKind,
      filterName,
      const DeepCollectionEquality().hash(_filterSettings));

  /// Create a copy of Filter
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FilterImplCopyWith<_$FilterImpl> get copyWith =>
      __$$FilterImplCopyWithImpl<_$FilterImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FilterImplToJson(
      this,
    );
  }
}

abstract class _Filter implements Filter {
  const factory _Filter(
      {required final bool filterEnabled,
      required final int filterIndex,
      required final String filterKind,
      required final String filterName,
      required final Map<String, dynamic> filterSettings}) = _$FilterImpl;

  factory _Filter.fromJson(Map<String, dynamic> json) = _$FilterImpl.fromJson;

  @override
  bool get filterEnabled;
  @override
  int get filterIndex;
  @override
  String get filterKind;
  @override
  String get filterName;
  @override
  Map<String, dynamic> get filterSettings;

  /// Create a copy of Filter
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FilterImplCopyWith<_$FilterImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
