import 'package:flutter/material.dart';

import '../../../../../shared/design/design.dart';
import 'audio_inputs/audio_inputs.dart';
import 'scene_items/scene_items.dart';

class SceneContentMobile extends StatelessWidget {
  /// When true, the Audio tab is listed (and shown) before Scene Items.
  final bool audioFirst;

  const SceneContentMobile({super.key, this.audioFirst = false});

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    final List<Widget> tabs = this.audioFirst
        ? const [Tab(child: Text('Audio')), Tab(child: Text('Scene Items'))]
        : const [Tab(child: Text('Scene Items')), Tab(child: Text('Audio'))];

    final List<Widget> views = this.audioFirst
        ? const [AudioInputs(), SceneItems()]
        : const [SceneItems(), AudioInputs()];

    return DefaultTabController(
      length: 2,

      /// Card fill behind the whole block (tab strip + content) so the
      /// fixed 400px content height reads as intentional container room
      /// instead of a void against the scaffold - the mobile counterpart
      /// of the tablet's titled BaseCards
      child: Container(
        color: theme.cardColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: Colors.transparent,
              child: TabBar(
                /// Active tab ink = accent, spent as text ([AppTextColors
                /// .accentText]) - token-delta rule 2 + §2.3
                labelColor: theme.extension<AppTextColors>()!.accentText,
                unselectedLabelColor: theme.textTheme.bodySmall!.color,
                labelStyle: theme.textTheme.titleSmall!.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: theme.textTheme.titleSmall,
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(
                    width: 3.0,

                    /// Painted ink spends the raw accent slot (selection,
                    /// token-delta rule 2) - the text derivative is for text
                    color: theme.buttonTheme.colorScheme!.secondary,
                  ),
                  insets: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                ),
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: Colors.transparent,
                tabs: tabs,
              ),
            ),

            /// Grown from 300 to 400 (the tablet card extent) so resting rows
            /// aren't clipped mid-glyph - taller content still scrolls inside
            /// via [NestedScrollManager]
            SizedBox(
              height: 400,
              child: TabBarView(
                physics: const NeverScrollableScrollPhysics(),
                children: views,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
