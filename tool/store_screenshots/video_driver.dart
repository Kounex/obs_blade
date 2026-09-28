// Host side of `flutter drive --profile` for integration_test/
// store_video_test.dart on Android (record.sh): the emulator runs an AOT
// profile build there - the debug build's JIT holds its recordings to
// ~20-25 fps. The iOS simulator only runs debug builds (`flutter test`).
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
