import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../shared/design/design.dart';
import '../../../../shared/general/tag_box.dart';
import '../../../../utils/styling_helper.dart';

/// How long the 'Copied' pill replaces the version text after a tap
const Duration _kCopiedDwell = Duration(seconds: 2);

/// Tap-to-copy version stamp (settings footer + about header): copies
/// 'version (buildNumber)' to the clipboard and swaps the text for a
/// transient status pill as confirmation.
class VersionStamp extends StatefulWidget {
  final TextStyle? style;

  /// Also render the build number next to the version (the settings
  /// footer keeps the short form)
  final bool showBuildNumber;

  const VersionStamp({super.key, this.style, this.showBuildNumber = false});

  @override
  State<VersionStamp> createState() => _VersionStampState();
}

class _VersionStampState extends State<VersionStamp> {
  bool _copied = false;
  Timer? _dwellTimer;

  @override
  void dispose() {
    _dwellTimer?.cancel();
    super.dispose();
  }

  void _copy(PackageInfo info) {
    Clipboard.setData(
      ClipboardData(text: '${info.version} (${info.buildNumber})'),
    );
    setState(() => _copied = true);
    _dwellTimer?.cancel();
    _dwellTimer = Timer(_kCopiedDwell, () {
      if (this.mounted) {
        setState(() => _copied = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppTextColors textColors = Theme.of(
      context,
    ).extension<AppTextColors>()!;

    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        return Pressable(
          springy: false,
          onTap: snapshot.hasData ? () => _copy(snapshot.data!) : null,
          child: AnimatedSwitcher(
            duration: AppMotion.medium,
            switchInCurve: AppMotion.standard,
            switchOutCurve: AppMotion.exit,
            child: _copied
                ? TagBox(
                    key: const ValueKey('copied'),
                    expand: false,
                    color: StylingHelper.lightenDarkenColor(
                      Theme.of(context).cardColor,
                      8,
                    ),
                    icon: Icon(
                      CupertinoIcons.checkmark,
                      size: 12.0,
                      color: textColors.textSecondary,
                    ),
                    label: 'Copied',
                    labelStyle: Theme.of(context).textTheme.labelSmall!
                        .copyWith(color: textColors.textSecondary),
                  )
                : SizedBox(
                    key: const ValueKey('version'),
                    height: 24.0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Version ', style: this.widget.style),
                        if (snapshot.hasData)
                          Text(
                            this.widget.showBuildNumber
                                ? '${snapshot.data!.version} (${snapshot.data!.buildNumber})'
                                : snapshot.data!.version,
                            style: this.widget.style,
                          ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }
}
