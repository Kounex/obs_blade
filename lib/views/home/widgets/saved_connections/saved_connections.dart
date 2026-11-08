import 'dart:math';

import 'package:flutter/material.dart';
import 'package:obs_blade/views/home/widgets/saved_connections/reachable_builder.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../models/connection.dart';
import '../../../../shared/design/design.dart';
import '../../../../shared/general/base/constrained_box.dart';
import '../../../../shared/general/hive_builder.dart';
import '../../../../types/enums/hive_keys.dart';
import '../../../../utils/styling_helper.dart';
import 'connection_box.dart';
import 'placeholder_connection.dart';

class SavedConnections extends StatelessWidget {
  /// User directive 2026-11-08 (was 172 x 268): room for the remote access
  /// line without squeezing the gaps
  static const double _cardHeight = 192.0;
  static const double _cardWidth = 320.0;

  const SavedConnections({super.key});

  @override
  Widget build(BuildContext context) {
    /// Same 720 content column the ConnectBox card centers itself in -
    /// aligns the section (header + cards) on large screens instead of
    /// hugging the left edge
    return Center(
      child: BaseConstrainedBox(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              /// Aligns with the card content edge above (16 card margin +
              /// 24 title inset = 40, relative to the capped column). The
              /// bottom spacing carries the separation now - the divider
              /// underline under section headers is retired (hierarchy via
              /// type/spacing, v12 direction)
              padding: const EdgeInsets.only(
                top: AppSpacing.md,
                bottom: AppSpacing.sm,
                left: AppSpacing.xl + AppSpacing.lg,
              ),

              /// Section header: caption scale, uppercase, textTertiary
              child: Text(
                'Saved Connections'.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: Theme.of(
                    context,
                  ).extension<AppTextColors>()!.textTertiary,
                ),
              ),
            ),

            Flexible(
              fit: FlexFit.loose,
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                child: HiveBuilder<Connection>(
                  hiveKey: HiveKeys.SavedConnections,
                  builder: (context, savedConnectionsBox, child) {
                    if (savedConnectionsBox.values.isEmpty) {
                      return const PlaceholderConnection(
                        height: _cardHeight,
                        width: _cardWidth,
                      );
                    }

                    return ReachableBuilder(
                      savedConnectionsBuilder: (savedConnections) {
                        final useCarousel =
                            MediaQuery.sizeOf(context).width <
                            StylingHelper.max_width_mobile;

                        if (useCarousel) {
                          return _ConnectionCarousel(
                            connections: savedConnections,
                            height: _cardHeight,
                            width: _cardWidth,
                          );
                        }

                        return SizedBox(
                          height: _cardHeight,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                            ),
                            itemCount: savedConnections.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: AppSpacing.lg),
                            itemBuilder: (context, index) =>
                                _animatedConnectionBox(
                                  savedConnections[index],
                                  index,
                                  width: _cardWidth,
                                  height: _cardHeight,
                                ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionCarousel extends StatefulWidget {
  final List<Connection> connections;
  final double height;
  final double width;

  const _ConnectionCarousel({
    required this.connections,
    required this.height,
    required this.width,
  });

  @override
  State<_ConnectionCarousel> createState() => _ConnectionCarouselState();
}

class _ConnectionCarouselState extends State<_ConnectionCarousel> {
  /// Room left of and right of the current card: its neighbors peek in
  static const double _peek = 28.0;

  PageController? _pageController;
  double? _fraction;

  /// The page is the card plus its padding; the card keeps its width
  /// unless the screen is too narrow for it and a peek on both sides
  /// (320 pt phones: 264 pt). Rebuilt on a width change (rotation).
  PageController _controllerFor(double fraction) {
    final PageController? previous = _pageController;
    if (previous != null && (_fraction! - fraction).abs() < 0.001) {
      return previous;
    }
    final int page = previous != null && previous.hasClients
        ? (previous.page ?? 0).round()
        : 0;
    _fraction = fraction;
    _pageController = PageController(
      viewportFraction: fraction,
      initialPage: page,
    );
    if (previous != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
    }
    return _pageController!;
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = this.widget.connections.length;
    final double screen = MediaQuery.sizeOf(context).width;
    final double cardWidth = min(this.widget.width, screen - 2 * _peek);
    final PageController controller = _controllerFor(
      min(1.0, (cardWidth + 2 * AppSpacing.sm) / screen),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: this.widget.height + AppSpacing.sm,
          child: PageView.builder(
            controller: controller,
            itemCount: count,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: controller,
                builder: (context, child) {
                  double scale = 1.0;
                  if (controller.position.haveDimensions) {
                    final page =
                        controller.page ?? controller.initialPage.toDouble();
                    final distance = (page - index).abs();
                    scale = (1.0 - (distance * 0.06)).clamp(0.94, 1.0);
                  }
                  return Center(
                    child: Transform.scale(
                      scale: scale,
                      alignment: Alignment.center,
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: _animatedConnectionBox(
                    this.widget.connections[index],
                    index,
                    width: cardWidth,
                    height: this.widget.height,
                  ),
                ),
              );
            },
          ),
        ),
        if (count > 1)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: SmoothPageIndicator(
              controller: controller,
              count: count,
              effect: ExpandingDotsEffect(
                dotHeight: 6.0,
                dotWidth: 6.0,
                expansionFactor: 3.0,
                spacing: 6.0,

                /// Active page dot = selection -> accent (grammar rule 2;
                /// the accent group lives on the buttonTheme colorScheme),
                /// inactive = ornament level
                activeDotColor: Theme.of(
                  context,
                ).buttonTheme.colorScheme!.secondary,
                dotColor: Theme.of(
                  context,
                ).extension<AppTextColors>()!.textOrnament,
              ),
            ),
          ),
      ],
    );
  }
}

/// One-shot staggered entrance + crossfade when the reachable-first
/// re-sort swaps which connection sits at a slot. Keyed by Hive identity
/// so pure reachability flag updates (dot color/text) don't animate and
/// MobX/setState rebuilds don't replay the entrance.
Widget _animatedConnectionBox(
  Connection connection,
  int index, {
  required double width,
  required double height,
}) => StaggeredEntrance(
  index: index,
  scaleFrom: 0.985,
  child: AnimatedSwitcher(
    duration: AppMotion.medium,
    child: ConnectionBox(
      key: ValueKey<dynamic>(connection.key),
      connection: connection,
      width: width,
      height: height,
    ),
  ),
);
