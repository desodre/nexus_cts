import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:nexus_cts/models/adb_device.dart';
import 'package:nexus_cts/models/run_mode.dart';
import 'package:nexus_cts/models/suite_entry.dart';
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

  // ── Computed ──
  bool get canRun {
    if (_selectedSuiteIndex == null) return false;
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

  Future<void> startRun({
    required String module,
    required String extraArgs,
  }) async {
    final suite = selectedSuite;
    final selectedSerials = _devices
        .where((d) => d.selected && d.isAvailable)
        .map((d) => d.serial)
        .toList();

    if (suite == null || selectedSerials.isEmpty) return;

    _running = true;
    _outputBuffer.clear();
    notifyListeners();

    try {
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
    } catch (e) {
      _appendOutput('Erro ao executar: $e\n');
    }

    _activeProcess = null;
    _running = false;
    notifyListeners();
  }
}
