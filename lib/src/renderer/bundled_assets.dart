import 'package:flutter/services.dart';

/// Manages and prepares bundled offline rendering assets for the Reader view.
class BundledAssets {
  static const String templatePath = 'assets/renderer/template.html';
  static const String cssPath = 'assets/renderer/renderer.css';
  static const String katexCssPath = 'assets/renderer/vendor/katex/katex.min.css';
  static const String markdownItJsPath = 'assets/renderer/vendor/markdown-it.min.js';
  static const String footnoteJsPath = 'assets/renderer/vendor/markdown-it-footnote.min.js';
  static const String taskListsJsPath = 'assets/renderer/vendor/markdown-it-task-lists.min.js';
  static const String highlightJsPath = 'assets/renderer/vendor/highlight.min.js';
  static const String katexJsPath = 'assets/renderer/vendor/katex/katex.min.js';
  static const String mhchemJsPath = 'assets/renderer/vendor/katex/mhchem.min.js';
  static const String mermaidJsPath = 'assets/renderer/vendor/mermaid.min.js';

  static String? _cachedSelfContainedHtml;

  /// Loads and caches a self-contained offline HTML document containing all
  /// bundled styles, scripts, and the rendering harness.
  static Future<String> getSelfContainedHtml() async {
    if (_cachedSelfContainedHtml != null) {
      return _cachedSelfContainedHtml!;
    }

    // Load all individual bundled assets
    final template = await rootBundle.loadString(templatePath);
    final css = await rootBundle.loadString(cssPath);
    final rawKatexCss = await rootBundle.loadString(katexCssPath);
    final katexCss = rawKatexCss.replaceAll('url(fonts/', 'url(assets/renderer/vendor/katex/fonts/');
    final markdownItJs = await rootBundle.loadString(markdownItJsPath);
    final footnoteJs = await rootBundle.loadString(footnoteJsPath);
    final taskListsJs = await rootBundle.loadString(taskListsJsPath);
    final highlightJs = await rootBundle.loadString(highlightJsPath);
    final katexJs = await rootBundle.loadString(katexJsPath);
    final mhchemJs = await rootBundle.loadString(mhchemJsPath);
    final mermaidJs = await rootBundle.loadString(mermaidJsPath);

    // Replace external link and script tags with inline content for 100% offline reliability
    var inlined = template;

    inlined = inlined.replaceFirst(
      '<link rel="stylesheet" href="renderer.css">',
      '<style id="renderer-css">\n$css\n</style>',
    );

    inlined = inlined.replaceFirst(
      '<link rel="stylesheet" href="vendor/katex/katex.min.css">',
      '<style id="katex-css">\n$katexCss\n</style>',
    );

    inlined = inlined.replaceFirst(
      '<script src="vendor/markdown-it.min.js"></script>',
      '<script id="markdown-it-js">\n$markdownItJs\n</script>',
    );

    inlined = inlined.replaceFirst(
      '<script src="vendor/markdown-it-footnote.min.js"></script>',
      '<script id="footnote-js">\n$footnoteJs\n</script>',
    );

    inlined = inlined.replaceFirst(
      '<script src="vendor/markdown-it-task-lists.min.js"></script>',
      '<script id="task-lists-js">\n$taskListsJs\n</script>',
    );

    inlined = inlined.replaceFirst(
      '<script src="vendor/highlight.min.js"></script>',
      '<script id="highlight-js">\n$highlightJs\n</script>',
    );

    inlined = inlined.replaceFirst(
      '<script src="vendor/katex/katex.min.js"></script>',
      '<script id="katex-js">\n$katexJs\n</script>',
    );

    inlined = inlined.replaceFirst(
      '<script src="vendor/katex/mhchem.min.js"></script>',
      '<script id="mhchem-js">\n$mhchemJs\n</script>',
    );

    inlined = inlined.replaceFirst(
      '<script src="vendor/mermaid.min.js"></script>',
      '<script id="mermaid-js">\n$mermaidJs\n</script>',
    );

    _cachedSelfContainedHtml = inlined;
    return inlined;
  }

  /// Builds a complete offline HTML string with the specified [markdown] pre-rendered or injected.
  static Future<String> buildHtmlDocument({
    required String markdown,
    required String theme,
    String? baseDir,
  }) async {
    final baseHtml = await getSelfContainedHtml();

    // Escape markdown for safe JS string injection
    final escapedMd = _escapeJsString(markdown);
    final escapedBaseDir = baseDir != null ? '"${_escapeJsString(baseDir)}"' : "null";

    // Inject immediate render execution right before the closing </body> tag
    final autoRenderScript = '''
<script id="initial-render-trigger">
  (function() {
    function tryRender() {
      if (typeof window.renderDocument === 'function') {
        window.renderDocument("$escapedMd", "$theme", $escapedBaseDir);
      }
    }
    if (document.readyState === 'complete' || document.readyState === 'interactive') {
      tryRender();
    } else {
      document.addEventListener('DOMContentLoaded', tryRender);
    }
  })();
</script>
''';

    final lastBodyIndex = baseHtml.lastIndexOf('</body>');
    if (lastBodyIndex != -1) {
      return '${baseHtml.substring(0, lastBodyIndex)}$autoRenderScript${baseHtml.substring(lastBodyIndex)}';
    }
    return '$baseHtml$autoRenderScript';
  }

  static String _escapeJsString(String s) {
    return s
        .replaceAll(r'\', r'\\')
        .replaceAll('"', r'\"')
        .replaceAll('\n', r'\n')
        .replaceAll('\r', r'\r')
        .replaceAll('\t', r'\t');
  }

  /// Clears the asset cache (useful during tests or theme reconfiguration).
  static void clearCache() {
    _cachedSelfContainedHtml = null;
  }
}

