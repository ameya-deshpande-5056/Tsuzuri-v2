import 'package:flutter_test/flutter_test.dart';
import 'package:tsuzuri/src/renderer/bundled_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BundledAssets', () {
    setUp(() {
      BundledAssets.clearCache();
    });

    test('getSelfContainedHtml inlines all CSS and JS assets', () async {
      final html = await BundledAssets.getSelfContainedHtml();

      expect(html, contains('<!DOCTYPE html>'));
      expect(html, contains('id="renderer-css"'));
      expect(html, contains('id="katex-css"'));
      expect(html, contains('id="markdown-it-js"'));
      expect(html, contains('id="footnote-js"'));
      expect(html, contains('id="task-lists-js"'));
      expect(html, contains('id="highlight-js"'));
      expect(html, contains('id="katex-js"'));
      expect(html, contains('id="mhchem-js"'));
      expect(html, contains('id="mermaid-js"'));

      // Ensure no external remote URLs or CDNs are referenced
      expect(html, isNot(contains('cdn.jsdelivr.net')));
      expect(html, isNot(contains('cdnjs.cloudflare.com')));
      expect(html, isNot(contains('unpkg.com')));
    });

    test('buildHtmlDocument injects initial render script with escaped markdown', () async {
      const sampleMarkdown = '# Test Heading\n\nInline math: \$x = 1\$.\n\n```mermaid\nflowchart TD\nA-->B\n```';
      final html = await BundledAssets.buildHtmlDocument(
        markdown: sampleMarkdown,
        theme: 'dark',
      );

      expect(html, contains('id="initial-render-trigger"'));
      expect(html, contains('window.renderDocument('));
      expect(html, contains('dark'));
    });
  });
}

