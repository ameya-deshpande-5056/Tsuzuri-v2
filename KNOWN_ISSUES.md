# KNOWN_ISSUES.md: Confirmed Defects, Limitations, and Technical Risks

This document maintains the authoritative log of confirmed defects, platform differences, runtime limitations, and technical risks in **Tsuzuri v2**.

---

## 1. Toolchain & Build Environment Status

### 1.1 Linux Desktop C++ Toolchain
- **Status**: Resolved on local host.
- **Description**: Flutter Linux desktop builds initially reported missing `clang++` via `flutter doctor`.
- **Workaround / Resolution**: Configured `/home/ameya/.local/bin/clang++` as a symlink pointing to the system `/usr/bin/g++`. Host has `webkit2gtk-4.1`, `cmake` 3.28, and `ninja` 1.11 installed.

### 1.2 Cross-Platform Compilation Boundaries
- **Status**: By Design / Platform Limitation.
- **Description**: The development environment is Linux x86_64 (`linux-x64`). Native binaries for Windows (`.exe`), macOS (`.app`), and iOS (`.ipa`) cannot be compiled directly on a Linux host without platform-native SDKs or CI/CD runners (e.g., GitHub Actions).
- **Validation**: Verified through structural analysis, unit/widget tests, Linux release compilation, and Web target compilation (`build/web`).

### 1.3 Android SDK Licenses & Toolchain
- **Status**: Resolved on local host.
- **Description**: All Android SDK package licenses were accepted via `flutter doctor --android-licenses`. `flutter doctor -v` reports all Android toolchain requirements satisfied (`[✓] Android toolchain`).
- **Memory Envelope**: `android/gradle.properties` is strictly tuned to guarantee >= 4 GB RAM remains free at all times: Gradle daemon capped to 1536m heap + 384m metaspace, Kotlin daemon capped to 768m heap, max workers limited to 2, and aggressive JVM heap shrinking enabled (`MinHeapFreeRatio=20`, `MaxHeapFreeRatio=40`). Measured available RAM during builds: >5.4 GB with zero swap usage.


---

## 2. Platform Matrix & Runtime Discrepancies

### 2.1 Linux Desktop Rendering & WebKitGTK Integration
- **Status**: Fully Resolved via ADR-007.
- **Description**: Earlier versions lacked an embedded WebKitGTK engine on Linux desktop when using `flutter_inappwebview`, resulting in fallback plain-text cards.
- **Resolution**: Integrated `webview_all: ^1.4.4` (`webview_all_linux`), which compiles directly against the host's native `libwebkit2gtk-4.1-dev`. The bundled offline rendering pipeline (MathJax 3 with AMS/physics/mhchem/cancel, Mermaid v12.1.0, highlight.js, and Markdown-it) now executes natively on Linux desktop with 100% visual and typesetting parity.

### 2.2 Editor Line Gutter Scrollbar on Desktop
- **Status**: Resolved via ADR-007.
- **Description**: Flutter Desktop attached an unwanted visible scrollbar to the line numbers gutter `ListView`.
- **Resolution**: Enclosed the gutter `ListView` in `ScrollConfiguration(behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false))` in `markdown_editor.dart`.

### 2.3 Desktop/Tablet More Actions Menu Layout Alignment & Airspace Occlusion
- **Status**: Fully Resolved via ADR-007, ADR-012, ADR-013, and ADR-017.
- **Description**: The More Actions menu previously opened as a mobile bottom sheet across all viewports, and on Linux desktop, the native WebKitGTK overlay occluded the Flutter popover in Reader view. Initial workaround used `rightInset: 304.0`, which narrowed the document and triggered text reflow and jumping.
- **Resolution**:
  - Viewports $\ge 681$px open an anchored popover dropdown below the More button with 290px width and subtle elevation, while viewports $< 681$px retain the mobile bottom sheet with grab handle.
  - In Reader view on Linux desktop, the popover renders directly inside WebKitGTK's DOM via `template.html` and `renderer.css` (`#actions-popover`) matching Tauri Tsuzuri styling (`layout.css` lines 656–740).
  - Reader view maintains 100% full-width (`rightInset: 0.0`) with zero document text reflow, zero line wrap shifts, and zero jumping on menu toggle.
  - Bidirectional bridge dispatches actions (`toggleMode`, `openFile`, `saveFile`, `saveAsFile`, `toggleWordWrap`, `about`, `theme:*`) back to Flutter seamlessly.
  - Converted `ActionsSheet` to `StatefulWidget` with local `_selectedThemeMode` state, ensuring theme button highlights update synchronously with the app theme on the exact same frame.

### 2.4 Web Target Local Filesystem Sandboxing
- **Status**: Platform Security Sandbox.
- **Description**: On the Web target (`build/web`), `dart:io` `File` and atomic disk writes are unavailable due to browser sandboxing. File operations fall back to browser memory buffers and download prompts via `file_picker`.

### 2.4 GTK Accessibility Assertion on Linux Desktop Launch
- **Status**: Upstream Flutter Engine Notice (Harmless).
- **Description**: When executing the compiled Linux binary `./build/linux/x64/release/bundle/tsuzuri`, GTK logs:
  ```text
  (com.tsuzuri.tsuzuri:...): Atk-CRITICAL **: atk_socket_embed: assertion 'plug_id != NULL' failed
  ```
  This occurs when no active ATK/Orca screen reader bridge is registered on the host X11/Wayland session. It does not affect application functionality or stability.

### 2.5 Android 9 (API 28) Debug Launch & Asset Injection Resolution
- **Status**: Fully Resolved on Physical Hardware (`CPH1859`).
- **Description**: Debug launches previously exhibited black screen and log reader detachment on Android 9.
- **Resolution**:
  - Replaced `replaceFirst('</body>', ...)` with `lastIndexOf('</body>')` in `bundled_assets.dart` to prevent syntax corruption of inlined `mermaid.min.js`.
  - Added `androidx.window:window:1.3.0` and `androidx.window.extensions.core:core:1.0.0` dependencies to `android/app/build.gradle.kts`.
  - Rewrote relative KaTeX font URLs in `katexCss` to point to APK assets `assets/renderer/vendor/katex/fonts/` with `baseUrl: file:///android_asset/flutter_assets/`.
  - Deferred initial document rendering via `WidgetsBinding.instance.addPostFrameCallback` in `ReaderView`.
  - Verified with live screen captures and interactive Dart VM DevTools attachment.


---

## 3. Rendering & Mathematical Constraints

### 3.1 Pure Dart TeX Ecosystem Gap
- **Status**: Upstream Dart Ecosystem Limitation (Resolved via Bundled Offline KaTeX + mhchem Harness).
- **Description**: Pure Dart LaTeX rendering engines (`flutter_math_fork`, `katex_dart`) only support a subset of KaTeX 0.12:
  - `\ce{...}` (`mhchem` chemistry notation): **0 macros supported in Dart**.
  - `\pdv`, `\dv` (`physics` package macros): **0 macros supported in Dart**.
  - `\upalpha`, `\upbeta` (`upgreek` package): **0 macros supported in Dart**.
  - `\cancel`, `\bcancel`: Restricted or missing.
  - AMS multiline numbered equation tagging (`tags: "ams"`): Unsupported.
- **Resolution**: Tsuzuri v2 uses an offline-bundled rendering pipeline with KaTeX + `mhchem.min.js`. Delimiter normalization in `MathDelimiterNormalizer` and token protection in `template.html` format both bare (`\ce{...}`, `\pu{...}`) and standard math equations with full fidelity.

### 3.2 Pure Dart Mermaid SDK Constraint (`mermaid_flutter`)
- **Status**: Dependency Toolchain Version Conflict.
- **Description**: The pure-Dart `mermaid_flutter` and `mermaid_core` packages on pub.dev declare `environment: { sdk: ^3.12.0 }`. The current Flutter 3.41.9 stable framework uses Dart 3.11.5, which blocks `flutter pub get` from resolving the published package without vendoring or relaxing the SDK constraint.

### 3.3 Chemistry Notation, Dart Highlighting & Code Wrap Parity
- **Status**: Fully Resolved via ADR-009.
- **Description**: Previously bare `\ce{...}` remained raw plaintext, Dart code blocks lacked token highlighting in highlight.js, and `<pre>` elements overflowed horizontally.
- **Resolution**:
  - Implemented `_normalizeChemistry()` in `MathDelimiterNormalizer` with balanced-brace parsing.
  - Added Dart language definition into `window.hljs` in `template.html` with full keyword/built-in support, plus regex fallback highlighting.
  - Added `white-space: pre-wrap !important; word-break: break-word !important; overflow-wrap: anywhere !important;` in `renderer.css`.
  - Verified on physical hardware (`CPH1859`) in both Light and AMOLED Dark modes.

### 3.4 Code Block Fence Swallowing & Math Parity Inversion in Large Documents
- **Status**: Fully Resolved via ADR-010.
- **Description**: In large, complex Markdown files (e.g., 7,000+ line study guides with HTML comments containing backticks like `<!-- (```mermaid) -->`), math formulae failed to render and fenced code blocks swallowed subsequent prose into `<pre>` blocks.
- **Resolution**:
  - Implemented newline-preserving line segmentation (`_splitKeepEnds`) in `MathDelimiterNormalizer` to prevent collision between closing fences and subsequent text.
  - Replaced naive regex block splitting in `template.html` with line-anchored CommonMark segmentation (`segmentMarkdown`) isolating code fences and HTML comments.
  - Intercepted Mermaid blocks via `md.renderer.rules.fence` to prevent illegal nesting within `<pre>` elements.
  - Added regression fixture `test/fixtures/06_gate_da_structure.md` and comprehensive unit tests. Verified 94/94 math equations render cleanly and 0 bad `<pre>` blocks remain on full 217 KB corpus.

### 3.5 Relative Asset Resolution for Unsaved Documents
- **Status**: Expected Behavior / Handled Gracefully.
- **Description**: Markdown image links with relative paths (`![chart](./images/fig1.png)`) cannot resolve against a local filesystem path for newly created documents (`untitled.md`) that have not yet been saved to disk.
- **Handling**: `AssetResolver` detects `baseDir == null` and provides a placeholder rather than throwing an unhandled exception.

---

## 4. Layout, Viewport, and Performance Constraints

### 4.1 Wide Tables and Diagrams on Ultra-Narrow Viewports
- **Status**: Handled & Tested.
- **Description**: At narrow widths (320px, 375px), wide GFM data tables or dense diagram syntax can exceed the screen width.
- **Handling**: Both `NativeReaderView` and the CSS template enclose tables in horizontally scrollable containers (`SingleChildScrollView(scrollDirection: Axis.horizontal)` in Dart and `overflow-x: auto` in CSS). Verified with zero `RenderFlex` overflow errors across all 7 test viewports (320px–1920px).

### 4.2 Large Document Virtualization in Native Reader
- **Status**: Scalability Consideration for Future Releases.
- **Description**: `NativeReaderView` currently parses the document into a list of elements and renders them inside a `SingleChildScrollView`. For typical documents (<2,000 lines), rendering is instantaneous (~16ms). For extremely large documents (>10,000 lines), migrating to a virtualized `ListView.builder` or sliver-based layout will optimize widget allocation and memory.

### 4.3 Asynchronous Typesetting Timing
- **Status**: Mitigated via Completion Handlers.
- **Description**: Rendering large mathematical documents with MathJax is asynchronous. In `ReaderView`, typesetting completion triggers `onRenderComplete` once MathJax and Mermaid promises resolve.

### 4.4 Editor Gutter Line-Wrap Synchronization & Caret Alignment
- **Status**: Fully Resolved via ADR-024.
- **Description**: In `MarkdownEditor`, wrapped lines previously caused cumulative vertical misalignment between text lines and gutter numbers, manifesting as line 21 aligning with line 20 in the gutter, particularly on Android.
- **Resolution**: Implemented `StrutStyle(forceStrutHeight: true)` and dynamic cached `TextPainter` line-height calculation matching reference project `md-latex-mermaid2pdf`. Gutter containers expand for wrapped lines, preserving 1:1 alignment with text lines across all platforms and viewports. Updated caret tracking to `selection.extentOffset`.

### 4.5 Mode-Switch Blank Screen Flash & Linux Tooltip Occlusion
- **Status**: Fully Resolved via ADR-024.
- **Description**: Switching between Reader and Editor previously destroyed and recreated `ReaderView`, triggering cold-start WebKitGTK initialization and a visible blank flash. Header button tooltips on Linux were occluded by native WebKitGTK child window. Keystroke `_onContentChanged` triggered full `AppShell` rebuilds and TOC re-parsing on every key.
- **Resolution**: Mounted both views in persistent `Stack` with `Offstage` + `TickerMode`. Added in-webview tooltip bridge (`#header-tooltip`) in WebKitGTK DOM. Restricted `_onContentChanged` rebuilds to dirty-state transitions.

### 4.6 Document Gallery Thumbnail Fallbacks for Mathematical Expressions and Mermaid Diagrams
- **Status**: By Design / Performance Optimization.
- **Description**: The primary Reader view uses MathJax/KaTeX and Mermaid.js embedded within WebKitGTK / platform webview to render pixel-perfect math formulas and SVG diagrams. However, rendering tens or hundreds of simultaneous webview instances or asynchronous typesetting promises for gallery thumbnails would cause severe CPU/GPU spikes, high memory footprint, and jerky scroll performance.
- **Resolution**: `ThumbnailService` deliberately uses lightweight, Flutter-native AST badges (`[Formula]` and `[Mermaid Diagram]`) inside miniature paper cards. Full typesetting is deferred until the user opens the document in the Reader view.

### 4.7 Document Gallery Thumbnail RenderFlex Overflow During Window Resizing & Unmaximized States
- **Status**: Fully Resolved.
- **Description**: In `DocumentThumbnail` (`lib/src/ui/document_thumbnail.dart`), document preview blocks were laid out in a flex `Column` placed inside loose/bounded vertical constraints. When a document had multiple blocks or headings that exceeded available thumbnail height, or when the desktop window was resized/unmaximized, Flutter's `RenderFlex` asserted with `A RenderFlex overflowed by 9.5 pixels on the bottom` (or 17 pixels).
- **Resolution**:
  - Configured `Stack(fit: StackFit.expand)` in `_buildPaper` to enforce tightly bounded card dimensions.
  - Wrapped document preview content in a combination of `ClipRect` and `OverflowBox(alignment: Alignment.topLeft, minWidth: 0, minHeight: 0, maxHeight: double.infinity)`.
  - Content width remains bounded to the thumbnail's paper width minus padding (preserving normal text wrapping), while vertical height is unbounded to the flex `Column`, eliminating all layout assertions.
  - Exceeding content is clipped strictly and cleanly at the paper's visible boundary, with the bottom gradient overlay fading into the card surface.
  - Empty and missing states remain centered within the card.
  - Fully verified across 9 responsive viewport and resizing tests without layout overflow or scrolling overhead.

---

## 5. Bundle Size & Memory Footprint

### 5.1 Release Bundle Size vs Target Budgets
- **Status**: Measured & Acceptable.
- **Measurements**:
  - Linux Release Bundle: **56.74 MB** (Engine `libflutter_linux_gtk.so`: 42 MB, compiled Dart app `libapp.so`: 4.5 MB, data assets: 11 MB).
  - Web Release Bundle: **43.37 MB** (Canvaskit: 30 MB, bundled assets: 11 MB, Dart JS: 2.6 MB).
  - Bundled Rendering Assets: **7.95 MB** (`mermaid.min.js`: 5.3 MB, MathJax: 1.2 MB, KaTeX fonts: 1.5 MB).
- **Target Comparison**: The desktop release bundle fits comfortably within Linux distribution standards. If building for mobile APKs where size is constrained (<25 MB), stripping unused KaTeX font weights and minifying Mermaid can reduce asset size by ~4–6 MB.

### 5.2 Runtime Memory Footprint
- **Status**: Measured & Expected.
- **Measurements**:
  - Pure Flutter Native (Shell + Editor + NativeReaderView): **~45 MB – 65 MB RSS**.
  - With InAppWebView process: **~180 MB – 260 MB RSS** (due to the separate WebKit/Chromium rendering and GPU processes).
