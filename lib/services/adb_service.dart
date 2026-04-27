import 'dart:io';
import 'package:adb_utils/adb_utils.dart' as adb_utils;
import 'package:nexus_cts/models/reboot_options.dart';

class AdbService {
  final adb_utils.AdbClient _client = adb_utils.AdbClient();

  /// Executa `adb -s <serial> shell getprop` e retorna mapa de propriedades.
  Future<Map<String, String>> fetchDeviceProperties(String serial) async {
    final device = adb_utils.AdbDevice(serial: serial, client: _client);
    final propsStr = await device.shell('getprop');
    
    final props = <String, String>{};
    final regex = RegExp(r'^\[(.+?)\]:\s*\[(.*)?\]$');
    for (final line in propsStr.split('\n')) {
      final match = regex.firstMatch(line.trim());
      if (match != null) {
        props[match.group(1)!] = match.group(2) ?? '';
      }
    }
    return props;
  }

  Future<void> adbRebootDevice(String serial, RebootOptions option) async {
    final device = adb_utils.AdbDevice(serial: serial, client: _client);
    await device.shell('reboot${option != RebootOptions.normal ? ':${option.name}' : ''}');
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

  /// Retorna lista de dispositivos via ADB server.
  Future<List<adb_utils.DeviceInfo>> fetchDevices() async {
    return _client.deviceList();
  }
}
