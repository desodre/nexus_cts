import 'package:adb_utils/adb_utils.dart' as adb_utils;
import 'package:flutter/material.dart';
import 'package:nexus_cts/view/widgets/device_status_helpers.dart';

class DeviceListSection extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<adb_utils.DeviceInfo> devices;
  final VoidCallback onRefresh;

  const DeviceListSection({
    super.key,
    required this.loading,
    this.error,
    required this.devices,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Dispositivos ADB',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Atualizar dispositivos',
              onPressed: loading ? null : onRefresh,
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(height: 100, child: _buildContent()),
      ],
    );
  }

  Widget _buildContent() {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text(error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (devices.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.usb_off, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('Nenhum dispositivo encontrado'),
          ],
        ),
      );
    }

    return ListView.separated(
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemCount: devices.length,
      itemBuilder: (context, index) {
        final device = devices[index];
        final state = device.state;
        final displayModel =
            device.model?.replaceAll('_', ' ') ?? device.serial;
        return ListTile(
          leading: Icon(
            deviceStatusIcon(state),
            color: deviceStatusColor(state),
          ),
          title: Text(
            displayModel,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Row(
            children: [
              Text(device.serial, style: const TextStyle(fontSize: 12)),
              if (device.product != null) ...[
                const SizedBox(width: 8),
                Text(
                  device.product!,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DevicePropIndicator(
                label: state.name,
                color: deviceStatusColor(state),
              ),
              if (device.device != null) ...[
                const SizedBox(width: 8),
                DevicePropIndicator(
                  label: device.device!,
                  color: deviceStatusColor(state),
                ),
              ],
            ],
          ),
        );
      }
    );
  }
}

class DevicePropIndicator extends StatelessWidget {
  const DevicePropIndicator({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
    );
  }
}
