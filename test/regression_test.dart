import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsuzuri/src/parser/math_delimiter_normalizer.dart';
import 'package:tsuzuri/src/parser/toc_parser.dart';
import 'package:tsuzuri/src/renderer/bundled_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Regression Corpus Suite', () {
    final fixtures = [
      'test/fixtures/01_commonmark_basics.md',
      'test/fixtures/02_latex_equations.md',
      'test/fixtures/03_mermaid_diagrams.md',
      'test/fixtures/04_code_and_math_mix.md',
      'test/fixtures/05_gfm_tables_footnotes_tasks.md',
      'test/fixtures/06_gate_da_structure.md',
    ];

    for (final fixturePath in fixtures) {
      test('Verifies regression fixture: $fixturePath', () async {
        final file = File(fixturePath);
        expect(await file.exists(), true);
        final rawMarkdown = await file.readAsString();

        // 1. Math Delimiter Normalization
        final normResult = MathDelimiterNormalizer.normalize(rawMarkdown);
        expect(normResult.hasWarnings, false);
        expect(normResult.normalizedText.isNotEmpty, true);

        // In code_and_math_mix, verify Python strings inside fences were NOT converted
        if (fixturePath.contains('04_code_and_math_mix.md')) {
          expect(normResult.normalizedText, contains(r'equation = "$E = mc^2$"'));
          expect(normResult.normalizedText, contains(r'display_formula = r"\[ \int_0^1 x dx \]"'));
          expect(normResult.normalizedText, contains(r'`\(not_an_equation\)`'));
          // Prose was converted
          expect(normResult.normalizedText, contains(r'Prose math right below: $\alpha + \beta = \gamma$.'));
        }

        // In gate_da_structure, verify HTML comment, closing fences, and chemistry
        if (fixturePath.contains('06_gate_da_structure.md')) {
          expect(normResult.normalizedText, contains('<!-- (```mermaid) -->'));
          expect(normResult.normalizedText, contains('**Memory hook:** A closing fence must terminate cleanly'));
          expect(normResult.normalizedText, contains(r'$\ce{2H2 + O2 -> 2H2O}$'));
          expect(normResult.normalizedText, contains(r'$\ce{CO2 + H2O <=> H2CO3}$'));
        }

        // 2. TOC Parsing
        final toc = TocParser.parse(normResult.normalizedText);
        expect(toc.isNotEmpty, true);
        expect(toc.every((item) => item.slug.isNotEmpty), true);

        // 3. Bundled Offline HTML Generation
        final html = await BundledAssets.buildHtmlDocument(
          markdown: normResult.normalizedText,
          theme: 'dark',
        );

        expect(html, contains('<!DOCTYPE html>'));
        expect(html, contains('id="renderer-css"'));
        expect(html, contains('id="initial-render-trigger"'));
        expect(html, contains('id="katex-js"'));
        expect(html, contains('id="mermaid-js"'));
      });
    }
  });
}
