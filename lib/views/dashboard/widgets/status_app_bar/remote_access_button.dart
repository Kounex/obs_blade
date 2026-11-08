import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';

import '../../../../models/connection.dart';
import '../../../../shared/design/design.dart';
import '../../../../shared/general/base/icon_button.dart';
import '../../../../shared/general/hive_builder.dart';
import '../../../../stores/pro_store.dart';
import '../../../../stores/shared/network.dart';
import '../../../../types/enums/hive_keys.dart';
import '../../../../utils/build_flavor.dart';
import 'general_actions.dart';

/// Remote access (Pro) one tap away in the dashboard bar, next to the
/// actions menu (user directive 2026-11-08: the menu entry alone was too
/// hidden for what it does). The globe tells the state of the active
/// connection:
/// - muted: not set up (free users get the Pro sheet from it)
/// - regular: set up for this PC
/// - highlight blue (as the Close pill): this session runs through the
///   relay - not the accent, which is red in some themes (live/rec)
///
/// Hidden in the FOSS build, like every Pro entry point.
class RemoteAccessButton extends StatelessWidget {
  const RemoteAccessButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (kFoss) return const SizedBox.shrink();
    final AppTextColors textColors = Theme.of(
      context,
    ).extension<AppTextColors>()!;

    /// The pairing is stored on the saved entry - follow the box so the
    /// globe changes the moment a pairing lands or is turned off
    return HiveBuilder<Connection>(
      hiveKey: HiveKeys.SavedConnections,
      builder: (context, _, _) => Observer(
        builder: (context) {
          final session = GetIt.instance<NetworkStore>().activeSession;
          if (session == null) return const SizedBox.shrink();
          final bool isPro =
              GetIt.instance.isRegistered<ProStore>() &&
              GetIt.instance<ProStore>().isPro;
          final bool viaRemote = session.viaRemote;
          final bool setUp = isPro && session.connection.hasRemote;

          final Color? color = viaRemote
              ? textColors.highlightText
              : setUp
              ? null
              : textColors.textTertiary;
          final String label = viaRemote
              ? 'Remote access, connected through the relay'
              : setUp
              ? 'Remote access, set up'
              : 'Remote access, not set up';

          return Semantics(
            button: true,
            label: label,
            excludeSemantics: true,
            child: Pressable(
              springy: false,
              onTap: () => GeneralActions.openRemoteAccess(context),
              child: SizedBox(
                width: kBaseIconButtonMinHitArea,
                height: kBaseIconButtonMinHitArea,
                child: Center(
                  child: Icon(CupertinoIcons.globe, size: 22.0, color: color),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
