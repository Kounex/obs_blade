import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../../../shared/design/design.dart';
import '../../../../../../shared/general/base/divider.dart';
import '../../../../../../stores/views/dashboard.dart';
import '../../../../../../types/classes/api/input.dart';
import '../../../../../../types/enums/request_type.dart';

const String kMonitorTypeNone = 'OBS_MONITORING_TYPE_NONE';
const String kMonitorTypeMonitorOnly = 'OBS_MONITORING_TYPE_MONITOR_ONLY';
const String kMonitorTypeMonitorAndOutput =
    'OBS_MONITORING_TYPE_MONITOR_AND_OUTPUT';

/// OBS monitor types (Advanced Audio Properties' "Audio Monitoring") as
/// segment value -> label. OBS 33+ only knows on / off: anything but NONE
/// is saved and reported as MONITOR_AND_OUTPUT, so On sends exactly that
/// and the control never jumps after the event
Map<String, String> monitorTypeOptions({required bool onOff}) => onOff
    ? const {kMonitorTypeNone: 'Off', kMonitorTypeMonitorAndOutput: 'On'}
    : const {
        kMonitorTypeNone: 'Off',
        kMonitorTypeMonitorOnly: 'Monitor',
        kMonitorTypeMonitorAndOutput: 'Both',
      };

/// The selected segment for [monitorType]. On OBS 33+ a stray
/// MONITOR_ONLY (never reported there, but cheap to cover) still reads
/// as On
String? monitorTypeSegment(String? monitorType, {required bool onOff}) {
  if (!onOff || monitorType == null || monitorType == kMonitorTypeNone) {
    return monitorType;
  }
  return kMonitorTypeMonitorAndOutput;
}

/// Per-input advanced audio: balance + monitoring, the two settings a
/// streamer reaches for mid-stream (hear a source on the OBS PC, fix a
/// one-sided mic). Loaded on open - the inputs batch doesn't carry them -
/// and kept live via the Input* events.
class AudioSettingsSheet extends StatefulWidget {
  final String inputName;

  const AudioSettingsSheet({super.key, required this.inputName});

  @override
  State<AudioSettingsSheet> createState() => _AudioSettingsSheetState();
}

class _AudioSettingsSheetState extends State<AudioSettingsSheet> {
  /// Local drag value so the thumb follows the finger; committed on release
  double? _draggingBalance;

  @override
  void initState() {
    super.initState();
    GetIt.instance<DashboardStore>().requestInputAudioSettings(
      this.widget.inputName,
    );
  }

  String _balanceLabel(double balance) {
    final int offset = ((balance - 0.5) * 200).round();
    if (offset == 0) return 'Center';
    return offset < 0 ? 'L ${-offset}%' : 'R $offset%';
  }

  @override
  Widget build(BuildContext context) {
    final DashboardStore dashboardStore = GetIt.instance<DashboardStore>();
    final ThemeData theme = Theme.of(context);
    final AppTextColors textColors = theme.extension<AppTextColors>()!;

    return Observer(
      builder: (context) {
        Input? input;
        for (final candidate in dashboardStore.allInputs) {
          if (candidate.inputName == this.widget.inputName) input = candidate;
        }
        final double? balance = _draggingBalance ?? input?.audioBalance;
        final bool monitoringIsOnOff = dashboardStore.monitoringIsOnOff;
        final String? monitorType = monitorTypeSegment(
          input?.monitorType,
          onOff: monitoringIsOnOff,
        );

        return SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(horizontal: 24.0) +
              EdgeInsets.only(
                bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.xl,
              ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Audio Settings', style: theme.textTheme.headlineSmall),
              Text(this.widget.inputName, style: theme.textTheme.bodySmall),
              const SizedBox(height: AppSpacing.lg),
              const BaseDivider(),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: Text('Balance', style: theme.textTheme.titleMedium),
                  ),
                  if (balance != null)
                    Text(
                      _balanceLabel(balance),
                      style: theme.textTheme.titleSmall!.copyWith(
                        color: textColors.textSecondary,
                        fontFeatures: kTabularFigures,
                      ),
                    ),
                ],
              ),
              StaleGuard(
                child: Slider(
                  min: 0.0,
                  max: 1.0,
                  value: balance ?? 0.5,
                  semanticFormatterCallback: (value) => _balanceLabel(value),
                  onChanged: balance == null
                      ? null
                      : (value) => setState(() => _draggingBalance = value),
                  onChangeEnd: (value) async {
                    /// Snap near-center to exact center - hitting 0.5 by
                    /// finger is otherwise near impossible
                    final double snapped = (value - 0.5).abs() < 0.03
                        ? 0.5
                        : value;
                    await dashboardStore.sendMutation(
                      RequestType.SetInputAudioBalance,
                      fields: {
                        'inputName': this.widget.inputName,
                        'inputAudioBalance': snapped,
                      },
                      label: 'Audio balance',
                    );
                    if (this.mounted) setState(() => _draggingBalance = null);
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Audio Monitoring', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                monitoringIsOnOff
                    ? 'Hear this source on the PC running OBS. It still goes to the stream unless you mute it.'
                    : 'Monitor lets you hear this source on the PC running OBS without sending it to the stream; Both does both.',
                style: theme.textTheme.bodySmall!.copyWith(
                  color: textColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: StaleGuard(
                  child: CupertinoSlidingSegmentedControl<String>(
                    groupValue: monitorType,
                    children: {
                      for (final entry in monitorTypeOptions(
                        onOff: monitoringIsOnOff,
                      ).entries)
                        entry.key: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm,
                          ),
                          child: Text(entry.value),
                        ),
                    },
                    onValueChanged: (type) {
                      if (type == null || type == monitorType) return;
                      dashboardStore.sendMutation(
                        RequestType.SetInputAudioMonitorType,
                        fields: {
                          'inputName': this.widget.inputName,
                          'monitorType': type,
                        },
                        label: 'Audio monitoring',
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
