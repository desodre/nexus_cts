import 'package:flutter/material.dart';
import 'package:nexus_cts/models/camera_its_result.dart';
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Atualizar dispositivos',
                      onPressed: _vm.loadingDevices ? null : _vm.fetchDevices,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(height: 200, child: _buildDeviceList()),
                const Divider(height: 32),
                // ── Resultados ──
                Expanded(
                  child: ListView(
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Resultados das Suítes',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            tooltip: 'Atualizar resultados',
                            onPressed: _vm.loadingResults
                                ? null
                                : () {
                                    _vm.fetchResults();
                                  },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildResultsSection(),
                      const Divider(height: 32),
                      _buildItsResultsSection(),
                    ],
                  ),
                ),
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
          title: Text(
            device.displayModel,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Row(
            children: [
              Text(device.serial, style: const TextStyle(fontSize: 12)),
              if (device.usb != null) ...[
                const SizedBox(width: 8),
                Icon(Icons.usb, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 2),
                Text(
                  device.usb!,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
              if (device.product != null) ...[
                const SizedBox(width: 8),
                Text(
                  device.product!,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ],
          ),
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

  Widget _buildResultsSection() {
    if (_vm.loadingResults) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_vm.noSuiteConfigured) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 48,
                color: Colors.orange,
              ),
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
        ),
      );
    }

    if (_vm.results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.folder_open, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text('Nenhum resultado encontrado nas suítes configuradas'),
            ],
          ),
        ),
      );
    }

    final orderedKeys = _vm.orderedGroupKeys;

    return Column(
      children: orderedKeys.map((suite) {
        final items = _vm.groupedResults[suite]!;
        final (IconData icon, Color color) = _suiteIconData(
          items.first.suiteType,
        );

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
      }).toList(),
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
                    child: Text(
                      r.folderName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    _formatDate(r.modified),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
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
                    _infoChip(
                      Icons.view_module,
                      '${s.modulesDone}/${s.modulesTotal}',
                      Colors.blueGrey,
                    ),
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
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.green,
                    ),
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

  // ── Camera ITS Results ──

  Widget _buildItsResultsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.camera_alt, color: Colors.orange),
            const SizedBox(width: 8),
            const Text(
              'Camera ITS',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (_vm.loadingItsResults)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Atualizar resultados',
              onPressed: _vm.loadingResults
                  ? null
                  : () {
                      _vm.fetchItsResults();
                    },
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_vm.itsResults.isEmpty && !_vm.loadingItsResults)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text(
                'Nenhum resultado Camera ITS encontrado em /tmp/',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ...(_vm.itsResults.map(_buildItsTile)),
      ],
    );
  }

  Widget _buildItsTile(CameraItsResult r) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: const Icon(Icons.camera_alt, color: Colors.orange),
        title: Text(
          r.folderName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Pass: ${r.totalPassed}  Fail: ${r.totalFailed}  '
          'Skip: ${r.totalSkipped}  —  ${r.passRate.toStringAsFixed(1)}%',
        ),
        trailing: Text(
          _formatDate(r.modified),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        children: [
          if (r.dutSerial != null || r.buildFingerprint != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Wrap(
                spacing: 16,
                children: [
                  if (r.dutSerial != null)
                    _detailText(Icons.phone_android, r.dutSerial!),
                  if (r.buildFingerprint != null)
                    _detailText(Icons.fingerprint, r.buildFingerprint!),
                ],
              ),
            ),
          ...r.scenes.map((sc) => _buildItsSceneTile(sc)),
        ],
      ),
    );
  }

  Widget _buildItsSceneTile(ItsSceneResult sc) {
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
                  const Icon(Icons.videocam, size: 18, color: Colors.blueGrey),
                  const SizedBox(width: 8),
                  Text(
                    'cam${sc.camera} / ${sc.scene}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  _infoChip(Icons.check_circle, '${sc.passed}', Colors.green),
                  const SizedBox(width: 8),
                  _infoChip(Icons.cancel, '${sc.failed}', Colors.red),
                  const SizedBox(width: 8),
                  _infoChip(Icons.skip_next, '${sc.skipped}', Colors.grey),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: sc.tests.map((t) {
                  final color = t.passed
                      ? Colors.green
                      : t.failed
                      ? Colors.red
                      : Colors.grey;
                  return GestureDetector(
                    onTap: t.detail != null
                        ? () => _showTestDetailDialog(t)
                        : null,
                    child: Chip(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      avatar: Icon(
                        t.passed
                            ? Icons.check_circle
                            : t.failed
                            ? Icons.cancel
                            : Icons.skip_next,
                        size: 16,
                        color: color,
                      ),
                      label: Text(
                        t.testName,
                        style: TextStyle(fontSize: 11, color: color),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers visuais ──

  void _showTestDetailDialog(ItsTestEntry t) {
    final d = t.detail!;
    final resultColor = d.result == 'PASS'
        ? Colors.green
        : d.result == 'FAIL'
        ? Colors.red
        : Colors.grey;

    String? fmtTime(int? ms) {
      if (ms == null) return null;
      final dt = DateTime.fromMillisecondsSinceEpoch(ms);
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}:'
          '${dt.second.toString().padLeft(2, '0')}';
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              d.result == 'PASS' ? Icons.check_circle : Icons.cancel,
              color: resultColor,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(t.testName, overflow: TextOverflow.ellipsis)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: resultColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                d.result ?? '—',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: resultColor,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 750,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Informações do Teste ──
                _sectionTitle('Informações do Teste', Icons.info_outline),
                _kvRow('Test Name', d.testName),
                _kvRow('Test Class', d.testClass),
                _kvRow('Signature', d.signature),
                if (d.beginTime != null) _kvRow('Início', fmtTime(d.beginTime)),
                if (d.endTime != null) _kvRow('Fim', fmtTime(d.endTime)),
                if (d.duration != null)
                  _kvRow('Duração', '${d.duration!.inSeconds}s'),
                const Divider(height: 24),

                // ── Sumário ──
                _sectionTitle('Sumário', Icons.bar_chart),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _summaryBadge('Passed', d.passedCount, Colors.green),
                    _summaryBadge('Failed', d.failedCount, Colors.red),
                    _summaryBadge('Error', d.errorCount, Colors.orange),
                    _summaryBadge('Executed', d.executedCount, Colors.blue),
                    _summaryBadge('Skipped', d.skippedCount, Colors.grey),
                  ],
                ),
                const Divider(height: 24),

                // ── Termination Signal ──
                if (d.terminationSignal != null) ...[
                  _sectionTitle(
                    'Termination Signal',
                    Icons.warning_amber_rounded,
                  ),
                  SelectableText(
                    d.terminationSignal!,
                    style: TextStyle(color: Colors.red.shade300),
                  ),
                  const Divider(height: 24),
                ],

                // ── Details ──
                if (d.details != null) ...[
                  _sectionTitle('Detalhes', Icons.description),
                  SelectableText(d.details!),
                  const Divider(height: 24),
                ],

                // ── Stacktrace ──
                if (d.stacktrace != null) ...[
                  _sectionTitle('Stacktrace', Icons.terminal),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      d.stacktrace!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Colors.greenAccent,
                      ),
                    ),
                  ),
                  const Divider(height: 24),
                ],

                // ── Controller Info (Dispositivos) ──
                if (d.devices.isNotEmpty) ...[
                  _sectionTitle(
                    'Controller Info (${d.devices.length} dispositivo${d.devices.length > 1 ? 's' : ''})',
                    Icons.phone_android,
                  ),
                  const SizedBox(height: 8),
                  ...d.devices.asMap().entries.map((e) {
                    final idx = e.key;
                    final dev = e.value;
                    final label = idx == 0 ? 'DUT' : 'Tablet';
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade700),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$label — ${dev.serial ?? "N/A"}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _kvRow('Model', dev.model),
                          _kvRow('Build ID', dev.buildId),
                          _kvRow('Product', dev.buildProduct),
                          _kvRow('Build Type', dev.buildType),
                          _kvRow('SDK Version', dev.sdkVersion),
                          _kvRow('Characteristics', dev.characteristics),
                          if (dev.buildFingerprint != null)
                            _kvRow('Fingerprint', dev.buildFingerprint),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blueAccent),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _kvRow(String key, String? value) {
    if (value == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$key:',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
          ),
          Expanded(
            child: SelectableText(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _summaryBadge(String label, int? count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${count ?? 0}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }

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
          child: Text(
            text,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
            overflow: TextOverflow.ellipsis,
          ),
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
      'CTS-on-GSI' => (Icons.verified_user, Colors.indigo),
      'VTS' => (Icons.memory, Colors.deepPurple),
      'GTS' => (Icons.play_circle, Colors.teal),
      'GTS-Interactive' => (Icons.touch_app, Colors.cyan),
      'GTS-Root' => (Icons.admin_panel_settings, Colors.deepOrange),
      'STS' => (Icons.security, Colors.red),
      'CTS Verifier' => (Icons.checklist, Colors.orange),
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
