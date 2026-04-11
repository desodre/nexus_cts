import 'package:flutter/foundation.dart';
import 'package:nexus_cts/models/adb_device.dart';
import 'package:nexus_cts/models/camera_its_result.dart';
import 'package:nexus_cts/models/suite_entry.dart';
import 'package:nexus_cts/models/test_result.dart';
import 'package:nexus_cts/services/adb_service.dart';
import 'package:nexus_cts/services/camera_its_result_service.dart';
import 'package:nexus_cts/services/suite_result_service.dart';

class HomeViewModel extends ChangeNotifier {
  final AdbService _adbService;
  final SuiteResultService _resultService;
  final CameraItsResultService _itsResultService;

  HomeViewModel({
    AdbService? adbService,
    SuiteResultService? resultService,
    CameraItsResultService? itsResultService,
  }) : _adbService = adbService ?? AdbService(),
       _resultService = resultService ?? SuiteResultService(),
       _itsResultService = itsResultService ?? CameraItsResultService();

  // ── Devices ──
  List<AdbDevice> _devices = [];
  List<AdbDevice> get devices => _devices;

  bool _loadingDevices = false;
  bool get loadingDevices => _loadingDevices;

  String? _devicesError;
  String? get devicesError => _devicesError;

  // ── Results ──
  List<SuiteResult> _results = [];
  List<SuiteResult> get results => _results;

  Map<String, List<SuiteResult>> _groupedResults = {};
  Map<String, List<SuiteResult>> get groupedResults => _groupedResults;

  bool _loadingResults = false;
  bool get loadingResults => _loadingResults;

  bool _noSuiteConfigured = false;
  bool get noSuiteConfigured => _noSuiteConfigured;

  // ── Camera ITS ──
  List<CameraItsResult> _itsResults = [];
  List<CameraItsResult> get itsResults => _itsResults;

  bool _loadingItsResults = false;
  bool get loadingItsResults => _loadingItsResults;

  void init() {
    fetchDevices();
    fetchResults();
    fetchItsResults();
  }

  Future<void> fetchItsResults() async {
    _loadingItsResults = true;
    notifyListeners();

    _itsResults = await _itsResultService.fetchResults();

    _loadingItsResults = false;
    notifyListeners();
  }

  Future<void> fetchDevices() async {
    _loadingDevices = true;
    _devicesError = null;
    notifyListeners();

    try {
      _devices = await _adbService.fetchDevices();
    } catch (e) {
      _devicesError = 'Erro ao executar adb: $e';
    }

    _loadingDevices = false;
    notifyListeners();
  }

  Future<void> fetchResults() async {
    _loadingResults = true;
    _noSuiteConfigured = false;
    notifyListeners();

    final suites = await SuiteStorage.load();
    final configured = suites.where((s) => s.path.isNotEmpty).toList();

    if (configured.isEmpty) {
      _loadingResults = false;
      _noSuiteConfigured = true;
      notifyListeners();
      return;
    }

    _results = await _resultService.fetchResults(configured);

    final grouped = <String, List<SuiteResult>>{};
    for (final r in _results) {
      grouped.putIfAbsent(r.suiteName, () => []).add(r);
    }
    _groupedResults = grouped;

    _loadingResults = false;
    notifyListeners();
  }

  List<String> get orderedGroupKeys {
    const typeOrder = [
      'CTS',
      'CTS-on-GSI',
      'VTS',
      'GTS',
      'GTS-Interactive',
      'GTS-Root',
      'STS',
      'CTS Verifier',
    ];
    return _groupedResults.keys.toList()..sort((a, b) {
      final ta = _groupedResults[a]!.first.suiteType;
      final tb = _groupedResults[b]!.first.suiteType;
      final ia = typeOrder.indexOf(ta);
      final ib = typeOrder.indexOf(tb);
      final oa = ia == -1 ? typeOrder.length : ia;
      final ob = ib == -1 ? typeOrder.length : ib;
      if (oa != ob) return oa.compareTo(ob);
      return a.compareTo(b);
    });
  }
}
