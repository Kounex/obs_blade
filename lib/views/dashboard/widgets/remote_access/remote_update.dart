import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../models/connection.dart';
import '../../../../shared/dialogs/confirmation.dart';
import '../../../../stores/pro_store.dart';
import '../../../../stores/shared/remote_bridge_updates.dart';
import '../../../../types/enums/hive_keys.dart';
import '../../../../types/enums/settings_keys.dart';
import '../../../../utils/build_flavor.dart';
import '../../../../utils/general_helper.dart';
import '../../../../utils/modal_handler.dart';
import '../../../../utils/remote/remote_relay_client.dart';

/// Where the PC side is downloaded - a short address on purpose: it is read
/// in the app and typed on the PC. The page links the latest GitHub release
/// of Kounex/obs-blade-remote.
final Uri kRemoteDownloadUri = Uri.parse('https://obs-blade.kounex.com/remote');

String get kRemoteDownloadAddress =>
    '${kRemoteDownloadUri.host}${kRemoteDownloadUri.path}';

/// 0.4.2: a standalone whose process check missed OBS answered "OBS not
/// running" while OBS ran (relay log 2026-11-20..22)
const String kRemoteObsCheckFixed = '0.4.2';

/// Whether [version] is a release below [than] ("0.4.1" < "0.4.2"); false
/// for anything that doesn't read as x.y.z.
bool remoteVersionBelow(String version, String than) {
  List<int>? parts(String text) {
    final List<int?> numbers = text
        .trim()
        .split('.')
        .map(int.tryParse)
        .toList();
    if (numbers.length != 3 || numbers.contains(null)) return null;
    return numbers.cast<int>();
  }

  final List<int>? a = parts(version);
  final List<int>? b = parts(than);
  if (a == null || b == null) return false;
  for (int i = 0; i < 3; i++) {
    if (a[i] != b[i]) return a[i] < b[i];
  }
  return false;
}

String _capitalized(String text) =>
    text.isEmpty ? text : '${text[0].toUpperCase()}${text.substring(1)}';

/// The sheet card's title
String remoteUpdateTitle(RemoteBridgeUpdate update) =>
    update.required ? 'Update required' : 'Update available';

/// The sheet card's line, e.g. "OBS Blade Remote 0.4.3 is out - this PC
/// has 0.4.1."
String remoteUpdateLine(RemoteBridgeUpdate update) => update.required
    ? 'This PC has ${update.name} ${update.current}, too old for remote '
          'access${update.latest.isEmpty ? '' : ' - ${update.latest} is out'}.'
    : '${_capitalized(update.name)} ${update.latest} is out - this PC has '
          '${update.current}.';

/// The connect prompt's body. [reason] (why something just failed)
/// replaces the opening - it already names what the PC runs.
String remoteUpdateDialogBody(
  RemoteBridgeUpdate update,
  String pc, {
  String? reason,
}) {
  final String latest = update.latest.isEmpty ? '' : '${update.latest} is out.';
  final String what = reason != null
      ? '$reason $latest'
      : update.required
      ? '$pc runs ${update.name} ${update.current}, which remote access no '
            'longer works with. $latest'
      : '$pc runs ${update.name} ${update.current} - $latest';
  return '${what.trim()}\n\nInstall it on the PC from '
      '$kRemoteDownloadAddress, or share the link to open it there.';
}

/// Whether the connect prompt still has to tell about [update] for this
/// PC: once per release ([prompted]: bridge id -> what was told).
bool shouldPromptRemoteUpdate(
  RemoteBridgeUpdate update,
  String bridgeId,
  Map<dynamic, dynamic> prompted,
) => prompted[bridgeId] != update.promptKey;

/// The share sheet with the download page: the installers are for the PC,
/// so sending the link there (AirDrop, Messages, mail) beats opening it
/// on the phone
Future<void> shareRemoteDownloadLink(BuildContext context) async {
  final Size size = MediaQuery.sizeOf(context);
  try {
    await SharePlus.instance.share(
      ShareParams(
        uri: kRemoteDownloadUri,
        subject: 'OBS Blade Remote',
        // iPad: the popover needs an anchor
        sharePositionOrigin: Rect.fromLTWH(
          size.width / 2,
          size.height / 2,
          1,
          1,
        ),
      ),
    );
  } catch (e) {
    GeneralHelper.logFailure(
      'Remote access: sharing the download link failed',
      e,
    );
  }
}

/// "Update OBS Blade Remote" with Share Link / Later. [reason] leads when
/// the update is why something just failed. [context] shares the link.
Widget remoteUpdateDialog(
  BuildContext context,
  RemoteBridgeUpdate update, {
  required String pc,
  String? reason,
}) => ConfirmationDialog(
  title: update.required
      ? 'OBS Blade Remote Needs an Update'
      : 'Update OBS Blade Remote',
  body: remoteUpdateDialogBody(update, pc, reason: reason),
  noText: 'Later',
  okText: 'Share Link',
  onOk: (_) => Future.delayed(ModalHandler.transitionDelayDuration, () {
    if (context.mounted) shareRemoteDownloadLink(context);
  }),
);

void showRemoteUpdateDialog(
  BuildContext context,
  RemoteBridgeUpdate update, {
  required String pc,
  String? reason,
}) => ModalHandler.showBaseDialog(
  context: context,
  dialogWidget: remoteUpdateDialog(context, update, pc: pc, reason: reason),
);

/// Records [info] for the globe and the sheet (app-wide holder).
void recordRemoteBridgeInfo(RemoteBridgeInfo info) {
  if (GetIt.instance.isRegistered<RemoteBridgeUpdates>()) {
    GetIt.instance<RemoteBridgeUpdates>().record(info);
  }
}

/// After connecting to a paired PC: reads its bridge info (never holding
/// the connect up, silent on failure) and, once per release, tells about
/// a newer OBS Blade Remote. LAN or relay alike - on the LAN is where a
/// PC stuck on an old version still connects.
Future<void> promptRemoteBridgeUpdate(
  BuildContext context,
  Connection connection, {
  RemoteRelayClient? relay,
}) async {
  if (kFoss || !connection.hasRemote) return;
  if (!GetIt.instance.isRegistered<ProStore>() ||
      !GetIt.instance<ProStore>().isPro) {
    return;
  }
  final RemoteBridgeInfo info;
  try {
    info = await (relay ?? RemoteRelayClient()).bridgeInfo(
      connection.relayBridgeId!,
      connection.relayAppToken!,
    );
  } catch (_) {
    return;
  }
  recordRemoteBridgeInfo(info);
  final RemoteBridgeUpdate? update = RemoteBridgeUpdate.of(info);
  if (update == null || !context.mounted) return;

  final Box settings = Hive.box(HiveKeys.Settings.name);
  final Map<dynamic, dynamic> prompted = Map.of(
    settings.get(SettingsKeys.RemoteUpdatePrompted.name, defaultValue: const {})
        as Map,
  );
  if (!shouldPromptRemoteUpdate(update, info.id, prompted)) return;
  prompted[info.id] = update.promptKey;
  await settings.put(SettingsKeys.RemoteUpdatePrompted.name, prompted);
  if (!context.mounted) return;
  showRemoteUpdateDialog(
    context,
    update,
    pc: info.name.isNotEmpty
        ? info.name
        : (connection.relayBridgeName ?? 'your PC'),
  );
}
