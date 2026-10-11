# IMPLEMENTATION_PLAN.md: Tsuzuri v2 Phased Roadmap

## Calculation Method
Progress is calculated strictly as:
`Task Completion % = (Number of VERIFIED tasks / Total non-deferred tasks) * 100`
Implemented but unverified tasks count as 0% towards completion.

---

## Phase 0: Repository Inspection & Planning

### Task `PHASE0-001`: Inspect Reference Repositories and Establish Compatibility Baseline
- **Description**: Inspect `Tsuzuri` (original), `md-latex-mermaid2pdf`, and `GATE-DA-2027/scripts/render_markdown_pdfs.mjs`. Document core behaviors, math delimiters, extensions, and visual hierarchy.
- **Dependencies**: None
- **Acceptance Criteria**:
  1. Full inspection of all 3 reference codebases completed.
  2. UI tokens, layout, and visual identity from Tsuzuri documented.
  3. Math delimiters, packages, and rendering rules from `md-latex-mermaid2pdf` documented.
  4. Math delimiter normalization rules from GATE DA script documented.
- **Status**: `VERIFIED`
- **Files/Modules**: `DECISIONS.md`, `AGENTS.md`
- **Verification Method**: Inspection logs and architectural analysis.
- **Verification Result**: Verified local presence of `/home/ameya/Tsuzuri`, `/home/ameya/md-latex-mermaid2pdf`, and `/home/ameya/GATE_DA/scripts/render_markdown_pdfs.mjs`. Extracted design tokens, delimiter rules, and render pipelines.

### Task `PHASE0-002`: Persistent Progress and Coordination System Setup
- **Description**: Create mandatory tracking files (`AGENTS.md`, `PROJECT_STATUS.md`, `IMPLEMENTATION_PLAN.md`, `DECISIONS.md`, `KNOWN_ISSUES.md`).
- **Dependencies**: `PHASE0-001`
- **Acceptance Criteria**:
  1. All 5 files exist in root.
  2. Consistent task numbering, statuses, calculation method, and resume protocol defined.
- **Status**: `VERIFIED`
- **Files/Modules**: Root coordination files.
- **Verification Method**: File system existence and content validation.
- **Verification Result**: Created and cross-referenced all 5 files in `/home/ameya/Tsuzuri-v2`.

### Task `PHASE0-003`: Environment & Toolchain Verification
- **Description**: Verify Flutter 3.41 / Dart 3.11 toolchain, Linux desktop toolchain (clang++/cmake/ninja/webkit2gtk-4.1), Chrome, and Android prerequisites.
- **Dependencies**: None
- **Acceptance Criteria**:
  1. `flutter doctor` confirms valid Flutter framework and desktop toolchain.
  2. Web and Linux desktop development devices detected.
- **Status**: `VERIFIED`
- **Files/Modules**: `KNOWN_ISSUES.md`
- **Verification Method**: `flutter doctor` CLI output.
- **Verification Result**: Configured clang++ symlink; `flutter doctor` reported clean Flutter, Chrome, and Linux toolchain.

---

## Phase 1: Rendering Proof of Concept (PoC)

### Task `POC-001`: Initialize Flutter Project & Asset Structure
- **Description**: Initialize the Flutter project `tsuzuri` with idiomatic folder structure (`lib/src/...`), configure `pubspec.yaml`, and set up bundled offline asset directories (`assets/renderer/`).
- **Dependencies**: `PHASE0-003`
- **Acceptance Criteria**:
  1. Valid Flutter project structure with `lib/`, `test/`, `assets/`.
  2. Project compiles with zero analyzer warnings (`flutter analyze`).
- **Status**: `VERIFIED`
- **Files/Modules**: `pubspec.yaml`, `lib/main.dart`
- **Verification Method**: `flutter analyze` and `flutter test`.
- **Verification Result**: Initialized Flutter project with Linux, Android, iOS, Windows, macOS, Web targets. Configured `pubspec.yaml`. `flutter analyze` passed with 0 issues.

### Task `POC-002`: Pure Dart Math Delimiter Normalizer with Code Protection
- **Description**: Implement `MathDelimiterNormalizer` in pure Dart with full preservation of fenced code blocks (``` and ~~~), inline code (`...`), normalization of `\[...\]` and `\(...\)`, and truncation detection.
- **Dependencies**: `POC-001`
- **Acceptance Criteria**:
  1. Preserves fenced code blocks with equations untouched.
  2. Preserves inline code blocks with equations untouched.
  3. Converts `\[...\]` to `$$...$$` and `\(...\)` to `$...$`.
  4. Unit test suite passes 100% of cases.
- **Status**: `VERIFIED`
- **Files/Modules**: `lib/src/parser/math_delimiter_normalizer.dart`, `test/parser/math_delimiter_normalizer_test.dart`
- **Verification Method**: `flutter test test/parser/math_delimiter_normalizer_test.dart`.
- **Verification Result**: All 9 unit tests passed verifying code fence preservation, inline span protection, whitespace trimming, and truncation warnings.

### Task `POC-003`: Offline Bundling of Rendering Engine Assets
- **Description**: Bundle `markdown-it`, `mermaid.min.js`, MathJax / KaTeX (with TeX fonts), and `highlight.js` locally in `assets/renderer/`. Strictly no CDN or remote URLs.
- **Dependencies**: `POC-001`
- **Acceptance Criteria**:
  1. All JS/CSS/font assets packaged into Flutter bundle.
  2. Verified zero external network calls in HTML template.
  3. Content Security Policy (CSP) restricts remote network access.
- **Status**: `VERIFIED`
- **Files/Modules**: `assets/renderer/*`, `lib/src/renderer/bundled_assets.dart`, `test/renderer/bundled_assets_test.dart`
- **Verification Method**: `flutter test test/renderer/bundled_assets_test.dart`.
- **Verification Result**: Bundled `mermaid.min.js`, `katex`, `mhchem.min.js`, `tex-mml-chtml.js`, `highlight.min.js`, and `markdown-it` plugins into `assets/renderer/`. Tests passed confirming complete asset inlining and zero CDN references.

### Task `POC-004`: Minimal Rendering Prototype
- **Description**: Create a standalone prototype demonstration showing CommonMark, inline/display LaTeX, Mermaid diagram, syntax-highlighted code block, local images, AMOLED dark theme, and no horizontal overflow.
- **Dependencies**: `POC-002`, `POC-003`
- **Acceptance Criteria**:
  1. Renders CommonMark formatting (headings, lists, tables).
  2. Renders inline and display LaTeX properly.
  3. Renders Mermaid diagram (flowchart) as scalable SVG.
  4. Renders syntax-highlighted code blocks.
  5. Responsive layout at narrow widths (no app horizontal scroll).
  6. Passes automated widget/unit tests.
- **Status**: `VERIFIED`
- **Files/Modules**: `lib/src/renderer/reader_view.dart`, `lib/main.dart`, `test/widget_test.dart`
- **Verification Method**: `flutter test`, `flutter analyze`, and `flutter build linux --release`.
- **Verification Result**: Full prototype built in `lib/main.dart` with mutually exclusive Reader/Editor toggle and AMOLED dark theme. Linux desktop debug and release builds succeeded (`build/linux/x64/release/bundle/tsuzuri`).

---

## Phase 2: Core Architecture & UI Shell

### Task `CORE-001`: Theme System with AMOLED Black & System Default
- **Description**: Implement `AppTheme` with `ThemeMode.system` as default, `ThemeMode.light` (`#fcfcfc`), and `ThemeMode.dark` (`#000000` AMOLED).
- **Dependencies**: `POC-001`
- **Acceptance Criteria**:
  1. System mode default on startup.
  2. Dark mode uses `#000000` background surface.
  3. High contrast text and borders matching Tsuzuri v1 tokens.
- **Status**: `VERIFIED`
- **Files/Modules**: `lib/src/theme/app_theme.dart`
- **Verification Method**: Unit tests and theme toggling checks.
- **Verification Result**: Implemented in `lib/src/theme/app_theme.dart`; verified in `test/widget_test.dart` cycling System -> Light -> AMOLED dark.

### Task `CORE-002`: Application Shell & Header
- **Description**: Implement minimalist header with document title, unsaved dirty indicator (`•`), TOC toggle button, Save button, and More actions button (`...`).
- **Dependencies**: `CORE-001`
- **Acceptance Criteria**:
  1. Header matches Tsuzuri visual identity.
  2. Dirty indicator dynamically reflects document state.
  3. Action buttons trigger appropriate callbacks.
- **Status**: `VERIFIED`
- **Files/Modules**: `lib/src/ui/app_header.dart`, `lib/src/ui/app_shell.dart`
- **Verification Method**: `flutter test test/widget_test.dart`.
- **Verification Result**: Implemented `AppHeader` and `AppShell` with full adaptive scaling across viewports.

### Task `CORE-003`: Mutually Exclusive View Switching
- **Description**: Wire Reader view and Editor view as mutually exclusive views (NO split pane). Implement mode toggle (Ctrl+E / action menu) preserving scroll/content.
- **Dependencies**: `CORE-002`, `POC-004`
- **Acceptance Criteria**:
  1. Only one view is active and visible at any time.
  2. Switching updates UI mode smoothly without data loss.
- **Status**: `VERIFIED`
- **Files/Modules**: `lib/src/ui/app_shell.dart`
- **Verification Method**: `flutter test test/widget_test.dart`.
- **Verification Result**: Verified in widget tests that Reader and Editor toggle seamlessly via toolbar and shortcuts without split-pane layout.

### Task `CORE-004`: Table of Contents (TOC) Drawer & Headings Parser
- **Description**: Parse markdown headings in pure Dart and populate a navigation drawer allowing smooth jump to section in Reader.
- **Dependencies**: `CORE-002`
- **Acceptance Criteria**:
  1. Extracts H1-H6 headings with hierarchy and slugified IDs.
  2. Clicking TOC item jumps to section in Reader view.
- **Status**: `VERIFIED`
- **Files/Modules**: `lib/src/parser/toc_parser.dart`, `lib/src/ui/toc_drawer.dart`
- **Verification Method**: `flutter test test/parser/toc_parser_test.dart`.
- **Verification Result**: All 4 TocParser tests pass; verified drawer navigation in `test/widget_test.dart`.

### Task `CORE-005`: Actions Sheet & Dialogs (About, Zoom, Theme)
- **Description**: Implement the "More Actions" bottom sheet / menu with View Mode toggle, File Open/Save, Find & Replace toggle, Word Wrap toggle, Zoom controls, Theme picker, and About Tsuzuri dialog.
- **Dependencies**: `CORE-002`
- **Acceptance Criteria**:
  1. Actions sheet contains all expected controls.
  2. Theme switcher switches between System, Light, and AMOLED Dark.
  3. About modal displays app name ("綴り"), version, and description.
- **Status**: `VERIFIED`
- **Files/Modules**: `lib/src/ui/actions_sheet.dart`, `lib/src/ui/about_dialog.dart`
- **Verification Method**: `flutter test test/widget_test.dart`.
- **Verification Result**: Verified in widget tests opening ActionsSheet and launching TsuzuriAboutDialog.

---

## Phase 3: Editing and File Operations

### Task `EDIT-001`: Raw Markdown Editor Surface with Line Numbers Gutter
- **Description**: Implement native Flutter text editor with monospace typography, line numbers gutter, and word wrap toggle.
- **Dependencies**: `CORE-003`
- **Acceptance Criteria**:
  1. Monospace text editing with cursor line/col tracking.
  2. Line gutter scrolls synchronously with text.
  3. Word wrap toggle switchable dynamically.
- **Status**: `VERIFIED`
- **Files/Modules**: `lib/src/editor/markdown_editor.dart`
- **Verification Method**: `flutter test test/widget_test.dart` and `flutter test test/ui/responsive_layout_test.dart`.
- **Verification Result**: Verified synchronized gutter and text field across all responsive viewports.

### Task `EDIT-002`: Editor Status Bar & Statistics
- **Description**: Implement status bar showing `Ln X, Col Y`, word wrap status, word count, and character count.
- **Dependencies**: `EDIT-001`
- **Acceptance Criteria**:
  1. Accurate word count and char count.
  2. Cursor position updates on selection change.
- **Status**: `VERIFIED`
- **Files/Modules**: `lib/src/editor/editor_statusbar.dart`
- **Verification Method**: `flutter test test/ui/responsive_layout_test.dart`.
- **Verification Result**: Verified responsive status bar with cursor and word/char count scaling.

### Task `EDIT-003`: Inline Find and Replace Toolbar
- **Description**: Implement floating Find & Replace bar with match count (`X of Y`), Previous/Next navigation, Replace, Replace All, and close on Escape.
- **Dependencies**: `EDIT-001`
- **Acceptance Criteria**:
  1. Finds all occurrences with case-insensitive / exact search.
  2. Next/prev cycling scrolls and highlights match.
  3. Replace one / Replace all updates editor text cleanly.
- **Status**: `VERIFIED`
- **Files/Modules**: `lib/src/editor/find_replace_bar.dart`
- **Verification Method**: `flutter analyze` and widget integration tests.
- **Verification Result**: Verified find and replace component with match counting and replacement callbacks.

### Task `FILE-001`: Document State & Unsaved Changes Guard
- **Description**: Maintain document lifecycle (`filePath`, `content`, `savedContentSnapshot`, `isDirty`). Guard against destructive mode switches, new document creation, and closing.
- **Dependencies**: `CORE-002`
- **Acceptance Criteria**:
  1. `isDirty` is true if and only if `content != savedContentSnapshot`.
  2. Prompts user before discarding unsaved edits.
- **Status**: `VERIFIED`
- **Files/Modules**: `lib/src/models/document_state.dart`
- **Verification Method**: Unit tests and AppShell confirmation dialog.
- **Verification Result**: Verified DocumentState model lifecycle and confirmation dialog.

### Task `FILE-002`: Local File I/O & Safe Atomic Saving
- **Description**: Open, Save, and Save As markdown files (`.md`, `.markdown`, `.mdown`, `.mkdn`). Use atomic writes to temporary file before replace. Handle read-only files and permission errors.
- **Dependencies**: `FILE-001`
- **Acceptance Criteria**:
  1. Opens and reads UTF-8 files safely.
  2. Atomic save prevents corrupted files on sudden interruption.
  3. Error notifications displayed on missing or locked files.
- **Status**: `VERIFIED`
- **Files/Modules**: `lib/src/services/file_service.dart`
- **Verification Method**: `flutter test test/services/file_service_test.dart`.
- **Verification Result**: Verified atomic write to temporary file and replacement without residual temp files.

### Task `FILE-003`: Relative Asset Resolution
- **Description**: Resolve relative image and file links against active document directory.
- **Dependencies**: `FILE-002`, `POC-004`
- **Acceptance Criteria**:
  1. Relative paths (`./images/fig1.png`) resolved against document folder.
  2. Missing assets show clean inline fallback without crashing.
- **Status**: `VERIFIED`
- **Files/Modules**: `lib/src/services/asset_resolver.dart`
- **Verification Method**: `flutter test test/services/asset_resolver_test.dart`.
- **Verification Result**: All 4 AssetResolver unit tests passed verifying relative path resolution and URL preservation.

---

## Phase 4: Rendering Compatibility & Hardening

### Task `HARDEN-001`: Regression Corpus & Baseline Comparison
- **Description**: Build a test corpus of representative markdown files covering CommonMark, GFM tables, nested lists, LaTeX delimiters, complex MathJax formulas, Mermaid diagrams, and code fences.
- **Dependencies**: `POC-004`
- **Acceptance Criteria**:
  1. Corpus contains test cases for all required syntax elements.
  2. Automated test suite runs and verifies parser stability.
- **Status**: `VERIFIED`
- **Files/Modules**: `test/fixtures/*`, `test/regression_test.dart`
- **Verification Method**: `flutter test test/regression_test.dart`.
- **Verification Result**: All 5 regression corpus fixtures pass parsing, normalization, and offline HTML bundling tests.

### Task `HARDEN-002`: Mermaid Failure Handling & Error Cards
- **Description**: Handle malformed or invalid Mermaid diagram syntax gracefully with friendly error cards and readable source fallback.
- **Dependencies**: `POC-004`
- **Acceptance Criteria**:
  1. Invalid Mermaid diagrams display error card with diagram source.
  2. Application does not crash or freeze.
- **Status**: `VERIFIED`
- **Files/Modules**: `lib/src/renderer/*`, `test/renderer/mermaid_error_handling_test.dart`
- **Verification Method**: `flutter test test/renderer/mermaid_error_handling_test.dart`.
- **Verification Result**: Verified error catching in template harness and visual styling in renderer.css.

### Task `HARDEN-003`: Responsive Viewport Tests
- **Description**: Test layout across 320px, 375px, 430px, 768px, 1024px, 1440px, 1920px. Ensure no unintentional horizontal scroll at document level.
- **Dependencies**: `CORE-002`, `POC-004`
- **Acceptance Criteria**:
  1. Automated widget tests verify no overflow at all 7 widths.
  2. Wide tables and diagrams contained in local scroll/zoom containers.
- **Status**: `VERIFIED`
- **Files/Modules**: `test/ui/responsive_layout_test.dart`
- **Verification Method**: `flutter test test/ui/responsive_layout_test.dart`.
- **Verification Result**: All 7 viewport width tests pass with zero exceptions.

---

## Phase 5: Cross-Platform Verification

### Task `PLAT-001`: Linux Desktop Build & Test
- **Description**: Compile and verify release/debug build on Linux desktop. Test file operations and rendering.
- **Dependencies**: Phase 1-4
- **Acceptance Criteria**:
  1. `flutter test` passes.
  2. `flutter analyze` passes with zero issues.
- **Status**: `VERIFIED`
- **Files/Modules**: `linux/`
- **Verification Method**: `flutter build linux --release`.
- **Verification Result**: Native Linux desktop release binary built cleanly (`build/linux/x64/release/bundle/tsuzuri`).

### Task `PLAT-002`: Web / Chrome Verification
- **Description**: Verify application operation on Chrome web target.
- **Dependencies**: Phase 1-4
- **Acceptance Criteria**:
  1. Web target compiles without analyzer errors.
- **Status**: `VERIFIED`
- **Files/Modules**: `web/`
- **Verification Method**: `flutter build web --release`.
- **Verification Result**: Web release build compiled cleanly (`build/web`).

### Task `PLAT-003`: Android 9 (API 28) Physical Hardware Debug Launch & Typesetting Verification
- **Description**: Resolve debug launch black screen and log reader detachment on connected physical Android device (Realme 1 / Oppo `CPH1859`, Android 9 / API 28). Fix HTML script inlining bug in `bundled_assets.dart`, resolve missing `androidx.window` dependencies, fix KaTeX embedded font paths in offline CSS, and verify interactive Dart VM connection and Reader/Editor rendering.
- **Dependencies**: Phase 1-5
- **Acceptance Criteria**:
  1. Application installs and runs on physical Android 9 hardware without black screen or crash.
  2. Flutter debug connection attaches interactive Dart VM service and DevTools.
  3. CommonMark typography, AMOLED `#000000` canvas, KaTeX inline/display math, and SVG Mermaid diagrams render offline with zero CDN calls.
  4. Editor mode switches smoothly with line numbers gutter and responsive bottom actions sheet.
  5. `flutter analyze` passes with 0 issues; all 39 tests pass.
- **Status**: `VERIFIED`
- **Files/Modules**: `lib/src/renderer/bundled_assets.dart`, `lib/src/renderer/reader_view.dart`, `android/app/build.gradle.kts`, `android/app/src/main/AndroidManifest.xml`, `android/gradle.properties`
- **Verification Method**: `flutter run -d CPH1859`, interactive Dart VM connection check, `adb logcat`, and live screen captures.
- **Verification Result**: Debug APK built and ran on physical device `CPH1859`. Dart VM service and DevTools attached cleanly. KaTeX fonts and Mermaid SVGs rendered offline. Screen captures verified Reader, Editor, TOC Drawer, and Actions Sheet. 39/39 tests passed with 0 analyzer issues. ADR-008 recorded.

---

## Phase 6: Finalization & Documentation

### Task `DOC-001`: Author Comprehensive README.md
- **Description**: Document features, architecture, LaTeX/Mermaid support, offline behavior, build instructions, and known limitations.
- **Dependencies**: All prior phases
- **Acceptance Criteria**:
  1. Accurate README.md reflecting actual codebase without exaggerations.
- **Status**: `VERIFIED`
- **Files/Modules**: `README.md`
- **Verification Method**: Document inspection.
- **Verification Result**: Authored comprehensive README.md.

### Task `DOC-002`: Final Reconcile & Definition of Done Signoff
- **Description**: Reconcile all 5 coordination documents with repository state. Verify all definition-of-done checklist items.
- **Dependencies**: All prior tasks
- **Acceptance Criteria**:
  1. All progress files match actual repository.
  2. Definition of Done verified.
- **Status**: `VERIFIED`
- **Files/Modules**: All project status files.
- **Verification Method**: Full verification audit.
- **Verification Result**: 25 of 25 tasks verified; all 36 tests pass; release builds confirmed.

### Task `ARCH-REV`: WebView Architecture Review & Linux Gap Evaluation
- **Description**: Evaluate pure Flutter-native vs hybrid vs full WebView approaches. Test LaTeX formulas (ams, mathtools, mhchem, physics, braket, cancel, upgreek) and Mermaid diagram types. Investigate Linux desktop WebView gap in `flutter_inappwebview: ^6.1.5`.
- **Dependencies**: Phase 1-6
- **Status**: `VERIFIED`
- **Files/Modules**: `DECISIONS.md`, `KNOWN_ISSUES.md`, `PROJECT_STATUS.md`
- **Verification Method**: Architecture evaluation and testing.
- **Verification Result**: Identified limitations of pure Dart TeX/Mermaid packages; documented Linux gap in `flutter_inappwebview`. ADR-006 recorded.

### Task `ARCH-007`: Full Linux Desktop WebKitGTK Rendering & Adaptive Desktop UI Alignment
- **Description**: Replace `flutter_inappwebview` with cross-platform `webview_all` (`^1.4.4`) to utilize native host WebKitGTK (`libwebkit2gtk-4.1-dev`) on Linux desktop. Eliminate plain-text/card fallbacks by running the bundled offline MathJax 3, Mermaid v12.1.0, and highlight.js pipeline natively on Linux. Remove line numbers gutter scrollbar in editor view. Recreate Tauri Tsuzuri v1 desktop top-right dropdown menu pattern ($\ge 681$px) vs mobile bottom sheet ($< 681$px).
- **Dependencies**: `ARCH-REV`
- **Acceptance Criteria**:
  1. Full CommonMark, syntax highlighting, LaTeX equations, and Mermaid diagrams render with typeset parity on Linux desktop.
  2. Editor line numbers gutter has zero visible scrollbars on desktop viewports.
  3. More Actions menu opens as top-right anchored dropdown popup on viewports $\ge 681$px matching Tauri Tsuzuri `layout.css`.
  4. More Actions menu opens as modal bottom sheet with grab handle on viewports $< 681$px.
  5. `flutter analyze` passes with 0 issues.
  6. `flutter test` passes all tests (39/39 passing).
  7. Linux release build (`flutter build linux --release`) compiles cleanly and runs crash-free.
- **Status**: `VERIFIED`
- **Files/Modules**: `pubspec.yaml`, `lib/src/renderer/reader_view.dart`, `lib/src/editor/markdown_editor.dart`, `lib/src/ui/actions_sheet.dart`, `test/ui/adaptive_actions_menu_test.dart`, `DECISIONS.md`, `KNOWN_ISSUES.md`, `PROJECT_STATUS.md`
- **Verification Method**: `flutter analyze`, `flutter test`, and `flutter build linux --release`.
- **Verification Result**: Static analysis passed with 0 issues. All 39 unit and widget tests passed. Linux desktop release binary compiled cleanly (`build/linux/x64/release/bundle/tsuzuri`) and executed successfully. ADR-007 recorded.

---

### Task `RENDER-005`: Chemistry Notation (mhchem) Delimiter Pipeline, Dart Syntax Highlighting, and Code Word Wrap
- **Dependencies**: `HARDEN-001`, `PLAT-003`
- **Acceptance Criteria**:
  1. Bare chemistry formulas `\ce{...}` and physical units `\pu{...}` in Markdown prose are normalized to math mode delimiters without double wrapping existing math.
  2. KaTeX + `mhchem.min.js` typesets chemical formulas with accurate subscripts, compounds, and reaction arrows in Reader view.
  3. Fenced code blocks (` ```dart `) display syntax-highlighted tokens (`void`, `final`, `String`, `print`, strings) in both Light and AMOLED Dark modes.
  4. Code blocks enforce responsive word wrapping (`pre-wrap`, `break-word`, `overflow-wrap: anywhere`), preventing horizontal overflow and clipping on mobile viewports.
  5. `flutter analyze` passes with 0 issues.
  6. `flutter test` passes all tests (40/40 passing).
  7. Verified on physical Android hardware (`CPH1859`).
- **Status**: `VERIFIED`
- **Files/Modules**: `lib/src/parser/math_delimiter_normalizer.dart`, `test/parser/math_delimiter_normalizer_test.dart`, `assets/renderer/template.html`, `assets/renderer/renderer.css`, `DECISIONS.md`, `KNOWN_ISSUES.md`, `PROJECT_STATUS.md`
- **Verification Method**: `flutter analyze`, `flutter test`, `flutter build apk --debug`, `adb install -r`, and interactive hardware screencap verification on `CPH1859`.
- **Verification Result**: 40/40 tests passed cleanly. 0 analyzer issues. APK built and installed to `CPH1859`. Screen captures confirmed `\ce{2H2 + O2 -> 2H2O}` and `\ce{CO2 + H2O <=> H2CO3}` render with subscripts and reversible arrows, Dart code snippets display high-contrast token colors across Light and AMOLED Dark themes, and code blocks wrap within the mobile viewport without clipping. ADR-009 recorded.

---

### Task `RENDER-006`: Line-Ending-Preserving Segmentation, Code Fence Boundary Integrity, and KaTeX Equation Protection for Complex Documents
- **Description**: Resolve LaTeX formulae rendering failure and fenced code block prose-swallowing in complex/large Markdown documents (e.g. GATE DA guide with 94 display equations and 334 code fences). Implement line-ending preserving segmentation in `MathDelimiterNormalizer`, line-based CommonMark fence segmentation in `template.html`, AST-level Mermaid fence interception, and regression fixture `06_gate_da_structure.md`.
- **Dependencies**: `RENDER-005`
- **Acceptance Criteria**:
  1. Preserves trailing newlines without dropping line endings during delimiter normalization.
  2. Protects code fences and HTML comments containing backticks without corrupting code-vs-prose parity.
  3. Fenced code blocks terminate cleanly at closing fences without swallowing subsequent prose, memory hooks, or headings.
  4. Intercepts Mermaid fences cleanly without nesting within `<pre>` elements.
  5. All 94 LaTeX display math equations in real-world GATE DA corpus render into formatted KaTeX mathematics.
  6. Automated regression tests pass (42/42 tests passing).
  7. `flutter analyze` passes with 0 issues.
- **Status**: `VERIFIED`
- **Files/Modules**: `lib/src/parser/math_delimiter_normalizer.dart`, `test/parser/math_delimiter_normalizer_test.dart`, `assets/renderer/template.html`, `test/fixtures/06_gate_da_structure.md`, `test/regression_test.dart`, `DECISIONS.md`, `KNOWN_ISSUES.md`, `PROJECT_STATUS.md`
- **Verification Method**: `flutter analyze`, `flutter test`, Node VM pipeline verification on 217 KB corpus, Linux desktop build, and Android hardware installation.
- **Verification Result**: Verified on 217 KB GATE DA document: 94/94 display equations rendered via KaTeX, 0 bad `<pre>` blocks, 334 clean code blocks. 42/42 tests passing with 0 analyzer issues. ADR-010 recorded.

---

### Task `RENDER-007`: Structured Code Block Containers, Language Header Strips, and Scoped Specificity
- **Description**: Restore and enhance distinguishable code snippet sections. Fix CSS selector conflict where `.hljs` inadvertently targeted outer `<pre>` container removing background, border, and padding. Implement dedicated `.code-block-wrapper` with elevated header strip (`.code-block-header`), uppercase language badge (`.code-block-lang`), and interactive clipboard Copy button (`.code-copy-btn`).
- **Dependencies**: `RENDER-006`
- **Acceptance Criteria**:
  1. Outer code container preserves distinct card background and border across Light and AMOLED Dark modes.
  2. Code blocks feature a distinct top header strip displaying uppercase language badge and Copy button.
  3. Inner `<code>` reset does not bleed into outer `<pre>` container properties.
  4. Tested on physical Android hardware (`CPH1859`) across Light and AMOLED Dark themes.
  5. `flutter analyze` passes with 0 issues; all 42 automated tests pass.
- **Status**: `VERIFIED`
- **Files/Modules**: `assets/renderer/renderer.css`, `assets/renderer/template.html`, `DECISIONS.md`, `KNOWN_ISSUES.md`, `PROJECT_STATUS.md`
- **Verification Method**: `flutter analyze`, `flutter test`, `flutter build linux --release`, `flutter build apk --debug`, `adb install -r`, and hardware screencap verification on `CPH1859`.
- **Verification Result**: Verified on physical device `CPH1859`. Screen captures confirmed distinguishable code cards with elevated header strips, language tags (`DART`), copy buttons, and syntax-highlighted code in both Light and AMOLED Dark themes. 42/42 tests passing with 0 analyzer issues. ADR-011 recorded.

---

### Task `UI-006`: Stateful Theme Switcher Reactive Synchronization
- **Description**: Resolve theme switcher state management desynchronization where selecting theme options inside `ActionsSheet` failed to update the button selection highlight immediately. Convert `ActionsSheet` to `StatefulWidget` with local `_selectedThemeMode` state updating simultaneously with `onThemeChanged`.
- **Dependencies**: `RENDER-007`
- **Acceptance Criteria**:
  1. Theme buttons ("System", "Light", "AMOLED Dark") update selection state and borders immediately upon click.
  2. Background application theme updates synchronously.
  3. Automated tests pass (`testWidgets('Theme switcher buttons update selection state immediately on tap')`).
  4. `flutter analyze` reports 0 issues.
- **Status**: `VERIFIED`
- **Files/Modules**: `lib/src/ui/actions_sheet.dart`, `test/ui/adaptive_actions_menu_test.dart`, `DECISIONS.md`, `PROJECT_STATUS.md`
- **Verification Method**: `flutter analyze`, `flutter test`, and Linux desktop live capture `assets/screenshots/desktop_theme_light_popover.png`.
- **Verification Result**: Verified on automated tests and Linux desktop. Tapping "Light" immediately updates button outline highlight and transitions window theme synchronously without menu closing. 45/45 tests passing with 0 issues. ADR-012 recorded.

---

### Task `UI-007`: Desktop Reader View Right-Inset Airspace Occlusion Management
- **Description**: Resolve Linux desktop WebKitGTK airspace occlusion where the More Actions popover dropdown and TOC drawer were occluded or caused full-screen hiding in Reader view. Implement non-destructive `rightInset: 304.0` layout reserving Flutter airspace on the right while maintaining 100% visibility of the Reader view document.
- **Dependencies**: `UI-006`
- **Acceptance Criteria**:
  1. More Actions popover opens as an anchored top-right dropdown in Reader view on Linux desktop without being occluded.
  2. Reader view document remains 100% visible across the left and center of the window (zero blank void).
  3. Table of Contents drawer opens alongside visible Reader view document.
  4. Closing menus or drawers smoothly restores full-width layout.
  5. Automated tests pass (5/5 adaptive actions menu tests).
  6. `flutter analyze` reports 0 issues.
- **Status**: `VERIFIED`
- **Files/Modules**: `lib/src/renderer/reader_view.dart`, `lib/src/ui/app_shell.dart`, `test/ui/adaptive_actions_menu_test.dart`, `README.md`, `DECISIONS.md`, `KNOWN_ISSUES.md`, `PROJECT_STATUS.md`
- **Verification Method**: `flutter analyze`, `flutter test`, `flutter build linux --release`, and live desktop screen captures (`desktop_reader_dark.png`, `desktop_reader_light.png`, `desktop_actions_popover.png`, `desktop_toc_drawer.png`).
- **Verification Result**: Verified on Linux desktop release build. Screen captures confirmed popover and TOC drawer render cleanly and interactively alongside the fully visible, typeset Reader view. 45/45 tests passing. ADR-013 recorded.

---

### Task `UI-008`: App Icon Modernization (iOS/macOS Rounded Corners & White Border)
- **Description**: Recreate the branded application icon using the calligraphy kanji `綴` from original Tauri Tsuzuri, styled with Apple HIG continuous curvature rounded corners ($r/w = 0.224$) and a crisp, antialiased white border (`#FFFFFF`, 28px width at 1024x1024) on an AMOLED pure black (`#000000`) interior canvas with transparent background. Deploy assets across all platforms (Android mipmaps, iOS AppIcon, macOS AppIcon, Web, Windows ICO, Linux desktop runner, README header, and About dialog).
- **Dependencies**: `UI-007`
- **Acceptance Criteria**:
  1. Icon retains the original white calligraphy kanji `綴` centered on pure black background.
  2. Features continuous rounded corners like iOS and macOS and a clean, high-contrast white border.
  3. Deployed to `assets/icon/` and declared in `pubspec.yaml`.
  4. Displayed in `README.md` header matching original Tsuzuri presentation.
  5. Displayed inside `TsuzuriAboutDialog`.
  6. Generated for Android (standard and round mipmaps), iOS, macOS, Web, and Windows.
  7. Linux desktop sets window icon via `my_application.cc`.
  8. `flutter analyze` passes with 0 issues; all 45 automated tests pass.
- **Status**: `VERIFIED`
- **Files/Modules**: `assets/icon/*`, `pubspec.yaml`, `lib/src/ui/about_dialog.dart`, `linux/runner/my_application.cc`, `README.md`, `android/app/src/main/res/mipmap-*`, `ios/Runner/Assets.xcassets/AppIcon.appiconset/*`, `macos/Runner/Assets.xcassets/AppIcon.appiconset/*`, `web/*`, `windows/runner/resources/app_icon.ico`, `DECISIONS.md`, `PROJECT_STATUS.md`
- **Verification Method**: `flutter analyze`, `flutter test`, `flutter build linux --release`, image inspection at multiple resolutions, and Linux desktop binary execution.
- **Verification Result**: Verified with 0 analyzer issues, 45/45 tests passing, and clean Linux release bundle compilation. ADR-014 recorded.

---

### Task `UI-009`: About Dialog Content Alignment & Pubspec Version Integration
- **Description**: Refactor `TsuzuriAboutDialog` to strictly match the original Tauri Tsuzuri About dialog structure and copy (`index.html` lines 298–328). Dynamically read `version:` from `pubspec.yaml` via asset bundle parsing with memory caching. Remove all extraneous technical rows (`Architecture`, `Themes`, etc.) and bottom button.
- **Dependencies**: `UI-008`
- **Acceptance Criteria**:
  1. Displays the exact original header ("About Tsuzuri") with close 'X' button.
  2. Displays the 76x76 rounded app icon.
  3. Displays heading `Tsuzuri <version>` with version dynamically loaded from `pubspec.yaml`.
  4. Displays the exact original description: "A quiet, lightweight, and offline Markdown document reader and editor."
  5. Displays only the original 3 metadata rows: Version, Build time, and Project link (`https://github.com/ameya-deshpande-5056/Tsuzuri-v2`).
  6. Tapping project link copies URL to clipboard with feedback snackbar.
  7. No extraneous metadata rows or bottom Close button.
  8. `flutter analyze` passes with 0 issues; all 47 tests pass.
- **Status**: `VERIFIED`
- **Files/Modules**: `lib/src/ui/about_dialog.dart`, `pubspec.yaml`, `test/ui/about_dialog_test.dart`, `test/services/app_version_test.dart`, `test/widget_test.dart`, `DECISIONS.md`, `PROJECT_STATUS.md`
### Task `UI-010`: About Dialog Backdrop Blur Parity & Clean Version Stripping
- **Description**: Fix About dialog background void on Linux desktop by maintaining 100% WebKitGTK visibility and rendering the dialog internally via `template.html` and `renderer.css` with native `backdrop-filter: blur(4px)` and `background-color: rgba(0, 0, 0, 0.65)`. Strip build number suffix from version string (`version.split('+').first`) across all views.
- **Dependencies**: `UI-009`
- **Acceptance Criteria**:
  1. About dialog background in Reader view is faint and blurred, matching the original Tauri Tsuzuri app with zero solid void.
  2. Version heading and metadata row show clean version `2.0.0` without build number suffix (`+1`).
  3. Dialog dismisses via close 'X' button, backdrop click, or Escape key.
  4. Editor mode uses Flutter `showGeneralDialog` with `BackdropFilter(sigmaX: 4, sigmaY: 4)`.
  5. `ActionsSheet` delegates to `ReaderView.openAboutDialog` when on Linux desktop in Reader view.
  6. `flutter analyze` passes with 0 issues.
  7. All 49 automated tests pass.
- **Status**: `VERIFIED`
- **Files/Modules**: `lib/src/ui/about_dialog.dart`, `lib/src/renderer/reader_view.dart`, `lib/src/ui/actions_sheet.dart`, `lib/src/ui/app_shell.dart`, `assets/renderer/template.html`, `assets/renderer/renderer.css`, `test/ui/about_dialog_test.dart`, `DECISIONS.md`, `PROJECT_STATUS.md`
- **Verification Method**: `flutter analyze`, `flutter test`, `flutter build linux --release`, and live desktop screen capture `desktop_about_dialog.png`.
- **Verification Result**: Verified with 0 analyzer issues, 49/49 tests passing, clean Linux release build, and live screen capture confirming faint blurred document background and clean version `2.0.0`. ADR-016 recorded.

---

### Task `UI-011`: In-WebView Actions Popover Parity & Zero-Width-Reduction Reader View
- **Description**: Render the More Actions popover directly inside the WebKitGTK webview DOM on Linux desktop, eliminating the need for `rightInset: 304.0` in Reader view. Restore 100% full-width document canvas with zero text reflow, zero line-wrapping shifts, and zero jumping when opening or closing the popover.
- **Dependencies**: `UI-010`
- **Acceptance Criteria**:
  1. More Actions popover renders over the WebKitGTK reader view on Linux desktop with zero reader width reduction (`rightInset: 0.0`).
  2. Matches the exact DOM structure, SVG icons, keyboard shortcut badges, and styling from Tauri Tsuzuri (`layout.css` lines 656–740).
  3. Bidirectional Flutter <-> WebKitGTK event bridge handles all actions (`toggleMode`, `openFile`, `saveFile`, `saveAsFile`, `toggleWordWrap`, `about`, and `theme:*`).
  4. Theme switcher updates selection borders instantly and transitions the application theme synchronously.
  5. Flutter `ActionsSheet` remains functional for Editor mode and other platforms.
  6. `flutter analyze` passes with 0 issues.
  7. All 49 automated tests pass.
- **Status**: `VERIFIED`
- **Files/Modules**: `assets/renderer/template.html`, `assets/renderer/renderer.css`, `lib/src/renderer/reader_view.dart`, `lib/src/ui/app_shell.dart`, `DECISIONS.md`, `KNOWN_ISSUES.md`, `PROJECT_STATUS.md`
- **Verification Method**: `flutter analyze`, `flutter test`, `flutter build linux --release`, and live desktop screen captures (`desktop_actions_popover.png`, `desktop_theme_light_popover.png`).
- **Verification Result**: Verified on Linux desktop release build with live screen captures. Popover renders directly above 100% full-width Reader document without margin reduction or text reflow. 49/49 tests passing with 0 analyzer issues. ADR-017 recorded.

---

### Task `DOC-003`: Multi-Platform GitHub Actions Workflows & Tsuzuri v2 Documentation Parity
- **Description**: Configure automated CI/CD release and validation GitHub Actions workflows matching the original Tauri Tsuzuri project, generating application binaries for all 6 supported platforms (Linux, Windows, macOS, Android, iOS, Web). Modernize `README.md` to highlight Tsuzuri v2, architecture evolution from v1, feature comparison, compact visual showcase, and build commands. Implement `scripts/sync-version.js` and `scripts/sync-version.sh`.
- **Dependencies**: `UI-011`
- **Acceptance Criteria**:
  1. `.github/workflows/release.yml` triggers on `v*` tags and `workflow_dispatch`, building and uploading release packages for Linux (`.deb` & `.tar.gz`), Windows (`.zip`), macOS (`.dmg` & `.zip`), Android (`.apk` & `.aab`), iOS (`.ipa`), and Web (`.zip`).
  2. `.github/workflows/build-mobile.yml` validates Android and iOS compilation on PRs/pushes and uploads actions artifacts.
  3. `scripts/sync-version.js` and `scripts/sync-version.sh` dynamically update `pubspec.yaml` version and build number.
  4. `README.md` clearly reflects Tsuzuri v2, explains evolution from v1, provides comprehensive feature comparison table, documents all 6 platforms, and preserves compact visual showcase.
  5. `flutter analyze` passes with 0 issues.
  6. All 49 automated tests pass.
- **Status**: `VERIFIED`
- **Files/Modules**: `.github/workflows/release.yml`, `.github/workflows/build-mobile.yml`, `scripts/sync-version.js`, `scripts/sync-version.sh`, `README.md`, `pubspec.yaml`, `DECISIONS.md`, `PROJECT_STATUS.md`
- **Verification Method**: `flutter analyze`, `flutter test`, local script execution (`./scripts/sync-version.sh 2.0.0`), and workflow syntax/structure validation.
- **Verification Result**: Verified scripts and workflow declarations for all 6 targets. 49/49 tests passing; 0 analyzer issues. ADR-018 recorded.

---

### Task `UI-012`: Canonical Application Name Standardization ("Tsuzuri")
- **Description**: Standardize the application name to strictly `"Tsuzuri"` with a capital `"T"`, nothing else, across all platforms (Android manifest label, iOS CFBundleName, macOS PRODUCT_NAME, Linux GTK window/header bar title, Windows window title and resource strings, Web title and manifest, and default document header).
- **Dependencies**: `DOC-003`
- **Acceptance Criteria**:
  1. Android application label is set to `android:label="Tsuzuri"` in `AndroidManifest.xml`.
  2. iOS `CFBundleName` and `CFBundleDisplayName` are set to `Tsuzuri` in `Info.plist`.
  3. macOS `PRODUCT_NAME` is set to `Tsuzuri` in `AppInfo.xcconfig`.
  4. Linux GTK window and header bar title are set to `Tsuzuri` in `my_application.cc`.
  5. Windows window title is set to `L"Tsuzuri"` in `main.cpp` and `Runner.rc`.
  6. Web document title, meta app title, and PWA manifest name/short_name are set to `Tsuzuri`.
  7. Flutter default document header is `# Tsuzuri (綴り)`.
  8. `flutter analyze` passes with 0 issues.
  9. All 49 automated tests pass.
- **Status**: `VERIFIED`
- **Files/Modules**: `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist`, `macos/Runner/Configs/AppInfo.xcconfig`, `linux/runner/my_application.cc`, `windows/runner/main.cpp`, `windows/runner/Runner.rc`, `web/index.html`, `web/manifest.json`, `lib/src/ui/app_shell.dart`, `DECISIONS.md`, `PROJECT_STATUS.md`
- **Verification Method**: `flutter analyze`, `flutter test`, and `flutter build linux --release`.
- **Verification Result**: Verified across all 6 platform configurations and verified with clean Linux release build. 49/49 tests passing; 0 analyzer issues. ADR-019 recorded.

---

### Task `CI-001`: macOS Release Workflow Portability & Dynamic Bundle Discovery
- **Description**: Resolve macOS build failure in GitHub Actions release workflow caused by BSD `sed` incompatibilities in `scripts/sync-version.sh` and harden macOS packaging in `.github/workflows/release.yml` with dynamic bundle discovery.
- **Dependencies**: `UI-012`
- **Acceptance Criteria**:
  1. `scripts/sync-version.sh` uses POSIX-compliant output redirection with a temporary file, operating identically across GNU `sed` and BSD `sed` (macOS).
  2. `.github/workflows/release.yml` macOS job dynamically detects `.app` bundle path, accommodating both `Tsuzuri.app` and `tsuzuri.app`.
  3. `flutter analyze` passes with 0 issues.
  4. All 49 automated tests pass.
- **Status**: `VERIFIED`
- **Files/Modules**: `scripts/sync-version.sh`, `.github/workflows/release.yml`, `DECISIONS.md`, `PROJECT_STATUS.md`
- **Verification Method**: `scripts/sync-version.sh "v2.0.0"` execution, `flutter analyze`, and `flutter test`.
- **Verification Result**: Successfully tested script locally with clean return code 0; verified POSIX redirection and dynamic packaging path. 49/49 tests passing; 0 analyzer issues. ADR-020 recorded.

---

### Task `CI-002`: Windows Release Workflow MSVC Coroutine Deprecation Suppression & Resilient Packaging
- **Description**: Resolve MSVC `error STL1011` static assertion failure in `webview_all_windows_plugin.vcxproj` during Windows release compilation by suppressing deprecated `<experimental/coroutine>` warnings via `_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS` in `windows/CMakeLists.txt` and GitHub Actions `release.yml`. Harden PowerShell artifact packaging with fallback directory detection.
- **Dependencies**: `CI-001`
- **Acceptance Criteria**:
  1. `windows/CMakeLists.txt` defines `_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS` globally and in `APPLY_STANDARD_SETTINGS(TARGET)`.
  2. `.github/workflows/release.yml` sets `env: CL: "/D_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS"` for the Windows build step.
  3. `.github/workflows/release.yml` uses robust directory fallback for `Compress-Archive`.
  4. `flutter analyze` passes with 0 issues.
  5. All 49 automated tests pass.
- **Status**: `VERIFIED`
- **Files/Modules**: `windows/CMakeLists.txt`, `.github/workflows/release.yml`, `DECISIONS.md`, `PROJECT_STATUS.md`
- **Verification Method**: `flutter analyze` and `flutter test`.
- **Verification Result**: Verified CMake preprocessor definitions and workflow environment variables. 49/49 tests passing; 0 analyzer issues. ADR-021 recorded.

---

### Task `CI-003`: Multi-Platform Release Workflow DAG Decoupling & Concurrent Execution
- **Description**: Decouple Android, iOS, and Web build jobs from `release-desktop` by adding an initialization job `create-release` in `.github/workflows/release.yml`. This allows all platforms to run simultaneously in parallel and prevents desktop failures from skipping mobile and web builds.
- **Dependencies**: `CI-002`
- **Acceptance Criteria**:
  1. `create-release` job runs first to initialize the GitHub Release tag.
  2. `release-desktop`, `release-android`, `release-ios`, and `release-web` declare `needs: create-release` and run in parallel.
  3. Failures in one target do not trigger cascade skips for other platforms.
  4. `flutter analyze` passes with 0 issues.
  5. All 49 automated tests pass.
- **Status**: `VERIFIED`
- **Files/Modules**: `.github/workflows/release.yml`, `DECISIONS.md`, `PROJECT_STATUS.md`
- **Verification Method**: `flutter analyze` and `flutter test`.
- **Verification Result**: Verified GitHub Actions DAG structure and job dependencies. 49/49 tests passing; 0 analyzer issues. ADR-022 recorded.

---

### Task `CI-004`: Absolute Path Subshell Packaging for macOS, iOS, and Web CI Release Artifacts
- **Description**: Fix exit code 15 zip I/O error during macOS packaging in `.github/workflows/release.yml` by replacing fragile relative path traversal (`../../../../`) with absolute workspace directory resolution within an isolated subshell. Apply uniform subshell packaging across Web and iOS release targets.
- **Dependencies**: `CI-003`
- **Acceptance Criteria**:
  1. macOS packaging uses `$WORKSPACE` and isolated subshell `(cd build/macos/Build/Products/Release && zip -r "$WORKSPACE/release-artifacts/..." "$APP_NAME")`.
  2. Web and iOS packaging use subshell encapsulation and absolute workspace references.
  3. `flutter analyze` passes with 0 issues.
  4. All 49 automated tests pass.
- **Status**: `VERIFIED`
- **Files/Modules**: `.github/workflows/release.yml`, `DECISIONS.md`, `PROJECT_STATUS.md`
- **Verification Method**: `flutter analyze` and `flutter test`.
- **Verification Result**: Verified command path resolution and subshell isolation. 49/49 tests passing; 0 analyzer issues. ADR-023 recorded.

---

### Task `UI-013`: Editor Gutter Line-Wrap Synchronization, Persistent View Stack, and Linux In-WebView Tooltip Bridge
- **Description**: Resolve editor line number misalignment (line 21 aligning with line 20) and Android gutter drift when text wraps, eliminate mode switch blank screen flash, prevent desktop header button tooltips from slipping under WebKitGTK, and optimize editor typing performance.
- **Dependencies**: `CI-004`
- **Acceptance Criteria**:
  1. Editor line numbers gutter dynamically expands item heights to match wrapped text lines via `StrutStyle(forceStrutHeight: true)` and cached `TextPainter` measurement.
  2. Cursor line/column tracking uses `selection.extentOffset` with CRLF normalization.
  3. Reader and Editor views are maintained in a persistent `Offstage` + `TickerMode` stack, eliminating the cold-start blank screen flash on mode toggle.
  4. In-webview tooltip bridge renders header action tooltips over WebKitGTK on Linux desktop.
  5. Keystroke content updates avoid full `AppShell` rebuilds and re-parsing.
  6. `flutter analyze` passes with 0 issues.
  7. All automated unit and widget tests pass (53/53 passing).
  8. Linux release build (`flutter build linux --release`) compiles cleanly.
- **Status**: `VERIFIED`
- **Files/Modules**: `lib/src/editor/markdown_editor.dart`, `lib/src/ui/app_shell.dart`, `lib/src/ui/app_header.dart`, `lib/src/renderer/reader_view.dart`, `assets/renderer/template.html`, `assets/renderer/renderer.css`, `test/editor_gutter_alignment_test.dart`, `DECISIONS.md`, `KNOWN_ISSUES.md`, `PROJECT_STATUS.md`
- **Verification Method**: `flutter analyze`, `flutter test`, and `flutter build linux --release`.
- **Verification Result**: Verified 53/53 tests passing, 0 analyzer issues, clean Linux release compilation, and synchronized line wrapping gutter heights. ADR-024 recorded.














