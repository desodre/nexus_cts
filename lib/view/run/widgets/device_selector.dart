import 'package:flutter/material.dart';
import 'package:nexus_cts/models/adb_device.dart';

class DeviceSelector extends StatelessWidget {
  final List<AdbDevice> devices;
  final bool loading;
  final bool isCtsVerifier;
  final String? dutSerial;
  final String? tabletSerial;
  final VoidCallback onRefresh;
  final ValueChanged<String?> onDutChanged;
  final ValueChanged<String?> onTabletChanged;
  final void Function(int index, bool value) onToggleDevice;

  const DeviceSelector({
    super.key,
    required this.devices,
    required this.loading,
    required this.isCtsVerifier,
    this.dutSerial,
    this.tabletSerial,
    required this.onRefresh,
    required this.onDutChanged,
    required this.onTabletChanged,
    required this.onToggleDevice,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Dispositivos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              tooltip: 'Atualizar dispositivos',
              onPressed: loading ? null : onRefresh,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (loading)
          const Center(child: CircularProgressIndicator())
        else if (devices.isEmpty)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Nenhum dispositivo conectado',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else if (isCtsVerifier) ...[
          DropdownButtonFormField<String>(
            initialValue: dutSerial,
            decoration: const InputDecoration(
              labelText: 'DUT (Device Under Test)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone_android),
            ),
            items: devices
                .where((d) => d.isAvailable)
                .map(
                  (d) =>
                      DropdownMenuItem(value: d.serial, child: Text(d.serial)),
                )
                .toList(),
            onChanged: onDutChanged,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: tabletSerial,
            decoration: const InputDecoration(
              labelText: 'Tablet (Camera ITS)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.tablet_android),
            ),
            items: devices
                .where((d) => d.isAvailable && d.serial != dutSerial)
                .map(
                  (d) =>
                      DropdownMenuItem(value: d.serial, child: Text(d.serial)),
                )
                .toList(),
            onChanged: onTabletChanged,
          ),
        ] else
          ...devices.asMap().entries.map((entry) {
            final i = entry.key;
            final d = entry.value;
            return CheckboxListTile(
              value: d.selected,
              title: Text(d.serial),
              subtitle: Text(d.status),
              secondary: Icon(
                d.isAvailable ? Icons.phone_android : Icons.phone_disabled,
                color: d.isAvailable ? Colors.green : Colors.grey,
              ),
              onChanged: d.isAvailable
                  ? (v) => onToggleDevice(i, v ?? false)
                  : null,
            );
          }),
      ],
    );
  }
}
