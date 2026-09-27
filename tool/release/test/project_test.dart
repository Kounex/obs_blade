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
}
