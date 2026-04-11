import 'package:flutter/material.dart';
import 'package:nexus_cts/view/device_properties/widgets/device_card.dart';
import 'package:nexus_cts/view/device_properties/widgets/device_props_panel.dart';
import 'package:nexus_cts/view/widgets/app_drawer.dart';
import 'package:nexus_cts/view/widgets/empty_state_widget.dart';
import 'package:nexus_cts/viewmodels/device_properties_viewmodel.dart';

class DevicePropertiesPage extends StatefulWidget {
  const DevicePropertiesPage({super.key});

  @override
  State<DevicePropertiesPage> createState() => _DevicePropertiesPageState();
}

class _DevicePropertiesPageState extends State<DevicePropertiesPage> {
  final _vm = DevicePropertiesViewModel();

  @override
  void initState() {
    super.initState();
    _vm.init();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Properties'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar dispositivos',
            onPressed: _vm.fetchDevices,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          if (_vm.loadingDevices) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_vm.devicesError != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(
                    _vm.devicesError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _vm.fetchDevices,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          }

          if (_vm.devices.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.usb_off,
              message: 'Nenhum dispositivo conectado',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _vm.devices.length,
            itemBuilder: (context, index) {
              final device = _vm.devices[index];
              final isExpanded = _vm.expandedSerial == device.serial;

              return Column(
                children: [
                  DeviceCard(
                    device: device,
                    isExpanded: isExpanded,
                    onTap: () => _vm.toggleDevice(device.serial),
                  ),
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: isExpanded
                        ? DevicePropsPanel(serial: device.serial, vm: _vm)
                        : const SizedBox.shrink(),
                    crossFadeState: isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 250),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
