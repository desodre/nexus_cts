import 'package:flutter/material.dart';
import 'package:nexus_cts/models/test_result.dart';
import 'package:nexus_cts/view/settings/settings_page.dart';
import 'package:nexus_cts/view/widgets/app_drawer.dart';
import 'package:nexus_cts/viewmodels/home_viewmodel.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _vm = HomeViewModel();

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
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Nexus CTS Home Page')),
          drawer: const AppDrawer(),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Dispositivos ──
                Row(
                  children: [
                    const Text(
                      'Dispositivos ADB',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Atualizar dispositivos',
                      onPressed:
                          _vm.loadingDevices ? null : _vm.fetchDevices,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(height: 200, child: _buildDeviceList()),
                const Divider(height: 32),
                // ── Resultados ──
                Row(
                  children: [
                    const Text(
                      'Resultados das Suítes',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Atualizar resultados',
                      onPressed:
                          _vm.loadingResults ? null : _vm.fetchResults,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(child: _buildResultsList()),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Devices ──

  Widget _buildDeviceList() {
    if (_vm.loadingDevices) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_vm.devicesError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text(_vm.devicesError!, textAlign: TextAlign.center),
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
      itemCount: _vm.devices.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final device = _vm.devices[index];
        return ListTile(
          leading: Icon(
            _statusIcon(device.status),
            color: _statusColor(device.status),
          ),
          title: Text(device.serial),
          trailing: Chip(
            label: Text(
              device.status,
              style: TextStyle(
                color: _statusColor(device.status),
                fontSize: 12,
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Results ──

  Widget _buildResultsList() {
    if (_vm.loadingResults) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_vm.noSuiteConfigured) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded,
                size: 48, color: Colors.orange),
            const SizedBox(height: 8),
            const Text(
              'Nenhum caminho de suíte configurado.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                );
                _vm.fetchResults();
              },
              icon: const Icon(Icons.settings),
              label: const Text('Ir para Configurações'),
            ),
          ],
        ),
      );
    }

    if (_vm.results.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('Nenhum resultado encontrado nas suítes configuradas'),
          ],
        ),
      );
    }

    final orderedKeys = _vm.orderedGroupKeys;

    return ListView.builder(
      itemCount: orderedKeys.length,
      itemBuilder: (context, index) {
        final suite = orderedKeys[index];
        final items = _vm.groupedResults[suite]!;
        final (IconData icon, Color color) =
            _suiteIconData(items.first.suiteType);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            leading: Icon(icon, color: color),
            title: Text(
              suite,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
            subtitle: Text('${items.length} resultado(s)'),
            initiallyExpanded: true,
            children: items.map((r) => _buildResultTile(r)).toList(),
          ),
        );
      },
    );
  }

  Widget _buildResultTile(SuiteResult r) {
    final s = r.summary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.folder, size: 20, color: Colors.blueGrey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(r.folderName,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  Text(_formatDate(r.modified),
                      style:
                          const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              if (s != null) ...[
                const Divider(height: 16),
                Row(
                  children: [
                    _infoChip(Icons.check_circle, '${s.passed}', Colors.green),
                    const SizedBox(width: 12),
                    _infoChip(Icons.cancel, '${s.failed}', Colors.red),
                    const SizedBox(width: 12),
                    _infoChip(Icons.view_module,
                        '${s.modulesDone}/${s.modulesTotal}', Colors.blueGrey),
                    const Spacer(),
                    Text(
                      '${s.passRate.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: s.passRate >= 90
                            ? Colors.green
                            : s.passRate >= 70
                                ? Colors.orange
                                : Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: s.total > 0 ? s.passed / s.total : 0,
                    minHeight: 6,
                    backgroundColor: Colors.red.shade100,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                ),
              ],
              if (r.suitePlan != null ||
                  r.startTime != null ||
                  r.deviceSerial != null ||
                  r.buildFingerprint != null) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    if (r.suitePlan != null)
                      _detailText(Icons.assignment, r.suitePlan!),
                    if (r.startTime != null)
                      _detailText(Icons.schedule, r.startTime!),
                    if (r.deviceSerial != null)
                      _detailText(Icons.phone_android, r.deviceSerial!),
                    if (r.buildFingerprint != null)
                      _detailText(Icons.fingerprint, r.buildFingerprint!),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers visuais ──

  Widget _infoChip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 13)),
      ],
    );
  }

  Widget _detailText(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Flexible(
          child: Text(text,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  IconData _statusIcon(String status) {
    return switch (status) {
      'device' => Icons.phone_android,
      'unauthorized' => Icons.lock,
      'offline' => Icons.signal_wifi_off,
      _ => Icons.device_unknown,
    };
  }

  Color _statusColor(String status) {
    return switch (status) {
      'device' => Colors.green,
      'unauthorized' => Colors.orange,
      'offline' => Colors.red,
      _ => Colors.grey,
    };
  }

  (IconData, Color) _suiteIconData(String suite) {
    return switch (suite) {
      'CTS' => (Icons.verified, Colors.blue),
      'VTS' => (Icons.memory, Colors.deepPurple),
      'GTS' => (Icons.play_circle, Colors.teal),
      _ => (Icons.science, Colors.grey),
    };
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}
