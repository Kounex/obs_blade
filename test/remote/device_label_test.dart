import 'package:flutter_test/flutter_test.dart';
import 'package:obs_blade/utils/remote/device_label.dart';

void main() {
  test('iOS: the model; unknown models fall back (null)', () {
    expect(deviceLabelFrom(iosModelName: 'iPhone 17 Pro'), 'iPhone 17 Pro');
    expect(deviceLabelFrom(iosModelName: 'Unknown device'), isNull);
    expect(deviceLabelFrom(iosModelName: ' '), isNull);
  });

  test('Android: the settings name, else maker + model', () {
    expect(
      deviceLabelFrom(
        androidDeviceName: "Rene's Pixel",
        androidManufacturer: 'Google',
        androidModel: 'Pixel 9',
      ),
      "Rene's Pixel",
    );
    expect(
      deviceLabelFrom(
        androidDeviceName: '',
        androidManufacturer: 'samsung',
        androidModel: 'SM-S918B',
      ),
      'Samsung SM-S918B',
    );
    expect(
      deviceLabelFrom(
        androidManufacturer: 'OnePlus',
        androidModel: 'OnePlus 12',
      ),
      'OnePlus 12',
      reason: 'no doubled maker',
    );
    expect(deviceLabelFrom(androidManufacturer: 'Google'), isNull);
  });

  test('capped at the 64 characters the relay keeps', () {
    expect(deviceLabelFrom(androidDeviceName: 'x' * 90), hasLength(64));
  });
}
