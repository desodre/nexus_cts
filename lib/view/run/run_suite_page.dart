import 'package:flutter/material.dart';
import 'package:nexus_cts/models/run_mode.dart';
import 'package:nexus_cts/view/run/widgets/device_selector.dart';
import 'package:nexus_cts/view/run/widgets/no_suite_warning.dart';
import 'package:nexus_cts/view/run/widgets/output_panel.dart';
import 'package:nexus_cts/view/run/widgets/run_mode_panel.dart';
import 'package:nexus_cts/view/run/widgets/suite_selector.dart';
import 'package:nexus_cts/view/run/widgets/verifier_action_panel.dart';
import 'package:nexus_cts/view/widgets/section_title.dart';
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
  final _scrollController = ScrollController();
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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
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
              ? NoSuiteWarning(onReturn: _vm.loadSuites)
              : _buildContent(),
        );
      },
    );
  }

  Widget _buildContent() {
    if (_vm.running) _scrollToBottom();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_panelCollapsed)
          SizedBox(
            width: 380,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SectionTitle('Suíte'),
                const SizedBox(height: 8),
                SuiteSelector(
                  suites: _vm.suites,
                  selectedIndex: _vm.selectedSuiteIndex,
                  onSelect: _vm.selectSuite,
                ),
                const Divider(height: 32),
                DeviceSelector(
                  devices: _vm.devices,
                  loading: _vm.loadingDevices,
                  isCtsVerifier: _vm.isCtsVerifier,
                  dutSerial: _vm.dutSerial,
                  tabletSerial: _vm.tabletSerial,
                  onRefresh: _vm.fetchDevices,
                  onDutChanged: _vm.setDutSerial,
                  onTabletChanged: _vm.setTabletSerial,
                  onToggleDevice: _vm.toggleDevice,
                ),
                const Divider(height: 32),
                if (!_vm.isCtsVerifier)
                  RunModePanel(
                    runMode: _vm.runMode,
                    onModeChanged: _vm.setRunMode,
                    selectedSuiteName: _vm.selectedSuite?.name,
                    availableResults: _vm.availableResults,
                    selectedResult: _vm.selectedResult,
                    onResultChanged: _vm.setSelectedResult,
                    availableSubplans: _vm.availableSubplans,
                    selectedSubplan: _vm.selectedSubplan,
                    onSubplanChanged: _vm.setSelectedSubplan,
                    moduleController: _moduleController,
                    extraArgsController: _extraArgsController,
                  ),
                if (_vm.isCtsVerifier)
                  VerifierActionPanel(
                    action: _vm.verifierAction,
                    onActionChanged: _vm.setVerifierAction,
                    venvs: _vm.venvs,
                    selectedVenvIndex: _vm.selectedVenvIndex,
                    onVenvChanged: _vm.setSelectedVenv,
                    cameraId: _vm.cameraId,
                    onCameraIdChanged: _vm.setCameraId,
                    scenesController: _scenesController,
                  ),
                const SizedBox(height: 24),
                _buildRunButton(),
              ],
            ),
          ),
        if (!_panelCollapsed) const VerticalDivider(width: 1),
        Expanded(
          child: OutputPanel(
            output: _vm.runOutput,
            running: _vm.running,
            panelCollapsed: _panelCollapsed,
            onToggleCollapse: () =>
                setState(() => _panelCollapsed = !_panelCollapsed),
            onStop: _vm.stopRun,
            onClear: _vm.clearOutput,
            scrollController: _scrollController,
          ),
        ),
      ],
    );
  }

  Widget _buildRunButton() {
    return SizedBox(
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
            : Icon(
                _vm.isCtsVerifier
                    ? _verifierActionIcon(_vm.verifierAction)
                    : Icons.rocket_launch,
              ),
        label: Text(
          _vm.running
              ? (_vm.isCtsVerifier
                    ? _verifierRunningLabel(_vm.verifierAction)
                    : 'Executando...')
              : (_vm.isCtsVerifier
                    ? _verifierActionLabel(_vm.verifierAction)
                    : 'Iniciar Execução'),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueGrey,
          foregroundColor: Colors.white,
        ),
      ),
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
