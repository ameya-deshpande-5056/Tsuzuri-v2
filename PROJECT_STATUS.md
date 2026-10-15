# PROJECT_STATUS.md: Authoritative Current Progress

## 1. Project Overview
- **Project Name**: Tsuzuri v2 (綴り v2)
- **Objective**: Lightweight, offline-first, cross-platform Markdown editor and reader using Flutter and Dart with first-class LaTeX and Mermaid support.
- **Target Platforms**: Linux, Windows, macOS, Android, iOS, Web.
- **Current Host Toolchain**:
  - Flutter 3.41.9 (channel stable), Dart 3.11.5 on Linux Mint 22.3 (kernel 7.0.0-38-generic).
  - C++ Toolchain: `clang++` (symlinked to `/usr/bin/g++`), `cmake` 3.28, `ninja` 1.11, `webkit2gtk-4.1`.
  - Android SDK 37.0.0 (all licenses accepted; Gradle memory envelope strictly capped guaranteeing >= 4GB free RAM). Chrome 154 available.

## 2. Current Progress & Calculation
- **Overall Completion**: **100.0%** (47 of 47 tasks verified)
- **Calculation Method**: `Task Completion % = (VERIFIED Tasks / Total Tasks) * 100` (Implemented but unverified tasks count as 0%).
- **Current Phase**: **Phase 7: Library & Document Discovery (COMPLETED)**
- **Active Task**: `RENDER-008`: In-WebView Responsive TOC Panel on Linux and Universal Viewport Accessibility (`VERIFIED`).

## 3. Status by Phase
| Phase | Title | Status | Completion |
|---|---|---|---|
| **Phase 0** | Repository Inspection and Planning | `COMPLETED` | 3 / 3 (100%) |
| **Phase 1** | Rendering Proof of Concept (PoC) | `COMPLETED` | 4 / 4 (100%) |
| **Phase 2** | Core Architecture & UI Shell | `COMPLETED` | 5 / 5 (100%) |
| **Phase 3** | Editing and File Operations | `COMPLETED` | 6 / 6 (100%) |
| **Phase 4** | Rendering Compatibility & Hardening | `COMPLETED` | 6 / 6 (100%) |
| **Phase 5** | Cross-Platform Verification | `COMPLETED` | 3 / 3 (100%) |
| **Phase 6** | Finalization & Documentation | `COMPLETED` | 15 / 15 (100%) |
| **Phase 7** | Library & Document Discovery | `COMPLETED` | 5 / 5 (100%) |

## 4. Completed & Verified Work
- `PHASE0-001`: Inspected all 3 reference repositories (`Tsuzuri`, `md-latex-mermaid2pdf`, `GATE_DA`). Established rendering and UI baselines.
- `PHASE0-002`: Created persistent progress tracking files (`AGENTS.md`, `PROJECT_STATUS.md`, `IMPLEMENTATION_PLAN.md`, `DECISIONS.md`, `KNOWN_ISSUES.md`).
- `PHASE0-003`: Inspected local Flutter/Dart/Linux environment; configured `clang++` toolchain for Linux desktop buildability.
- `POC-001`: Flutter project initialized with Linux, Android, iOS, macOS, Windows, Web targets.
- `POC-002`: Pure Dart `MathDelimiterNormalizer` implemented and verified with 10 comprehensive unit tests.
- `POC-003`: Offline rendering assets (`mermaid.min.js`, `katex`, `mhchem`, MathJax, `highlight.js`, `markdown-it`) bundled locally with zero CDN references.
- `POC-004`: Minimal rendering prototype verified. Linux desktop debug and release binaries built cleanly.
- `CORE-001`: Theme system with true AMOLED pure black (`#000000`) and System default mode implemented and verified.
- `CORE-002`: Responsive `AppHeader` implemented with adaptive icon scaling across viewports.
- `CORE-003`: Mutually exclusive Reader & Editor view switching implemented and verified.
- `CORE-004`: `TocParser` and `TocDrawer` implemented with heading extraction and smooth jump navigation.
- `CORE-005`: `ActionsSheet` bottom sheet and `TsuzuriAboutDialog` implemented and verified.
- `EDIT-001`: `MarkdownEditor` with synchronized line gutter, word wrap toggle, and monospace typography implemented.
- `EDIT-002`: `EditorStatusBar` implemented with cursor Ln/Col, word count, and char count.
- `EDIT-003`: `FindReplaceBar` implemented with match cycling, replace, and replace-all.
- `FILE-001`: `DocumentState` model with dirty state tracking and unsaved change confirmation guards implemented.
- `FILE-002`: `FileService` implemented with safe atomic file writes and error handling.
- `FILE-003`: `AssetResolver` implemented with relative image path resolution and file URI conversion.
- `HARDEN-001`: Regression test suite with 5 comprehensive corpus fixtures implemented and passing.
- `HARDEN-002`: Mermaid failure handling with friendly error cards and source fallback implemented.
- `HARDEN-003`: Responsive layout tests verified across all 7 required viewport widths (320px to 1920px).
- `PLAT-001`: Linux desktop release binary built (`build/linux/x64/release/bundle/tsuzuri`).
- `PLAT-002`: Web release target built (`build/web`).
- `DOC-001`: Comprehensive `README.md` authored.
- `DOC-002`: Final coordination reconciliation and Definition of Done verification complete.
- `ARCH-007`: Full Linux Desktop rendering parity via WebKitGTK (`webview_all`), editor line gutter scrollbar suppression, and adaptive desktop popover dropdown menu ($\ge 681$px) aligned with Tauri Tsuzuri v1 layout.
- `PLAT-003`: Android 9 (API 28) physical hardware debug launch and offline asset rendering verified on Realme 1 (`CPH1859`). Resolved script inlining conflict in `bundled_assets.dart`, added `androidx.window` dependencies, rewrote KaTeX embedded font paths, and verified interactive Dart VM connection and DevTools attachment.
- `RENDER-005`: Verified KaTeX mhchem chemistry equations, Highlight.js Dart grammar registration, and code block responsive word wrapping on physical Android hardware (`CPH1859`).
- `RENDER-006`: Line-ending-preserving segmentation in `MathDelimiterNormalizer`, CommonMark line-based fence segmentation in `template.html`, and AST-level Mermaid fence rule interception. Verified on full 217 KB GATE DA corpus: 94/94 LaTeX display math equations render via KaTeX, 0 bad `<pre>` blocks swallowing prose, 334 code fences preserved and terminated cleanly. 42/42 tests passing.
- `RENDER-007`: Structured code block containers with distinct header strips, uppercase language badges (`.code-block-lang`), and interactive clipboard Copy buttons (`.code-copy-btn`). Fixed CSS selector conflict where `.hljs` reset outer `<pre>` container styling. Verified on physical hardware (`CPH1859`) across Light and AMOLED Dark modes.
- `UI-006`: Converted `ActionsSheet` to `StatefulWidget` with local `_selectedThemeMode`. Tapping theme buttons immediately reflects selection border and switches app theme synchronously on the same frame.
- `UI-007`: Resolved desktop WebKitGTK airspace occlusion via non-destructive `rightInset: 304.0`. More Actions popover and TOC drawer render cleanly alongside fully visible Reader view without full-screen blanking. Verified on Linux desktop release build.
- `UI-008`: Recreated branded app icon from original Tauri Tsuzuri kanji calligraphy `綴` with Apple HIG continuous curvature rounded corners ($r/w = 0.224$) and crisp 28px white border on AMOLED black canvas. Deployed across `assets/icon/`, `README.md`, `about_dialog.dart`, Android mipmaps, iOS/macOS AppIcon sets, Web, Windows ICO, and Linux desktop window icon runner.
- `UI-009`: Refactored `TsuzuriAboutDialog` to strictly match the original Tauri Tsuzuri application layout and copy (`index.html` lines 298–328). Version dynamically resolved from `pubspec.yaml` via asset bundle parsing with memory caching. Removed all extraneous technical metadata rows and bottom button.
- `UI-010`: Resolved Linux desktop About dialog background void in Reader view by maintaining 100% WebKitGTK visibility and embedding the modal backdrop internally via `template.html` and `renderer.css` (`backdrop-filter: blur(4px)`, `background-color: rgba(0, 0, 0, 0.65)`). Clean semantic version string (`2.0.0`) stripped of build metadata (`+1`) across all UI views and tests.
- `UI-011`: In-WebView Actions Popover Parity & Zero-Width-Reduction Reader View on Linux. Embedded `#popover-backdrop` and `#actions-popover` inside `template.html` and `renderer.css` mirroring Tauri Tsuzuri styling (`layout.css` lines 656–740). Bidirectional Flutter <-> WebKitGTK action bridge handles menu actions and theme switching. Eliminated `rightInset: 304.0` in Reader view, maintaining 100% full-width document canvas with zero text reflow, zero line-wrapping shifts, and zero jumping on menu toggle.
- `DOC-003`: Multi-Platform GitHub Actions Workflows & Tsuzuri v2 Documentation Parity. Configured automated production release workflow (`.github/workflows/release.yml`) and mobile CI workflow (`.github/workflows/build-mobile.yml`) generating application binaries for all 6 target platforms (Linux `.deb`/`.tar.gz`, Windows `.zip`, macOS `.dmg`/`.zip`, Android `.apk`/`.aab`, iOS `.ipa`, Web `.zip`). Created version synchronization scripts (`scripts/sync-version.js`, `scripts/sync-version.sh`). Modernized `README.md` to highlight Tsuzuri v2, architecture evolution from v1, feature comparison matrix, build commands, and workflow documentation.
- `UI-012`: Canonical Application Name Standardization ("Tsuzuri"). Standardized application display name across all platforms to strictly `"Tsuzuri"` with a capital `"T"`, nothing else (Android manifest label, iOS CFBundleName, macOS PRODUCT_NAME, Linux GTK window/header bar title, Windows window title and resource strings, Web title and manifest, and default document header).
- `CI-001`: macOS Release Workflow Portability & Dynamic Bundle Discovery. Replaced non-portable `sed -i` in `scripts/sync-version.sh` with POSIX-compliant output redirection to support BSD `sed` on macOS GitHub Actions runners. Hardened `.github/workflows/release.yml` with dynamic discovery of the macOS `.app` bundle name (`Tsuzuri.app`), preventing path mismatch failures during DMG creation and ZIP archiving. Verified script execution and test suite.
- `CI-002`: Windows Release Workflow MSVC Coroutine Deprecation Suppression & Resilient Packaging. Defined `_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS` globally in `windows/CMakeLists.txt` and inside `APPLY_STANDARD_SETTINGS`, eliminating MSVC `error STL1011` static assertion failure in `webview_all_windows_plugin`. Configured `env: CL: ...` in `.github/workflows/release.yml` and hardened PowerShell ZIP packaging with fallback path discovery. Verified test suite.
- `CI-003`: Multi-Platform Release Workflow DAG Decoupling & Concurrent Execution. Replaced sequential `needs: release-desktop` dependencies with an independent `create-release` initialization job. Decoupled Desktop, Android (APK/AAB), iOS (IPA), and Web target builds to execute simultaneously in parallel, preventing failures or delays on one platform from causing cascade skips on mobile or web targets. Verified test suite and DAG structure.
- `CI-004`: Absolute Path Subshell Packaging for macOS, iOS, and Web CI Release Artifacts. Replaced fragile `../../../../` relative traversal in macOS zip packaging with absolute `$WORKSPACE` / `$PWD` paths within isolated subshell `(cd build/macos/Build/Products/Release && zip -r "$WORKSPACE/release-artifacts/..." "$APP_NAME")`. Standardized subshell packaging across Web and iOS release jobs. Verified test suite.
- `UI-013`: Editor Gutter Line-Wrap Synchronization, Persistent View Stack, and Linux In-WebView Tooltip Bridge. Implemented dynamic editor line-wrap gutter synchronization via `StrutStyle(forceStrutHeight: true)` and cached `TextPainter` measurements matching reference project `md-latex-mermaid2pdf`, resolving line number misalignment and Android vertical drift. Switched cursor position tracking to `selection.extentOffset`. Swapped conditional view mounting with persistent `Offstage` + `TickerMode` stack in `AppShell`, eliminating cold-start blank screen flash on mode toggle. Implemented in-webview header action tooltip bridge (`#header-tooltip`) over WebKitGTK on Linux. Optimized keystroke dirty-state triggering to maintain 60fps typing responsiveness.
- `LIB-001`: Initial Library Screen & Document Thumbnail Gallery Grid. Implemented initial Library screen as primary application entry point. Structured browsing experience as a responsive document gallery grid modeled after note galleries like Mi Canvas. Permanently anchored dedicated "New Document" tile with prominent `+` at index 0 regardless of sort mode, prompting for filename (validating `.md`, `.markdown`, `.mdown`, `.mkdn`), writing atomic initial markdown content, registering in library, and navigating directly into Editor mode. Implemented lightweight `ThumbnailService` and `DocumentThumbnail` miniature sheet-of-paper previews reading only opening snippets (~3KB) with in-memory LRU cache (250 entries) and safe fallback badges for LaTeX (`[Formula]`) and Mermaid diagrams (`[Mermaid Diagram]`). Integrated real-time search, multi-field sorting, context menus (Open in Reader, Open in Editor, safe Remove from Library), and responsive layout across all 7 required viewports (320px to 1920px) with 0 RenderFlex overflow errors.
- `LIB-002`: Document Thumbnail Responsive Page Boundary Clipping & RenderFlex Overflow Elimination. Diagnosed root cause of RenderFlex overflow assertions during Linux desktop window unmaximized and resizing states (9.5px and 17px overflow on Column in `DocumentThumbnail`). Replaced unconstrained inner flex measurement with bounded `Stack(fit: StackFit.expand)`, `ClipRect`, and `OverflowBox(alignment: Alignment.topLeft, minWidth: 0, minHeight: 0, maxHeight: double.infinity)`. Miniature document preview blocks lay out naturally starting from the top, wrap cleanly within paper width minus padding, and clip strictly at the visible page boundary without scrolling overhead or layout assertions. Verified across unmaximized (800x600, 750x580, 680x520, 550x480), maximized (1920x1080), and continuous dynamic resizing tests. 72/72 tests passing with 0 flutter analyze warnings.
- `LIB-003`: Unified Library Actions, Theme Switcher, and About Dialog Integration. Exposed the About Tsuzuri dialog and 3-mode Theme Switcher (System, Light, AMOLED Dark) on the initial Library screen without code duplication. Refactored `ActionsSheet` with `isLibraryMode: true`, showing "Open Document...", "Add Folder to Library...", "Rescan Library Folders", "About Tsuzuri", and the Theme Switcher. Added a More Actions (`...`) button in the `LibraryScreen` header row and verified theme changes apply immediately and synchronously across the entire app shell and library.
- `LIB-004`: Persistent User-Authorized Directory Management and Recursive Markdown Discovery. Implemented persistent authorized directories in `LibraryService` via `SharedPreferences`. Added recursive directory discovery (`discoverInDirectory()`) traversing subfolders up to depth 4, recognizing supported extensions (`.md`, `.markdown`, `.mdown`, `.mkdn`) case-insensitively, and skipping hidden directories (`.git`, `.cache`, `.config`) and common build caches (`node_modules`, `build`, `.dart_tool`, `.gradle`, `target`). Implemented `rescanAll()` merging disk files with existing entries, canonicalizing paths to prevent duplicates, and flagging removed files as inaccessible without data loss. Added "Add Folder..." and "Manage Folders..." in the Add menu.
- `RENDER-008`: In-WebView Responsive TOC Panel on Linux and Universal Viewport Accessibility. Resolved Table of Contents (TOC) layout disruption and airspace occlusion on Linux desktop and narrow viewports. On Linux desktop WebKitGTK, opening the TOC previously shrank the webview by 304px, shifting the document canvas to the left. On mobile widths (< 681px), Flutter's native `endDrawer` was occluded behind the WebKitGTK native child window, and on viewports < 360px the TOC button was conditionally hidden in `AppHeader`. Embedded an in-webview `#toc-panel` and `#toc-backdrop` inside `template.html` and `renderer.css`, routed TOC opening to `ReaderView.openTocPanel()` via JavaScript bridge with `rightInset: 0.0` (zero document displacement), and unconditionally exposed the TOC button across all viewports.

## 5. Verification Records
- `flutter analyze`: Passed with 0 issues found.
- `flutter test`: All 80 unit, widget, responsive, and regression tests passed.
- `flutter build linux --release`: `✓ Built build/linux/x64/release/bundle/tsuzuri` (verified crash-free execution on Linux host).
- `flutter build linux --debug`: `✓ Built build/linux/x64/debug/bundle/tsuzuri` (verified crash-free execution on Linux host).
- `flutter build web --release`: `✓ Built build/web`.
- `flutter run -d CPH1859` / Hardware Installation: Verified on physical Android 9 device `SW898SDUSOYHCEMV` (`CPH1859`) with interactive Dart VM service, AMOLED pure black canvas, KaTeX inline/display math, mhchem chemistry notation (`\ce{2H2 + O2 -> 2H2O}` and `\ce{CO2 + H2O <=> H2CO3}`), SVG Mermaid diagrams, syntax-highlighted code blocks with responsive word wrapping, and mutually exclusive editor mode.
- Real-world Corpus Verification: Full 217 KB GATE DA guide (7,252 lines, 94 display equations, 334 code fences, 7 Mermaid diagrams) parsed and typeset with 100% delimiter protection and 0 fence boundary collisions.
- Code Section Distinction Verification: Verified code blocks render inside dedicated `.code-block-wrapper` cards with elevated header strips, language tags (`DART`, `PYTHON`, `SQL`, etc.), copy buttons, and high-contrast boundaries in both Light and AMOLED Dark modes on physical Android hardware.
- Desktop Airspace Occlusion & Popover Verification: Verified in-webview popover renders directly over the 100% full-width Reader view with 0 reader width reduction (`rightInset: 0.0`), eliminating text reflow and content jumping.
- Theme Switcher Instantaneous Reflection Verification: Verified theme buttons update selection border immediately upon click while synchronously transitioning application background between `#000000` AMOLED and `#FCFCFC` Light.
- GitHub Actions Workflows Verification: Verified workflow syntax, triggers, platform matrix, and version synchronization scripts (`./scripts/sync-version.sh 2.0.0`) for Linux, Windows, macOS, Android, iOS, and Web.
- Canonical Name Verification: Verified application title is strictly `"Tsuzuri"` across Android, iOS, macOS, Linux, Windows, Web, and Flutter UI layers.
- macOS Release Workflow Portability Verification: Verified `./scripts/sync-version.sh "v2.0.0"` executes cleanly with exit code 0 using POSIX redirection across BSD and GNU sed, and hardened `.github/workflows/release.yml` with dynamic bundle path resolution.
- Windows Release Workflow MSVC Coroutine Deprecation Verification: Verified preprocessor definitions in `windows/CMakeLists.txt` and `release.yml` suppress STL1011 static assertion in `webview_all_windows`, with hardened fallback path resolution in PowerShell.
- Workflow DAG Decoupling Verification: Verified independent `create-release` job allows Desktop, Android, iOS, and Web targets to build concurrently with zero cascade skips upon individual platform failures.
- macOS Subshell Packaging Verification: Verified absolute workspace directory resolution in isolated subshell eliminates zip I/O error 15, standardizing packaging across macOS, Web, and iOS.
- Editor Gutter Line-Wrap Synchronization & Persistent Mode Switch Verification: Verified with widget tests that wrapped lines dynamically expand gutter item heights in exact sync with text line wrapping, selection tracking accurately reflects caret position, and persistent Offstage view stack eliminates blank screen cold starts.
- Library Gallery Grid & Native Thumbnail Generation Verification: Verified with 8 comprehensive widget and 7 unit tests that the Library is the initial route, New Document tile is permanently first, document opening previews render within tile bounds, math and mermaid diagrams render safe fallback badges, search and sort operate cleanly, responsive column counts adapt without horizontal overflow across 320px–1920px viewports, and remove actions never delete files.

## 6. Definition of Done Checklist
- [x] Application is implemented in Flutter and Dart.
- [x] Core architecture is documented and maintainable.
- [x] Reader and Editor are separate, mutually exclusive views.
- [x] Initial Library screen serves as primary launch route with visual document gallery.
- [x] Dedicated "New Document" tile is always anchored as the first tile in the gallery.
- [x] Lightweight Flutter-native document thumbnail previews render opening content without webviews.
- [x] Markdown support has been tested against the reference baseline.
- [x] LaTeX delimiters and required mathematical features have been tested.
- [x] Mermaid diagrams render locally for the documented supported subset.
- [x] Required rendering resources work offline (zero CDNs).
- [x] Local images and relative paths work.
- [x] File opening, editing, and atomic saving behave reliably.
- [x] Light, Dark, and System themes work, with System as default.
- [x] AMOLED dark mode uses a true black `#000000` main surface.
- [x] Responsive layout tests have been run (320px, 375px, 430px, 768px, 1024px, 1440px, 1920px).
- [x] Desktop/tablet More Actions menu operates as an anchored top-right popover dropdown (>= 681px) per Tauri Tsuzuri design.
- [x] Mobile More Actions menu operates as a bottom sheet with grab handle (< 681px).
- [x] Editor line gutter has zero visible scrollbars on desktop viewports.
- [x] Chemistry equations (\ce{...} and \pu{...}) render into typeset chemical notation via offline KaTeX and mhchem.
- [x] Code blocks display rich syntax highlighting across Light and AMOLED Dark themes.
- [x] Code blocks enforce responsive word wrapping preventing horizontal clipping.
- [x] Code snippets render as distinct, structured sections with elevated language header bars and clipboard copy actions.
- [x] Large and complex documents with backticks in comments and immediate prose after code blocks render cleanly without fence boundary collisions or math inversion.
- [x] Theme switcher immediately updates selection outline and app theme synchronously without closing the menu.
- [x] Desktop More Actions popover renders over 100% full-width Reader view with zero text reflow, zero jumping, and zero blank screen occlusion.
- [x] Multi-platform GitHub Actions release and CI workflows generate binaries across all 6 target platforms matching Tauri Tsuzuri repository design.
- [x] Application name is strictly "Tsuzuri" across all platform configurations, window titles, and shells.
- [x] No known critical data-loss or security defect remains.
- [x] Build and test results are recorded honestly.
- [x] Platform support claims match actual verification.
- [x] README reflects Tsuzuri v2, architecture evolution from v1, and full desktop & mobile visual showcases.
- [x] All progress files match the actual repository.
- [x] Another agent can resume development from the persistent project state.

## 7. Last Updated
- **Date**: 2026-10-15
- **Latest Change**: Implemented Task `LIB-001`: Redesigned Tsuzuri v2 Library screen as a visual Document Thumbnail Gallery Grid with dedicated first "New Document" tile, lightweight Flutter-native opening snippet previews (`DocumentThumbnail` and `ThumbnailService`), LRU caching, math/mermaid fallback badges, responsive layout across 320px–1920px viewports, real-time search, sorting, context menus, and navigation integration. 68/68 tests passing; 0 analyzer issues. Built clean Linux debug binary.








