import 'dart:io';

import 'package:nexus_cts/models/adb_device.dart';

class AdbService {
  Future<List<AdbDevice>> fetchDevices() async {
    final result = await Process.run('adb', ['devices']);
    if (result.exitCode != 0) {
      throw Exception('adb retornou código ${result.exitCode}');
    }

    final lines = (result.stdout as String)
        .split('\n')
        .skip(1)
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty);

    final devices = <AdbDevice>[];
    for (final line in lines) {
      final parts = line.split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        devices.add(AdbDevice(serial: parts[0], status: parts[1]));
      }
    }
    return devices;
  }
}
