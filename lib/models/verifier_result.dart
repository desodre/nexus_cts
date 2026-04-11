/// Modelo de execução importada do CTS Verifier.
class VerifierExecution {
  final int? id;
  final String xmlPath;
  final String? deviceSerial;
  final String? buildFingerprint;
  final String? suitePlan;
  final String? suiteVersion;
  final String? startTime;
  final int passed;
  final int failed;
  final int notExecuted;
  final int modulesDone;
  final int modulesTotal;
  final DateTime importedAt;

  VerifierExecution({
    this.id,
    required this.xmlPath,
    this.deviceSerial,
    this.buildFingerprint,
    this.suitePlan,
    this.suiteVersion,
    this.startTime,
    required this.passed,
    required this.failed,
    required this.notExecuted,
    required this.modulesDone,
    required this.modulesTotal,
    required this.importedAt,
  });

  int get total => passed + failed + notExecuted;
  double get passRate => (passed + failed) > 0 ? (passed / (passed + failed)) * 100 : 0;

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'xml_path': xmlPath,
        'device_serial': deviceSerial,
        'build_fingerprint': buildFingerprint,
        'suite_plan': suitePlan,
        'suite_version': suiteVersion,
        'start_time': startTime,
        'passed': passed,
        'failed': failed,
        'not_executed': notExecuted,
        'modules_done': modulesDone,
        'modules_total': modulesTotal,
        'imported_at': importedAt.toIso8601String(),
      };

  factory VerifierExecution.fromMap(Map<String, dynamic> m) => VerifierExecution(
        id: m['id'] as int?,
        xmlPath: m['xml_path'] as String? ?? '',
        deviceSerial: m['device_serial'] as String?,
        buildFingerprint: m['build_fingerprint'] as String?,
        suitePlan: m['suite_plan'] as String?,
        suiteVersion: m['suite_version'] as String?,
        startTime: m['start_time'] as String?,
        passed: m['passed'] as int? ?? 0,
        failed: m['failed'] as int? ?? 0,
        notExecuted: m['not_executed'] as int? ?? 0,
        modulesDone: m['modules_done'] as int? ?? 0,
        modulesTotal: m['modules_total'] as int? ?? 0,
        importedAt: DateTime.tryParse(m['imported_at'] as String? ?? '') ??
            DateTime.now(),
      );
}

/// Módulo individual de uma execução CTS Verifier.
class VerifierModule {
  final int? id;
  final int executionId;
  final String name;
  final String abi;
  final bool done;
  final int passed;
  final int failed;
  final int totalTests;
  final String? runtimeMs;
  final String? itsScenes; // JSON-encoded list of ITS scene names

  VerifierModule({
    this.id,
    required this.executionId,
    required this.name,
    required this.abi,
    required this.done,
    required this.passed,
    required this.failed,
    required this.totalTests,
    this.runtimeMs,
    this.itsScenes,
  });

  bool get hasCameraItsFailures =>
      name.contains('CameraITS') && failed > 0;

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'execution_id': executionId,
        'name': name,
        'abi': abi,
        'done': done ? 1 : 0,
        'passed': passed,
        'failed': failed,
        'total_tests': totalTests,
        'runtime_ms': runtimeMs,
        'its_scenes': itsScenes,
      };

  factory VerifierModule.fromMap(Map<String, dynamic> m) => VerifierModule(
        id: m['id'] as int?,
        executionId: m['execution_id'] as int? ?? 0,
        name: m['name'] as String? ?? '',
        abi: m['abi'] as String? ?? '',
        done: (m['done'] as int? ?? 0) == 1,
        passed: m['passed'] as int? ?? 0,
        failed: m['failed'] as int? ?? 0,
        totalTests: m['total_tests'] as int? ?? 0,
        runtimeMs: m['runtime_ms'] as String?,
        itsScenes: m['its_scenes'] as String?,
      );
}

/// Caso de teste individual de um módulo.
class VerifierTestCase {
  final int? id;
  final int moduleId;
  final String name;
  final String result; // pass, fail, not_executed
  final String? message;
  final String? stacktrace;

  VerifierTestCase({
    this.id,
    required this.moduleId,
    required this.name,
    required this.result,
    this.message,
    this.stacktrace,
  });

  bool get isFail => result == 'fail';

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'module_id': moduleId,
        'name': name,
        'result': result,
        'message': message,
        'stacktrace': stacktrace,
      };

  factory VerifierTestCase.fromMap(Map<String, dynamic> m) => VerifierTestCase(
        id: m['id'] as int?,
        moduleId: m['module_id'] as int? ?? 0,
        name: m['name'] as String? ?? '',
        result: m['result'] as String? ?? 'not_executed',
        message: m['message'] as String?,
        stacktrace: m['stacktrace'] as String?,
      );
}
