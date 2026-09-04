import 'package:provisioning/src/commands.dart';
import 'package:test/test.dart';

void main() {
  group('argOrEnv', () {
    test('flag wins over env', () {
      expect(argOrEnv('flag', 'env'), 'flag');
    });

    test('env used when flag absent', () {
      expect(argOrEnv(null, 'env'), 'env');
    });

    test('env used when flag empty', () {
      expect(argOrEnv('', 'env'), 'env');
    });

    test('null when both absent', () {
      expect(argOrEnv(null, null), isNull);
    });

    test('null when both empty', () {
      expect(argOrEnv('', ''), isNull);
    });
  });
}
