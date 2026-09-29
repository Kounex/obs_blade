import 'package:release/src/commands.dart';
import 'package:test/test.dart';

void main() {
  test('poster time code is HH:MM:SS:FF at 30 fps', () {
    expect(Release.timeCode(5), '00:00:05:00');
    expect(Release.timeCode(12.5), '00:00:12:15');
    expect(Release.timeCode(61), '00:01:01:00');
  });
}
