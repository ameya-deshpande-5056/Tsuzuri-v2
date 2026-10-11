# DECISIONS.md: Architectural Decision Records (ADRs)

## ADR-001: Authority and Role of Reference Repositories
- **Status**: Accepted
- **Date**: 2026-10-11
- **Context**: Three reference repositories exist:
  1. `Tsuzuri` (original): Tauri/JS/HTML/CSS desktop/mobile app.
  2. `md-latex-mermaid2pdf`: Web-based Markdown to PDF studio with MathJax, Mermaid, Highlight.js, and Markdown-it.
  3. `GATE-DA-2027/scripts/render_markdown_pdfs.mjs`: Playwright Node.js script for automated markdown PDF rendering.
- **Decision**:
  - `Tsuzuri` (original) is strictly a **UI/UX visual reference**: minimalist Japanese typography aesthetics ("綴り"), typography tokens, AMOLED pure black theme (`#000000`), header layout, TOC drawer, actions sheet, and editor toolbar. Its Tauri/Rust/JS codebase will NOT be ported.
  - `md-latex-mermaid2pdf` is the **primary behavioral reference** for Markdown, LaTeX, and Mermaid rendering pipelines, extensions, fallback handling, and SVG diagram output.
  - `render_markdown_pdfs.mjs` provides the behavioral reference for **math delimiter normalization** (`\[...\]` -> `$$...$$`, `\(...\)` -> `$...$`), code fence protection, input truncation detection, and asynchronous typesetting completion verification.
- **Consequences**: Tsuzuri v2 is an independent Flutter/Dart software project built from scratch while achieving functional parity with user expectations.

---

## ADR-002: Application Architecture & Rendering Component Strategy
- **Status**: Accepted
- **Date**: 2026-10-11
- **Context**: The app requires:
  - CommonMark + GFM (tables, task lists, footnotes, autolinks, strikethrough, `[[toc]]`).
  - Advanced LaTeX math with MathJax packages (`ams`, `bbox`, `braket`, `cancel`, `color`, `mathtools`, `mhchem`, `physics`, `upgreek`).
  - Mermaid diagram rendering (flowcharts, sequence, class, state, ER, gantt, pie, gitGraph) to scalable SVG.
  - 100% offline execution without runtime CDN downloads or network calls.
  - Pure native Flutter UI shell, menus, drawers, file I/O, dialogs, and raw Markdown editor.
- **Alternatives Considered**:
  1. *Pure Native Flutter Widgets for everything (`flutter_markdown` + `flutter_math_fork`)*:
     - Fails Mermaid: Dart has no native Mermaid parser/SVG generator (Mermaid is deeply coupled to d3/dagre/js).
     - Fails MathJax parity: `flutter_math_fork` supports basic KaTeX subset, but lacks `\ce{}` (mhchem), physics macros, cancel strike lines, mathtools, etc.
     - Table responsiveness and complex formatting in `flutter_markdown` are fragile.
  2. *Hybrid Native Flutter with Dedicated Bundled Offline Rendering Component*:
     - Primary app shell, editor, file handling, settings, and navigation are 100% native Flutter widgets.
     - The Reader typeset view uses a dedicated, sandboxed, offline-bundled rendering pipeline (using local assets: `markdown-it`, `mermaid.min.js`, MathJax/KaTeX, `highlight.js`, and customized responsive styling).
     - On desktop/mobile, the Reader view renders via an embedded local component (`flutter_inappwebview` or local webview window with bundled assets, zero external network access, strict CSP).
     - Math delimiter normalization and document AST/TOC extraction are implemented in pure Dart for fast headless parsing and validation.
- **Decision**: Adopt Option 2. The primary application and Editor are native Flutter widgets; the Reader view uses a dedicated bundled offline rendering component.
- **Consequences**: Full fidelity with `md-latex-mermaid2pdf` and `GATE-DA-2027` while keeping Flutter as the core application architecture.

---

## ADR-003: Mutually Exclusive Views (Reader vs Editor)
- **Status**: Accepted
- **Date**: 2026-10-11
- **Context**: Tsuzuri is designed as a focused, distraction-free reader and editor.
- **Decision**: Reader and Editor are mutually exclusive views. Split-pane live preview is explicitly rejected. Switching modes preserves cursor/scroll position where possible and guards unsaved changes.
- **Consequences**: Optimized screen real estate on mobile and narrow viewports; reduced CPU/battery usage from continuous simultaneous typesetting.

---

## ADR-004: Delimiter Normalization and Code Protection
- **Status**: Accepted
- **Date**: 2026-10-11
- **Context**: Markdown documents often contain LaTeX in mixed formats: `$...$`, `$$...$$`, `\(...\)`, and `\[...\]`. Code blocks (fenced ``` or ~~~) and inline code (`...`) must NEVER have their contents transformed or mangled.
- **Decision**: Implement a pure Dart `MathDelimiterNormalizer` that:
  1. Segments document into code fences (``` and ~~~), inline code spans (`...`), and plain text.
  2. Normalizes display math `\[...\]` to `$$...$$` with line breaks.
  3. Normalizes inline math `\(...\)` to `$...$`.
  4. Preserves already valid delimiters and escapes.
  5. Verifies document character counts to prevent silent truncation.
- **Consequences**: Delimiters work identically across standard Markdown parsers and MathJax, with comprehensive unit test coverage in Dart.

---

## ADR-005: Theme Architecture & AMOLED Dark Mode
- **Status**: Accepted
- **Date**: 2026-10-11
- **Context**: Requirement specifies 3 themes (System default, Light, Dark). Dark mode must use pure black (`#000000`) for the canvas.
- **Decision**:
  - ThemeMode: `ThemeMode.system` (default), `ThemeMode.light`, `ThemeMode.dark`.
  - Light palette: Canvas `#fcfcfc`, Surface `#ffffff`, Text `#18181b`, Border `#e4e4e7`, Link `#0969da`.
  - AMOLED Dark palette: Canvas `#000000`, Surface `#040404`, Sub-surface `#0d0d0f`, Text `#f4f4f5`, Border `#1c1c20`, Link `#58a6ff`.
  - The Reader rendering component inherits the active theme dynamically via message bridge or CSS classes without flickering.
- **Consequences**: True battery savings on OLED devices and deep contrast consistency between native Flutter widgets and rendered document views.

---

## ADR-006: Rendering Pipeline Architecture Review & Hybrid Strategy for Linux WebView Gap
- **Status**: Accepted
- **Date**: 2026-10-11
- **Context**:
  An architecture review was conducted on `pubspec.yaml`, the dependency tree, and the rendering pipeline to evaluate whether `flutter_inappwebview: ^6.1.5` is justified or if pure Flutter-native rendering should replace it.
  The review analyzed:
  1. Feature dependency: which features strictly require a browser engine versus native Flutter widgets.
  2. Platform support matrix and the **Linux desktop gap** in `flutter_inappwebview`.
  3. Measured performance, bundle size, and memory footprint across candidate approaches.
  4. LaTeX fidelity against reference `md-latex-mermaid2pdf` (specifically `ams`, `mathtools`, `mhchem`, `physics`, `braket`, `cancel`, and `upgreek`).
  5. Mermaid diagram coverage and layout fidelity.
- **Empirical Findings & Evidence**:
  1. **The Linux Gap**: `flutter_inappwebview: ^6.1.5` supports Android, iOS, macOS, Windows, and Web, but **completely lacks a Linux desktop plugin implementation**. Executing the application and mounting `InAppWebView` on Linux threw a fatal `Null check operator used on a null value` error in `InAppWebView.fromPlatformCreationParams`. Relying exclusively on `InAppWebView` crashes the Linux desktop application.
  2. **Native LaTeX Limitations**: Pure Dart TeX engines (`flutter_math_fork`, `katex_dart`) only support basic KaTeX math. Testing demonstrated:
     - `\ce{...}` (`mhchem`): **Unsupported** (0 macros defined in Dart).
     - `\pdv`, `\dv` (`physics`): **Unsupported** (0 macros defined in Dart).
     - `\upalpha`, `\upbeta` (`upgreek`): **Unsupported** (0 macros defined in Dart).
     - `\cancel{...}`, `\bcancel{...}`: Partial or missing.
     - AMS numbered multiline alignment with automatic equation tags (`tags: "ams"`): Unsupported.
     - Conversely, bundled `MathJax 3` with its TeX extension modules provides 100% parity with `md-latex-mermaid2pdf`.
  3. **Mermaid Fidelity**: Tested pure-Dart `mermaid_core` (v0.3.0) against 7 representative diagram types from `md-latex-mermaid2pdf` (flowchart, sequence, class, state, gitGraph, pie, ER). `mermaid_core` successfully parsed and rendered all 7 to SVG, but with measured trade-offs:
     - Layout differences: Uses deterministic ELK layout; lacks fcose force simulation and cose-bilkent solvers.
     - Dependency friction: Pub package declares `sdk: ^3.12.0` (while Flutter stable channel provides Dart 3.11.5).
     - Bundled `mermaid.js` v12.1.0 delivers exact pixel and DOM styling parity with the reference project.
  4. **Measured Resource Footprint**:
     - Linux release bundle: Total `56.74 MB` (`libflutter_linux_gtk.so` is 42 MB, compiled app is 4.5 MB, bundled assets are 11 MB).
     - Web release bundle: Total `43.37 MB` (Canvaskit: 30 MB, bundled assets: 11 MB).
     - Bundled offline rendering assets: `7.95 MB` (Mermaid 5.3 MB, MathJax 1.2 MB, KaTeX fonts 1.5 MB). Zero external network calls.
     - Runtime memory (RSS): Pure Flutter ~45-65 MB; with WebView process ~180-260 MB.
- **Evaluated Approaches**:
  - **Approach 1 (Pure Flutter-Native)**: Use `flutter_markdown` + `flutter_math_fork` + `mermaid_core`.
    *Verdict: Rejected as primary reader*. Fails user's required LaTeX feature set (`mhchem`, `physics`, `upgreek`) and breaks visual parity with `md-latex-mermaid2pdf`.
  - **Approach 2 (Hybrid Architecture)**:
    - Primary App Shell, Header, TOC Drawer, Actions Sheet, and Markdown Editor remain 100% native Flutter widgets.
    - Reader View dynamically checks the host platform:
      * On **Linux Desktop**: Uses `NativeReaderView`, a pure Flutter widget tree rendering styled CommonMark, syntax-highlighted code blocks, horizontal scrollable tables, and formatted equation/diagram containers. This eliminates the `Null check operator` crash entirely and ensures fast, resilient offline viewing.
      * On **Android, iOS, macOS, Windows, and Web**: Uses the bundled offline `InAppWebView` harness with local MathJax 3 and Mermaid.js for 100% feature parity.
---

## ADR-007: Full Linux Desktop Rendering via WebKitGTK (`webview_all`) & Adaptive Desktop UI Alignment
- **Status**: Accepted
- **Date**: 2026-10-11
- **Context**:
  1. The user reported that on Linux desktop, raw Markdown (`**Bold**`), syntax highlighting, LaTeX equations (`\ce{}`, display equations), and Mermaid diagrams were not rendering typeset content in the reader view. This occurred because a temporary fallback `NativeReaderView` had bypassed the bundled offline MathJax 3, Mermaid v12.1.0, and Highlight.js pipeline to avoid the unbacked `flutter_inappwebview` Linux null-check crash.
  2. The editor line numbers gutter had a visible scrollbar on desktop platforms.
  3. The More Actions menu was showing a mobile pull-up bottom sheet unconditionally, diverging from the original Tauri Tsuzuri desktop layout specification (which specifies a top-right anchored dropdown menu at $\ge 681$px).
- **Decision**:
  1. **Cross-Platform Rendering via `webview_all` (WebKitGTK on Linux)**:
     - Replaced `flutter_inappwebview` with `webview_all` (`^1.4.4`).
     - On Linux desktop, `webview_all` utilizes `webview_all_linux`, which compiles against the host's existing `libwebkit2gtk-4.1-dev` library.
     - The bundled offline harness (`template.html` with MathJax 3, Mermaid v12.1.0, highlight.js, and Markdown-it) now executes natively on Linux desktop, eliminating the need for degraded text cards.
     - Removed the obsolete and unparsed `native_reader_view.dart`.
  2. **Editor Gutter Scrollbar Elimination**:
     - Wrapped the line numbers `ListView.builder` in `ScrollConfiguration(behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false))` to suppress Flutter desktop's automatic scrollbar attachment while preserving smooth programmatic scroll synchronization.
  3. **Adaptive Desktop Dropdown vs Mobile Bottom Sheet**:
     - Recreated the exact Tauri Tsuzuri layout pattern (`layout.css` min-width: 681px):
       - Viewports $\ge 681$px: Displays a 290px-wide popover dropdown anchored at the top-right corner below the More Actions header button, with rounded corners (`10px`), elevation shadow, close button, and hidden handle bar.
       - Viewports $< 681$px: Displays a modal bottom sheet with rounded top corners (`16px`) and grab handle bar.
- **Consequences**:
  - Full LaTeX (including `mhchem`, `physics`, `upgreek`), Mermaid diagrams, syntax highlighting, and CommonMark render identically with 100% fidelity on Linux desktop.
  - Zero visible scrollbars on the editor line numbers gutter.
  - Pixel and interaction fidelity restored to match original Tauri Tsuzuri UI layout on both desktop and mobile viewports.
  - Verified with 39 passing unit and widget tests and clean Linux release compilation.

---

## ADR-008: Android 9 (API 28) Physical Device Debug Launch & Asset Injection Resolution
- **Status**: Accepted & Verified
- **Date**: 2026-10-11
- **Context**:
  - When running `flutter run -d CPH1859` (Realme 1 / Oppo `CPH1859`, Android 9 / API 28) in debug mode, the app installed but displayed a black screen, and the debug console crashed with `Error waiting for a debug connection: The log reader stopped unexpectedly. Exited (1)`.
- **Root Cause Analysis & Fixes**:
  1. **HTML Script Injection Corruption in `bundled_assets.dart`**:
     - `BundledAssets.buildHtmlDocument` used `baseHtml.replaceFirst('</body>', ...)`.
     - In `vendor/mermaid.min.js`, the minified JS code contains literal strings like `Nt+"</body></html>"`. `replaceFirst('</body>', ...)` matched the first occurrence *inside* Mermaid source code, injecting `<script id="initial-render-trigger">` directly into the JavaScript text.
     - This caused `Uncaught SyntaxError: Unexpected identifier 'initial'`, completely halting document rendering and leaving the Reader view as an unrendered black canvas.
     - *Fix*: Changed to `baseHtml.lastIndexOf('</body>')` to target the true HTML closing tag, and ensured `baseDir` was properly quoted.
  2. **Android 9 / ColorOS Main Thread Freeze**:
     - `ReaderView.initState` ran `_loadDocument()` synchronously during activity creation, causing a frame hitch that prompted ColorOS / ActivityManager to trigger `Activity pause timeout` and kill the debug connection.
     - *Fix*: Deferred `_loadDocument()` execution using `WidgetsBinding.instance.addPostFrameCallback`.
  3. **Missing Jetpack Window Dependencies on API 28**:
     - System WebView (v138) on Android 9 API 28 threw `java.lang.NoClassDefFoundError: Failed resolution of: Landroidx/window/extensions/core/util/function/Consumer;`.
     - *Fix*: Added `implementation("androidx.window:window:1.3.0")` and `implementation("androidx.window.extensions.core:core:1.0.0")` in `android/app/build.gradle.kts`. Kept `android.enableJetifier=false` to prevent heap exhaustion during Gradle transforms.
  4. **KaTeX Embedded Font Path Resolution**:
     - `katex.min.css` used relative URLs `url(fonts/KaTeX_...)`. In Android APKs, assets are packaged under `assets/flutter_assets/assets/renderer/vendor/katex/fonts/`.
     - *Fix*: Rewrote `url(fonts/` to `url(assets/renderer/vendor/katex/fonts/` in `katexCss` and set `baseUrl` to `file:///android_asset/flutter_assets/` on Android. KaTeX fonts now resolve from APK assets with zero missing asset warnings.
- **Verification**:
  - Verified on physical hardware (`SW898SDUSOYHCEMV`): App launched in debug mode with interactive Dart VM service and DevTools attached cleanly.
  - Reader view rendered with AMOLED `#000000` canvas, CommonMark typography, interactive checkboxes, inline/display LaTeX ($e^{i\pi}+1=0$, $\nabla \cdot \vec{E}$, $\int e^{-x^2}dx$, $\sum 1/n^2$), Mermaid flowchart SVGs, and syntax-highlighted code blocks.
  - Smooth mutually exclusive switching to Markdown Editor mode with synchronized gutter and responsive bottom actions sheet.
  - Zero analyzer issues; 39/39 automated unit and widget tests passing.

---

## ADR-009: Chemistry Notation (mhchem) Delimiter Pipeline, Highlight.js Dart Grammar, and Code Word Wrap
- **Status**: Implemented & Verified on Hardware (`CPH1859`).
- **Context**:
  - Chemistry notation (`\ce{2H2 + O2 -> 2H2O}` and `\ce{CO2 + H2O <=> H2CO3}`) was rendering as raw text rather than typeset chemical equations.
  - Dart code blocks in Reader view were rendering as monochrome white text without syntax highlighting token styling.
  - Code blocks did not wrap long lines to fit the mobile viewport, causing horizontal overflow.
- **Root Cause Analysis**:
  1. Bare chemistry macros (`\ce{...}` and `\pu{...}`) outside math mode were ignored by `MathDelimiterNormalizer` (which only handled `\[` and `\(`) and by `template.html`'s `protectMath()` (which only handled `$$` and `$`). Although `mhchem.min.js` was bundled, it was never invoked for bare macros.
  2. The bundled `highlight.min.js` distribution lacked Dart grammar. When highlight.js encountered ````dart`, it had no registered language definition and returned plain escaped text.
  3. Default browser `<pre>` styles use `white-space: pre`, preventing text wrapping and forcing horizontal overflow on narrow viewports.
- **Decision & Architecture**:
  1. **Chemistry Delimiter Normalization (`lib/src/parser/math_delimiter_normalizer.dart`)**:
     - Added `_normalizeChemistry()` with brace-depth counting to convert bare `\ce{...}` and `\pu{...}` expressions in Markdown prose into standard `$\ce{...}$` and `$\pu{...}$`.
     - Strictly protected fenced code blocks, inline code spans, and existing math mode to prevent double wrapping or corrupting code snippets.
  2. **Harness Chemistry Protection (`assets/renderer/template.html`)**:
     - Updated `protectMath()` to detect `\(ce|pu)\{...\}` outside math delimiters and assign `@@MATH_CHEM_i@@` placeholders.
     - Updated `restoreMath()` to typeset them with KaTeX + `mhchem.min.js`.
  3. **Dart Language Grammar & Fallback (`assets/renderer/template.html`)**:
     - Implemented `registerExtraLanguages()` in `template.html` registering official Dart grammar with keywords, built-ins (`String`, `print`, `int`, etc.), strings, and string interpolation into `window.hljs`.
     - Added `normalizeCodeLanguage()` with language aliases (`dartlang`, `golang`, `cplusplus`, `shell`, etc.).
     - Ported regex-based fallback highlighting for unregistered languages from reference project `md-latex-mermaid2pdf`.
  4. **Code Block Word Wrap & Highlight Tokens (`assets/renderer/renderer.css`)**:
     - Added `white-space: pre-wrap !important; word-break: break-word !important; overflow-wrap: anywhere !important;` to `pre`, `pre code`, and `.hljs`.
     - Configured token classes (`.hljs-keyword`, `.hljs-built_in`, `.hljs-function_`, `.hljs-string`, `.hljs-comment`, `.hljs-number`) across Light and AMOLED Dark palettes.
- **Verification**:
  - Live verification on connected physical device (`CPH1859`, Android 9):
    - Confirmed `\ce{2H2 + O2 -> 2H2O}` and `\ce{CO2 + H2O <=> H2CO3}` render into KaTeX chemical notation with subscripts and equilibrium reaction arrows.
    - Confirmed Dart syntax highlighting displays rich token colors (`void`, `String`, `final`, `print`, strings) in both Light and AMOLED Dark modes.
    - Confirmed code blocks wrap lines to screen width with zero horizontal clipping.
  - Automated verification: All 40 unit and widget tests pass (`flutter test`), and static analysis reports 0 issues (`flutter analyze`).

---

## ADR-010: Line-Ending-Preserving Segmentation & CommonMark Fence Rule Interception for Large Complex Documents
- **Status**: Implemented & Verified
- **Date**: 2026-10-11
- **Context**:
  - A real-world 217 KB, 7,252-line Markdown study guide (`GATE DA: The Ultimate Guide for Dummies`) containing 94 display equations, 334 code fences, and 7 Mermaid diagrams exhibited two critical rendering defects:
    1. Almost all LaTeX formulae failed to render, remaining raw plaintext `$$...$$`.
    2. Fenced code blocks failed to close cleanly at ` ``` `, causing subsequent prose paragraphs, memory hooks, headings, and tables to be swallowed into massive `<pre>` blocks.
- **Root Cause Analysis**:
  1. **Newline Omission in `MathDelimiterNormalizer`**:
     - `_segmentMarkdown` previously split the document with `split('\n')` and rejoined chunks with `.join('\n')`.
     - When adjacent segments were concatenated with `buffer.write(segment.text)`, the newline between adjacent segments was omitted.
     - Consequently, closing fences collided with subsequent prose lines (e.g. ` ```**Memory hook:** `). CommonMark parsers require closing fences to occupy a line by themselves; the collision prevented recognition of the closing fence, swallowing subsequent prose into code blocks.
  2. **Naive Regex Code Block Split in `template.html`**:
     - `protectMath()` previously split markdown using `markdown.split(/(```[\s\S]*?```|~~~[\s\S]*?~~~|`[^`\n]+`)/g)`.
     - Line 2 of the document contained an HTML comment with backticks: `<!-- (```mermaid) -->`.
     - Because regex matching was not line-anchored, it matched from `(```mermaid)` to the first real code fence on line 50. This inverted the document's code-vs-prose parity: every subsequent prose section with `$$` was treated as "inside a code block" and left un-typeset.
  3. **Mermaid Block Wrapping in `<pre>`**:
     - Returning `<div class="mermaid-block">` from `highlight(code, 'mermaid')` caused Markdown-it to wrap the output in `<pre><code class="language-mermaid">` because the return string did not start with `<pre`.
- **Decision & Architecture**:
  1. **Line-Ending-Preserving Segmentation (`lib/src/parser/math_delimiter_normalizer.dart`)**:
     - Implemented `_splitKeepEnds(markdown)` so every line preserves its exact trailing newline (`\n` or `\r\n`). Segments are joined with `.join('')`.
     - Document reconstruction is mathematically identical to input with zero lost newlines.
  2. **Line-Based CommonMark Segmentation (`assets/renderer/template.html`)**:
     - Replaced regex splitting with `segmentMarkdown(markdown)` enforcing CommonMark fence rules (0-3 leading spaces, matching fence character and length, HTML comment isolation).
     - Only `prose` segments are inspected for `$$...$$`, `$...$`, and `\ce{...}` tokens.
  3. **Custom Block Fence Renderer Rule (`assets/renderer/template.html`)**:
     - Intercepted `lang === 'mermaid'` via `md.renderer.rules.fence` at the AST token level, emitting `<div class="mermaid-block" data-source="..."><pre class="mermaid">...</pre></div>\n` cleanly without outer `<pre>` wrapper.
  4. **Regression Corpus & Tests**:
     - Added `test/fixtures/06_gate_da_structure.md` and automated tests in `test/parser/math_delimiter_normalizer_test.dart` and `test/regression_test.dart`.
- **Verification**:
  - Full 217 KB GATE DA corpus:
    - 94 / 94 LaTeX display math equations rendered via KaTeX.
    - 0 bad `<pre>` blocks swallowing prose (reduced from 103).
    - Exactly 334 code fences preserved and terminated cleanly.
  - Automated test suite: 42 / 42 tests passing (`flutter test`), 0 issues (`flutter analyze`).
  - Linux release bundle and Android 9 APK builds verified cleanly.

---

## ADR-011: Structured Code Block Containers with Language Header Section and Copy Action
- **Status**: Implemented & Verified on Hardware (`CPH1859`)
- **Date**: 2026-10-11
- **Context**:
  - Code blocks appeared borderless and backgroundless against the AMOLED black background, losing their distinguishable card/section boundaries.
  - The root cause was a CSS selector conflict: `pre code, .hljs { background: none; border: none; padding: 0; }` matched `<pre class="hljs">`, which inadvertently stripped the background, border, and padding from the outer container element itself.
  - Furthermore, code blocks lacked clear language identifiers and headers to distinguish them as standalone code sections.
- **Decision & Architecture**:
  1. **Structured Container Markup (`assets/renderer/template.html`)**:
     - Upgraded Markdown-it's `md.renderer.rules.fence` and `md.renderer.rules.code_block` to wrap each code block in a dedicated `<div class="code-block-wrapper">`.
     - Added a top header bar `<div class="code-block-header">` featuring an uppercase language label `<span class="code-block-lang">` and an interactive `<button class="code-copy-btn">Copy</button>`.
     - Wired `window.copyCode(button)` to copy clean raw source text to the clipboard with feedback states (`Copied!`).
  2. **Scoped CSS Rule Specificity (`assets/renderer/renderer.css`)**:
     - Disentangled the inner code reset: scoped strictly to `pre code, pre.hljs code, code.hljs`, ensuring the outer `<pre>` and `.code-block-wrapper` maintain their background, border, and padding.
  3. **High-Contrast Theme Tokens**:
     - AMOLED Dark mode: `--code-bg: #0e0f14;`, `--code-border: #23242c;`, `--code-header-bg: #14151b;`.
     - Light mode: `--code-bg: #f4f4f6;`, `--code-border: #e2e4e8;`, `--code-header-bg: #eaebee;`.
- **Verification**:
  - Verified on physical hardware (`Realme 1`, Android 9): Live screen captures confirmed crisp code cards with elevated header strips, language tags (`DART`), copy buttons, and high-contrast token syntax highlighting in both Light and AMOLED Dark modes.
  - Automated test suite: All 42 unit, widget, responsive, and regression tests passing with 0 analyzer issues.

---

## ADR-012: Stateful Theme Switcher Reactive Synchronization
- **Status**: Implemented & Verified
- **Date**: 2026-10-11
- **Context**:
  - Tapping the theme switcher buttons ("System", "Light", "AMOLED Dark") inside the More Actions menu triggered an immediate background theme change in `MaterialApp`, but the switcher buttons inside the menu failed to reflect the selection state immediately until the menu was closed and reopened.
  - Root Cause: `ActionsSheet` was a `StatelessWidget` receiving `currentThemeMode` at the time of route push. Because modal dialog routes (`RawDialogRoute`, `ModalBottomSheetRoute`) exist as independent route elements on the Navigator, rebuilding `MaterialApp` and `AppShell` did not alter the immutable `currentThemeMode` property on the pre-instantiated `ActionsSheet` object.
- **Decision & Architecture**:
  1. Converted `ActionsSheet` from `StatelessWidget` to `StatefulWidget`.
  2. Maintained local `_selectedThemeMode` state initialized from `widget.currentThemeMode` and synchronized in `didUpdateWidget`.
  3. On theme button selection:
     ```dart
     void _onSelectTheme(ThemeMode mode) {
       setState(() {
         _selectedThemeMode = mode;
       });
       widget.onThemeChanged(mode);
     }
     ```
  4. Both the local button highlight outline (`width: 1.4`, contrast border) and the `MaterialApp` theme change synchronously on the exact same frame.
- **Verification**:
  - Automated test `Theme switcher buttons update selection state immediately on tap` passed (`flutter test`).
  - Verified on Linux desktop release build: Live screen capture `assets/screenshots/desktop_theme_light_popover.png` confirmed instant button outline selection and light theme transition while the menu remained open.

---

## ADR-013: Desktop Reader View Right-Inset Airspace Occlusion Management
- **Status**: Implemented & Verified
- **Date**: 2026-10-11
- **Context**:
  - On Linux desktop, `webview_all` embeds a native GTK widget (`WebKitWebView`) inside `GtkOverlay`.
  - Native GTK widgets sit physically above Flutter's OpenGL/Software compositing surface (`FlView`).
  - Previously, Flutter's More Actions popover (`showGeneralDialog`) was drawn at `top: 48, right: 12, width: 290` underneath the native WebKitGTK overlay, occluding the menu in Reader view.
  - An initial attempt to hide the entire WebKit view (`Visibility(visible: false)`) caused the entire Reader view to vanish into a blank canvas whenever the menu opened, violating visual continuity.
- **Decision & Architecture**:
  1. **Non-destructive Inset Layout (`rightInset`)**:
     - When the More Actions popover or Table of Contents drawer opens on desktop ($\ge 681$px), `ReaderView` receives `rightInset: 304.0`.
     - `ReaderView` wraps `WebViewWidget` in `Container(padding: EdgeInsets.only(right: effectiveRightInset))`.
     - `webview_all_linux`'s geometry observer recalculates the native frame to `[0, 48, screenWidth - 304, height]`.
     - The native WebKitGTK view remains 100% VISIBLE across the rest of the window, displaying the formatted Markdown document with zero blank void.
     - In the right 304px, no native GTK overlay exists, allowing Flutter to paint the popover or TOC drawer with full transparency, shadow, and interaction.
  2. **Selective Center Dialog Visibility**:
     - Only for center modal dialogs (like `TsuzuriAboutDialog` or `AlertDialog`), `isDialogActive` temporarily suppresses the native overlay so the center dialog is visible to the user.
- **Verification**:
  - Automated tests in `test/ui/adaptive_actions_menu_test.dart` (5/5 passing).
  - All 45 unit, widget, and regression tests passing with 0 issues in `flutter analyze`.
  - Verified on native Linux desktop: Live screen captures `desktop_actions_popover.png`, `desktop_theme_light_popover.png`, and `desktop_toc_drawer.png` confirm the popover and TOC drawer render cleanly alongside the fully visible, typeset Reader view.

---

## ADR-014: App Icon Modernization (iOS/macOS Rounded Corners & White Border)
- **Status**: Accepted
- **Date**: 2026-10-11
- **Context**:
  - The original Tsuzuri Tauri app used a raw square icon (`512x512` and `1024x1024`) featuring the white calligraphy kanji `綴` on an unbordered black `#000000` canvas.
  - On modern desktop and mobile platforms (macOS dock, iOS home screen, Android launchers, Linux window managers, and GitHub light/dark markdown previews), unbordered dark icons blend into dark backgrounds or lack definition.
  - User requested adopting the original Tsuzuri icon with a white border and rounded corners like in iOS and macOS.
- **Decision & Architecture**:
  1. **Geometry & Curvature**:
     - Applied Apple HIG continuous curvature rounded corners ($r / w = 0.224$, 229px radius at 1024x1024).
     - Applied an antialiased pure white (`#FFFFFF`) border of 28px width at 1024x1024 resolution (~2.7% icon dimension), providing strong visual definition across light, dark, and AMOLED surfaces.
     - Centered the original white calligraphy kanji `綴` on an AMOLED pure black (`#000000`) interior canvas.
     - Preserved transparent alpha channel outside the rounded boundary for floating desktop/mobile rendering.
     - Supersampled at 4x (4096x4096) with Lanczos downsampling for subpixel edge antialiasing.
  2. **Multi-Platform Deployment**:
     - Bundled `assets/icon/` with resolutions from 16x16 to 1024x1024 and declared in `pubspec.yaml`.
     - Integrated into `README.md` header matching the original Tsuzuri layout.
     - Integrated into `TsuzuriAboutDialog` in `about_dialog.dart`.
     - Deployed Android mipmaps (`mipmap-mdpi` through `mipmap-xxxhdpi` for both standard and round launchers).
     - Deployed macOS AppIcon set (`app_icon_16.png` through `app_icon_1024.png`).
     - Deployed iOS AppIcon set (`Icon-App-*.png`).
     - Deployed Web icons (`favicon.png`, `Icon-192.png`, `Icon-512.png`, maskable variants).
     - Deployed Windows multi-resolution `app_icon.ico`.
     - Integrated `gtk_window_set_icon_from_file` into Linux desktop `my_application.cc`.
- **Verification**:
  - `flutter analyze` 0 issues.
  - `flutter test` 45/45 passing.
  - `flutter build linux --release` verified crash-free execution with icon asset bundling.

---

## ADR-015: About Dialog Content Parity with Original Tauri Tsuzuri & Dynamic Version Resolution
- **Status**: Accepted
- **Date**: 2026-10-11
- **Context**:
  - The previous v2 About dialog introduced extraneous technical metadata rows (`Architecture`, `Themes`, `LaTeX Support`, `Mermaid Support`, `Network`) and a redundant bottom "Close" button not present in the original Tauri application.
  - Hardcoded version strings (`v2.0.0`) risked drift whenever `pubspec.yaml` was incremented.
  - Requirement: Align the About dialog to show strictly the exact elements and copy from the original Tauri Tsuzuri app (`index.html` lines 298–328 and `layout.css`), with dynamic version resolution from `pubspec.yaml`.
- **Decision & Architecture**:
  1. **Strict Content Parity**:
     - Header: "About Tsuzuri" title with close 'X' button (`Icons.close`, tooltip `Close`).
     - Body:
       - App icon (76x76 rounded squircle with white border).
       - Heading: `Tsuzuri <version>`.
       - Description: `A quiet, lightweight, and offline Markdown document reader and editor.`
       - Metadata grid with exactly 3 fields:
         - `Version:` `<version>`
         - `Build time:` `<build_time>`
         - `Project:` `https://github.com/ameya-deshpande-5056/Tsuzuri-v2` (clickable/copyable link)
     - Removed all extraneous technical rows and bottom button.
  2. **Dynamic Version Loading from `pubspec.yaml`**:
     - Registered `pubspec.yaml` as an application asset in `pubspec.yaml`.
     - `_loadVersionFromPubspec()` reads `pubspec.yaml` via `rootBundle.loadString('pubspec.yaml')` at runtime, extracts `version: ...`, and caches it in memory.
     - Operates 100% offline across all target platforms with zero third-party plugin dependencies.
- **Verification**:
  - `flutter analyze` 0 issues.
  - Widget tests in `test/ui/about_dialog_test.dart` and `test/services/app_version_test.dart` verify dynamic version parsing, content matching, and absence of removed fields.
  - Full test suite passes: 49/49 tests.
  - Linux release build compiled and verified.

---

## ADR-016: About Dialog Background Blur Parity & Clean Version Stripping
- **Status**: Accepted
- **Date**: 2026-10-11
- **Context**:
  - On Linux desktop in Reader view, opening the About dialog previously detached/hid the WebKitGTK view (`Visibility(visible: false)`), exposing Flutter's blank background container and `ModalBarrier` as a solid black/grey void instead of showing a faint blurred background of the rendered document as seen in Tauri Tsuzuri.
  - The version displayed `2.0.0+1` with the build number `+1`, when only the clean semantic version `2.0.0` was desired.
- **Decision & Architecture**:
  1. **Clean Version Stripping**:
     - `getCleanVersion()` and `_loadVersionFromPubspec()` in `about_dialog.dart` parse `version:` from `pubspec.yaml` and strip any build metadata via `.split('+').first.trim()`.
     - Heading displays `Tsuzuri 2.0.0` and the metadata row displays `Version: 2.0.0`.
  2. **Native WebKitGTK Modal Backdrop & Dialog on Linux**:
     - In Reader view on Linux, the native WebKitGTK view remains 100% visible (zero blanking).
     - The modal dialog and backdrop are embedded in `template.html` and `renderer.css` using the exact CSS rules from Tauri Tsuzuri's `layout.css` lines 870–1040:
       `background-color: rgba(0, 0, 0, 0.65); backdrop-filter: blur(4px); -webkit-backdrop-filter: blur(4px);`
     - The rendered document behind the dialog is blurred and faintly darkened, providing complete visual parity with the original Tauri Tsuzuri app.
     - Supports dismissal via close 'X' button, backdrop click, or Escape key.
  3. **Flutter General Dialog for Editor & Mobile/Web Views**:
     - In Editor mode and on mobile/web platforms, `TsuzuriAboutDialog.show(context)` utilizes `showGeneralDialog` with `BackdropFilter(filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4))` and `barrierColor: Colors.black.withValues(alpha: isDark ? 0.65 : 0.35)`, smoothly blurring the editor source text behind the dialog.
  4. **ActionsSheet Delegation**:
     - `ActionsSheet` introduces `final VoidCallback? onOpenAbout;` allowing `AppShell` to dynamically invoke `_readerKey.currentState?.openAboutDialog(cleanVersion)` when in Reader view on Linux desktop, or `TsuzuriAboutDialog.show(context)` in Editor mode / fallback platforms.
- **Verification**:
  - `flutter analyze` 0 issues.
  - `flutter test` 49/49 passing.
  - Release Linux desktop binary executed on `DISPLAY=:0`. Screen capture `desktop_about_dialog.png` confirms the About dialog displays centered over the faint, blurred document background with `Tsuzuri 2.0.0` (clean version with zero build number).

---

## ADR-017: In-WebView Actions Popover Parity & Zero-Width-Reduction Reader View on Linux
- **Status**: Accepted
- **Date**: 2026-10-11
- **Context**:
  - On Linux desktop, WebKitGTK (`webview_all_linux`) is rendered as a native X11 child widget over Flutter's `FlView`. Any Flutter overlay rendered in the same airspace is occluded by WebKitGTK.
  - Previously (ADR-013), an outer layout inset (`rightInset: 304.0`) was introduced to narrow the WebKitGTK widget when the More Actions popover was open. While this made the Flutter popover visible, it shrank the Reader viewport, forcing document text reflow, re-wrapping long lines, and causing content jumping on every menu toggle.
  - In the original Tauri Tsuzuri app, the More Actions menu was rendered directly within the web document DOM as a top-right popover over the full-width canvas, producing zero text reflow or content shifting.
- **Decision & Architecture**:
  1. **In-WebView Popover DOM & Styling Parity**:
     - Embedded `#popover-backdrop` and `<aside id="actions-popover" class="actions-popover">` directly into `assets/renderer/template.html` and `assets/renderer/renderer.css`, mirroring the original Tauri Tsuzuri markup and CSS (`layout.css` lines 656–740).
     - Geometry: `position: fixed; top: 8px; right: 12px; width: 290px; z-index: 1000;`.
     - Styling: AMOLED pure black surface (`#040404`), 1px subtle border, deep drop shadow (`0 12px 36px rgba(0,0,0,0.45)`), smooth scale/fade transition (`translateY(-8px) scale(0.96) -> translateY(0) scale(1)`).
     - Includes all action items with exact SVG icons, labels, and `<kbd>` badges (`Ctrl+E`, `Ctrl+O`, `Ctrl+S`, `Ctrl+Shift+S`, `Alt+Z`), plus the 3-state theme switcher (`System`, `Light`, `AMOLED Dark`).
  2. **Bi-Directional Flutter <-> WebKitGTK Action Bridge**:
     - Flutter -> WebKitGTK: `ReaderView.toggleActionsPopover({required bool wordWrap, required String themeMode})` and `closeActionsPopover()` run JavaScript on the `WebViewController` to sync state and trigger popover visibility.
     - WebKitGTK -> Flutter: `window.sendAction(action)` dispatches actions via `window.TsuzuriHost.postMessage(action)` with a fallback to `location.href = 'tsuzuri-action://' + action` intercepted by `NavigationDelegate.onNavigationRequest`.
     - `AppShell` receives action events via `onAction: _handleReaderAction` and routes them to `toggleMode`, `openFile`, `saveFile`, `saveAsFile`, `toggleWordWrap`, `about` (triggering the in-webview About dialog), and `theme:<mode>`.
  3. **Zero Reader View Width Reduction**:
     - For the More Actions popover in Reader view on Linux, `_readerRightInset` evaluates to `0.0`.
     - The reader view remains 100% full-width at all times. Opening or closing the popover introduces zero text reflow, zero line wrap shifts, and zero visual jumping.
  4. **Fallback & Editor Mode Preservation**:
     - In Editor mode and on platforms where WebKitGTK airspace occlusion does not occur, Flutter's native `ActionsSheet` dropdown/bottom-sheet continues to be utilized.
- **Verification**:
  - `flutter analyze`: 0 issues found.
  - `flutter test`: 49/49 automated unit, widget, and regression tests passed.
  - `flutter build linux --release`: Built cleanly.
  - Executed on Linux desktop (`DISPLAY=:0`). Verified with live screen captures:
    - `desktop_actions_popover.png`: Popover renders directly over the 100% full-width Reader view in AMOLED dark mode with 0 reader width reduction.
    - `desktop_theme_light_popover.png`: Immediate switch to Light mode with popover open over full-width canvas.

---

## ADR-018: Multi-Platform GitHub Actions Workflows and Tsuzuri v2 Documentation Parity
- **Status**: Accepted
- **Date**: 2026-10-11
- **Context**:
  - The repository required automated CI/CD release and validation workflows matching the original Tauri Tsuzuri project (`.github/workflows/release.yml` and `.github/workflows/build-mobile.yml`), adapted for Flutter across all 6 target platforms: Linux, Windows, macOS, Android, iOS, and Web.
  - The `README.md` needed to explicitly reflect Tsuzuri v2, articulating the architectural evolution from Tauri 2/Rust to Flutter/Dart, multi-platform feature comparisons, compact visual showcases, and compilation guides.
- **Decision & Architecture**:
  1. **Automated Production Release Workflow (`.github/workflows/release.yml`)**:
     - Triggered on tag pushes (`v*`) and manual `workflow_dispatch`.
     - Matrix desktop job (`release-desktop`):
       - Linux (`ubuntu-22.04`): Compiles with WebKitGTK and GTK3 headers. Generates `Tsuzuri_<version>_amd64.deb` via `dpkg-deb` and `Tsuzuri_<version>_linux-x64.tar.gz`.
       - Windows (`windows-latest`): Compiles release bundle and packages `Tsuzuri_<version>_windows-x64.zip`.
       - macOS (`macos-latest`): Compiles release bundle and packages `Tsuzuri_<version>_macos.dmg` and `Tsuzuri_<version>_macos.zip`.
     - Mobile & Web jobs:
       - Android (`ubuntu-latest`): Compiles release APK and AAB. Auto-signs with repository secret keystore or self-signed fallback via `apksigner` and `zipalign`. Publishes `Tsuzuri_<version>.apk` and `Tsuzuri_<version>.aab`.
       - iOS (`macos-14`): Compiles unsigned bundle via Xcode 16 and Flutter, packaging `Payload/Runner.app` into `Tsuzuri_<version>.ipa`.
       - Web (`ubuntu-latest`): Compiles production web bundle into `Tsuzuri_<version>_web.zip`.
     - All jobs publish directly to GitHub Releases via `softprops/action-gh-release@v2`.
  2. **Mobile CI Validation Workflow (`.github/workflows/build-mobile.yml`)**:
     - Runs on pull requests and pushes to `main` and `master`.
     - Validates Android debug compilation (`tsuzuri-android-apk`) and iOS debug compilation (`tsuzuri-ios-payload`), uploading artifacts via `actions/upload-artifact@v4`.
  3. **Version Synchronization Scripts (`scripts/sync-version.js` & `scripts/sync-version.sh`)**:
     - Dynamically extracts semantic version and computes incremental build numbers (`major * 1000000 + minor * 1000 + patch`).
     - Updates `pubspec.yaml` prior to build execution.
  4. **Tsuzuri v2 README Modernization**:
     - Updated `README.md` to showcase the v1-to-v2 architectural evolution, feature comparison table, compact visual showcase, keyboard shortcuts, build commands, and workflow documentation.
- **Verification**:
  - Scripts tested and verified locally (`./scripts/sync-version.sh 2.0.0`).
  - `flutter analyze`: 0 issues found.
  - `flutter test`: 49/49 automated unit, widget, and regression tests passed.

---

## ADR-019: Canonical Application Name Standardization ("Tsuzuri")
- **Status**: Accepted
- **Date**: 2026-10-11
- **Context**:
  - Several platform configuration files and runners previously used lowercase `tsuzuri` or appended designations (`Tsuzuri v2`) in OS-facing titles and manifests (e.g. Android app drawer label, Linux GTK title bar, Windows window title, macOS bundle name, Web manifest, and default document header).
  - Explicit requirement: Ensure that the application name is strictly `"Tsuzuri"` with a capital `"T"`, nothing else.
- **Decision & Architecture**:
  1. **Android**: Updated `android/app/src/main/AndroidManifest.xml` with `android:label="Tsuzuri"`.
  2. **iOS & macOS**: Updated `ios/Runner/Info.plist` with `CFBundleName="Tsuzuri"` (matching `CFBundleDisplayName="Tsuzuri"`), and `macos/Runner/Configs/AppInfo.xcconfig` with `PRODUCT_NAME = Tsuzuri`.
  3. **Linux Desktop**: Updated `linux/runner/my_application.cc` with `gtk_header_bar_set_title(header_bar, "Tsuzuri")` and `gtk_window_set_title(window, "Tsuzuri")`.
  4. **Windows Desktop**: Updated `windows/runner/main.cpp` with `window.Create(L"Tsuzuri", origin, size)` and `windows/runner/Runner.rc` with `FileDescription` and `ProductName` set to `"Tsuzuri"`.
  5. **Web Target**: Updated `web/index.html` with `<title>Tsuzuri</title>` and `apple-mobile-web-app-title="Tsuzuri"`, and `web/manifest.json` with `"name": "Tsuzuri"` and `"short_name": "Tsuzuri"`.
  6. **Application Shell & Default Document**: Preserved `MaterialApp.title: 'Tsuzuri'` in `main.dart` and standardized default document heading to `# Tsuzuri (綴り)` in `app_shell.dart`.
- **Verification**:
  - `flutter analyze`: 0 issues found.
  - `flutter test`: 49/49 automated unit, widget, and regression tests passed.
---

## ADR-020: macOS Release Workflow BSD Sed Portability and Dynamic Bundle Discovery
- **Status**: Accepted
- **Date**: 2026-10-11
- **Context**:
  - The GitHub Actions release workflow (`.github/workflows/release.yml`) failed during the macOS build step:
    ```text
    Run ./scripts/sync-version.sh "v2.0.0"
    sed: -I or -i may not be used with stdin
    Error: Process completed with exit code 1.
    ```
  - On macOS GitHub runners (`macos-latest` / Darwin), the system `sed` is BSD `sed`, unlike GNU `sed` on Linux (`ubuntu-latest`).
  - GNU `sed` accepts `-i "expr" file`. BSD `sed` treats the argument immediately following `-i` as the backup extension string (e.g. `-i '' "expr" file`); without that argument, BSD `sed` interprets `-i` as taking no parameter and mistakes the file as standard input, triggering `sed: -I or -i may not be used with stdin`.
  - In addition, macOS packaging previously assumed a hardcoded bundle path `build/macos/Build/Products/Release/tsuzuri.app`. Following ADR-019 where `PRODUCT_NAME` was canonicalized to `Tsuzuri`, the Xcode build output bundle is `Tsuzuri.app`, which would cause `hdiutil` and `zip` packaging to fail on case-sensitive paths.
- **Decision & Architecture**:
  1. **POSIX-Compliant Portable Stream Replacement (`scripts/sync-version.sh`)**:
     - Removed the non-portable `sed -i` flag.
     - Implemented standard POSIX output redirection via a temporary file:
       ```bash
       sed "s/^version: .*/version: ${CLEAN_VERSION}+${BUILD_NUMBER}/" "$PUBSPEC" > "${PUBSPEC}.tmp" && mv "${PUBSPEC}.tmp" "$PUBSPEC"
       ```
     - This is 100% portable across GNU `sed`, BSD `sed` (macOS), Busybox, Alpine, and all Unix shells with zero platform-specific flags.
  2. **Dynamic Bundle Discovery in Packaging (`.github/workflows/release.yml`)**:
     - Replaced hardcoded `tsuzuri.app` path with dynamic discovery:
       ```bash
       APP_PATH=$(find build/macos/Build/Products/Release -name "*.app" -maxdepth 1 2>/dev/null | head -n 1)
       APP_NAME=$(basename "$APP_PATH")
       ```
     - Handles either `Tsuzuri.app` or `tsuzuri.app` seamlessly for `.dmg` and `.zip` creation.
- **Verification**:
  - Locally tested `./scripts/sync-version.sh "v2.0.0"`, successfully updating `pubspec.yaml` with exit code 0.
  - `flutter analyze`: 0 issues found.
  - `flutter test`: 49/49 automated unit, widget, and regression tests passed.

---

## ADR-021: Windows Release Workflow MSVC Coroutine Deprecation Suppression and Resilient Packaging
- **Status**: Accepted
- **Date**: 2026-10-11
- **Context**:
  - The GitHub Actions release workflow failed during `flutter build windows --release`:
    ```text
    C:\Program Files\Microsoft Visual Studio\18\Enterprise\VC\Tools\MSVC\14.51.36231\include\experimental\coroutine(37,1): error C2338: static assertion failed: 'error STL1011: The /await compiler option, <experimental/coroutine>, <experimental/generator>, and <experimental/resumable> are deprecated by Microsoft and will be REMOVED SOON. They are superseded by the C++20 <coroutine> and C++23 <generator> headers. You can define _SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS to suppress this error for now.' [D:\a\Tsuzuri-v2\Tsuzuri-v2\build\windows\x64\plugins\webview_all_windows\webview_all_windows_plugin.vcxproj]
    ```
  - Visual Studio 2022 / 2026 (MSVC toolset 14.40+ / 14.51 in recent CI images) deprecated `<experimental/coroutine>` and enabled `STL1011` as a fatal static assertion by default.
  - The `webview_all_windows` plugin depends on `Microsoft.Windows.ImplementationLibrary` (WIL) version 1.0.220914.1 and C++/WinRT, which reference `<experimental/coroutine>`.
- **Decision & Architecture**:
  1. **Global CMake & Standard Settings Preprocessor Definition (`windows/CMakeLists.txt`)**:
     - Added `add_definitions(-D_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS)` globally in `windows/CMakeLists.txt`.
     - Injected `target_compile_definitions(${TARGET} PRIVATE "_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS")` into `APPLY_STANDARD_SETTINGS(TARGET)`, which is invoked by `webview_all_windows` and all Flutter Windows plugin targets.
  2. **CI Environment Variable Guard (`.github/workflows/release.yml`)**:
     - Added `env: CL: "/D_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS"` to the Windows build step in GitHub Actions.
     - In MSVC, the `CL` environment variable is read by `cl.exe` for all C++ invocations, providing defense-in-depth across direct compiler invocations, NuGet dependencies, and CMake builds.
  3. **Resilient Windows Bundle Packaging**:
     - Hardened the `Compress-Archive` PowerShell step in `release.yml` with fallback directory detection (`build\windows\x64\runner\Release` and `build\windows\runner\Release`).
- **Verification**:
  - `flutter analyze`: 0 issues found.
  - `flutter test`: 49/49 automated unit, widget, and regression tests passed.

---

## ADR-022: Multi-Platform Release Workflow DAG Decoupling & Concurrent Execution
- **Status**: Accepted
- **Date**: 2026-10-11
- **Context**:
  - The GitHub Actions release workflow previously declared `needs: release-desktop` on `release-android`, `release-ios`, and `release-web`.
  - In GitHub Actions DAG semantics, when any matrix runner in `release-desktop` fails, the parent job status evaluates to `failure`. Consequently, all dependent downstream jobs (`release-android`, `release-ios`, and `release-web`) were automatically skipped by GitHub Actions without running.
  - Furthermore, serial dependency forced mobile and web jobs to wait for desktop builds to finish, tripling workflow run time.
- **Decision & Architecture**:
  1. **Dedicated Initialization Job (`create-release`)**:
     - Introduced a lightweight `create-release` job running on `ubuntu-latest` that initializes the release draft/tag on GitHub in ~5 seconds using `softprops/action-gh-release@v2`.
  2. **Job Decoupling & Concurrent Execution**:
     - Replaced `needs: release-desktop` with `needs: create-release` across `release-desktop`, `release-android`, `release-ios`, and `release-web`.
     - All 4 platform target jobs execute simultaneously in parallel across independent runner pools.
     - A build failure or delay on any desktop OS does not prevent Android, iOS, or Web builds from running, packaging, and publishing artifacts.
- **Verification**:
  - `flutter analyze`: 0 issues found.
  - `flutter test`: 49/49 automated unit, widget, and regression tests passed.
  - Workflow syntax validated.

---

## ADR-023: Absolute Path Subshell Packaging for macOS, iOS, and Web CI Release Artifacts
- **Status**: Accepted
- **Date**: 2026-10-11
- **Context**:
  - The macOS desktop packaging step failed with:
    ```text
    zip I/O error: No such file or directory
    zip error: Could not create output file (../../../../release-artifacts/Tsuzuri_2.0.1_macos.zip)
    Error: Process completed with exit code 15.
    ```
  - The build directory `build/macos/Build/Products/Release` is 5 directory levels deep (`build` / `macos` / `Build` / `Products` / `Release`).
  - The command previously used `../../../../release-artifacts`, which ascended only 4 levels (pointing to non-existent `build/release-artifacts/`).
- **Decision & Architecture**:
  - Replaced all fragile `../` relative paths in archive packaging with absolute `$WORKSPACE` / `$PWD` paths executed within isolated subshells:
    ```bash
    WORKSPACE="$PWD"
    (cd build/macos/Build/Products/Release && zip -r "$WORKSPACE/release-artifacts/Tsuzuri_${VERSION}_macos.zip" "$APP_NAME")
    ```
  - Applied the same subshell pattern to Web packaging (`(cd build/web && zip -r "$WORKSPACE/release-artifacts/Tsuzuri_${VERSION}_web.zip" .)`) and iOS packaging (`(cd release-artifacts && zip -r "Tsuzuri_${VERSION}.ipa" Payload)`).
  - This eliminates path-counting bugs, preserves the parent shell's working directory, and guarantees reliable artifact generation.
- **Verification**:
  - `flutter analyze`: 0 issues found.
  - `flutter test`: 49/49 automated unit, widget, and regression tests passed.

















