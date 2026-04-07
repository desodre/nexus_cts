import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:nexus_cts/models/suite_entry.dart';
import 'package:nexus_cts/models/test_result.dart';
import 'package:xml/xml.dart';

/// Executada em isolate separado para não bloquear a UI.
List<SuiteResult> _fetchResultsSync(List<Map<String, dynamic>> suiteMaps) {
  final results = <SuiteResult>[];

  for (final map in suiteMaps) {
    final suite = SuiteEntry.fromJson(map);
    final basePath = suite.normalizedPath;
    final resultsDir = Directory('$basePath/results');
    if (!resultsDir.existsSync()) continue;

    for (final entity in resultsDir.listSync()) {
      if (entity is! Directory) continue;
      final testResult = File('${entity.path}/test_result.xml');
      if (testResult.existsSync()) {
        final parsed = _parseTestResult(testResult);
        results.add(SuiteResult(
          suiteName: '${suite.name} (${suite.type})',
          suiteType: suite.type,
          folderName: entity.path.split('/').last,
          fullPath: testResult.path,
          modified: testResult.lastModifiedSync(),
          summary: parsed.$1,
          deviceSerial: parsed.$2,
          buildFingerprint: parsed.$3,
          suitePlan: parsed.$4,
          startTime: parsed.$5,
        ));
      }
    }
  }

  results.sort((a, b) => b.modified.compareTo(a.modified));
  return results;
}

(TestSummary?, String?, String?, String?, String?) _parseTestResult(
    File file) {
  try {
    final content = file.readAsStringSync();
    final doc = XmlDocument.parse(content);
    final root = doc.rootElement;

    TestSummary? summary;
    final summaryEl = root.findElements('Summary').firstOrNull;
    if (summaryEl != null) {
      summary = TestSummary(
        passed: int.tryParse(summaryEl.getAttribute('pass') ?? '') ?? 0,
        failed: int.tryParse(summaryEl.getAttribute('failed') ?? '') ?? 0,
        modulesDone:
            int.tryParse(summaryEl.getAttribute('modules_done') ?? '') ?? 0,
        modulesTotal:
            int.tryParse(summaryEl.getAttribute('modules_total') ?? '') ?? 0,
      );
    }

    String? serial;
    String? fingerprint;
    final buildEl = root.findElements('Build').firstOrNull;
    if (buildEl != null) {
      serial = buildEl.getAttribute('device_serial') ??
          buildEl.getAttribute('deviceSerial');
      fingerprint = buildEl.getAttribute('build_fingerprint') ??
          buildEl.getAttribute('buildFingerprint');
    }

    final plan =
        root.getAttribute('suite_plan') ?? root.getAttribute('plan');
    final startTime =
        root.getAttribute('start_display') ?? root.getAttribute('start');

    return (summary, serial, fingerprint, plan, startTime);
  } catch (_) {
    return (null, null, null, null, null);
  }
}

class SuiteResultService {
  Future<List<SuiteResult>> fetchResults(List<SuiteEntry> suites) async {
    final configured = suites.where((s) => s.path.isNotEmpty).toList();
    if (configured.isEmpty) return [];

    final suiteMaps = configured.map((s) => s.toJson()).toList();
    return compute(_fetchResultsSync, suiteMaps);
  }

  List<String> scanResultDirs(String suitePath) {
    final basePath = suitePath.replaceAll(RegExp(r'/+$'), '');
    final resultsDir = Directory('$basePath/results');
    final results = <String>[];
    if (resultsDir.existsSync()) {
      for (final entity in resultsDir.listSync()) {
        if (entity is Directory) {
          results.add(entity.path.split('/').last);
        }
      }
    }
    results.sort((a, b) => b.compareTo(a));
    return results;
  }

  List<String> scanSubplans(String suitePath) {
    final basePath = suitePath.replaceAll(RegExp(r'/+$'), '');
    final subplansDir = Directory('$basePath/subplans');
    final subplans = <String>[];
    if (subplansDir.existsSync()) {
      for (final entity in subplansDir.listSync()) {
        if (entity is File && entity.path.endsWith('.xml')) {
          final name = entity.path.split('/').last;
          subplans.add(name.replaceAll('.xml', ''));
        }
      }
    }
    subplans.sort();
    return subplans;
  }
}
