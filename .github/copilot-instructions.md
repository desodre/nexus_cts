# nexus_cts — Copilot Instructions

Flutter desktop app (Linux/macOS/Windows) that orchestrates Android test suites (CTS/VTS/GTS) via Tradefed, providing live log streaming, XML result parsing, and device management through ADB.

## Commands

```bash
flutter pub get                        # Install dependencies
flutter run                            # Run in debug mode
flutter test                           # Run all tests
flutter test test/widget_test.dart     # Run a single test file
flutter analyze lib/                   # Static analysis
dart format lib/ test/                 # Format code
flutter build linux --release          # Production build
```

### Packaging (Fastforge)
```bash
dart pub global activate fastforge
fastforge package --platform linux --targets zip,deb,appimage,rpm
fastforge release --name dev           # All Linux targets to dist/
```

## Architecture

MVVM with `ChangeNotifier` — **no Provider package**. ViewModels are instantiated directly inside `StatefulWidget` state classes and observed with `ListenableBuilder`.

```
lib/
├── models/       # Pure data classes with JSON serialization and SharedPreferences storage
├── services/     # I/O layer: ADB/tradefed processes, XML parsing, file scanning
├── viewmodels/   # ChangeNotifier subclasses; own service instances via optional constructor injection
└── view/         # StatefulWidgets — each page creates its own ViewModel in initState
    ├── home/     # Dashboard: device list + grouped suite results
    ├── settings/ # CRUD for suites and Python venvs
    ├── run/      # Live log streaming page
    ├── verifier/ # CTS Verifier results
    └── widgets/  # AppDrawer (shared navigation)
```

**Key data flow:**
1. `SuiteStorage` / `VenvStorage` persist config via `SharedPreferences` (JSON-encoded lists)
2. `SuiteResultService.fetchResults()` runs in an isolate via `compute()` to parse `test_result.xml` files without blocking UI
3. `SuiteRunnerService.executeStream()` spawns a `Process` and streams stdout/stderr via callbacks — the `Process` handle is returned to allow cancellation
4. `AdbService` wraps `Process.run` calls for `adb devices -l`, `adb shell getprop`, `adb reboot`, and `fastboot getvar all`

## Key Conventions

**ViewModel instantiation:** ViewModels are created in `State` classes as `final _vm = SomeViewModel()` and disposed in `dispose()`. Services are injected via optional named constructor params (defaulting to `SomeService()`) — this pattern enables testing without a DI framework.

**Tradefed binary path:** Always constructed as `{suite.normalizedPath}/tools/{type.toLowerCase()}-tradefed`. The `normalizedPath` getter strips trailing slashes.

**Supported suite types:** `CTS`, `VTS`, `GTS`, `STS`, `CTS-on-GSI`, `GTS-Interactive`, `GTS-Root`, `CTS Verifier`. These are the canonical values used in `SettingsViewModel.suiteTypes` and `HomeViewModel.orderedGroupKeys`.

**Run modes:** `RunMode.newRun` (full suite), `RunMode.retest` (retry with `--retry <index>`), `RunMode.subplan` (custom XML from `/subplans/`), `RunMode.install` (CTS Verifier APK setup).

**XML parsing:** Uses the `xml` package. `test_result.xml` attributes vary between suite versions — always check both camelCase and snake_case variants (e.g., `device_serial` and `deviceSerial`).

**Camera ITS:** Generates a `config.yml` in `{suite.path}/CameraITS/`, then runs `python tools/run_all_tests.py` inside the venv via `bash -c "source venv/bin/activate && ..."`. Venv paths are managed as `VenvEntry` objects stored in SharedPreferences.

**Naming:** `snake_case` for files, `PascalCase` for classes. Linting uses `package:flutter_lints/flutter.yaml` (configured in `analysis_options.yaml`).
