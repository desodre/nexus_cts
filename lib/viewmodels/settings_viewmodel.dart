import 'package:flutter/foundation.dart';
import 'package:nexus_cts/models/suite_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsViewModel extends ChangeNotifier {
  List<SuiteEntry> _suites = [];
  List<SuiteEntry> get suites => _suites;

  bool _autoRetest = true;
  bool get autoRetest => _autoRetest;

  bool _rebootOnFail = false;
  bool get rebootOnFail => _rebootOnFail;

  bool _loading = true;
  bool get loading => _loading;

  static const suiteTypes = ['CTS', 'VTS', 'GTS'];

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final suites = await SuiteStorage.load();
    _suites = suites;
    _autoRetest = prefs.getBool('auto_retest') ?? true;
    _rebootOnFail = prefs.getBool('reboot_on_fail') ?? false;
    _loading = false;
    notifyListeners();
  }

  Future<void> _saveSuites() async {
    await SuiteStorage.save(_suites);
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  void addSuite() {
    _suites.add(SuiteEntry(name: '', type: 'CTS', path: ''));
    notifyListeners();
  }

  void removeSuite(int index) {
    _suites.removeAt(index);
    _saveSuites();
    notifyListeners();
  }

  void updateSuiteName(int index, String value) {
    _suites[index].name = value;
    _saveSuites();
    notifyListeners();
  }

  void updateSuiteType(int index, String value) {
    _suites[index].type = value;
    _saveSuites();
    notifyListeners();
  }

  void updateSuitePath(int index, String value) {
    _suites[index].path = value;
    _saveSuites();
  }

  void setAutoRetest(bool value) {
    _autoRetest = value;
    _saveBool('auto_retest', value);
    notifyListeners();
  }

  void setRebootOnFail(bool value) {
    _rebootOnFail = value;
    _saveBool('reboot_on_fail', value);
    notifyListeners();
  }
}
