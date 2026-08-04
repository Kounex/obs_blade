import 'package:flutter/material.dart';
import 'package:obs_blade/shared/general/base/divider.dart';
import 'package:obs_blade/views/home/widgets/saved_connections/reachable_builder.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../models/connection.dart';
import '../../../../shared/design/design.dart';
import '../../../../shared/general/hive_builder.dart';
import '../../../../types/enums/hive_keys.dart';
import 'connection_box.dart';
import 'placeholder_connection.dart';

class SavedConnections extends StatelessWidget {
  static const double _cardHeight = 172.0;
  static const double _cardWidth = 268.0;

  const SavedConnections({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          /// Aligns with the card content edge above (16 card margin +
          /// 24 title inset = 40)
          padding: const EdgeInsets.only(
            top: AppSpacing.md,
            left: AppSpacing.xl + AppSpacing.lg,
          ),

          /// Section header: caption scale, uppercase, theme-aware grey
          child: Text(
            'Saved Connections'.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),

        /// Inset to the caption edge instead of full-bleed (iOS grouped
        /// separator convention)
        const Padding(
          padding: EdgeInsets.only(left: AppSpacing.xl + AppSpacing.lg),
          child: BaseDivider(),
        ),
        Flexible(
          fit: FlexFit.loose,
          child: Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.lg,
            ),
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
                        MediaQuery.sizeOf(context).width < _cardWidth * 2.5;

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
                        itemBuilder: (context, index) => _animatedConnectionBox(
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
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    this._controller = PageController(viewportFraction: 0.68);
  }

  @override
  void dispose() {
    this._controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = this.widget.connections.length;
    final muted = Theme.of(context).textTheme.bodySmall?.color;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: this.widget.height + AppSpacing.sm,
          child: PageView.builder(
            controller: this._controller,
            itemCount: count,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: this._controller,
                builder: (context, child) {
                  double scale = 1.0;
                  if (this._controller.position.haveDimensions) {
                    final page = this._controller.page ??
                        this._controller.initialPage.toDouble();
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
                    width: this.widget.width,
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
              controller: this._controller,
              count: count,
              effect: ExpandingDotsEffect(
                dotHeight: 6.0,
                dotWidth: 6.0,
                expansionFactor: 3.0,
                spacing: 6.0,
                activeDotColor: Theme.of(context).colorScheme.secondary,
                dotColor: (muted ?? Colors.grey).withValues(alpha: 0.35),
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
}) =>
    StaggeredEntrance(
      index: index,
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
