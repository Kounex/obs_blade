import 'package:freezed_annotation/freezed_annotation.dart';

part 'filter.freezed.dart';
part 'filter.g.dart';

@freezed
class Filter with _$Filter {
  const factory Filter({
    required bool filterEnabled,
    required int filterIndex,
    required String filterKind,
    required String filterName,
    required Map<String, dynamic> filterSettings,
  }) = _Filter;

  factory Filter.fromJson(Map<String, Object?> json) => _$FilterFromJson(json);
}
