import 'dart:io';

import 'package:nexus_cts/models/adb_device.dart';

class AdbService {
  Future<List<AdbDevice>> fetchDevices() async {
    final result = await Process.run('adb', ['devices', '-l']);
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
      if (parts.length < 2) continue;

      final serial = parts[0];
      final status = parts[1];

      String? usb, product, model, device, transportId;
      for (final part in parts.skip(2)) {
        final kv = part.split(':');
        if (kv.length == 2) {
          switch (kv[0]) {
            case 'usb':
              usb = kv[1];
            case 'product':
              product = kv[1];
            case 'model':
              model = kv[1];
            case 'device':
              device = kv[1];
            case 'transport_id':
              transportId = kv[1];
          }
        }
      }

      devices.add(
        AdbDevice(
          serial: serial,
          status: status,
          usb: usb,
          product: product,
          model: model,
          device: device,
          transportId: transportId,
        ),
      );
    }
    return devices;
  }
}
