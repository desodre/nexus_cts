import 'package:flutter/material.dart';

IconData deviceStatusIcon(String status) {
  return switch (status) {
    'device' => Icons.phone_android,
    'unauthorized' => Icons.lock,
    'offline' => Icons.signal_wifi_off,
    _ => Icons.device_unknown,
  };
}

Color deviceStatusColor(String status) {
  return switch (status) {
    'device' => Colors.green,
    'unauthorized' => Colors.orange,
    'offline' => Colors.red,
    _ => Colors.grey,
  };
}
