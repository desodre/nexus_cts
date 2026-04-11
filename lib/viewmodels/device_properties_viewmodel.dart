import 'package:flutter/foundation.dart';
import 'package:nexus_cts/models/adb_device.dart';
import 'package:nexus_cts/services/adb_service.dart';

class DevicePropertiesViewModel extends ChangeNotifier {
  final AdbService _adbService;

  DevicePropertiesViewModel({AdbService? adbService})
    : _adbService = adbService ?? AdbService();

  // ── Devices ──
  List<AdbDevice> _devices = [];
  List<AdbDevice> get devices => _devices;

  bool _loadingDevices = false;
  bool get loadingDevices => _loadingDevices;

  String? _devicesError;
  String? get devicesError => _devicesError;

  // ── Expanded device ──
  String? _expandedSerial;
  String? get expandedSerial => _expandedSerial;

  // ── Properties cache: serial → props ──
  final Map<String, Map<String, String>> _propsCache = {};
  Map<String, String>? propsFor(String serial) => _propsCache[serial];

  // ── Fastboot vars cache ──
  final Map<String, Map<String, String>> _fastbootCache = {};
  Map<String, String>? fastbootFor(String serial) => _fastbootCache[serial];

  // ── Loading/error per device ──
  final Set<String> _loadingProps = {};
  bool isLoadingProps(String serial) => _loadingProps.contains(serial);

  final Map<String, String> _propsErrors = {};
  String? propsErrorFor(String serial) => _propsErrors[serial];

  final Set<String> _loadingFastboot = {};
  bool isLoadingFastboot(String serial) => _loadingFastboot.contains(serial);

  // ── Search ──
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Map<String, String> filteredProps(String serial) {
    final props = _propsCache[serial];
    if (props == null) return {};
    if (_searchQuery.isEmpty) return props;
    final q = _searchQuery.toLowerCase();
    return Map.fromEntries(
      props.entries.where(
        (e) =>
            e.key.toLowerCase().contains(q) ||
            e.value.toLowerCase().contains(q),
      ),
    );
  }

  Map<String, String> filteredFastboot(String serial) {
    final vars = _fastbootCache[serial];
    if (vars == null) return {};
    if (_searchQuery.isEmpty) return vars;
    final q = _searchQuery.toLowerCase();
    return Map.fromEntries(
      vars.entries.where(
        (e) =>
            e.key.toLowerCase().contains(q) ||
            e.value.toLowerCase().contains(q),
      ),
    );
  }

  // ── Init ──
  void init() {
    fetchDevices();
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

  void toggleDevice(String serial) {
    if (_expandedSerial == serial) {
      _expandedSerial = null;
      _searchQuery = '';
    } else {
      _expandedSerial = serial;
      _searchQuery = '';
      if (!_propsCache.containsKey(serial)) {
        _fetchProps(serial);
      }
    }
    notifyListeners();
  }

  Future<void> _fetchProps(String serial) async {
    _loadingProps.add(serial);
    _propsErrors.remove(serial);
    notifyListeners();

    try {
      final props = await _adbService.fetchDeviceProperties(serial);
      _propsCache[serial] = Map.fromEntries(
        props.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
      );
    } catch (e) {
      _propsErrors[serial] = '$e';
    }

    _loadingProps.remove(serial);
    notifyListeners();
  }

  Future<void> refreshProps(String serial) async {
    _propsCache.remove(serial);
    _fastbootCache.remove(serial);
    await _fetchProps(serial);
  }

  Future<void> fetchFastbootVars(String serial) async {
    if (_fastbootCache.containsKey(serial)) return;

    _loadingFastboot.add(serial);
    notifyListeners();

    try {
      _adbService.adbRebootDevice(serial, .bootloader);
      final vars = await _adbService.fetchFastbootVars(serial);
      _fastbootCache[serial] = Map.fromEntries(
        vars.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
      );
      _adbService.fastbootRebootDevice(serial, .normal);
    } catch (_) {
      // Fastboot pode falhar se device não está em bootloader — silencioso
    }

    _loadingFastboot.remove(serial);
    notifyListeners();
  }
}
