import 'package:flutter/material.dart';
import 'package:nexus_cts/models/run_mode.dart';
import 'package:nexus_cts/view/settings/settings_page.dart';
import 'package:nexus_cts/viewmodels/run_suite_viewmodel.dart';

class RunSuitePage extends StatefulWidget {
  const RunSuitePage({super.key});

  @override
  State<RunSuitePage> createState() => _RunSuitePageState();
}

class _RunSuitePageState extends State<RunSuitePage> {
  final _vm = RunSuiteViewModel();
  final _moduleController = TextEditingController();
  final _extraArgsController = TextEditingController();
  final _scenesController = TextEditingController();
  bool _panelCollapsed = false;

  @override
  void initState() {
    super.initState();
    _vm.init();
  }

  @override
  void dispose() {
    _moduleController.dispose();
    _extraArgsController.dispose();
    _scenesController.dispose();
    _scrollController.dispose();
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Executar Suíte')),
          body: _vm.loadingSuites
              ? const Center(child: CircularProgressIndicator())
              : _vm.suites.isEmpty
                  ? _buildNoSuiteWarning()
                  : _buildContent(),
        );
      },
    );
  }

  Widget _buildNoSuiteWarning() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 56, color: Colors.orange),
          const SizedBox(height: 12),
          const Text('Nenhum caminho de suíte configurado.',
              style: TextStyle(fontSize: 16)),
          const SizedBox(height: 4),
          const Text('Defina o local das suítes em Configurações.',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
              _vm.loadSuites();
            },
            icon: const Icon(Icons.settings),
            label: const Text('Ir para Configurações'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Painel esquerdo ──
        if (!_panelCollapsed)
        SizedBox(
          width: 380,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _sectionTitle('Suíte'),
              const SizedBox(height: 8),
              RadioGroup<int>(
                groupValue: _vm.selectedSuiteIndex ?? -1,
                onChanged: (v) {
                  if (v != null && v != -1) _vm.selectSuite(v);
                },
                child: Column(
                  children: List.generate(_vm.suites.length, (i) {
                    final s = _vm.suites[i];
                    return ListTile(
                      leading: Radio<int>(value: i),
                      title: Text('${s.name} (${s.type})'),
                      subtitle:
                          Text(s.path, overflow: TextOverflow.ellipsis),
                      trailing: Icon(
                        _suiteIcon(s.type),
                        color: _suiteColor(s.type),
                      ),
                      onTap: () => _vm.selectSuite(i),
                    );
                  }),
                ),
              ),
              const Divider(height: 32),
              // ── Dispositivos ──
              Row(
                children: [
                  _sectionTitle('Dispositivos'),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    tooltip: 'Atualizar dispositivos',
                    onPressed:
                        _vm.loadingDevices ? null : _vm.fetchDevices,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_vm.loadingDevices)
                const Center(child: CircularProgressIndicator())
              else if (_vm.devices.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Nenhum dispositivo conectado',
                      style: TextStyle(color: Colors.grey)),
                )
              else if (_vm.isCtsVerifier) ...[
                // ── DUT + Tablet ──
                DropdownButtonFormField<String>(
                  initialValue: _vm.dutSerial,
                  decoration: const InputDecoration(
                    labelText: 'DUT (Device Under Test)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone_android),
                  ),
                  items: _vm.devices
                      .where((d) => d.isAvailable)
                      .map((d) => DropdownMenuItem(
                          value: d.serial, child: Text(d.serial)))
                      .toList(),
                  onChanged: _vm.setDutSerial,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _vm.tabletSerial,
                  decoration: const InputDecoration(
                    labelText: 'Tablet (Camera ITS)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.tablet_android),
                  ),
                  items: _vm.devices
                      .where((d) =>
                          d.isAvailable && d.serial != _vm.dutSerial)
                      .map((d) => DropdownMenuItem(
                          value: d.serial, child: Text(d.serial)))
                      .toList(),
                  onChanged: _vm.setTabletSerial,
                ),
              ] else
                ..._vm.devices.asMap().entries.map((entry) {
                  final i = entry.key;
                  final d = entry.value;
                  return CheckboxListTile(
                    value: d.selected,
                    title: Text(d.serial),
                    subtitle: Text(d.status),
                    secondary: Icon(
                      d.isAvailable
                          ? Icons.phone_android
                          : Icons.phone_disabled,
                      color: d.isAvailable ? Colors.green : Colors.grey,
                    ),
                    onChanged: d.isAvailable
                        ? (v) => _vm.toggleDevice(i, v ?? false)
                        : null,
                  );
                }),
              const Divider(height: 32),
              // ── Modo de execução ──
              if (!_vm.isCtsVerifier) ...[
              _sectionTitle('Modo de Execução'),
              const SizedBox(height: 8),
              RadioGroup<RunMode>(
                groupValue: _vm.runMode,
                onChanged: (v) {
                  if (v != null) _vm.setRunMode(v);
                },
                child: Column(
                  children: [
                    _modeRadio(RunMode.newRun, 'Nova Run', Icons.play_arrow,
                        'Executa a suíte completa'),
                    _modeRadio(RunMode.retest, 'Retry / Re-teste',
                        Icons.replay, 'Re-executa testes que falharam'),
                    _modeRadio(RunMode.subplan, 'Subplan', Icons.list_alt,
                        'Executa um subplan específico'),
                  ],
                ),
              ),
              if (_vm.runMode == RunMode.retest) ...[
                const SizedBox(height: 12),
                if (_vm.selectedSuite == null)
                  const Text(
                    'Selecione uma suíte para listar os resultados.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  )
                else if (_vm.availableResults.isEmpty)
                  const Text(
                    'Nenhum resultado encontrado nesta suíte.',
                    style: TextStyle(color: Colors.orange, fontSize: 13),
                  )
                else
                  DropdownButtonFormField<String>(
                    initialValue: _vm.selectedResult,
                    decoration: const InputDecoration(
                      labelText: 'Resultado para Retry',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.history),
                    ),
                    items: _vm.availableResults
                        .map((r) => DropdownMenuItem(
                            value: r,
                            child:
                                Text(r, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: _vm.setSelectedResult,
                  ),
              ],
              if (_vm.runMode == RunMode.subplan) ...[
                const SizedBox(height: 12),
                if (_vm.selectedSuite == null)
                  const Text(
                    'Selecione uma suíte para listar os subplans.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  )
                else if (_vm.availableSubplans.isEmpty)
                  const Text(
                    'Nenhum subplan encontrado nesta suíte.',
                    style: TextStyle(color: Colors.orange, fontSize: 13),
                  )
                else
                  DropdownButtonFormField<String>(
                    initialValue: _vm.selectedSubplan,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Subplan',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.list_alt),
                    ),
                    items: _vm.availableSubplans
                        .map((s) =>
                            DropdownMenuItem(value: s, child: Text(s, overflow: .clip)))
                        .toList(),
                    onChanged: _vm.setSelectedSubplan,
                  ),
              ],
              ], // fim do !isCtsVerifier
              if (_vm.isCtsVerifier) ...[
                _sectionTitle('Ação'),
                const SizedBox(height: 8),
                RadioGroup<VerifierAction>(
                  groupValue: _vm.verifierAction,
                  onChanged: (v) {
                    if (v != null) _vm.setVerifierAction(v);
                  },
                  child: Column(
                    children: [
                      _verifierActionRadio(
                        VerifierAction.installApks,
                        'Instalar APKs',
                        Icons.install_mobile,
                        'Instala todos os APKs do CTS Verifier',
                      ),
                      _verifierActionRadio(
                        VerifierAction.cameraIts,
                        'Camera ITS',
                        Icons.camera_alt,
                        'Executa os testes Camera ITS',
                      ),
                      _verifierActionRadio(
                        VerifierAction.cameraWebcamTest,
                        'Camera Webcam Test',
                        Icons.videocam,
                        'Executa o CameraWebcamTest',
                      ),
                    ],
                  ),
                ),
                if (_vm.verifierAction == VerifierAction.cameraIts ||
                    _vm.verifierAction == VerifierAction.cameraWebcamTest) ...[
                  const Divider(height: 24),
                  _sectionTitle('Python Venv'),
                  const SizedBox(height: 8),
                  if (_vm.venvs.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'Nenhuma venv configurada.\n'
                        'Adicione em Configurações.',
                        style: TextStyle(color: Colors.orange, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    DropdownButtonFormField<int>(
                      initialValue: _vm.selectedVenvIndex,
                      decoration: const InputDecoration(
                        labelText: 'Virtual Environment',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.terminal),
                      ),
                      items: _vm.venvs.asMap().entries.map((e) {
                        final v = e.value;
                        return DropdownMenuItem(
                          value: e.key,
                          child: Text(
                            v.name.isNotEmpty ? v.name : v.path,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: _vm.setSelectedVenv,
                    ),
                ],
                if (_vm.verifierAction == VerifierAction.cameraIts) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _vm.cameraId,
                    decoration: const InputDecoration(
                      labelText: 'Camera',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.camera_alt),
                    ),
                    items: const [
                      DropdownMenuItem(value: '0', child: Text('0')),
                      DropdownMenuItem(value: '0.3', child: Text('0.3')),
                      DropdownMenuItem(value: '0.5', child: Text('0.5')),
                      DropdownMenuItem(value: '1', child: Text('1')),
                    ],
                    onChanged: (v) {
                      if (v != null) _vm.setCameraId(v);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _scenesController,
                    decoration: const InputDecoration(
                      labelText: 'Scenes (opcional)',
                      border: OutlineInputBorder(),
                      hintText: 'ex: scene1,scene0',
                      prefixIcon: Icon(Icons.photo_library),
                    ),
                  ),
                ],
              ],
              if (!_vm.isCtsVerifier) ...[
              const Divider(height: 32),
              // ── Opções extras ──
              _sectionTitle('Opções Avançadas'),
              const SizedBox(height: 8),
              TextField(
                controller: _moduleController,
                decoration: const InputDecoration(
                  labelText: 'Módulo específico (-m)',
                  border: OutlineInputBorder(),
                  hintText: 'ex: CtsMediaTestCases',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _extraArgsController,
                decoration: const InputDecoration(
                  labelText: 'Argumentos extras',
                  border: OutlineInputBorder(),
                  hintText: 'ex: --skip-preconditions',
                ),
              ),
              ],
              const SizedBox(height: 24),
              // ── Botão Executar ──
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _vm.canRun && !_vm.running
                      ? () => _vm.startRun(
                            module: _moduleController.text,
                            extraArgs: _extraArgsController.text,
                            scenes: _scenesController.text,
                          )
                      : null,
                  icon: _vm.running
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(_vm.isCtsVerifier
                          ? _verifierActionIcon(_vm.verifierAction)
                          : Icons.rocket_launch),
                  label: Text(_vm.running
                      ? (_vm.isCtsVerifier
                          ? _verifierRunningLabel(_vm.verifierAction)
                          : 'Executando...')
                      : (_vm.isCtsVerifier
                          ? _verifierActionLabel(_vm.verifierAction)
                          : 'Iniciar Execução')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!_panelCollapsed) const VerticalDivider(width: 1),
        // ── Painel direito: saída ──
        Expanded(child: _buildOutputPanel()),
      ],
    );
  }

  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Widget _buildOutputPanel() {
    if (_vm.runOutput == null && !_vm.running) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.terminal, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'Selecione suíte, dispositivos e modo de execução,\n'
              'depois clique em "Iniciar Execução".',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_vm.running) _scrollToBottom();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              IconButton(
                icon: Icon(_panelCollapsed
                    ? Icons.chevron_right
                    : Icons.chevron_left),
                tooltip: _panelCollapsed
                    ? 'Mostrar painel'
                    : 'Expandir terminal',
                onPressed: () => setState(() {
                  _panelCollapsed = !_panelCollapsed;
                }),
              ),
              _sectionTitle('Saída'),
              if (_vm.running) ...[
                const SizedBox(width: 12),
                const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
              const Spacer(),
              if (_vm.running)
                TextButton.icon(
                  onPressed: _vm.stopRun,
                  icon: const Icon(Icons.stop, color: Colors.red),
                  label: const Text('Parar',
                      style: TextStyle(color: Colors.red)),
                )
              else
                IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  tooltip: 'Limpar',
                  onPressed: _vm.clearOutput,
                ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 0, 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
            ),
            child: SingleChildScrollView(
              controller: _scrollController,
              child: SelectableText(
                _vm.runOutput ?? '',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: Colors.greenAccent,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Helpers visuais ──

  Widget _modeRadio(
      RunMode mode, String label, IconData icon, String desc) {
    return ListTile(
      leading: Radio<RunMode>(value: mode),
      title: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
      subtitle: Text(desc, style: const TextStyle(fontSize: 12)),
      onTap: () => _vm.setRunMode(mode),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
  }

  IconData _suiteIcon(String type) {
    return switch (type.toUpperCase()) {
      'CTS' => Icons.verified,
      'VTS' => Icons.memory,
      'GTS' => Icons.play_circle,
      'CTS VERIFIER' => Icons.checklist,
      _ => Icons.science,
    };
  }

  Color _suiteColor(String type) {
    return switch (type.toUpperCase()) {
      'CTS' => Colors.blue,
      'VTS' => Colors.deepPurple,
      'GTS' => Colors.teal,
      'CTS VERIFIER' => Colors.orange,
      _ => Colors.grey,
    };
  }

  Widget _verifierActionRadio(
      VerifierAction action, String label, IconData icon, String desc) {
    return ListTile(
      leading: Radio<VerifierAction>(value: action),
      title: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
      subtitle: Text(desc, style: const TextStyle(fontSize: 12)),
      onTap: () => _vm.setVerifierAction(action),
    );
  }

  IconData _verifierActionIcon(VerifierAction action) {
    return switch (action) {
      VerifierAction.installApks => Icons.install_mobile,
      VerifierAction.cameraIts => Icons.camera_alt,
      VerifierAction.cameraWebcamTest => Icons.videocam,
    };
  }

  String _verifierActionLabel(VerifierAction action) {
    return switch (action) {
      VerifierAction.installApks => 'Instalar APKs',
      VerifierAction.cameraIts => 'Rodar Camera ITS',
      VerifierAction.cameraWebcamTest => 'Rodar Webcam Test',
    };
  }

  String _verifierRunningLabel(VerifierAction action) {
    return switch (action) {
      VerifierAction.installApks => 'Instalando...',
      VerifierAction.cameraIts => 'Rodando Camera ITS...',
      VerifierAction.cameraWebcamTest => 'Rodando Webcam Test...',
    };
  }
}
