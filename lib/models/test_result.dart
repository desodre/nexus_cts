class TestSummary {
  final int passed;
  final int failed;
  final int modulesDone;
  final int modulesTotal;

  TestSummary({
    required this.passed,
    required this.failed,
    required this.modulesDone,
    required this.modulesTotal,
  });

  int get total => passed + failed;
  double get passRate => total > 0 ? (passed / total) * 100 : 0;
}

class SuiteResult {
  final String suiteName;
  final String suiteType;
  final String folderName;
  final String fullPath;
  final DateTime modified;
  final TestSummary? summary;
  final String? deviceSerial;
  final String? buildFingerprint;
  final String? suitePlan;
  final String? startTime;

  SuiteResult({
    required this.suiteName,
    required this.suiteType,
    required this.folderName,
    required this.fullPath,
    required this.modified,
    this.summary,
    this.deviceSerial,
    this.buildFingerprint,
    this.suitePlan,
    this.startTime,
  });
}
