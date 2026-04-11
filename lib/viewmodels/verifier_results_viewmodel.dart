import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'package:nexus_cts/data/verifier_database.dart';
import 'package:nexus_cts/models/verifier_result.dart';
import 'package:nexus_cts/services/verifier_parser_service.dart';

class VerifierResultsViewModel extends ChangeNotifier {
  final VerifierParserService _parser;

  VerifierResultsViewModel({VerifierParserService? parser})
      : _parser = parser ?? VerifierParserService();

  // ── Executions ──
  List<VerifierExecution> _executions = [];
  List<VerifierExecution> get executions => _executions;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  bool _importing = false;
  bool get importing => _importing;

  // ── Detalhes da execução selecionada ──
  VerifierExecution? _selectedExecution;
  VerifierExecution? get selectedExecution => _selectedExecution;

  List<VerifierModule> _allModules = [];
  List<VerifierModule> get modules => _filteredModules;

  // ── Test cases agrupados por módulo ──
  Map<int, List<VerifierTestCase>> _testCasesByModule = {};

  List<VerifierTestCase> testCasesForModule(int moduleId) {
    var list = _testCasesByModule[moduleId] ?? [];
    if (_showOnlyFailed) {
      list = list.where((tc) => tc.isFail).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((tc) => tc.name.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  // ── Filtros ──
  bool _showOnlyFailed = false;
  bool get showOnlyFailed => _showOnlyFailed;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  // ── Camera ITS ──
  List<String> _cameraItsScenes = [];
  List<String> get cameraItsScenes => _cameraItsScenes;

  String? _cameraItsLogPath;
  String? get cameraItsLogPath => _cameraItsLogPath;

  // ── ITS scenes do XML ──
  List<String> _itsXmlScenes = [];
  List<String> get itsXmlScenes => _itsXmlScenes;

  // ── Computed filtered lists ──
  List<VerifierModule> get _filteredModules {
    var list = _allModules;
    if (_showOnlyFailed) {
      list = list.where((m) => m.failed > 0).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((m) {
        if (m.name.toLowerCase().contains(q)) return true;
        final tcs = _testCasesByModule[m.id] ?? [];
        return tcs.any((tc) => tc.name.toLowerCase().contains(q));
      }).toList();
    }
    return list;
  }

  // ── Init ──
  void init() {
    fetchExecutions();
  }

  Future<void> fetchExecutions() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _executions = await VerifierDatabase.allExecutions();
    } catch (e) {
      _error = 'Erro ao carregar execuções: $e';
    }

    _loading = false;
    notifyListeners();
  }

  // ── Importar XML ──
  Future<void> pickAndImportXml() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xml'],
      dialogTitle: 'Selecionar test_result.xml',
    );

    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;

    _importing = true;
    _error = null;
    notifyListeners();

    try {
      await _parser.importXml(path);
      await fetchExecutions();
    } catch (e) {
      _error = 'Erro ao importar: $e';
    }

    _importing = false;
    notifyListeners();
  }

  // ── Selecionar execução ──
  Future<void> selectExecution(VerifierExecution exec) async {
    _selectedExecution = exec;
    _testCasesByModule = {};
    _cameraItsScenes = [];
    _cameraItsLogPath = null;
    _itsXmlScenes = [];
    _searchQuery = '';
    notifyListeners();

    await _loadModules();
    _extractItsScenes();
  }

  void clearSelection() {
    _selectedExecution = null;
    _allModules = [];
    _testCasesByModule = {};
    _cameraItsScenes = [];
    _cameraItsLogPath = null;
    _itsXmlScenes = [];
    _searchQuery = '';
    notifyListeners();
  }

  Future<void> _loadModules() async {
    if (_selectedExecution?.id == null) return;
    final id = _selectedExecution!.id!;
    _allModules = await VerifierDatabase.modulesFor(id);
    _testCasesByModule = await VerifierDatabase.allTestCasesGrouped(id);
    notifyListeners();
  }

  void toggleFailedFilter() {
    _showOnlyFailed = !_showOnlyFailed;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // ── Deletar execução ──
  Future<void> deleteExecution(int id) async {
    await VerifierDatabase.deleteExecution(id);
    if (_selectedExecution?.id == id) {
      clearSelection();
    }
    await fetchExecutions();
  }

  // ── Camera ITS: selecionar pasta de logs ──
  Future<void> pickCameraItsLogs() async {
    final result = await FilePicker.getDirectoryPath(
      dialogTitle: 'Selecionar pasta CameraITS (ex: /tmp/CameraITS_*)',
    );

    if (result == null) return;
    _cameraItsLogPath = result;
    _cameraItsScenes = _scanFailedScenes(result);
    notifyListeners();
  }

  List<String> _scanFailedScenes(String basePath) {
    final failed = <String>[];
    final dir = Directory(basePath);
    if (!dir.existsSync()) return failed;

    for (final camDir in dir.listSync().whereType<Directory>()) {
      final camName = camDir.path.split('/').last;
      if (!camName.startsWith('cam_id_')) continue;

      for (final sceneDir in camDir.listSync().whereType<Directory>()) {
        final sceneName = sceneDir.path.split('/').last;
        final summaryFile =
            File('${sceneDir.path}/scene_test_summary.txt');
        if (!summaryFile.existsSync()) continue;

        final content = summaryFile.readAsStringSync();
        if (content.contains('FAIL')) {
          failed.add('$camName/$sceneName');
        }
      }
    }

    failed.sort();
    return failed;
  }

  /// Extrai scenes do ITS a partir dos módulos carregados (campo its_scenes).
  void _extractItsScenes() {
    final scenes = <String>[];
    for (final mod in _allModules) {
      if (mod.itsScenes != null && mod.itsScenes!.isNotEmpty) {
        try {
          final list = (jsonDecode(mod.itsScenes!) as List).cast<String>();
          scenes.addAll(list);
        } catch (_) {}
      }
    }
    scenes.sort();
    _itsXmlScenes = scenes;
  }

  bool get hasCameraItsFailures =>
      _allModules.any((m) => m.hasCameraItsFailures);

  bool get hasItsScenes => _itsXmlScenes.isNotEmpty;
}
