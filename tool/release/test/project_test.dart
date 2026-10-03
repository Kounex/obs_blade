import 'package:release/src/project.dart';
import 'package:test/test.dart';

void main() {
  group('nextBuild (YYYYMMDDNN)', () {
    final day = DateTime(2026, 9, 28);

    test('first build of a new day', () {
      expect(Project.nextBuild(2026092501, day), 2026092801);
    });

    test('another build the same day counts up', () {
      expect(Project.nextBuild(2026092801, day), 2026092802);
      expect(Project.nextBuild(2026092809, day), 2026092810);
    });

    test('never goes backwards', () {
      expect(Project.nextBuild(2026093001, day), 2026093002);
    });
  });

  group('forbiddenDefines', () {
    test('client id alone is fine', () {
      expect(
        Project.forbiddenDefines('{"KICK_OAUTH_CLIENT_ID": "abc"}'),
        isEmpty,
      );
    });

    test('a non-empty secret is refused', () {
      expect(
        Project.forbiddenDefines(
          '{"KICK_OAUTH_CLIENT_ID": "abc", "KICK_OAUTH_CLIENT_SECRET": "s"}',
        ),
        ['KICK_OAUTH_CLIENT_SECRET'],
      );
    });

    test('an empty secret is fine', () {
      expect(
        Project.forbiddenDefines('{"KICK_OAUTH_CLIENT_SECRET": " "}'),
        isEmpty,
      );
    });
  });
}
