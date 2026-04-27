# nexus_cts - Google Suite Centralizer

## Project Overview

`nexus_cts` is a Flutter desktop application (Linux, macOS, Windows) designed to automate, manage, and analyze official Android test suites (CTS, VTS, GTS, and custom types). It provides a centralized dashboard for test results, dynamic suite configuration, real-time log streaming, and XML parsing of test results (`test_result.xml`). 

The application uses an MVVM (Model-View-ViewModel) architecture implemented with pure Flutter (`ChangeNotifier`, avoiding third-party state management packages like `Provider`). It is designed for high performance, delegating heavy I/O operations and XML parsing to separate isolates to maintain UI responsiveness.

## Building and Running

The project relies on standard Flutter tooling. Ensure Flutter SDK (^3.11.4) and Dart SDK (^3.11.4) are installed. Platform Tools (for ADB) and JDK 17+ are required for test suite execution.

*   **Install Dependencies:**
    ```bash
    flutter pub get
    ```
*   **Run Application (Debug Mode):**
    ```bash
    flutter run
    ```
*   **Run Tests:**
    ```bash
    flutter test
    ```
*   **Static Analysis:**
    ```bash
    flutter analyze lib/
    ```
*   **Code Formatting:**
    ```bash
    flutter format lib/
    ```
*   **Build for Linux (Production):**
    ```bash
    flutter build linux --release
    ```

## Development Conventions

*   **Architecture (MVVM):** Strictly follow the existing MVVM pattern. Logic should be separated into Models, ViewModels (using `ChangeNotifier`), and Views (UI widgets). Services handle external integrations (like ADB, running suites, parsing XML).
*   **State Management:** State is managed via `ChangeNotifier` and `AnimatedBuilder`/`ListenableBuilder` (or manual `addListener` callbacks). Avoid introducing external state management packages.
*   **Performance:** Heavy workloads, especially large file reading (I/O) and XML parsing (like `test_result.xml`), must be offloaded to separate Isolates to avoid blocking the main UI thread.
*   **Directory Structure:** 
    *   `lib/models/`: Data classes (e.g., `TestResult`, `SuiteEntry`).
    *   `lib/services/`: Business logic, ADB interactions, file parsing.
    *   `lib/viewmodels/`: UI state management bridging Views and Services.
    *   `lib/view/`: UI components and screens organized by feature (e.g., `home/`, `run/`, `settings/`).
*   **Persistence:** Local data, such as dynamic suite configurations, is saved using `shared_preferences` and potentially SQLite (`sqflite_common_ffi`).
*   **Platform Specifics:** Keep in mind that this is primarily a desktop application intended for environments where external binaries (like ADB and Java/tradefed) are available in the system PATH.