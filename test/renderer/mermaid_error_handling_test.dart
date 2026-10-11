import 'package:flutter_test/flutter_test.dart';
import 'package:tsuzuri/src/renderer/bundled_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Mermaid Error Handling & Failure Recovery', () {
    test('verifies template.html contains mermaid catch block and error card styling', () async {
      final html = await BundledAssets.getSelfContainedHtml();

      // Verify try/catch error handling around mermaid.render
      expect(html, contains('await window.mermaid.render'));
      expect(html, contains('catch (error)'));
      expect(html, contains('mermaid-error'));
      expect(html, contains('mermaid-error-title'));
      expect(html, contains('mermaid-error-source'));

      // Verify renderer.css contains styling for error cards
      expect(html, contains('.mermaid-error'));
      expect(html, contains('.mermaid-error-title'));
      expect(html, contains('.mermaid-error-source'));
    });

    test('builds html document with malformed mermaid diagram source without throwing', () async {
      const malformedDoc = '''# Malformed Mermaid Test

```mermaid
graph INVALID SYNTAX -> -> -> ???
```
''';

      final html = await BundledAssets.buildHtmlDocument(
        markdown: malformedDoc,
        theme: 'light',
      );

      expect(html, contains('graph INVALID SYNTAX'));
      expect(html, contains('window.renderDocument('));
    });
  });
}

