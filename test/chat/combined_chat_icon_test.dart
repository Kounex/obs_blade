import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/views/dashboard/widgets/obs_widgets/stream_chat/combined_chat_icon.dart';

void main() {
  testWidgets('Combined gets the painted multi-color mark, platforms keep '
      'their tinted glyph, all normalised to Kick\'s ink size', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                chatTypeIcon(context, ChatType.Combined, size: 30.0),
                chatTypeIcon(context, ChatType.Kick, color: Colors.green),
                chatTypeIcon(context, ChatType.Owncast),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byType(CombinedChatIcon), findsOneWidget);

    /// Normalised to Kick's ink: every slot has the requested size, the
    /// glyph inside is scaled - Kick 1.0, Combined up a hair, Owncast
    /// (taller ink) down.
    /// The glyph's painted width vs. its slot = the applied scale.
    double scaleOf(Finder glyph) {
      final painted = tester.getRect(glyph).width;
      final slot = tester
          .getRect(
            find.ancestor(of: glyph, matching: find.byType(SizedBox)).last,
          )
          .width;
      return painted / slot;
    }

    expect(
      scaleOf(find.byType(CombinedChatIcon)),
      closeTo(0.78 / 0.771, 0.001),
    );
    expect(scaleOf(find.byIcon(ChatType.Kick.icon)), 1.0);
    expect(
      scaleOf(find.byIcon(ChatType.Owncast.icon)),
      closeTo(0.78 / 0.948, 0.001),
    );
    expect(tester.getSize(find.byType(CombinedChatIcon)), const Size(30, 30));
    expect(find.bySemanticsLabel('Combined chat'), findsOneWidget);
    expect(find.byIcon(ChatType.Kick.icon), findsOneWidget);
    expect(find.byIcon(ChatType.Combined.icon), findsNothing);
  });
}
