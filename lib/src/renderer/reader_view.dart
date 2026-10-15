import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_all/webview_all.dart';
import 'bundled_assets.dart';
import '../parser/math_delimiter_normalizer.dart';
import '../parser/toc_parser.dart';

/// Renders a formatted Markdown document with first-class LaTeX and Mermaid support.
///
/// Mutually exclusive with the raw Markdown Editor view.
/// Operates completely offline using bundled assets.
class ReaderView extends StatefulWidget {
  final String markdown;
  final ThemeMode themeMode;
  final String? baseDir;
  final VoidCallback? onRenderComplete;
  final ValueChanged<String>? onAction;
  final double rightInset;
  final bool isDialogActive;

  const ReaderView({
    super.key,
    required this.markdown,
    this.themeMode = ThemeMode.system,
    this.baseDir,
    this.onRenderComplete,
    this.onAction,
    this.rightInset = 0.0,
    this.isDialogActive = false,
  });

  @override
  State<ReaderView> createState() => ReaderViewState();
}

class ReaderViewState extends State<ReaderView> {
  WebViewController? _controller;
  bool _isInitialized = false;

  bool get hasActiveController => _controller != null;

  bool get isDarkMode {
    if (widget.themeMode == ThemeMode.dark) return true;
    if (widget.themeMode == ThemeMode.light) return false;
    return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
  }

  String get themeName => isDarkMode ? 'dark' : 'light';

  @override
  void initState() {
    super.initState();
    if (WebViewPlatform.instance != null) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..addJavaScriptChannel(
          'TsuzuriHost',
          onMessageReceived: (JavaScriptMessage message) {
            widget.onAction?.call(message.message);
          },
        )
        ..setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: (NavigationRequest request) {
              if (request.url.startsWith('tsuzuri-action://')) {
                final action = request.url.replaceFirst('tsuzuri-action://', '');
                widget.onAction?.call(action);
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
            onPageFinished: (url) {
              widget.onRenderComplete?.call();
            },
          ),
        );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadDocument();
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onRenderComplete?.call();
      });
    }
  }

  @override
  void didUpdateWidget(covariant ReaderView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.markdown != widget.markdown ||
        oldWidget.themeMode != widget.themeMode ||
        oldWidget.baseDir != widget.baseDir) {
      _updateContent();
    }
  }

  Future<void> _loadDocument() async {
    if (_controller == null) return;
    try {
      final normalizedResult = MathDelimiterNormalizer.normalize(widget.markdown);
      final html = await BundledAssets.buildHtmlDocument(
        markdown: normalizedResult.normalizedText,
        theme: themeName,
        baseDir: widget.baseDir,
      );

      final String? baseUrl;
      if (kIsWeb) {
        baseUrl = null;
      } else if (Platform.isAndroid) {
        baseUrl = 'file:///android_asset/flutter_assets/';
      } else if (widget.baseDir != null) {
        baseUrl = 'file://${widget.baseDir}/';
      } else {
        baseUrl = null;
      }
      await _controller?.loadHtmlString(html, baseUrl: baseUrl);
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error loading document in ReaderView: $e');
    }
  }

  Future<void> _updateContent() async {
    if (_controller == null) return;
    if (!_isInitialized) {
      await _loadDocument();
      return;
    }
    final normalizedResult = MathDelimiterNormalizer.normalize(widget.markdown);
    final escapedMd = _escapeJs(normalizedResult.normalizedText);
    final escapedTheme = themeName;
    final escapedBase = widget.baseDir != null ? '"${_escapeJs(widget.baseDir!)}"' : 'null';

    try {
      await _controller?.runJavaScript(
        'window.renderDocument("$escapedMd", "$escapedTheme", $escapedBase);',
      );
    } catch (_) {
      await _loadDocument();
    }
  }

  String _escapeJs(String s) {
    return s
        .replaceAll(r'\', r'\\')
        .replaceAll('"', r'\"')
        .replaceAll('\n', r'\n')
        .replaceAll('\r', r'\r')
        .replaceAll('\t', r'\t');
  }

  /// Scrolls smoothly to a specific heading slug ID.
  Future<void> scrollToHeading(String headingId) async {
    if (_controller == null) return;
    try {
      await _controller?.runJavaScript(
        'window.scrollToHeading("${_escapeJs(headingId)}");',
      );
    } catch (_) {}
  }

  /// Opens the About Tsuzuri modal dialog inside the rendered Reader view
  /// with faint blurred backdrop matching the original Tauri application.
  Future<void> openAboutDialog(String version, [String buildTime = '2026-10-11T12:00:00Z']) async {
    if (_controller == null) return;
    try {
      await _controller?.runJavaScript(
        'window.openAboutDialog("${_escapeJs(version)}", "${_escapeJs(buildTime)}");',
      );
    } catch (_) {}
  }

  /// Toggles the actions menu popover inside the rendered Reader view on Linux desktop.
  Future<void> toggleActionsPopover({
    required bool wordWrap,
    required String themeMode,
  }) async {
    if (_controller == null) return;
    try {
      await _controller?.runJavaScript(
        'window.toggleActionsPopover({ wordWrap: $wordWrap, theme: "$themeMode" });',
      );
    } catch (_) {}
  }

  /// Closes the actions menu popover inside the rendered Reader view.
  Future<void> closeActionsPopover() async {
    if (_controller == null) return;
    try {
      await _controller?.runJavaScript('window.closeActionsPopover();');
    } catch (_) {}
  }

  /// Displays the header action tooltip over the webview on Linux desktop.
  Future<void> showTooltip(String text, double rightOffset) async {
    if (_controller == null) return;
    try {
      final escaped = _escapeJs(text);
      await _controller?.runJavaScript('window.showTooltip("$escaped", $rightOffset);');
    } catch (_) {}
  }

  /// Hides the header action tooltip over the webview.
  Future<void> hideTooltip() async {
    if (_controller == null) return;
    try {
      await _controller?.runJavaScript('window.hideTooltip();');
    } catch (_) {}
  }

  /// Opens the Table of Contents slide-in overlay panel in Reader view.
  Future<void> openTocPanel(List<TocItem> items) async {
    if (_controller == null) return;
    try {
      final jsonList = items.map((item) => {
        'level': item.level,
        'text': item.text,
        'slug': item.slug,
      }).toList();
      final jsonStr = jsonEncode(jsonList);
      final escaped = _escapeJs(jsonStr);
      await _controller?.runJavaScript('window.openTocPanel("$escaped");');
    } catch (_) {}
  }

  /// Closes the Table of Contents slide-in overlay panel in Reader view.
  Future<void> closeTocPanel() async {
    if (_controller == null) return;
    try {
      await _controller?.runJavaScript('window.closeTocPanel();');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDarkMode ? const Color(0xFF000000) : const Color(0xFFFCFCFC);
    final effectiveRightInset = (!kIsWeb && Platform.isLinux) ? widget.rightInset : 0.0;

    if (_controller == null) {
      return Container(
        color: backgroundColor,
        child: const Center(
          child: Text('Reader View'),
        ),
      );
    }

    return Container(
      color: backgroundColor,
      padding: EdgeInsets.only(right: effectiveRightInset),
      child: WebViewWidget(controller: _controller!),
    );
  }
}
