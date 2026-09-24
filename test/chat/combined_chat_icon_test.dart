import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/combined_chat_icon.dart';

void main() {
  testWidgets('Combined gets the painted multi-color mark, platforms keep '
      'their tinted glyph', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                chatTypeIcon(
                  context,
                  ChatType.Combined.icon,
                  combined: true,
                  size: 30.0,
                ),
                chatTypeIcon(
                  context,
                  ChatType.Kick.icon,
                  combined: false,
                  color: Colors.green,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byType(CombinedChatIcon), findsOneWidget);
    expect(tester.getSize(find.byType(CombinedChatIcon)), const Size(30, 30));
    expect(find.bySemanticsLabel('Combined chat'), findsOneWidget);
    expect(find.byIcon(ChatType.Kick.icon), findsOneWidget);
    expect(find.byIcon(ChatType.Combined.icon), findsNothing);
  });
}
