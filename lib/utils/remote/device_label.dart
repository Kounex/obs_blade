import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

import '../general_helper.dart';

/// What pairings were named before the model name (2026-11-09), and the
/// fallback when the model is unknown: a pairing still named one of these
/// is renamed to the model once the sheet sees it
const Set<String> kGenericDeviceNames = {
  'iPhone',
  'iPad',
  'Android phone',
  'Android tablet',
};

/// The relay keeps 64 characters of a name
const int kDeviceNameMaxLength = 64;

/// The name this device shows up under on the PC (the panel's paired
/// devices): the model on iOS ("iPhone 17 Pro" - the user's own device
/// name needs an Apple entitlement since iOS 16), the device name from
/// the Android settings (the model unless the user changed it). Null when
/// neither is known.
String? deviceLabelFrom({
  String? iosModelName,
  String? androidDeviceName,
  String? androidManufacturer,
  String? androidModel,
}) {
  String? label;
  if (iosModelName != null) {
    final String model = iosModelName.trim();

    /// device_info_plus answers this for identifiers newer than its table
    if (model.isNotEmpty && model != 'Unknown device') label = model;
  } else {
    final String name = (androidDeviceName ?? '').trim();
    final String model = (androidModel ?? '').trim();
    final String maker = (androidManufacturer ?? '').trim();
    if (name.isNotEmpty) {
      label = name;
    } else if (model.isNotEmpty) {
      label =
          maker.isEmpty || model.toLowerCase().startsWith(maker.toLowerCase())
          ? model
          : '${maker[0].toUpperCase()}${maker.substring(1)} $model';
    }
  }
  if (label == null) return null;
  return label.length > kDeviceNameMaxLength
      ? label.substring(0, kDeviceNameMaxLength)
      : label;
}

/// [deviceLabelFrom] for this device; null when unknown or not a phone
Future<String?> currentDeviceLabel() async {
  try {
    final DeviceInfoPlugin plugin = DeviceInfoPlugin();
    if (Platform.isIOS) {
      return deviceLabelFrom(iosModelName: (await plugin.iosInfo).modelName);
    }
    if (Platform.isAndroid) {
      final AndroidDeviceInfo info = await plugin.androidInfo;
      return deviceLabelFrom(
        androidDeviceName: info.name,
        androidManufacturer: info.manufacturer,
        androidModel: info.model,
      );
    }
  } catch (e) {
    GeneralHelper.logFailure('Remote access: reading the device model', e);
  }
  return null;
}
