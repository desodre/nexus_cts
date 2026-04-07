import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:nexus_cts/models/adb_device.dart';
import 'package:nexus_cts/models/run_mode.dart';
import 'package:nexus_cts/models/suite_entry.dart';
import 'package:nexus_cts/models/venv_entry.dart';
import 'package:nexus_cts/services/adb_service.dart';
import 'package:nexus_cts/services/suite_result_service.dart';
import 'package:nexus_cts/services/suite_runner_service.dart';

class RunSuiteViewModel extends ChangeNotifier {
  final AdbService _adbService;
  final SuiteResultService _resultService;
  final SuiteRunnerService _runnerService;

  RunSuiteViewModel({
    AdbService? adbService,
    SuiteResultService? resultService,
    SuiteRunnerService? runnerService,
  })  : _adbService = adbService ?? AdbService(),
        _resultService = resultService ?? SuiteResultService(),
        _runnerService = runnerService ?? SuiteRunnerService();

  // ── Suites ──
  List<SuiteEntry> _suites = [];
  List<SuiteEntry> get suites => _suites;

  int? _selectedSuiteIndex;
  int? get selectedSuiteIndex => _selectedSuiteIndex;

  bool _loadingSuites = true;
  bool get loadingSuites => _loadingSuites;

  SuiteEntry? get selectedSuite =>
      _selectedSuiteIndex != null ? _suites[_selectedSuiteIndex!] : null;

  // ── Devices ──
  List<AdbDevice> _devices = [];
  List<AdbDevice> get devices => _devices;

  bool _loadingDevices = false;
  bool get loadingDevices => _loadingDevices;

  // ── Run mode ──
  RunMode _runMode = RunMode.newRun;
  RunMode get runMode => _runMode;

  // ── Retry / Subplan ──
  List<String> _availableResults = [];
  List<String> get availableResults => _availableResults;

  String? _selectedResult;
  String? get selectedResult => _selectedResult;

  List<String> _availableSubplans = [];
  List<String> get availableSubplans => _availableSubplans;

  String? _selectedSubplan;
  String? get selectedSubplan => _selectedSubplan;

  // ── Execution ──
  bool _running = false;
  bool get running => _running;

  final StringBuffer _outputBuffer = StringBuffer();
  String? get runOutput =>
      _outputBuffer.isEmpty ? null : _outputBuffer.toString();

  Process? _activeProcess;
  bool _cancelled = false;

  // ── CTS Verifier ──
  VerifierAction _verifierAction = VerifierAction.installApks;
  VerifierAction get verifierAction => _verifierAction;

  String? _dutSerial;
  String? get dutSerial => _dutSerial;

  String? _tabletSerial;
  String? get tabletSerial => _tabletSerial;

  List<VenvEntry> _venvs = [];
  List<VenvEntry> get venvs => _venvs;

  String _cameraId = '0';
  String get cameraId => _cameraId;

  int? _selectedVenvIndex;
  int? get selectedVenvIndex => _selectedVenvIndex;
  VenvEntry? get selectedVenv =>
      _selectedVenvIndex != null ? _venvs[_selectedVenvIndex!] : null;

  // ── Computed ──
  bool get isCtsVerifier => selectedSuite?.type == 'CTS Verifier';

  bool get canRun {
    if (_selectedSuiteIndex == null) return false;
    if (isCtsVerifier) {
      if (_dutSerial == null) return false;
      if (_verifierAction == VerifierAction.cameraIts ||
          _verifierAction == VerifierAction.cameraWebcamTest) {
        if (_tabletSerial == null) return false;
        if (_selectedVenvIndex == null) return false;
      }
      return true;
    }
    final hasDevice = _devices.any((d) => d.selected && d.isAvailable);
    if (!hasDevice) return false;
    if (_runMode == RunMode.subplan && _selectedSubplan == null) return false;
    if (_runMode == RunMode.retest && _selectedResult == null) return false;
    return true;
  }

  // ── Init ──
  void init() {
    loadSuites();
    fetchDevices();
    _loadVenvs();
  }

  Future<void> _loadVenvs() async {
    _venvs = await VenvStorage.load();
    notifyListeners();
  }

  Future<void> loadSuites() async {
    final suites = await SuiteStorage.load();
    _suites = suites.where((s) => s.path.isNotEmpty).toList();
    _selectedSuiteIndex = null;
    _loadingSuites = false;
    notifyListeners();
  }

  Future<void> fetchDevices() async {
    _loadingDevices = true;
    notifyListeners();

    try {
      _devices = await _adbService.fetchDevices();
    } catch (_) {
      _devices = [];
    }

    _loadingDevices = false;
    notifyListeners();
  }

  void selectSuite(int index) {
    _selectedSuiteIndex = index;
    _selectedResult = null;
    _selectedSubplan = null;
    _dutSerial = null;
    _tabletSerial = null;
    _selectedVenvIndex = null;
    if (_suites[index].type == 'CTS Verifier') {
      _runMode = RunMode.install;
      _verifierAction = VerifierAction.installApks;
    } else if (_runMode == RunMode.install) {
      _runMode = RunMode.newRun;
    }
    _scanResultsAndSubplans();
    notifyListeners();
  }

  void setRunMode(RunMode mode) {
    _runMode = mode;
    notifyListeners();
  }

  void toggleDevice(int index, bool value) {
    _devices[index].selected = value;
    notifyListeners();
  }

  void setVerifierAction(VerifierAction action) {
    _verifierAction = action;
    notifyListeners();
  }

  void setDutSerial(String? serial) {
    _dutSerial = serial;
    if (_tabletSerial == serial) _tabletSerial = null;
    notifyListeners();
  }

  void setTabletSerial(String? serial) {
    _tabletSerial = serial;
    if (_dutSerial == serial) _dutSerial = null;
    notifyListeners();
  }

  void setSelectedVenv(int? index) {
    _selectedVenvIndex = index;
    notifyListeners();
  }

  void setSelectedResult(String? value) {
    _selectedResult = value;
    notifyListeners();
  }

  void setSelectedSubplan(String? value) {
    _selectedSubplan = value;
    notifyListeners();
  }

  void clearOutput() {
    _outputBuffer.clear();
    notifyListeners();
  }

  void stopRun() {
    _cancelled = true;
    _activeProcess?.kill();
    _activeProcess = null;
    _appendOutput('\n[Execução cancelada pelo usuário]\n');
    _running = false;
    notifyListeners();
  }

  void _appendOutput(String data) {
    _outputBuffer.write(data);
    notifyListeners();
  }

  void _scanResultsAndSubplans() {
    final suite = selectedSuite;
    if (suite == null) {
      _availableResults = [];
      _availableSubplans = [];
      return;
    }
    _availableResults = _resultService.scanResultDirs(suite.path);
    _availableSubplans = _resultService.scanSubplans(suite.path);
  }

  void setCameraId(String id) {
    _cameraId = id;
    notifyListeners();
  }

  Future<void> startRun({
    required String module,
    required String extraArgs,
    String? scenes,
  }) async {
    final suite = selectedSuite;
    if (suite == null) return;

    final List<String> selectedSerials;
    if (isCtsVerifier) {
      if (_dutSerial == null) return;
      selectedSerials = [_dutSerial!];
    } else {
      selectedSerials = _devices
          .where((d) => d.selected && d.isAvailable)
          .map((d) => d.serial)
          .toList();
      if (selectedSerials.isEmpty) return;
    }

    _running = true;
    _cancelled = false;
    _outputBuffer.clear();
    notifyListeners();

    try {
      if (isCtsVerifier) {
        switch (_verifierAction) {
          case VerifierAction.installApks:
            await _runnerService.installVerifier(
              suite: suite,
              serials: selectedSerials,
              onOutput: _appendOutput,
              onProcessChanged: (p) => _activeProcess = p,
              isCancelled: () => _cancelled,
            );
          case VerifierAction.cameraIts:
            if (_tabletSerial == null || selectedVenv == null) break;
            await _runnerService.runCameraIts(
              suite: suite,
              dutSerial: _dutSerial!,
              tabletSerial: _tabletSerial!,
              venvPath: selectedVenv!.path,
              onOutput: _appendOutput,
              onProcessChanged: (p) => _activeProcess = p,
              isCancelled: () => _cancelled,
              scenes: scenes,
              cameraId: _cameraId,
            );
          case VerifierAction.cameraWebcamTest:
            // TODO: implementar cameraWebcamTest
            _appendOutput('[AVISO] Camera Webcam Test ainda não implementado.\n');
        }
      } else {
        _activeProcess = await _runnerService.executeStream(
          suite: suite,
          serials: selectedSerials,
          mode: _runMode,
          onOutput: _appendOutput,
          selectedResult: _selectedResult,
          selectedSubplan: _selectedSubplan,
          module: module,
          extraArgs: extraArgs,
        );

        final exitCode = await _activeProcess!.exitCode;
        _appendOutput('\n[Processo finalizado com código $exitCode]\n');
      }
    } catch (e) {
      _appendOutput('Erro ao executar: $e\n');
    }

    _activeProcess = null;
    _running = false;
    notifyListeners();
  }
}
