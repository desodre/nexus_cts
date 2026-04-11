import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nexus_cts/models/suite_entry.dart';
import 'package:nexus_cts/models/venv_entry.dart';
import 'package:nexus_cts/viewmodels/settings_viewmodel.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _vm = SettingsViewModel();

  @override
  void initState() {
    super.initState();
    _vm.loadSettings();
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
        if (_vm.loading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Configurações')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Configurações')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  const Text(
                    'Suítes Configuradas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _vm.addSuite,
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar Suíte'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_vm.suites.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Nenhuma suíte configurada.\nClique em "Adicionar Suíte" para começar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ..._vm.suites.asMap().entries.map((entry) {
                  return _buildSuiteCard(entry.key, entry.value);
                }),

              const Divider(height: 32),
              Row(
                children: [
                  const Text(
                    'Python Virtual Environments',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _vm.addVenv,
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar Venv'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Ambientes virtuais Python para execução do Camera ITS.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 12),
              if (_vm.venvs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Nenhuma venv configurada.\nClique em "Adicionar Venv" para começar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ..._vm.venvs.asMap().entries.map((entry) {
                  return _buildVenvCard(entry.key, entry.value);
                }),
            ],
          ),
        );
      },
    );
  }

  (IconData, Color) _suiteIconData(String type) {
    return switch (type) {
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

  Widget _buildSuiteCard(int index, SuiteEntry suite) {
    final (IconData icon, Color color) = _suiteIconData(suite.type);
    final title = suite.name.isNotEmpty
        ? suite.name
        : '${suite.type} #${index + 1}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Icon(icon, color: color, size: 28),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
        subtitle: Text(
          suite.path.isNotEmpty ? suite.path : 'Caminho não configurado',
          style: TextStyle(
            fontSize: 12,
            color: suite.path.isNotEmpty ? Colors.grey : Colors.red.shade300,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          tooltip: 'Remover suíte',
          onPressed: () => _vm.removeSuite(index),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                TextFormField(
                  key: ValueKey('suite_name_$index'),
                  initialValue: suite.name,
                  decoration: const InputDecoration(
                    labelText: 'Apelido da Suíte',
                    border: OutlineInputBorder(),
                    hintText: 'ex: 16_r1.3_pab, cts_prod',
                    prefixIcon: Icon(Icons.label),
                  ),
                  onChanged: (v) => _vm.updateSuiteName(index, v),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue:
                      SettingsViewModel.suiteTypes.contains(suite.type)
                      ? suite.type
                      : null,
                  decoration: InputDecoration(
                    labelText: 'Tipo da Suíte',
                    border: const OutlineInputBorder(),
                    ),
                  items: SettingsViewModel.suiteTypes.map((t) {
                    final (IconData tIcon, Color tColor) = _suiteIconData(t);
                    return DropdownMenuItem(
                      value: t,
                      child: Row(
                        children: [
                          Icon(tIcon, color: tColor, size: 20),
                          const SizedBox(width: 8),
                          Text(t),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) _vm.updateSuiteType(index, v);
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  key: ValueKey('suite_path_$index'),
                  initialValue: suite.path,
                  decoration: const InputDecoration(
                    labelText: 'Caminho da Suíte',
                    border: OutlineInputBorder(),
                    hintText: 'ex: /home/user/CTS/16.1_r3/android-cts',
                    prefixIcon: Icon(Icons.folder),
                  ),
                  onChanged: (v) => _vm.updateSuitePath(index, v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVenvCard(int index, VenvEntry venv) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.terminal, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  venv.name.isNotEmpty ? venv.name : 'Venv #${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.terminal, color: Colors.green),
                  tooltip: 'Abrir terminal com venv',
                  onPressed: venv.path.isEmpty
                      ? null
                      : () => _openVenvTerminal(venv),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Remover venv',
                  onPressed: () => _vm.removeVenv(index),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: ValueKey('venv_name_$index'),
              initialValue: venv.name,
              decoration: const InputDecoration(
                labelText: 'Apelido da Venv',
                border: OutlineInputBorder(),
                hintText: 'ex: its_py311, camera_its',
                prefixIcon: Icon(Icons.label),
              ),
              onChanged: (v) => _vm.updateVenvName(index, v),
            ),
            const SizedBox(height: 10),
            TextFormField(
              key: ValueKey('venv_path_$index'),
              initialValue: venv.path,
              decoration: const InputDecoration(
                labelText: 'Caminho da Venv',
                border: OutlineInputBorder(),
                hintText: 'ex: /home/user/.venvs/its',
                prefixIcon: Icon(Icons.folder),
              ),
              onChanged: (v) => _vm.updateVenvPath(index, v),
            ),
          ],
        ),
      ),
    );
  }

  void _openVenvTerminal(VenvEntry venv) async {
    final activatePath = '${venv.normalizedPath}/bin/activate';
    try {
      await Process.start('x-terminal-emulator', [
        '-e',
        'bash',
        '-c',
        'source $activatePath && exec bash',
      ], mode: ProcessStartMode.detached);
    } catch (_) {
      try {
        await Process.start('gnome-terminal', [
          '--',
          'bash',
          '-c',
          'source $activatePath && exec bash',
        ], mode: ProcessStartMode.detached);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não foi possível abrir o terminal.')),
          );
        }
      }
    }
  }
}
