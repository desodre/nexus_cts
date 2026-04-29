# nexus_cts - Google Suite Centralizer

## Project Overview

`nexus_cts` is a Flutter desktop application (Linux, macOS, Windows) designed to automate, manage, and analyze official Android test suites (CTS, VTS, GTS, and custom types). It provides a centralized dashboard for test results, dynamic suite configuration, real-time log streaming, and XML parsing of test results (`test_result.xml`).

The application uses an MVVM (Model-View-ViewModel) architecture implemented with pure Flutter (`ChangeNotifier`, avoiding third-party state management packages like `Provider`). It is designed for high performance, delegating heavy I/O operations and XML parsing to separate isolates to maintain UI responsiveness.

## Building and Running

The project relies on standard Flutter tooling (SDK ^3.11.4). Platform Tools (ADB) and JDK 17+ are required.

*   **Dependencies:** `flutter pub get`
*   **Run (Debug):** `flutter run`
*   **Tests:** `flutter test`
*   **Static Analysis:** `flutter analyze lib/`
*   **Formatting:** `dart format lib/ test/`

### Build (Linux)
Para garantir compatibilidade com Ubuntu 20.04+ (evitar erros de `libc6`):
*   **Via Docker (Recomendado):** `docker-compose up --build`
*   **Manual (Native):** `flutter build linux --release` (Requer Ubuntu 20.04 ou inferior para retrocompatibilidade).

### Packaging (Linux)
O projeto usa `fastforge` para packaging. O build via Docker já executa o packaging automaticamente.
*   **ZIP/DEB/AppImage:** `fastforge package --platform linux --targets <target>`
*   **RPM:** Use `bash scripts/build_rpm.sh` (fixes path issues in fastforge-generated spec files).
*   **Icons:** PNGs are pre-generated in `linux/icons/`. `linux/runner/my_application.cc` loads the icon from the bundle's `data/` directory at runtime.

### CI/CD
GitHub Actions (`.github/workflows/build.yml`) automates builds for all Linux targets. Releases are triggered by version tags (`v*.*.*`).

## Development Conventions

### Architecture (MVVM)
Strictly follow the MVVM pattern without external state management (No Provider/Riverpod).
*   **Models:** Pure data classes in `lib/models/`. Use JSON serialization for storage.
*   **Services:** I/O layer in `lib/services/` (ADB, Tradefed, XML parsing, file scanning).
*   **ViewModels:** `ChangeNotifier` subclasses in `lib/viewmodels/`. Services are injected via optional named constructor parameters (defaulting to the concrete implementation) to facilitate testing.
*   **Views:** `StatefulWidget` classes in `lib/view/`. ViewModels are instantiated in `initState`, stored as `final`, and disposed in `dispose()`. Use `ListenableBuilder` to observe changes.

### Key Data Flow & Integrations
*   **Heavy I/O:** XML parsing of `test_result.xml` must run in an isolate via `compute()`.
*   **Process Streaming:** `SuiteRunnerService.executeStream()` returns a `Process` handle and uses callbacks for live log streaming.
*   **ADB/Fastboot:** `AdbService` wraps `Process.run` calls.
*   **Persistence:** Configs (suites, venvs) are JSON-encoded and stored in `SharedPreferences`.
*   **Tradefed Paths:** Constructed as `{suite.normalizedPath}/tools/{type}-tradefed`.
*   **Camera ITS:** Uses a Python venv (managed via `VenvEntry`). Runs `python tools/run_all_tests.py` inside the activated venv.

### Standards
*   **Suite Types:** Canonical values: `CTS`, `VTS`, `GTS`, `STS`, `CTS-on-GSI`, `GTS-Interactive`, `GTS-Root`, `CTS Verifier`.
*   **Run Modes:** `RunMode.newRun`, `RunMode.retest`, `RunMode.subplan`, `RunMode.install`.
*   **XML Parsing:** Use the `xml` package. Support both `camelCase` and `snake_case` attributes for compatibility across suite versions.
*   **Naming:** `snake_case` for files, `PascalCase` for classes.
*   **Linting:** Follow `package:flutter_lints/flutter.yaml`.
