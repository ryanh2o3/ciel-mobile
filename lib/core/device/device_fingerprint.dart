import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

/// Stable-ish device string for `POST /account/device/register`.
Future<String> buildDeviceFingerprint() async {
  final plugin = DeviceInfoPlugin();
  if (Platform.isIOS) {
    final ios = await plugin.iosInfo;
    return 'flutter-ios-${ios.identifierForVendor ?? 'unknown'}';
  }
  if (Platform.isAndroid) {
    final android = await plugin.androidInfo;
    return 'flutter-android-${android.id}';
  }
  return 'flutter-${Platform.operatingSystem}';
}
