import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../../../../../shared/design/design.dart';
import '../../../../../../shared/general/base/button.dart';
import '../../../../../../shared/general/base/divider.dart';
import '../../../../../../stores/shared/network.dart';
import '../../../../../../stores/views/dashboard.dart';
import '../../../../../../types/classes/stream/responses/base.dart';
import '../../../../../../types/enums/request_type.dart';
import '../../../../../../utils/network_helper.dart';

/// Text source kinds (GDI+ on Windows, FreeType 2 elsewhere) - both keep
/// the displayed text in the `text` setting
bool isTextInputKind(String? inputKind) =>
    inputKind != null &&
    (inputKind.startsWith('text_gdiplus') ||
        inputKind.startsWith('text_ft2_source'));

/// Edit a text source's text live ("Starting soon", a countdown label,
/// the current goal). Reads the current text once via GetInputSettings,
/// writes with overlay so every other setting (font, color, ...) stays.
class TextSourceSheet extends StatefulWidget {
  final String inputName;

  const TextSourceSheet({super.key, required this.inputName});

  @override
  State<TextSourceSheet> createState() => _TextSourceSheetState();
}

class _TextSourceSheetState extends State<TextSourceSheet> {
  final TextEditingController _controller = TextEditingController();
  StreamSubscription<dynamic>? _subscription;
  bool _loaded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// One-off read: the dashboard store has no use for input settings, so
  /// the sheet listens for its own answer instead of storing it app-wide
  void _load() {
    final NetworkStore networkStore = GetIt.instance<NetworkStore>();
    final session = networkStore.activeSession;
    if (session == null) return;

    _subscription = networkStore.watchOBSStream().listen((message) {
      if (message is BaseResponse &&
          message.requestType == RequestType.GetInputSettings &&
          message.status.result &&
          !_loaded &&
          this.mounted) {
        setState(() {
          _controller.text = message.json['inputSettings']?['text'] ?? '';
          _loaded = true;
        });
      }
    });

    NetworkHelper.makeRequest(session.socket, RequestType.GetInputSettings, {
      'inputName': this.widget.inputName,
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ack = await GetIt.instance<DashboardStore>().sendMutation(
      RequestType.SetInputSettings,
      fields: {
        'inputName': this.widget.inputName,
        'inputSettings': {'text': _controller.text},
        'overlay': true,
      },
      label: 'Text update',
    );
    if (!this.mounted) return;
    setState(() => _saving = false);
    if (ack.success) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SingleChildScrollView(
      padding:
          const EdgeInsets.symmetric(horizontal: 24.0) +
          EdgeInsets.only(
            bottom:
                MediaQuery.viewInsetsOf(context).bottom +
                MediaQuery.paddingOf(context).bottom +
                AppSpacing.xl,
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Edit Text', style: theme.textTheme.headlineSmall),
          Text(this.widget.inputName, style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.lg),
          const BaseDivider(),
          const SizedBox(height: AppSpacing.lg),
          CupertinoTextField(
            controller: _controller,
            enabled: _loaded,
            placeholder: _loaded ? 'Text' : 'Loading...',
            minLines: 1,
            maxLines: 6,
            autofocus: true,
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: StaleGuard(
              child: BaseButton(
                text: 'Update',
                onPressed: _loaded && !_saving ? _save : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
