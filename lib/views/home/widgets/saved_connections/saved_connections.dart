import 'package:flutter/material.dart';
import 'package:obs_blade/shared/general/base/divider.dart';
import 'package:obs_blade/views/home/widgets/saved_connections/reachable_builder.dart';

import '../../../../models/connection.dart';
import '../../../../shared/design/design.dart';
import '../../../../shared/general/hive_builder.dart';
import '../../../../types/enums/hive_keys.dart';
import 'connection_box.dart';
import 'placeholder_connection.dart';

class SavedConnections extends StatelessWidget {
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
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
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
                double height = 180.0;
                double width = 250.0;

                if (savedConnectionsBox.values.isEmpty) {
                  return PlaceholderConnection(
                    height: height,
                    width: width,
                  );
                } else {
                  return ReachableBuilder(
                    savedConnectionsBuilder: ((savedConnections) =>
                        MediaQuery.sizeOf(context).width < width * 2.5
                            ? SizedBox(
                                height: height,
                                child: PageView.builder(
                                  controller:
                                      PageController(viewportFraction: 0.75),
                                  itemCount: savedConnectionsBox.values.length,
                                  itemBuilder: (context, index) => Padding(
                                    padding: const EdgeInsets.only(
                                        left: AppSpacing.lg,
                                        right: AppSpacing.lg),
                                    child: _animatedConnectionBox(
                                      savedConnections[index],
                                      index,
                                      width: width,
                                      height: height,
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Wrap(
                                  spacing: 32.0,
                                  runSpacing: 32.0,
                                  children: [
                                    for (final (index, savedConnection)
                                        in savedConnectionsBox.values.indexed)
                                      _animatedConnectionBox(
                                        savedConnection,
                                        index,
                                        width: width,
                                        height: height,
                                      ),
                                  ],
                                ),
                              )),
                  );
                  // return Observer(
                  //   builder: (context) => FutureBuilder<List<Connection>>(
                  //     future:
                  //         GetIt.instance<HomeStore>().autodiscoverConnections,
                  //     builder: (context, snapshot) {
                  //       List<Connection> savedConnections =
                  //           savedConnectionsBox.values.toList();

                  //       for (var connection in savedConnections) {
                  //         connection.reachable = snapshot.hasData &&
                  //             snapshot.data!.any((discoverConnection) =>
                  //                 discoverConnection.host == connection.host &&
                  //                 discoverConnection.port == connection.port);
                  //       }
                  //       savedConnections
                  //           .sort((c1, c2) => c1.reachable != c2.reachable
                  //               ? c1.reachable!
                  //                   ? 0
                  //                   : 1
                  //               : c1.name!.compareTo(c2.name!));

                  //       return MediaQuery.sizeOf(context).width < width * 2.5
                  //           ? SizedBox(
                  //               height: height,
                  //               child: PageView.builder(
                  //                 controller:
                  //                     PageController(viewportFraction: 0.75),
                  //                 itemCount: savedConnectionsBox.values.length,
                  //                 itemBuilder: (context, index) => Padding(
                  //                   padding: const EdgeInsets.only(
                  //                       left: 18.0, right: 18.0),
                  //                   child: ConnectionBox(
                  //                     connection: savedConnections[index],
                  //                     width: width,
                  //                     height: height,
                  //                   ),
                  //                 ),
                  //               ),
                  //             )
                  //           : Center(
                  //               child: Wrap(
                  //                 spacing: 32.0,
                  //                 runSpacing: 32.0,
                  //                 children: savedConnectionsBox.values
                  //                     .map(
                  //                       (savedConnection) => ConnectionBox(
                  //                         connection: savedConnection,
                  //                         width: width,
                  //                         height: height,
                  //                       ),
                  //                     )
                  //                     .toList(),
                  //               ),
                  //             );
                  //     },
                  //   ),
                  // );
                }
              },
            ),
          ),
        ),
      ],
    );
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
}
