import 'package:flutter/material.dart';

import '../../../../models/enums/log_level.dart';
import '../../../../shared/general/base/card.dart';
import '../../../../shared/general/custom_expansion_tile.dart';
import '../../../../shared/general/enumeration_block/enumeration_block.dart';
import '../../../../shared/general/enumeration_block/enumeration_entry.dart';
import '../../../../shared/general/themed/rich_text.dart';

class LogExplanation extends StatelessWidget {
  const LogExplanation({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      bottomPadding: 12.0,
      child: CustomExpansionTile(
        headerText: 'Information about logs',
        headerPadding: const EdgeInsets.all(0.0),
        expandedBody: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12.0),
            const Text(
                'Logs listed here have been created programmatically by me and are only available locally. I\'m not sending them to any servers or alike. You can view them here and decide to share them (for example with me) if you encounter any problems and would like to give me more information to work on or even want to try to figure out the problem on your own!'),
            const SizedBox(height: 12.0),
            const Text(
                'You can delete log entries selectively here or all together in "Data Management" in the settings tab.'),
            const SizedBox(height: 12.0),
            const Text('Used log types:'),
            const SizedBox(height: 4.0),
            EnumerationBlock(
              customEntries: [
                EnumerationEntry(
                  customEntry: ThemedRichText(
                    textSpans: [
                      TextSpan(
                        text: 'Info',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: LogLevel.Info.color,
                          // decoration: TextDecoration.underline,
                        ),
                      ),
                      const TextSpan(
                        text:
                            ': triggered by used packages or manually by myself to provide helpful informations',
                      ),
                    ],
                  ),
                ),
                EnumerationEntry(
                  customEntry: ThemedRichText(
                    textSpans: [
                      TextSpan(
                        text: 'Warning',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: LogLevel.Warning.color,
                          // decoration: TextDecoration.underline,
                        ),
                      ),
                      const TextSpan(
                        text:
                            ': triggered manually by me to log important informations / events',
                      ),
                    ],
                  ),
                ),
                EnumerationEntry(
                  customEntry: ThemedRichText(
                    textSpans: [
                      TextSpan(
                        text: 'Error',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: LogLevel.Error.color,
                          // decoration: TextDecoration.underline,
                        ),
                      ),
                      const TextSpan(
                        text:
                            ': triggered by different kind of exceptions and (mostly) unintended events',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            const Text(
                'Logs are grouped by days and can be filtered to find the relevant ones easier. Feel free to suggest improvements!')
          ],
        ),
      ),
    );
  }
}
