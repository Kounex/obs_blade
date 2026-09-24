import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/models/enums/chat_type.dart';
import 'package:obs_blade/types/classes/combined/combined_combo.dart';
import 'package:obs_blade/types/classes/twitch/twitch_channel_ref.dart';

void main() {
  final twitch = TwitchChannelRef(
    id: '42',
    login: 'xqcow',
    displayName: 'xQcOW',
    addedAt: DateTime.utc(2026, 9, 25),
  );

  test('round-trips through JSON', () {
    final combo = CombinedCombo(
      id: 'c1',
      name: 'xQc everywhere',
      twitch: twitch,
      youTube: const CombinedYouTubeSource(label: 'xQc', value: '@xqcow'),
      kickSlug: 'xqc',
    );

    final back = parseCombinedCombos([combo.toJson()]).single;

    expect(back.id, 'c1');
    expect(back.name, 'xQc everywhere');
    expect(back.twitch, twitch);
    expect(back.twitch!.login, 'xqcow');
    expect(back.youTube, combo.youTube);
    expect(back.kickSlug, 'xqc');
    expect(back.platforms, [ChatType.Twitch, ChatType.YouTube, ChatType.Kick]);
    expect(back.primary, isNull);
    expect(
      parseCombinedCombos([
        {'id': 'p', 'kick': 'xqc', 'primary': 'Kick'},
      ]).single.primary,
      ChatType.Kick,
    );
  });

  test('display name falls back to ONE channel name - the first picked', () {
    expect(
      CombinedCombo(id: 'c', twitch: twitch, kickSlug: 'xqc').displayName,
      'xQcOW',
    );
    expect(
      CombinedCombo(
        id: 'c',
        twitch: twitch,
        kickSlug: 'xqc',
        primary: ChatType.Kick,
      ).displayName,
      'xqc',
    );
    expect(
      const CombinedCombo(id: 'c', name: '  ', kickSlug: 'xqc').displayName,
      'xqc',
    );
  });

  test('malformed and empty entries are skipped, the rest survive', () {
    final combos = parseCombinedCombos([
      {'id': 'ok', 'kick': 'aaa'},
      {'kick': 'no-id'},
      'garbage',
      {'id': 'empty'},
    ]);

    expect(combos.map((c) => c.id), ['ok']);
    expect(parseCombinedCombos(null), isEmpty);
  });
}
