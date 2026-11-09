import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../../models/connection.dart';
import '../../../../shared/dialogs/input.dart';
import '../../../../shared/animator/status_dot.dart';
import '../../../../shared/design/design.dart';
import '../../../../shared/general/base/button.dart';
import '../../../../shared/general/base/divider.dart';
import '../../../../shared/general/base/sheet.dart';
import '../../../../shared/general/base/icon_button.dart';
import '../../../../shared/overlay/base_result.dart';
import '../../../pro/widgets/pro_badge.dart';
import '../../../../utils/modal_handler.dart';
import '../../../../utils/overlay_handler.dart';
import '../../../../stores/views/remote_access.dart';
import '../../../../utils/relative_time.dart';
import '../../../../utils/remote/remote_relay_client.dart';

/// Remote access (Pro): pair this device with OBS Blade Remote on the PC
/// (the OBS plugin or the standalone app) while connected on the same
/// network, then reach OBS from anywhere through the relay. Spec:
/// `docs/superpowers/specs/2026-11-07-remote-relay-design.md`.
class RemoteAccessSheet extends StatefulWidget {
  /// The active session's connection
  final Connection connection;

  /// Saved connections only: the pairing lives on the saved entry
  final bool saved;
  final bool isPro;

  /// This session runs through the relay right now
  final bool viaRemote;

  final RemoteAccessStore store;

  /// Device name / platform sent to the relay (shown on the PC)
  final String deviceName;
  final String platform;

  final VoidCallback onGetPro;
  final VoidCallback onSaveConnection;

  const RemoteAccessSheet({
    super.key,
    required this.connection,
    required this.saved,
    required this.isPro,
    required this.viaRemote,
    required this.store,
    required this.deviceName,
    required this.platform,
    required this.onGetPro,
    required this.onSaveConnection,
  });

  @override
  State<RemoteAccessSheet> createState() => _RemoteAccessSheetState();
}

class _RemoteAccessSheetState extends State<RemoteAccessSheet> {
  @override
  void initState() {
    super.initState();
    if (this.widget.isPro && this.widget.connection.hasRemote) {
      this.widget.store.refresh(this.widget.connection);
    }
  }

  @override
  void dispose() {
    this.widget.store.cancel();
    super.dispose();
  }

  void _pair() => this.widget.store.pair(
    this.widget.connection,
    deviceName: this.widget.deviceName,
    platform: this.widget.platform,
  );

  /// The store-driven part: the paired state (bridge info) or the pairing
  /// run. Only this observes the store - the free / unsaved states read
  /// nothing from it, and an Observer around them watched nothing.
  Widget _storeBody() => Observer(
    builder: (context) {
      final RemoteAccessStore store = this.widget.store;
      if (this.widget.connection.hasRemote) {
        return _Paired(
          connection: this.widget.connection,
          info: store.info,
          loading: store.infoLoading,
          unreachable: store.infoError?.isNetwork ?? false,
          viaRemote: this.widget.viaRemote,
          onRemoveDevice: (id) async {
            if (!await store.removeDevice(this.widget.connection, id) &&
                context.mounted) {
              _relayProblem(context);
            }
          },
          onRenameDevice: (device) => ModalHandler.showBaseDialog(
            context: context,
            dialogWidget: InputDialog(
              title: 'Rename Device',
              body: 'The name your PC lists this device under.',
              inputText: device.name,
              inputPlaceholder: 'Device name',
              inputCheck: (name) =>
                  (name ?? '').trim().isEmpty ? 'Enter a name' : null,
              onSave: (name) async {
                if (!await store.renameDevice(
                      this.widget.connection,
                      device.id,
                      name ?? '',
                    ) &&
                    context.mounted) {
                  _relayProblem(context);
                }
              },
            ),
          ),
          onTurnOff: () async {
            if (!await store.forget(this.widget.connection) &&
                context.mounted) {
              _relayProblem(context);
            }
          },
        );
      }
      return switch (store.phase) {
        RemotePairingPhase.starting || RemotePairingPhase.waitingForBridge =>
          _Waiting(code: store.code, onCancel: store.cancel),
        RemotePairingPhase.failed => _Failed(
          failure: store.failure!,
          onRetry: this._pair,
          onGetPro: this.widget.onGetPro,
        ),
        RemotePairingPhase.idle || RemotePairingPhase.paired => _SetUp(
          buttonText: 'Set Up Remote Access',
          onPressed: this._pair,
        ),
      };
    },
  );

  @override
  Widget build(BuildContext context) {
    final Widget body = !this.widget.isPro
        /// Free users read the same pitch as Pro users before setting
        /// up - only the button leads to the paywall instead
        /// (user directive 2026-11-08)
        ? _SetUp(buttonText: 'Unlock Pro', onPressed: this.widget.onGetPro)
        : !this.widget.saved
        ? _NeedsSavedConnection(onSave: this.widget.onSaveConnection)
        : this._storeBody();

    return BaseSheetScaffold(
      header: const BaseSheetTitle(
        'Remote Access',
        subtitle: 'Control OBS from anywhere',
        titleSuffix: ProBadge(scale: 1.2),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BaseDivider(),
          const SizedBox(height: AppSpacing.lg),
          body,
        ],
      ),
    );
  }
}

void _relayProblem(BuildContext context) => OverlayHandler.showStatusOverlay(
  context: context,
  content: const BaseResult(
    icon: BaseResultIcon.Negative,
    text: 'Couldn\'t reach the OBS Blade relay. Try again in a moment.',
  ),
);

TextStyle _secondary(BuildContext context) =>
    Theme.of(context).textTheme.bodyMedium!.copyWith(
      color: Theme.of(context).extension<AppTextColors>()!.textSecondary,
    );

/// What the relay can't see (spec "End-to-end encryption", 2026-11-08)
class _EndToEndNote extends StatelessWidget {
  const _EndToEndNote();

  @override
  Widget build(BuildContext context) {
    final TextStyle style = _secondary(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: Icon(CupertinoIcons.lock_fill, size: 16.0, color: style.color),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            'End-to-end encrypted: the relay passes your session on but '
            'can\'t read it - not your scenes, your preview or your stream '
            'key.',
            style: style,
          ),
        ),
      ],
    );
  }
}

class _NeedsSavedConnection extends StatelessWidget {
  final VoidCallback onSave;

  const _NeedsSavedConnection({required this.onSave});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Save this connection first - remote access is set up for a saved '
        'connection, so the app knows which PC to reach later.',
        style: _secondary(context),
      ),
      const SizedBox(height: AppSpacing.lg),
      SizedBox(
        width: double.infinity,
        child: BaseButton(text: 'Save Connection', onPressed: this.onSave),
      ),
    ],
  );
}

/// The pitch and the PC side - with the setup button for Pro users, the
/// paywall's for free users
class _SetUp extends StatelessWidget {
  final String buttonText;
  final VoidCallback onPressed;

  const _SetUp({required this.buttonText, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'When OBS isn\'t on the same network as this device, OBS Blade '
          'connects through the OBS Blade relay instead. Nothing to open '
          'on your router, and your OBS password never leaves the PC.',
          style: _secondary(context),
        ),
        const SizedBox(height: AppSpacing.md),
        const _EndToEndNote(),
        const SizedBox(height: AppSpacing.lg),
        Text('On the PC running OBS', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Install OBS Blade Remote - the OBS plugin (runs with OBS), or the '
          'app if you\'d rather not add plugins. Then set it up here while '
          'you\'re connected to OBS like right now.',
          style: _secondary(context),
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: BaseButton(text: this.buttonText, onPressed: this.onPressed),
        ),
      ],
    );
  }
}

class _Waiting extends StatelessWidget {
  final String? code;
  final VoidCallback onCancel;

  const _Waiting({required this.code, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const CupertinoActivityIndicator(),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Waiting for OBS Blade Remote on your PC…',
                style: theme.textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          this.code == null
              ? 'Asking the relay for a pairing code.'
              : 'Pairing code ${this.code!.substring(0, 4)}-${this.code!.substring(4)} - '
                    'it goes to the PC through OBS, nothing to type.',
          style: _secondary(context),
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: BaseButton(
            text: 'Cancel',
            secondary: true,
            onPressed: this.onCancel,
          ),
        ),
      ],
    );
  }
}

/// Copy for a failed pairing (and whether the Pro page helps).
(String, bool) remotePairingFailureCopy(RemotePairingFailure failure) =>
    switch (failure) {
      RemotePairingFailure.noAccount => (
        'Couldn\'t confirm Pro on this device. Open Pro, tap Restore '
            'Purchases, then try again.',
        true,
      ),
      RemotePairingFailure.proRequired => (
        'Remote access is part of Pro.',
        true,
      ),
      RemotePairingFailure.verifyUnavailable => (
        'Couldn\'t check Pro right now. Try again in a moment.',
        false,
      ),
      RemotePairingFailure.rateLimited => (
        'Too many attempts. Try again in a few minutes.',
        false,
      ),
      RemotePairingFailure.network => (
        'Couldn\'t reach the OBS Blade relay. Check your internet connection.',
        false,
      ),
      RemotePairingFailure.noBridge => (
        'OBS Blade Remote didn\'t answer. Make sure it\'s installed on the PC '
            'running OBS and turned on, then try again.',
        false,
      ),
      RemotePairingFailure.noConfirmation => (
        'OBS Blade Remote on the PC didn\'t confirm. Update it to the latest '
            'version, then try again.',
        false,
      ),
    };

class _Failed extends StatelessWidget {
  final RemotePairingFailure failure;
  final VoidCallback onRetry;
  final VoidCallback onGetPro;

  const _Failed({
    required this.failure,
    required this.onRetry,
    required this.onGetPro,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final (String text, bool pro) = remotePairingFailureCopy(this.failure);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Not set up', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(text, style: _secondary(context)),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: pro
              ? BaseButton(text: 'Open Pro', onPressed: this.onGetPro)
              : BaseButton(text: 'Try Again', onPressed: this.onRetry),
        ),
      ],
    );
  }
}

/// One line on the PC's state from the relay's view.
String remoteBridgeStatusLine(RemoteBridgeInfo info, {DateTime? now}) {
  if (info.updateRequired) return 'Update OBS Blade Remote on this PC';
  if (!info.online) {
    final seen = info.lastSeen;
    if (info.obsState == 'closed' && info.kind == 'plugin') {
      return seen == null
          ? 'OBS was closed'
          : 'OBS was closed ${relativeTimeAgo(seen, now: now)}';
    }
    return seen == null
        ? 'Offline'
        : 'Offline - last seen ${relativeTimeAgo(seen, now: now)}';
  }
  // The dot next to the name already says Online
  return switch (info.obsState) {
    'running' => 'OBS running',
    'ws_off' => 'Turn on the WebSocket server in OBS',
    'auth_failed' => 'OBS refused OBS Blade Remote\'s password',
    'closed' || 'crashed' => 'OBS isn\'t running',
    _ => 'Waiting for OBS',
  };
}

class _Paired extends StatelessWidget {
  final Connection connection;
  final RemoteBridgeInfo? info;
  final bool loading;
  final bool unreachable;
  final bool viaRemote;
  final Future<void> Function(String deviceId) onRemoveDevice;
  final void Function(RemoteDevice device) onRenameDevice;
  final VoidCallback onTurnOff;

  const _Paired({
    required this.connection,
    required this.info,
    required this.loading,
    required this.unreachable,
    required this.viaRemote,
    required this.onRemoveDevice,
    required this.onRenameDevice,
    required this.onTurnOff,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppStatusColors status = theme.extension<AppStatusColors>()!;
    final AppTextColors textColors = theme.extension<AppTextColors>()!;
    final RemoteBridgeInfo? info = this.info;
    final String name = info?.name.isNotEmpty == true
        ? info!.name
        : (this.connection.relayBridgeName ?? 'Your PC');
    final String kind =
        (info?.kind ?? this.connection.relayBridgeKind) == 'standalone'
        ? 'OBS Blade Remote app'
        : 'OBS plugin';
    final bool online = info?.online ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(name, style: theme.textTheme.titleMedium)),
            StatusDot(
              size: 8.0,
              pulsing: false,
              color: info == null
                  ? textColors.textOrnament
                  : online
                  ? status.reachable
                  : status.unreachable,
              text: info == null
                  ? 'Checking'
                  : online
                  ? 'Online'
                  : 'Offline',
              style: theme.textTheme.titleSmall,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          info != null
              ? '$kind · ${remoteBridgeStatusLine(info)}'
              : this.unreachable
              ? '$kind · couldn\'t reach the OBS Blade relay'
              : '$kind · checking…',
          style: _secondary(context),
        ),
        if (this.viaRemote) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Connected through the relay right now',
            style: _secondary(context),
          ),
        ],
        if (info != null && info.devices.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('Paired devices', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          for (final device in info.devices)
            SizedBox(
              /// One row height for every device, with or without the
              /// Remove button's 44 pt hit area
              height: kBaseIconButtonMinHitArea,
              child: Row(
                children: [
                  Icon(
                    device.platform == 'android'
                        ? Icons.phone_android
                        : CupertinoIcons.device_phone_portrait,
                    size: 18.0,
                    color: textColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      device.isThisDevice
                          ? '${device.name} (this device)'
                          : device.name,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),

                  /// This device: renamed here (turned off below); the
                  /// others: removed
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(
                      kBaseIconButtonMinHitArea,
                      kBaseIconButtonMinHitArea,
                    ),
                    onPressed: device.isThisDevice
                        ? () => this.onRenameDevice(device)
                        : () => this.onRemoveDevice(device.id),
                    child: Text(
                      device.isThisDevice ? 'Rename' : 'Remove',
                      style: theme.textTheme.bodyMedium!.copyWith(
                        color: device.isThisDevice
                            ? textColors.highlightText
                            : CupertinoColors.destructiveRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: BaseButton(
            text: 'Turn Off on This Device',
            isDestructive: true,
            onPressed: this.onTurnOff,
          ),
        ),
      ],
    );
  }
}
