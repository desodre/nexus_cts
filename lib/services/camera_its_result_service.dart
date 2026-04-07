import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:nexus_cts/models/camera_its_result.dart';

/// Varre /tmp/CameraITS_* e retorna os resultados parseados.
List<CameraItsResult> _scanCameraItsSync(String tmpDir) {
  final results = <CameraItsResult>[];
  final dir = Directory(tmpDir);
  if (!dir.existsSync()) return results;

  for (final entity in dir.listSync()) {
    if (entity is! Directory) continue;
    final name = entity.path.split('/').last;
    if (!name.startsWith('CameraITS_')) continue;

    final scenes = <ItsSceneResult>[];
    String? dutSerial;
    String? buildFingerprint;

    // cam_id_*/scene*/scene_test_summary.txt
    for (final camDir in entity.listSync().whereType<Directory>()) {
      final camName = camDir.path.split('/').last;
      if (!camName.startsWith('cam_id_')) continue;
      final camera = camName.replaceFirst('cam_id_', '');

      for (final sceneDir in camDir.listSync().whereType<Directory>()) {
        final sceneName = sceneDir.path.split('/').last;
        final summaryFile =
            File('${sceneDir.path}/scene_test_summary.txt');
        if (!summaryFile.existsSync()) continue;

        final tests = <ItsTestEntry>[];
        final lines = summaryFile.readAsLinesSync();

        // Mapear detalhes a partir dos test_summary.yaml individuais
        final detailMap = _buildTestDetailMap(sceneDir.path);

        for (final line in lines) {
          // Primeira linha: "Cam0 scene0" — ignorar
          final trimmed = line.trim();
          if (trimmed.isEmpty) continue;
          if (trimmed.startsWith('Cam')) continue;

          // Formato: "PASS  test_jitter.py"
          final parts = trimmed.split(RegExp(r'\s+'));
          if (parts.length >= 2) {
            final testName = parts.sublist(1).join(' ');
            final detail = detailMap[testName];
            tests.add(ItsTestEntry(
              result: parts[0],
              testName: testName,
              detail: detail,
            ));
          }
        }

        scenes.add(ItsSceneResult(
          scene: sceneName,
          camera: camera,
          tests: tests,
        ));

        // Tentar extrair serial/fingerprint do primeiro test_summary.yaml
        if (dutSerial == null) {
          final parsed = _extractDeviceInfo(sceneDir.path);
          dutSerial = parsed.$1;
          buildFingerprint = parsed.$2;
        }
      }
    }

    if (scenes.isEmpty) continue;

    final stat = entity.statSync();
    results.add(CameraItsResult(
      folderName: name,
      fullPath: entity.path,
      modified: stat.modified,
      dutSerial: dutSerial,
      buildFingerprint: buildFingerprint,
      scenes: scenes,
    ));
  }

  results.sort((a, b) => b.modified.compareTo(a.modified));
  return results;
}

/// Mapeia test_name.py → ItsTestDetail
/// a partir dos test_summary.yaml dentro de TEST_BED_*/*/
Map<String, ItsTestDetail> _buildTestDetailMap(String scenePath) {
  final map = <String, ItsTestDetail>{};
  try {
    final sceneDir = Directory(scenePath);
    for (final testBed in sceneDir.listSync().whereType<Directory>()) {
      final testBedName = testBed.path.split('/').last;
      if (!testBedName.startsWith('TEST_BED_') &&
          !testBedName.contains('latest')) {
        continue;
      }
      if (testBedName == 'latest') continue;

      for (final testDir in testBed.listSync().whereType<Directory>()) {
        final yamlFile = File('${testDir.path}/test_summary.yaml');
        if (!yamlFile.existsSync()) continue;

        final content = yamlFile.readAsStringSync();

        // Extrair Test Name
        final nameMatch = RegExp(r'^Test Name:\s*(.+)$', multiLine: true)
            .firstMatch(content);
        if (nameMatch == null) continue;
        final rawName = nameMatch.group(1)!.trim();
        final testFileName = '$rawName.py';

        // Result
        final resultVal = _yamlField(content, 'Result');

        // Test Class
        final testClass = _yamlField(content, 'Test Class');

        // Details
        String? details = _yamlField(content, 'Details');
        if (details == 'null') details = null;

        // Stacktrace
        String? stacktrace;
        final stMatch = RegExp(
          r'^Stacktrace:\s*"([\s\S]*?)"$',
          multiLine: true,
        ).firstMatch(content);
        if (stMatch != null) {
          stacktrace = stMatch
              .group(1)
              ?.replaceAll(r'\n', '\n')
              .replaceAll('\\    ', '')
              .trim();
        }
        if (stacktrace == 'null') stacktrace = null;

        // Termination Signal Type
        String? termSignal = _yamlField(content, 'Termination Signal Type');
        if (termSignal == 'null') termSignal = null;

        // Signature
        final signature = _yamlField(content, 'Signature');

        // Timestamps
        final beginTime =
            int.tryParse(_yamlField(content, 'Begin Time') ?? '');
        final endTime =
            int.tryParse(_yamlField(content, 'End Time') ?? '');

        // Summary counts
        final errorCount =
            int.tryParse(_yamlField(content, 'Error') ?? '');
        final executedCount =
            int.tryParse(_yamlField(content, 'Executed') ?? '');
        final failedCount =
            int.tryParse(_yamlField(content, 'Failed') ?? '');
        final passedCount =
            int.tryParse(_yamlField(content, 'Passed') ?? '');
        final skippedCount =
            int.tryParse(_yamlField(content, 'Skipped') ?? '');

        // Controller Info — dispositivos
        final devices = _parseDevices(content);

        map[testFileName] = ItsTestDetail(
          testName: rawName,
          testClass: testClass,
          result: resultVal,
          details: details,
          stacktrace: stacktrace,
          terminationSignal: termSignal,
          signature: signature,
          beginTime: beginTime,
          endTime: endTime,
          devices: devices,
          errorCount: errorCount,
          executedCount: executedCount,
          failedCount: failedCount,
          passedCount: passedCount,
          skippedCount: skippedCount,
        );
      }
    }
  } catch (_) {}
  return map;
}

/// Extrai um campo simples do YAML: "FieldName: value".
String? _yamlField(String content, String field) {
  final match =
      RegExp('^$field:\\s*(.+)\$', multiLine: true).firstMatch(content);
  if (match == null) return null;
  final val = match.group(1)?.trim().replaceAll(RegExp(r"^'+|'+$"), '');
  return (val == null || val.isEmpty) ? null : val;
}

/// Parseia blocos de dispositivos do Controller Info.
List<ItsDeviceInfo> _parseDevices(String content) {
  final devices = <ItsDeviceInfo>[];
  final deviceBlocks = content.split(RegExp(r'\n-\s+build_info:'));
  for (var i = 1; i < deviceBlocks.length; i++) {
    final block = deviceBlocks[i];
    devices.add(ItsDeviceInfo(
      serial: _blockField(block, 'serial'),
      model: _blockField(block, 'model'),
      buildFingerprint: _blockField(block, 'build_fingerprint'),
      buildId: _blockField(block, 'build_id'),
      buildProduct: _blockField(block, 'build_product'),
      buildType: _blockField(block, 'build_type'),
      sdkVersion: _blockField(block, 'build_version_sdk'),
      characteristics: _blockField(block, 'build_characteristics'),
    ));
  }
  return devices;
}

/// Extrai campo de um bloco YAML indentado.
String? _blockField(String block, String field) {
  final match =
      RegExp('$field:\\s*(.+)\$', multiLine: true).firstMatch(block);
  if (match == null) return null;
  final val = match.group(1)?.trim().replaceAll(RegExp(r"^'+|'+$"), '');
  return (val == null || val.isEmpty || val == 'null') ? null : val;
}

/// Extrai serial e fingerprint do primeiro test_summary.yaml encontrado.
(String?, String?) _extractDeviceInfo(String scenePath) {
  try {
    // Procurar em TEST_BED_*/*/test_summary.yaml
    final sceneDir = Directory(scenePath);
    for (final testBed in sceneDir.listSync().whereType<Directory>()) {
      for (final testDir in testBed.listSync().whereType<Directory>()) {
        final yamlFile = File('${testDir.path}/test_summary.yaml');
        if (!yamlFile.existsSync()) continue;

        final content = yamlFile.readAsStringSync();
        String? serial;
        String? fingerprint;

        // Parse simples — procurar serial e build_fingerprint do DUT (label: dut)
        final serialMatch =
            RegExp(r'serial:\s*(\S+)').firstMatch(content);
        if (serialMatch != null) {
          serial = serialMatch.group(1)?.replaceAll("'", '').replaceAll('"', '');
        }

        final fpMatch =
            RegExp(r'build_fingerprint:\s*(\S+)').firstMatch(content);
        if (fpMatch != null) {
          fingerprint = fpMatch.group(1);
        }

        if (serial != null) return (serial, fingerprint);
      }
    }
  } catch (_) {}
  return (null, null);
}

class CameraItsResultService {
  Future<List<CameraItsResult>> fetchResults() async {
    return compute(_scanCameraItsSync, '/tmp');
  }
}
