import 'dart:io';

import 'package:nexus_cts/models/run_mode.dart';
import 'package:nexus_cts/models/suite_entry.dart';

class SuiteRunnerService {
  List<String> buildCommand({
    required SuiteEntry suite,
    required List<String> serials,
    required RunMode mode,
    String? selectedResult,
    String? selectedSubplan,
    String? module,
    String? extraArgs,
  }) {
    final suiteType = suite.type.toLowerCase();
    final basePath = suite.normalizedPath;
    final tradefedBin = '$basePath/tools/$suiteType-tradefed';

    final args = <String>[];
    switch (mode) {
      case RunMode.newRun:
        args.addAll(['run', 'commandAndExit', suiteType]);
      case RunMode.retest:
        args.addAll([
          'run',
          'commandAndExit',
          'retry',
          '--retry',
          selectedResult ?? '',
        ]);
      case RunMode.subplan:
        args.addAll([
          'run',
          'commandAndExit',
          suiteType,
          '--subplan',
          selectedSubplan ?? '',
        ]);
    }

    if (serials.length == 1) {
      args.addAll(['-s', serials.first]);
    } else {
      for (final s in serials) {
        args.addAll(['--serial', s]);
      }
      args.addAll(['--shard-count', '${serials.length}']);
    }

    if (module != null && module.trim().isNotEmpty) {
      args.addAll(['-m', module.trim()]);
    }

    if (extraArgs != null && extraArgs.trim().isNotEmpty) {
      args.addAll(extraArgs.trim().split(RegExp(r'\s+')));
    }

    return [tradefedBin, ...args];
  }

  /// Executa o comando e emite cada chunk via [onOutput].
  /// Retorna o [Process] para permitir cancelamento.
  Future<Process> executeStream({
    required SuiteEntry suite,
    required List<String> serials,
    required RunMode mode,
    required void Function(String data) onOutput,
    String? selectedResult,
    String? selectedSubplan,
    String? module,
    String? extraArgs,
  }) async {
    final cmd = buildCommand(
      suite: suite,
      serials: serials,
      mode: mode,
      selectedResult: selectedResult,
      selectedSubplan: selectedSubplan,
      module: module,
      extraArgs: extraArgs,
    );

    onOutput('> ${cmd.join(' ')}\n');

    final process = await Process.start(
      cmd.first,
      cmd.sublist(1),
      workingDirectory: suite.normalizedPath,
    );

    process.stdout
        .transform(const SystemEncoding().decoder)
        .listen((data) => onOutput(data));

    process.stderr
        .transform(const SystemEncoding().decoder)
        .listen((data) => onOutput('[STDERR] $data'));

    return process;
  }
}
