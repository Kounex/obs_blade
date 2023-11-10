import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:obs_blade/types/classes/api/input_channel.dart';

part 'input.freezed.dart';
part 'input.g.dart';

@freezed
class Input with _$Input {
  const factory Input({
    required String? inputKind,
    required String? inputName,
    required String? unversionedInputKind,
    double? inputVolumeMul,
    double? inputVolumeDb,
    List<InputChannel>? inputLevelsMul,
    @Default(false) bool inputMuted,
  }) = _Input;

  factory Input.fromJson(Map<String, Object?> json) => _$InputFromJson(json);
}
