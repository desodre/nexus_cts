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
      case RunMode.install:
        return [];
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

  /// Executa um comando e aguarda o término, retornando o exit code.
  Future<int> _runCmd(
    List<String> cmd,
    void Function(String) onOutput,
    void Function(Process?) onProcessChanged,
  ) async {
    onOutput('> ${cmd.join(' ')}\n');
    try {
      final process = await Process.start(cmd.first, cmd.sublist(1));
      onProcessChanged(process);

      process.stdout
          .transform(const SystemEncoding().decoder)
          .listen((data) => onOutput(data));
      process.stderr
          .transform(const SystemEncoding().decoder)
          .listen((data) => onOutput('[STDERR] $data'));

      final exitCode = await process.exitCode;
      return exitCode;
    } catch (e) {
      onOutput('[ERRO] $e\n');
      return -1;
    }
  }

  /// Obtém uma propriedade do dispositivo via adb shell getprop.
  Future<String> _getDeviceProp(String serial, String prop) async {
    final result = await Process.run('adb', [
      '-s',
      serial,
      'shell',
      'getprop',
      prop,
    ]);
    return (result.stdout as String).trim();
  }

  /// Realiza o setup completo e instalação do CTS Verifier.
  Future<void> installVerifier({
    required SuiteEntry suite,
    required List<String> serials,
    required void Function(String data) onOutput,
    required void Function(Process?) onProcessChanged,
    required bool Function() isCancelled,
  }) async {
    final basePath = suite.normalizedPath;
    final buildName = basePath.split('/').last;
    final user =
        Platform.environment['USER'] ??
        Platform.environment['LOGNAME'] ??
        'user';

    for (final serial in serials) {
      if (isCancelled()) return;

      onOutput('\n═══ Configurando dispositivo $serial ═══\n\n');

      // ── Propriedades do dispositivo ──
      final buildId = await _getDeviceProp(serial, 'ro.build.id');
      final carrierId = await _getDeviceProp(serial, 'ro.carrier');
      final productId = await _getDeviceProp(serial, 'ro.product.board');

      // ── Diretório de resultados ──
      final resultsDir =
          '/home/$user/CTSVerifier/Results/'
          'CTS-Verifier_${buildName}_${productId}_${carrierId}_$buildId';
      onOutput('Criando diretório de resultados:\n$resultsDir/\n\n');
      await Directory(resultsDir).create(recursive: true);

      // ── Setup do dispositivo ──
      final setupCmds = <List<String>>[
        [
          'adb',
          '-s',
          serial,
          'shell',
          'settings',
          'put',
          'system',
          'system_locales',
          'en-US',
        ],
        [
          'adb',
          '-s',
          serial,
          'shell',
          'settings',
          'put',
          'system',
          'screen_brightness_mode',
          '0',
        ],
        [
          'adb',
          '-s',
          serial,
          'shell',
          'settings',
          'put',
          'system',
          'screen_off_timeout',
          '1800000',
        ],
        [
          'adb',
          '-s',
          serial,
          'shell',
          'settings',
          'put',
          'global',
          'stay_on_while_plugged_in',
          '15',
        ],
        [
          'adb',
          '-s',
          serial,
          'shell',
          'settings',
          'put',
          'global',
          'verifier_verify_adb_installs',
          '0',
        ],
        ['adb', '-s', serial, 'shell', 'locksettings', 'set-disabled', 'true'],
      ];

      for (final cmd in setupCmds) {
        if (isCancelled()) return;
        await _runCmd(cmd, onOutput, onProcessChanged);
      }

      // ── ADB root ──
      if (isCancelled()) return;
      await _runCmd(['adb', '-s', serial, 'root'], onOutput, onProcessChanged);

      // ── Push APKs ──
      final pushCmds = <List<String>>[
        [
          'adb',
          '-s',
          serial,
          'push',
          '$basePath/NotificationBot.apk',
          '/data/local/tmp',
        ],
        [
          'adb',
          '-s',
          serial,
          'push',
          '$basePath/CtsVpnFirewallAppNotAlwaysOn.apk',
          '/data/local/tmp',
        ],
      ];

      for (final cmd in pushCmds) {
        if (isCancelled()) return;
        await _runCmd(cmd, onOutput, onProcessChanged);
      }

      // ── Instalação dos APKs ──
      final installCmds = <List<String>>[
        [
          'adb',
          '-s',
          serial,
          'install',
          '-r',
          '-g',
          '$basePath/CrossProfileTestApp.apk',
        ],
        [
          'adb',
          '-s',
          serial,
          'install',
          '-r',
          '-g',
          '$basePath/CtsCarWatchdogCompanionApp.apk',
        ],
        [
          'adb',
          '-s',
          serial,
          'install',
          '-r',
          '-g',
          '-t',
          '$basePath/CtsDefaultNotesApp.apk',
        ],
        [
          'adb',
          '-s',
          serial,
          'install',
          '-r',
          '-g',
          '$basePath/CtsDeviceControlsApp.apk',
        ],
        [
          'adb',
          '-s',
          serial,
          'install',
          '-r',
          '-g',
          '-t',
          '$basePath/CtsEmptyDeviceOwner.apk',
        ],
        [
          'adb',
          '-s',
          serial,
          'install',
          '-r',
          '-g',
          '$basePath/CtsForceStopHelper.apk',
        ],
        [
          'adb',
          '-s',
          serial,
          'install',
          '-r',
          '-g',
          '$basePath/CtsPermissionApp.apk',
        ],
        [
          'adb',
          '-s',
          serial,
          'install',
          '-r',
          '-g',
          '$basePath/CtsTileServiceApp.apk',
        ],
        [
          'adb',
          '-s',
          serial,
          'install',
          '-r',
          '-g',
          '$basePath/CtsTtsEngineSelectorTestHelper2.apk',
        ],
        [
          'adb',
          '-s',
          serial,
          'install',
          '-r',
          '-g',
          '$basePath/CtsTtsEngineSelectorTestHelper.apk',
        ],
        [
          'adb',
          '-s',
          serial,
          'install',
          '-r',
          '-g',
          '$basePath/CtsVerifier.apk',
        ],
        [
          'adb',
          '-s',
          serial,
          'install',
          '-r',
          '-g',
          '--instant',
          '$basePath/CtsVerifierInstantApp.apk',
        ],
        [
          'adb',
          '-s',
          serial,
          'install',
          '-r',
          '-g',
          '$basePath/CtsVerifierUSBCompanion.apk',
        ],
        [
          'adb',
          '-s',
          serial,
          'install',
          '-r',
          '-g',
          '$basePath/CtsVpnFirewallAppApi23.apk',
        ],
        [
          'adb',
          '-s',
          serial,
          'install',
          '-r',
          '-g',
          '$basePath/CtsVpnFirewallAppApi24.apk',
        ],
        [
          'adb',
          '-s',
          serial,
          'install',
          '-r',
          '-g',
          '$basePath/CtsVpnFirewallAppNotAlwaysOn.apk',
        ],
        [
          'adb',
          '-s',
          serial,
          'install',
          '-r',
          '-g',
          '$basePath/NotificationBot.apk',
        ],
        [
          'adb',
          '-s',
          serial,
          'install',
          '-r',
          '-g',
          '$basePath/jetpack-camera-app.apk',
        ],
        [
          'adb',
          '-s',
          serial,
          'install',
          '-r',
          '-g',
          '$basePath/MultiDevice/NfcEmulatorTestApp.apk',
        ],
        [
          'adb',
          '-s',
          serial,
          'install',
          '--bypass-low-target-sdk-block',
          '-r',
          '-g',
          '$basePath/QSensorTest.apk',
        ],
        [
          'adb',
          '-s',
          serial,
          'install',
          '--bypass-low-target-sdk-block',
          '-r',
          '-g',
          '$basePath/OpenCV_3.0.0_Manager_3.00_arm64-v8a.apk',
        ],
        [
          'adb',
          '-s',
          serial,
          'install',
          '--bypass-low-target-sdk-block',
          '-r',
          '-g',
          '$basePath/MIDI BLE Connect_1.1.apk',
        ],
      ];

      for (final cmd in installCmds) {
        if (isCancelled()) return;
        final exitCode = await _runCmd(cmd, onOutput, onProcessChanged);
        final apkName = cmd.last.split('/').last;
        if (exitCode == 0) {
          onOutput('[OK] $apkName\n');
        } else {
          onOutput('[ERRO] $apkName (código $exitCode)\n');
        }
      }

      // ── Configurações pós-instalação ──
      final postCmds = <List<String>>[
        [
          'adb',
          '-s',
          serial,
          'shell',
          'appops',
          'set',
          '--user',
          '0',
          'com.android.cts.verifier',
          'MANAGE_EXTERNAL_STORAGE',
          '0',
        ],
        [
          'adb',
          '-s',
          serial,
          'shell',
          'settings',
          'put',
          'global',
          'hidden_api_policy',
          '1',
        ],
        [
          'adb',
          '-s',
          serial,
          'shell',
          'appops',
          'set',
          'com.android.cts.verifier',
          'MANAGE_EXTERNAL_STORAGE',
          '0',
        ],
        [
          'adb',
          '-s',
          serial,
          'shell',
          'appops',
          'set',
          'com.android.cts.verifier',
          'android:read_device_identifiers',
          'allow',
        ],
        [
          'adb',
          '-s',
          serial,
          'shell',
          'am',
          'compat',
          'enable',
          'ALLOW_TEST_API_ACCESS',
          'com.android.cts.verifier',
        ],
        [
          'adb',
          '-s',
          serial,
          'shell',
          'appops',
          'set',
          'com.android.cts.verifier',
          'TURN_SCREEN_ON',
          '0',
        ],
      ];

      for (final cmd in postCmds) {
        if (isCancelled()) return;
        await _runCmd(cmd, onOutput, onProcessChanged);
      }

      onOutput('\n[OK] Setup completo para $serial\n');
    }

    onOutput('\n[Instalação do CTS Verifier finalizada]\n');
  }

  /// Executa os testes Camera ITS via script bash.
  Future<void> runCameraIts({
    required SuiteEntry suite,
    required String dutSerial,
    required String tabletSerial,
    required String venvPath,
    required void Function(String data) onOutput,
    required void Function(Process?) onProcessChanged,
    required bool Function() isCancelled,
    String? scenes,
    String cameraId = '0',
  }) async {
    final basePath = suite.normalizedPath;
    final cameraItsDir = '$basePath/CameraITS';
    final venvNorm = venvPath.replaceAll(RegExp(r'/+$'), '');

    onOutput('\n═══ Camera ITS ═══\n\n');

    // ── Montar config.yml ──
    final configContent =
        '''
# Generated by nexus_cts
TestBeds:
  - Name: TEST_BED_TABLET_SCENES  # Need 'tablet' in name for tablet scenes
    Controllers:
        AndroidDevice:
          - serial: "$dutSerial"
            label: dut
          - serial: "$tabletSerial"
            label: tablet
    TestParams:
      brightness: 192
      chart_distance: 22.0
      debug_mode: "False"
      lighting_cntl: "None"
      lighting_ch: 1
      camera: $cameraId
      scene: <scene-name>
      foldable_device: "False"
      chart_scaling: "None"

  - Name: TEST_BED_SENSOR_FUSION  # Need 'sensor_fusion' in name for
    # checkerboard scenes (SF, scene_flash, and feature_combination) tests
    Controllers:
        AndroidDevice:
          - serial: "$dutSerial"
            label: dut
    TestParams:
      fps: 30
      img_size: 640,480
      test_length: 7
      debug_mode: "False"
      chart_distance: 22
      rotator_cntl: "None"
      rotator_ch: 1
      camera: $cameraId
      foldable_device: "False"
      tablet_device: "False"
      lighting_cntl: "None"
      lighting_ch: 1
      scene: "checkerboard"
      parallel_execution: "True"

  - Name: TEST_BED_GEN2
    Controllers:
        AndroidDevice:
          - serial: "$dutSerial"
            label: dut
    TestParams:
      debug_mode: "False"
      chart_distance: 30
      rotator_cntl: "None"
      rotator_ch: 1
      camera: $cameraId
      foldable_device: "False"
      tablet_device: "False"
      lighting_cntl: "None"
      lighting_ch: 1
      scene: scene_ip
''';

    final configFile = File('$cameraItsDir/config.yml');
    onOutput('[INFO] Escrevendo config.yml em $cameraItsDir\n');
    await configFile.writeAsString(configContent);
    onOutput('[OK] config.yml criado\n\n');

    if (isCancelled()) return;

    // ── Montar comando de execução ──
    final testCmd = StringBuffer()
      ..write('python tools/run_all_tests.py camera=$cameraId');
    if (scenes != null && scenes.trim().isNotEmpty) {
      testCmd.write(' scenes=${scenes.trim()}');
    }

    final script =
        '''
source "$venvNorm/bin/activate"
cd "$cameraItsDir"
source build/envsetup.sh
$testCmd
''';

    onOutput('[INFO] Ativando venv e executando testes...\n');
    onOutput('> bash -c "..."\n\n');

    if (isCancelled()) return;

    try {
      final process = await Process.start('bash', [
        '-c',
        script,
      ], workingDirectory: cameraItsDir);
      onProcessChanged(process);

      process.stdout
          .transform(const SystemEncoding().decoder)
          .listen((data) => onOutput(data));
      process.stderr
          .transform(const SystemEncoding().decoder)
          .listen((data) => onOutput('[STDERR] $data'));

      final exitCode = await process.exitCode;
      onOutput('\n[Camera ITS finalizado com código $exitCode]\n');
    } catch (e) {
      onOutput('[ERRO] $e\n');
    }
  }

  /// Executa os testes Camera Webcam Test via script Python.
  Future<void> runCameraWebcamTest({
    required SuiteEntry suite,
    required String dutSerial,
    required String venvPath,
    required void Function(String data) onOutput,
    required void Function(Process?) onProcessChanged,
    required bool Function() isCancelled,
  }) async {
    final basePath = suite.normalizedPath;
    final webcamDir =
        '$basePath/CameraWebcamTest/packages/services/DeviceAsWebcam/tests';
    final venvNorm = venvPath.replaceAll(RegExp(r'/+$'), '');

    onOutput('\n═══ Camera Webcam Test ═══\n\n');

    // ── Gerar config.yml com serial do DUT ──
    final configContent =
        '''
# Generated by nexus_cts
TestBeds:
  - Name: TEST_BED_WEBCAM
    Controllers:
        AndroidDevice:
          - serial: "$dutSerial"
            label: dut
''';

    final configFile = File('$webcamDir/config.yml');
    onOutput('[INFO] Escrevendo config.yml em $webcamDir\n');
    await configFile.writeAsString(configContent);
    onOutput('[OK] config.yml criado\n\n');

    if (isCancelled()) return;

    // ── Executar run_webcam_test.py ──
    final script =
        '''
source "$venvNorm/bin/activate"
cd "$webcamDir"
python run_webcam_test.py -c config.yml
''';

    onOutput('[INFO] Ativando venv e executando webcam test...\n');
    onOutput('> python run_webcam_test.py -c config.yml\n\n');

    if (isCancelled()) return;

    try {
      final process = await Process.start('bash', [
        '-c',
        script,
      ], workingDirectory: webcamDir);
      onProcessChanged(process);

      process.stdout
          .transform(const SystemEncoding().decoder)
          .listen((data) => onOutput(data));
      process.stderr
          .transform(const SystemEncoding().decoder)
          .listen((data) => onOutput('[STDERR] $data'));

      final exitCode = await process.exitCode;
      onOutput('\n[Camera Webcam Test finalizado com código $exitCode]\n');
    } catch (e) {
      onOutput('[ERRO] $e\n');
    }
  }
}
