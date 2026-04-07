import 'package:flutter/foundation.dart';
import 'package:nexus_cts/models/adb_device.dart';
import 'package:nexus_cts/models/suite_entry.dart';
import 'package:nexus_cts/models/test_result.dart';
import 'package:nexus_cts/services/adb_service.dart';
import 'package:nexus_cts/services/suite_result_service.dart';

class HomeViewModel extends ChangeNotifier {
  final AdbService _adbService;
  final SuiteResultService _resultService;

  HomeViewModel({
    AdbService? adbService,
    SuiteResultService? resultService,
  })  : _adbService = adbService ?? AdbService(),
        _resultService = resultService ?? SuiteResultService();

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

  void init() {
    fetchDevices();
    fetchResults();
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
    const typeOrder = ['CTS', 'VTS', 'GTS'];
    return _groupedResults.keys.toList()
      ..sort((a, b) {
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
