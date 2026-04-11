import 'dart:io';

import 'package:nexus_cts/models/adb_device.dart';
import 'package:nexus_cts/models/reboot_options.dart';

class AdbService {
  /// Executa `adb -s <serial> shell getprop` e retorna mapa de propriedades.
  Future<Map<String, String>> fetchDeviceProperties(String serial) async {
    final result = await Process.run('adb', ['-s', serial, 'shell', 'getprop']);
    if (result.exitCode != 0) {
      throw Exception('adb getprop falhou (code ${result.exitCode})');
    }

    final props = <String, String>{};
    final lines = (result.stdout as String).split('\n');
    final regex = RegExp(r'^\[(.+?)\]:\s*\[(.*)?\]$');
    for (final line in lines) {
      final match = regex.firstMatch(line.trim());
      if (match != null) {
        props[match.group(1)!] = match.group(2) ?? '';
      }
    }
    return props;
  }

  Future<void> adbRebootDevice(String serial, RebootOptions option) async {
    final result = await Process.run('adb', ['-s', serial, 'reboot', if (option != RebootOptions.normal) option.name]);
    if (result.exitCode != 0) {
      throw Exception('adb reboot falhou (code ${result.exitCode})');
    }
  }

  Future<void> fastbootRebootDevice(String serial, RebootOptions option) async {
    final result = await Process.run('fastboot', ['-s', serial, 'reboot', if (option != RebootOptions.normal) option.name]);
    if (result.exitCode != 0) {
      throw Exception('fastboot reboot falhou (code ${result.exitCode})');
    }
  }

  /// Executa `fastboot -s <serial> getvar all` e retorna mapa de variáveis.
  Future<Map<String, String>> fetchFastbootVars(String serial) async {
    final result = await Process.run('fastboot', [
      '-s',
      serial,
      'getvar',
      'all',
    ], environment: Platform.environment);
    // fastboot getvar all imprime em stderr
    final output = '${result.stdout}${result.stderr}';

    final vars = <String, String>{};
    for (final line in output.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith('(bootloader)')) {
        final content = trimmed.substring('(bootloader)'.length).trim();
        final idx = content.indexOf(':');
        if (idx > 0) {
          vars[content.substring(0, idx).trim()] = content
              .substring(idx + 1)
              .trim();
        }
      } else if (trimmed.contains(':')) {
        final idx = trimmed.indexOf(':');
        final key = trimmed.substring(0, idx).trim();
        final value = trimmed.substring(idx + 1).trim();
        if (key.isNotEmpty && !key.startsWith('Finished')) {
          vars[key] = value;
        }
      }
    }
    return vars;
  }

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
