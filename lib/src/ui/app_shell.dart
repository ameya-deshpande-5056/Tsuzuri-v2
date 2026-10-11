import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../editor/markdown_editor.dart';
import '../models/document_state.dart';
import '../parser/toc_parser.dart';
import '../renderer/reader_view.dart';
import '../services/file_service.dart';
import 'about_dialog.dart';
import 'actions_sheet.dart';
import 'app_header.dart';
import 'modal_overlay_tracker.dart';
import 'toc_drawer.dart';

/// The central application shell widget for Tsuzuri v2.
///
/// Manages:
/// - Mutually exclusive Reader and Editor views
/// - Document state lifecycle and safe file saving
/// - Table of Contents navigation drawer
/// - Actions sheet and keyboard shortcuts
class AppShell extends StatefulWidget {
  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  final String? initialFilePath;
  final String? initialContent;

  const AppShell({
    super.key,
    required this.currentThemeMode,
    required this.onThemeChanged,
    this.initialFilePath,
    this.initialContent,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<ReaderViewState> _readerKey = GlobalKey<ReaderViewState>();

  late DocumentState _document;
  late TextEditingController _editorController;

  bool _isEditorMode = false;
  bool _showFindReplace = false;
  bool _wordWrap = true;
  bool _isActionsMenuOpen = false;
  bool _isEndDrawerOpen = false;
  List<TocItem> _tocItems = [];

  bool get _isCenterDialogActive =>
      ModalOverlayTracker.instance.hasModalRoute.value && !_isActionsMenuOpen;

  double get _readerRightInset {
    final isDesktop = MediaQuery.sizeOf(context).width >= 681;
    if (!isDesktop) return 0.0;
    if (_isActionsMenuOpen || _isEndDrawerOpen) {
      return 304.0;
    }
    return 0.0;
  }

  @override
  void initState() {
    super.initState();
    ModalOverlayTracker.instance.hasModalRoute.addListener(_onModalOverlayChanged);
    final content = widget.initialContent ?? _defaultDocument;
    _document = DocumentState(
      filePath: widget.initialFilePath,
      content: content,
      savedSnapshot: content,
    );
    _editorController = TextEditingController(text: content);
    _updateToc(content);
  }

  @override
  void dispose() {
    ModalOverlayTracker.instance.hasModalRoute.removeListener(_onModalOverlayChanged);
    _editorController.dispose();
    super.dispose();
  }

  void _onModalOverlayChanged() {
    if (mounted) setState(() {});
  }

  void _updateToc(String markdown) {
    _tocItems = TocParser.parse(markdown);
  }

  void _onContentChanged(String newContent) {
    if (!_document.isDirty) {
      setState(() {
        _document = _document.copyWithContent(newContent);
      });
    } else {
      _document = _document.copyWithContent(newContent);
    }
  }

  void _toggleViewMode() {
    setState(() {
      _isEditorMode = !_isEditorMode;
      if (!_isEditorMode) {
        // Sync reader with edited content
        _document = _document.copyWithContent(_editorController.text);
        _updateToc(_editorController.text);
      }
    });
  }

  void _openToc() {
    _updateToc(_editorController.text);
    _scaffoldKey.currentState?.openEndDrawer();
  }

  Future<void> _handleSave() async {
    final currentContent = _editorController.text;

    if (_document.filePath == null) {
      // Prompt Save As
      await _handleSaveAs();
      return;
    }

    try {
      await FileService.saveFileAtomic(_document.filePath!, currentContent);
      setState(() {
        _document = _document.markSaved(_document.filePath!);
      });
      _showToast('Document saved successfully.');
    } catch (e) {
      _showToast('Error saving file: $e', isError: true);
    }
  }

  Future<void> _handleSaveAs() async {
    final currentContent = _editorController.text;
    try {
      final savedPath = await FileService.pickSavePathAndSave(
        defaultFileName: _document.title,
        content: currentContent,
      );

      if (savedPath != null) {
        setState(() {
          _document = _document.markSaved(savedPath);
        });
        _showToast('Document saved as ${savedPath.split('/').last}.');
      }
    } catch (e) {
      _showToast('Error saving file: $e', isError: true);
    }
  }

  Future<void> _handleOpen() async {
    // Check for unsaved changes before opening new file
    if (_document.isDirty) {
      final proceed = await _confirmDiscardUnsavedChanges();
      if (!proceed) return;
    }

    try {
      final filePath = await FileService.pickMarkdownFile();
      if (filePath != null) {
        final content = await FileService.readFile(filePath);
        setState(() {
          _document = DocumentState(
            filePath: filePath,
            content: content,
            savedSnapshot: content,
          );
          _editorController.text = content;
          _updateToc(content);
        });
        _showToast('Opened ${_document.title}.');
      }
    } catch (e) {
      _showToast('Error opening file: $e', isError: true);
    }
  }

  Future<bool> _confirmDiscardUnsavedChanges() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes in this document. Do you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _openMoreActions() async {
    final readerState = _readerKey.currentState;
    if (!kIsWeb &&
        Platform.isLinux &&
        !_isEditorMode &&
        (readerState?.hasActiveController ?? false)) {
      final themeStr = widget.currentThemeMode == ThemeMode.dark
          ? 'dark'
          : widget.currentThemeMode == ThemeMode.light
              ? 'light'
              : 'system';
      readerState?.toggleActionsPopover(
        wordWrap: _wordWrap,
        themeMode: themeStr,
      );
      return;
    }

    setState(() => _isActionsMenuOpen = true);
    try {
      await ActionsSheet.show(
        context,
        ActionsSheet(
          isEditorMode: _isEditorMode,
          wordWrap: _wordWrap,
          currentThemeMode: widget.currentThemeMode,
          onToggleMode: _toggleViewMode,
          onOpenFile: _handleOpen,
          onSaveFile: _handleSave,
          onSaveAsFile: _handleSaveAs,
          onToggleFindReplace: () => setState(() => _showFindReplace = !_showFindReplace),
          onToggleWordWrap: () => setState(() => _wordWrap = !_wordWrap),
          onThemeChanged: widget.onThemeChanged,
          onOpenAbout: () async {
            final cleanVersion = await TsuzuriAboutDialog.getCleanVersion();
            final currentReader = _readerKey.currentState;
            if (!kIsWeb &&
                Platform.isLinux &&
                !_isEditorMode &&
                (currentReader?.hasActiveController ?? false)) {
              currentReader?.openAboutDialog(cleanVersion);
            } else {
              if (mounted) {
                TsuzuriAboutDialog.show(context);
              }
            }
          },
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isActionsMenuOpen = false);
      }
    }
  }

  void _handleReaderAction(String action) async {
    switch (action) {
      case 'toggleMode':
        _toggleViewMode();
        break;
      case 'openFile':
        _handleOpen();
        break;
      case 'saveFile':
        _handleSave();
        break;
      case 'saveAsFile':
        _handleSaveAs();
        break;
      case 'toggleWordWrap':
        setState(() => _wordWrap = !_wordWrap);
        break;
      case 'about':
        final cleanVersion = await TsuzuriAboutDialog.getCleanVersion();
        _readerKey.currentState?.openAboutDialog(cleanVersion);
        break;
      case 'theme:system':
        widget.onThemeChanged(ThemeMode.system);
        break;
      case 'theme:light':
        widget.onThemeChanged(ThemeMode.light);
        break;
      case 'theme:dark':
        widget.onThemeChanged(ThemeMode.dark);
        break;
    }
  }

  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[800] : null,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onSelectTocHeading(TocItem item) {
    if (_isEditorMode) {
      _toggleViewMode();
    }
    // Jump to heading in reader
    _readerKey.currentState?.scrollToHeading(item.slug);
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyE, control: true): _toggleViewMode,
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): _handleSave,
        const SingleActivator(LogicalKeyboardKey.keyS, control: true, shift: true): _handleSaveAs,
        const SingleActivator(LogicalKeyboardKey.keyO, control: true): _handleOpen,
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): () {
          if (_isEditorMode) setState(() => _showFindReplace = !_showFindReplace);
        },
        const SingleActivator(LogicalKeyboardKey.keyZ, alt: true): () {
          setState(() => _wordWrap = !_wordWrap);
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          key: _scaffoldKey,
          onEndDrawerChanged: (isOpen) {
            setState(() => _isEndDrawerOpen = isOpen);
          },
          appBar: AppHeader(
            documentTitle: _document.title,
            isDirty: _document.isDirty,
            isEditorMode: _isEditorMode,
            onToggleMode: _toggleViewMode,
            onOpenToc: _openToc,
            onSave: _handleSave,
            onMoreActions: _openMoreActions,
            onShowTooltip: (!kIsWeb && Platform.isLinux && !_isEditorMode)
                ? (text, rightOffset) => _readerKey.currentState?.showTooltip(text, rightOffset)
                : null,
            onHideTooltip: (!kIsWeb && Platform.isLinux && !_isEditorMode)
                ? () => _readerKey.currentState?.hideTooltip()
                : null,
          ),
          endDrawer: TocDrawer(
            items: _tocItems,
            onSelectHeading: _onSelectTocHeading,
          ),
          body: Stack(
            children: [
              Offstage(
                offstage: _isEditorMode,
                child: TickerMode(
                  enabled: !_isEditorMode,
                  child: ReaderView(
                    key: _readerKey,
                    markdown: _document.content,
                    themeMode: widget.currentThemeMode,
                    baseDir: _document.baseDir,
                    rightInset: _readerRightInset,
                    isDialogActive: _isCenterDialogActive,
                    onAction: _handleReaderAction,
                  ),
                ),
              ),
              Offstage(
                offstage: !_isEditorMode,
                child: TickerMode(
                  enabled: _isEditorMode,
                  child: MarkdownEditor(
                    controller: _editorController,
                    showFindReplace: _showFindReplace,
                    onCloseFindReplace: () => setState(() => _showFindReplace = false),
                    onChanged: _onContentChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const String _defaultDocument = '''# Tsuzuri (綴り)

A quiet, lightweight, offline-first Markdown reader and editor built with Flutter and Dart.

## 1. Design & Typography

Tsuzuri focuses on a restrained, readable reading experience:
- **Bold text**, *italic text*, and ~~strikethrough~~.
- Fenced code spans and nested lists.
- [x] Offline rendering bundled locally
- [x] First-class LaTeX mathematics
- [x] Mermaid diagram SVG generation
- [ ] Split-pane preview (Explicitly rejected: views are mutually exclusive)

## 2. LaTeX Mathematical Correctness

### Inline Mathematics
Euler's identity: \$e^{i\\pi} + 1 = 0\$, and Gauss's law: \\(\\nabla \\cdot \\vec{E} = \\frac{\\rho}{\\varepsilon_0}\\).

### Display Mathematics
The Gaussian integral:
\$\$
\\int_{-\\infty}^{\\infty} e^{-x^2}\\,dx = \\sqrt{\\pi}
\$\$

Normalized LaTeX display delimiter:
\\[
\\sum_{n=1}^{\\infty} \\frac{1}{n^2} = \\frac{\\pi^2}{6}
\\]

### Chemistry Notation (mhchem)
\\ce{2H2 + O2 -> 2H2O} and \\ce{CO2 + H2O <=> H2CO3}

## 3. Mermaid Diagram Rendering

```mermaid
flowchart TD
  A[Markdown Source] --> B[Delimiter Normalizer]
  B --> C[Offline Render Harness]
  C --> D[KaTeX Math Engine]
  C --> E[Mermaid SVG Engine]
  D --> F[Reader View Canvas]
  E --> F
```

## 4. Syntax Highlighting

```dart
void renderDocument(String source) {
  final normalized = MathDelimiterNormalizer.normalize(source);
  print('Document parsed successfully: \${normalized.normalizedLength} chars');
}
```

## 5. Responsive Data Table

| Specification | Target | Status |
| :--- | :---: | :--- |
| Canvas Color (Dark) | `#000000` | AMOLED Pure Black |
| Offline Assets | 100% Bundled | Zero CDN Runtime Calls |
| Math Delimiters | `\$`, `\$\$`, `\\(`, `\\[` | Fully Normalized |
| Diagram Engine | Mermaid SVG | Local Sandbox Execution |

## 6. Footnotes & References

Footnotes render cleanly at the end of the document.[^note1]

[^note1]: Tsuzuri (綴り) is designed for deep, distraction-free reading and technical writing.
''';
}

