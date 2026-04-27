import 'package:adb_utils/adb_utils.dart' as adb_utils;
import 'package:flutter/material.dart';

IconData deviceStatusIcon(adb_utils.DeviceState state) {
  return switch (state) {
    adb_utils.DeviceState.device => Icons.phone_android,
    adb_utils.DeviceState.unauthorized => Icons.lock,
    adb_utils.DeviceState.offline => Icons.signal_wifi_off,
    _ => Icons.device_unknown,
  };
}

Color deviceStatusColor(adb_utils.DeviceState state) {
  return switch (state) {
    adb_utils.DeviceState.device => Colors.green,
    adb_utils.DeviceState.unauthorized => Colors.orange,
    adb_utils.DeviceState.offline => Colors.red,
    _ => Colors.grey,
  };
}
