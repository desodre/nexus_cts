import 'package:flutter/material.dart';
import 'package:nexus_cts/models/suite_entry.dart';
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
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              const Text(
                'Execução',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SwitchListTile(
                title: const Text('Re-teste automático em falhas'),
                subtitle: const Text(
                  'Dispara re-teste isolado para módulos que falharam',
                ),
                value: _vm.autoRetest,
                onChanged: _vm.setAutoRetest,
              ),
              SwitchListTile(
                title: const Text('Reboot ao falhar'),
                subtitle: const Text(
                  'Reinicia o dispositivo antes de re-testar módulos com falha',
                ),
                value: _vm.rebootOnFail,
                onChanged: _vm.setRebootOnFail,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSuiteCard(int index, SuiteEntry suite) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.science, color: Colors.blueGrey),
                const SizedBox(width: 8),
                Text(
                  suite.name.isNotEmpty
                      ? '${suite.name} (${suite.type})'
                      : '${suite.type} #${index + 1}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Remover suíte',
                  onPressed: () => _vm.removeSuite(index),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: TextEditingController(text: suite.name),
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
              initialValue: SettingsViewModel.suiteTypes.contains(suite.type)
                  ? suite.type
                  : null,
              decoration: const InputDecoration(
                labelText: 'Tipo da Suíte',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: SettingsViewModel.suiteTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) {
                if (v != null) _vm.updateSuiteType(index, v);
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: TextEditingController(text: suite.path),
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
    );
  }
}
