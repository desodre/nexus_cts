/// Informações de um dispositivo extraídas do Controller Info.
class ItsDeviceInfo {
  final String? serial;
  final String? model;
  final String? buildFingerprint;
  final String? buildId;
  final String? buildProduct;
  final String? buildType;
  final String? sdkVersion;
  final String? characteristics;

  ItsDeviceInfo({
    this.serial,
    this.model,
    this.buildFingerprint,
    this.buildId,
    this.buildProduct,
    this.buildType,
    this.sdkVersion,
    this.characteristics,
  });
}

/// Detalhes completos extraídos do test_summary.yaml.
class ItsTestDetail {
  final String? testName;
  final String? testClass;
  final String? result;
  final String? details;
  final String? stacktrace;
  final String? terminationSignal;
  final String? signature;
  final int? beginTime;
  final int? endTime;
  final List<ItsDeviceInfo> devices;
  final int? errorCount;
  final int? executedCount;
  final int? failedCount;
  final int? passedCount;
  final int? skippedCount;

  ItsTestDetail({
    this.testName,
    this.testClass,
    this.result,
    this.details,
    this.stacktrace,
    this.terminationSignal,
    this.signature,
    this.beginTime,
    this.endTime,
    this.devices = const [],
    this.errorCount,
    this.executedCount,
    this.failedCount,
    this.passedCount,
    this.skippedCount,
  });

  Duration? get duration {
    if (beginTime != null && endTime != null) {
      return Duration(milliseconds: endTime! - beginTime!);
    }
    return null;
  }
}

/// Resultado individual de um teste Camera ITS.
class ItsTestEntry {
  final String testName;
  final String result; // PASS, FAIL, SKIP
  final ItsTestDetail? detail;

  ItsTestEntry({required this.testName, required this.result, this.detail});

  bool get passed => result == 'PASS';
  bool get failed => result == 'FAIL';
  bool get skipped => result == 'SKIP';
}

/// Resultado de uma scene (ex: scene0) de uma câmera.
class ItsSceneResult {
  final String scene;
  final String camera;
  final List<ItsTestEntry> tests;

  ItsSceneResult({
    required this.scene,
    required this.camera,
    required this.tests,
  });

  int get passed => tests.where((t) => t.passed).length;
  int get failed => tests.where((t) => t.failed).length;
  int get skipped => tests.where((t) => t.skipped).length;
  int get total => tests.length;
}

/// Resultado completo de uma execução Camera ITS (uma pasta /tmp/CameraITS_*).
class CameraItsResult {
  final String folderName;
  final String fullPath;
  final DateTime modified;
  final String? dutSerial;
  final String? buildFingerprint;
  final List<ItsSceneResult> scenes;

  CameraItsResult({
    required this.folderName,
    required this.fullPath,
    required this.modified,
    this.dutSerial,
    this.buildFingerprint,
    required this.scenes,
  });

  int get totalPassed => scenes.fold(0, (s, r) => s + r.passed);
  int get totalFailed => scenes.fold(0, (s, r) => s + r.failed);
  int get totalSkipped => scenes.fold(0, (s, r) => s + r.skipped);
  int get totalTests => scenes.fold(0, (s, r) => s + r.total);
  double get passRate => totalTests - totalSkipped > 0
      ? (totalPassed / (totalTests - totalSkipped)) * 100
      : 0;
}
