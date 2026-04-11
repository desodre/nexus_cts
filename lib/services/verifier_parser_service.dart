import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';

import 'package:nexus_cts/data/verifier_database.dart';
import 'package:nexus_cts/models/verifier_result.dart';

const _verifierPrefix = 'com.android.cts.verifier.';

/// Importa um test_result.xml do CTS Verifier para o banco SQLite.
class VerifierParserService {
  Future<int> importXml(String xmlPath) async {
    final file = File(xmlPath);
    if (!file.existsSync()) {
      throw FileSystemException('Arquivo não encontrado', xmlPath);
    }

    final parsed = await compute(_parseXml, file.readAsStringSync());

    final execId = await VerifierDatabase.insertExecution(
      VerifierExecution(
        xmlPath: xmlPath,
        deviceSerial: parsed.deviceSerial,
        buildFingerprint: parsed.buildFingerprint,
        suitePlan: parsed.suitePlan,
        suiteVersion: parsed.suiteVersion,
        startTime: parsed.startTime,
        passed: parsed.passed,
        failed: parsed.failed,
        notExecuted: parsed.notExecuted,
        modulesDone: parsed.modulesDone,
        modulesTotal: parsed.modulesTotal,
        importedAt: DateTime.now(),
      ),
    );

    for (final mod in parsed.modules) {
      final modId = await VerifierDatabase.insertModule(
        VerifierModule(
          executionId: execId,
          name: mod.name,
          abi: mod.abi,
          done: mod.done,
          passed: mod.passed,
          failed: mod.failed,
          totalTests: mod.totalTests,
          runtimeMs: mod.runtimeMs,
          itsScenes: mod.itsScenes,
        ),
      );

      if (mod.testCases.isNotEmpty) {
        await VerifierDatabase.insertTestCasesBatch(
          mod.testCases
              .map((tc) => VerifierTestCase(
                    moduleId: modId,
                    name: tc.name,
                    result: tc.result,
                    message: tc.message,
                    stacktrace: tc.stacktrace,
                  ))
              .toList(),
        );
      }
    }

    return execId;
  }
}

// ── Estrutura intermediária para isolate ──

class _ParsedExecution {
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
  final List<_ParsedModule> modules;

  _ParsedExecution({
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
    required this.modules,
  });
}

class _ParsedModule {
  final String name;
  final String abi;
  final bool done;
  final int passed;
  final int failed;
  final int totalTests;
  final String? runtimeMs;
  final String? itsScenes;
  final List<_ParsedTestCase> testCases;

  _ParsedModule({
    required this.name,
    required this.abi,
    required this.done,
    required this.passed,
    required this.failed,
    required this.totalTests,
    this.runtimeMs,
    this.itsScenes,
    required this.testCases,
  });
}

class _ParsedTestCase {
  final String name;
  final String result;
  final String? message;
  final String? stacktrace;

  _ParsedTestCase({
    required this.name,
    required this.result,
    this.message,
    this.stacktrace,
  });
}

/// Extrai a categoria do pacote do nome completo do teste.
/// Ex: "com.android.cts.verifier.audio.AudioAEC" → "audio"
String _extractCategory(String fullName) {
  final stripped = fullName.startsWith(_verifierPrefix)
      ? fullName.substring(_verifierPrefix.length)
      : fullName;
  final dotIndex = stripped.indexOf('.');
  if (dotIndex > 0) return stripped.substring(0, dotIndex);
  return stripped;
}

/// Remove o prefixo do verifier do nome do teste.
String _stripPrefix(String fullName) {
  return fullName.startsWith(_verifierPrefix)
      ? fullName.substring(_verifierPrefix.length)
      : fullName;
}

/// Executado em isolate — parse puro sem I/O de banco.
_ParsedExecution _parseXml(String xmlContent) {
  final doc = XmlDocument.parse(xmlContent);
  final root = doc.rootElement;

  // Build info
  String? serial;
  String? fingerprint;
  final buildEl = root.findElements('Build').firstOrNull;
  if (buildEl != null) {
    serial = buildEl.getAttribute('device_serial') ??
        buildEl.getAttribute('deviceSerial') ??
        buildEl.getAttribute('build_serial');
    fingerprint = buildEl.getAttribute('build_fingerprint') ??
        buildEl.getAttribute('buildFingerprint');
  }

  // Summary
  int passed = 0, failed = 0, notExecuted = 0, modulesDone = 0, modulesTotal = 0;
  final summaryEl = root.findElements('Summary').firstOrNull;
  if (summaryEl != null) {
    passed = int.tryParse(summaryEl.getAttribute('pass') ?? '') ?? 0;
    failed = int.tryParse(summaryEl.getAttribute('failed') ?? '') ?? 0;
    notExecuted =
        int.tryParse(summaryEl.getAttribute('not_executed') ?? '') ?? 0;
    modulesDone =
        int.tryParse(summaryEl.getAttribute('modules_done') ?? '') ?? 0;
    modulesTotal =
        int.tryParse(summaryEl.getAttribute('modules_total') ?? '') ?? 0;
  }

  final plan =
      root.getAttribute('suite_plan') ?? root.getAttribute('plan');
  final version = root.getAttribute('suite_version');
  final startTime =
      root.getAttribute('start_display') ?? root.getAttribute('start');

  // Coletar todos os testes e agrupar por categoria
  final categoryTests = <String, List<_ParsedTestCase>>{};
  // ITS scenes por categoria (só para camera.its)
  final itsScenesByCategory = <String, Set<String>>{};

  for (final moduleEl in root.findElements('Module')) {
    for (final testCaseEl in moduleEl.findElements('TestCase')) {
      for (final testEl in testCaseEl.findElements('Test')) {
        final testName = testEl.getAttribute('name') ?? '';
        final testResult =
            (testEl.getAttribute('result') ?? 'not_executed').toLowerCase();

        final category = _extractCategory(testName);
        final shortName = _stripPrefix(testName);
        // Strip category prefix from display name (e.g. "sensor.MagneticFieldTest" → "MagneticFieldTest")
        final displayName = shortName.startsWith('$category.')
            ? shortName.substring(category.length + 1)
            : shortName;

        String? message;
        String? stacktrace;
        final failureEl = testEl.findElements('Failure').firstOrNull;
        if (failureEl != null) {
          message = failureEl.getAttribute('message');
          final stEl = failureEl.findElements('StackTrace').firstOrNull;
          stacktrace = stEl?.innerText;
        }

        categoryTests.putIfAbsent(category, () => []);
        categoryTests[category]!.add(_ParsedTestCase(
          name: displayName,
          result: testResult,
          message: message,
          stacktrace: stacktrace,
        ));

        // Extrair scenes do ITS a partir dos RunHistory subtests
        for (final rh in testEl.findElements('RunHistory')) {
          final subtest = rh.getAttribute('subtest');
          if (subtest != null && subtest.startsWith('Camera_ITS_')) {
            // Ex: "Camera_ITS_0_scene2_b[folded]" → "Camera_ITS_0_scene2_b"
            final sceneName = subtest.replaceAll('[folded]', '');
            itsScenesByCategory.putIfAbsent(category, () => {});
            itsScenesByCategory[category]!.add(sceneName);
          }
        }
      }
    }
  }

  // Criar módulos virtuais por categoria
  final categories = categoryTests.keys.toList()..sort();
  final modules = <_ParsedModule>[];

  for (final cat in categories) {
    final tests = categoryTests[cat]!;
    final catPassed = tests.where((t) => t.result == 'pass').length;
    final catFailed = tests.where((t) => t.result == 'fail').length;

    String? itsScenes;
    final scenes = itsScenesByCategory[cat];
    if (scenes != null && scenes.isNotEmpty) {
      final sorted = scenes.toList()..sort();
      itsScenes = jsonEncode(sorted);
    }

    final moduleName = cat[0].toUpperCase() + cat.substring(1);
    modules.add(_ParsedModule(
      name: moduleName,
      abi: '',
      done: true,
      passed: catPassed,
      failed: catFailed,
      totalTests: tests.length,
      itsScenes: itsScenes,
      testCases: tests,
    ));
  }

  // Se não houve reagrupamento (XML sem CtsVerifier), usar original
  if (categoryTests.isEmpty) {
    for (final moduleEl in root.findElements('Module')) {
      final modName = moduleEl.getAttribute('name') ?? '';
      final modAbi = moduleEl.getAttribute('abi') ?? '';
      final modDone = moduleEl.getAttribute('done') == 'true';
      final modRuntime = moduleEl.getAttribute('runtime');

      int modPassed = 0, modFailed = 0, modTotal = 0;
      final testCases = <_ParsedTestCase>[];

      for (final testCaseEl in moduleEl.findElements('TestCase')) {
        for (final testEl in testCaseEl.findElements('Test')) {
          final testName = testEl.getAttribute('name') ?? '';
          final testResult =
              (testEl.getAttribute('result') ?? 'not_executed').toLowerCase();

          String? message;
          String? stacktrace;
          final failureEl = testEl.findElements('Failure').firstOrNull;
          if (failureEl != null) {
            message = failureEl.getAttribute('message');
            final stEl = failureEl.findElements('StackTrace').firstOrNull;
            stacktrace = stEl?.innerText;
          }

          if (testResult == 'pass') modPassed++;
          if (testResult == 'fail') modFailed++;
          modTotal++;

          testCases.add(_ParsedTestCase(
            name: testName,
            result: testResult,
            message: message,
            stacktrace: stacktrace,
          ));
        }
      }

      modules.add(_ParsedModule(
        name: modName,
        abi: modAbi,
        done: modDone,
        passed: modPassed,
        failed: modFailed,
        totalTests: modTotal,
        runtimeMs: modRuntime,
        testCases: testCases,
      ));
    }
  }

  // Recalcular modulesTotal com base nos módulos virtuais
  final actualModulesTotal =
      categoryTests.isNotEmpty ? modules.length : modulesTotal;
  final actualModulesDone =
      categoryTests.isNotEmpty ? modules.length : modulesDone;

  return _ParsedExecution(
    deviceSerial: serial,
    buildFingerprint: fingerprint,
    suitePlan: plan,
    suiteVersion: version,
    startTime: startTime,
    passed: passed,
    failed: failed,
    notExecuted: notExecuted,
    modulesDone: actualModulesDone,
    modulesTotal: actualModulesTotal,
    modules: modules,
  );
}
