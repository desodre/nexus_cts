import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nexus_cts/view/device_properties/widgets/props_table.dart';
import 'package:nexus_cts/viewmodels/device_properties_viewmodel.dart';

class DevicePropsPanel extends StatelessWidget {
  final String serial;
  final DevicePropertiesViewModel vm;

  const DevicePropsPanel({super.key, required this.serial, required this.vm});

  @override
  Widget build(BuildContext context) {
    if (vm.isLoadingProps(serial)) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final error = vm.propsErrorFor(serial);
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(error, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => vm.refreshProps(serial),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final props = vm.filteredProps(serial);
    final fastboot = vm.filteredFastboot(serial);
    final totalProps = vm.propsFor(serial)?.length ?? 0;

    return Card(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildToolbar(context, totalProps, props.length),
            const SizedBox(height: 12),
            if (props.isNotEmpty) ...[
              PropsTable(
                properties: props,
                title: 'adb shell getprop',
                icon: Icons.phone_android,
              ),
            ],
            if (fastboot.isNotEmpty) ...[
              const SizedBox(height: 16),
              PropsTable(
                properties: fastboot,
                title: 'fastboot getvar all',
                icon: Icons.memory,
                initiallyExpanded: false,
              ),
            ],
            if (props.isEmpty && fastboot.isEmpty && vm.searchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Nenhum resultado para "${vm.searchQuery}"',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, int total, int filtered) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 36,
            child: TextField(
              onChanged: vm.setSearchQuery,
              decoration: InputDecoration(
                hintText: 'Filtrar propriedades...',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.search, size: 18),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (vm.searchQuery.isNotEmpty)
          Text(
            '$filtered/$total',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.copy, size: 18),
          tooltip: 'Copiar todas as propriedades',
          onPressed: () {
            final allProps = vm.propsFor(serial);
            if (allProps == null) return;
            final text = allProps.entries
                .map((e) => '[${e.key}]: [${e.value}]')
                .join('\n');
            Clipboard.setData(ClipboardData(text: text));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$total propriedades copiadas'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.refresh, size: 18),
          tooltip: 'Recarregar propriedades',
          onPressed: () => vm.refreshProps(serial),
        ),
        IconButton(
          icon: vm.isLoadingFastboot(serial)
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.developer_board, size: 18),
          tooltip: 'Carregar fastboot getvar all',
          onPressed: vm.isLoadingFastboot(serial)
              ? null
              : () => vm.fetchFastbootVars(serial),
        ),
      ],
    );
  }
}
