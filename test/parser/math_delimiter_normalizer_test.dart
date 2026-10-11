import 'package:flutter_test/flutter_test.dart';
import 'package:tsuzuri/src/parser/math_delimiter_normalizer.dart';

void main() {
  group('MathDelimiterNormalizer', () {
    test('normalizes inline LaTeX \\(...\\) to \$...\$', () {
      const input = 'This is inline math: \\(e^{i\\pi} + 1 = 0\\) in text.';
      final result = MathDelimiterNormalizer.normalize(input);

      expect(result.inlineDelimitersNormalized, 1);
      expect(result.displayDelimitersNormalized, 0);
      expect(result.normalizedText, 'This is inline math: \$e^{i\\pi} + 1 = 0\$ in text.');
      expect(result.hasWarnings, false);
    });

    test('normalizes display LaTeX \\[...\\] to \$\$...\$\$ with spacing', () {
      const input = 'Display equation:\n\\[\n\\int_0^\\infty e^{-x^2} dx = \\frac{\\sqrt{\\pi}}{2}\n\\]';
      final result = MathDelimiterNormalizer.normalize(input);

      expect(result.displayDelimitersNormalized, 1);
      expect(result.inlineDelimitersNormalized, 0);
      expect(
        result.normalizedText,
        contains('\$\$\n\\int_0^\\infty e^{-x^2} dx = \\frac{\\sqrt{\\pi}}{2}\n\$\$'),
      );
      expect(result.hasWarnings, false);
    });

    test('strictly preserves fenced code blocks (backticks and tildes)', () {
      const input = '''
# Example

Here is code with LaTeX delimiters:

```latex
\\begin{equation}
\\[ x = \\frac{-b \\pm \\sqrt{b^2 - 4ac}}{2a} \\]
\\( \\alpha + \\beta \\)
\\end{equation}
```

And in tildes:

~~~bash
echo "\\(do not touch\\)"
~~~

And here is real prose: \\(x = 1\\).
''';

      final result = MathDelimiterNormalizer.normalize(input);

      expect(result.inlineDelimitersNormalized, 1);
      expect(result.displayDelimitersNormalized, 0);

      // Verify code blocks were untouched
      expect(result.normalizedText, contains('\\[ x = \\frac{-b \\pm \\sqrt{b^2 - 4ac}}{2a} \\]'));
      expect(result.normalizedText, contains('\\( \\alpha + \\beta \\)'));
      expect(result.normalizedText, contains('echo "\\(do not touch\\)"'));

      // Verify prose was converted
      expect(result.normalizedText, contains('And here is real prose: \$x = 1\$.'));
    });

    test('strictly preserves inline code spans `...`', () {
      const input = 'Use `\\(x\\)` to format inline or `\\[y\\]` for display, but prose \\(z = 1\\).';
      final result = MathDelimiterNormalizer.normalize(input);

      expect(result.inlineDelimitersNormalized, 1);
      expect(result.displayDelimitersNormalized, 0);
      expect(result.normalizedText, 'Use `\\(x\\)` to format inline or `\\[y\\]` for display, but prose \$z = 1\$.');
    });

    test('preserves existing \$...\$ and \$\$...\$\$ equations without double wrapping', () {
      const input = '''
An existing inline equation: \$E = mc^2\$.
And an existing display block:
\$\$
\\sum_{i=1}^n i = \\frac{n(n+1)}{2}
\$\$
''';
      final result = MathDelimiterNormalizer.normalize(input);

      expect(result.inlineDelimitersNormalized, 0);
      expect(result.displayDelimitersNormalized, 0);
      expect(result.normalizedText, input);
    });

    test('preserves HTML comments <!-- ... -->', () {
      const input = '<!-- \\[commented equation\\] -->\nReal equation: \\(a^2 + b^2 = c^2\\)';
      final result = MathDelimiterNormalizer.normalize(input);

      expect(result.inlineDelimitersNormalized, 1);
      expect(result.normalizedText, contains('<!-- \\[commented equation\\] -->'));
      expect(result.normalizedText, contains('Real equation: \$a^2 + b^2 = c^2\$'));
    });

    test('detects unclosed code fences and warns of potential truncation', () {
      const input = '''
```python
def test():
    pass
''';
      final result = MathDelimiterNormalizer.normalize(input);
      expect(result.hasWarnings, true);
      expect(result.warnings.first, contains('unclosed code fence'));
    });

    test('handles empty input gracefully', () {
      final result = MathDelimiterNormalizer.normalize('');
      expect(result.normalizedText, '');
      expect(result.originalLength, 0);
      expect(result.normalizedLength, 0);
      expect(result.hasWarnings, false);
    });

    test('handles mixed document with tables, footnotes, and math', () {
      const input = '''
| Term | Equation |
| --- | --- |
| Gauss | \\( \\int e^{-x^2} dx \\) |
| Fourier | \\[ F(\\omega) = \\int f(t) e^{-i\\omega t} dt \\] |

Footnote ref[^1].

[^1]: Note with \\( \\hbar = \\frac{h}{2\\pi} \\).
''';
      final result = MathDelimiterNormalizer.normalize(input);

      expect(result.inlineDelimitersNormalized, 2);
      expect(result.displayDelimitersNormalized, 1);
      expect(result.normalizedText, contains('| Gauss | \$\\int e^{-x^2} dx\$ |'));
      expect(result.normalizedText, contains('\$\$\nF(\\omega) = \\int f(t) e^{-i\\omega t} dt\n\$\$'));
      expect(result.normalizedText, contains('[^1]: Note with \$\\hbar = \\frac{h}{2\\pi}\$.'));
    });

    test('normalizes bare chemistry \\ce{...} and \\pu{...} to \$...\$ without double wrapping', () {
      const input = '''
### Chemistry Notation (mhchem)
\\ce{2H2 + O2 -> 2H2O} and \\ce{CO2 + H2O <=> H2CO3}
Already in math: \$\\ce{H+ + OH- <=> H2O}\$
Physical units: \\pu{123 kJ/mol}
Code block with \\ce:
```
\\ce{do not touch}
```
Inline code: `\\ce{also do not touch}`
''';
      final result = MathDelimiterNormalizer.normalize(input);

      expect(result.normalizedText, contains('\$\\ce{2H2 + O2 -> 2H2O}\$ and \$\\ce{CO2 + H2O <=> H2CO3}\$'));
      expect(result.normalizedText, contains('Already in math: \$\\ce{H+ + OH- <=> H2O}\$'));
      expect(result.normalizedText, contains('Physical units: \$\\pu{123 kJ/mol}\$'));
      expect(result.normalizedText, contains('```\n\\ce{do not touch}\n```'));
      expect(result.normalizedText, contains('`\\ce{also do not touch}`'));
    });

    test('regression: HTML comment with backticks does not corrupt code fence detection or math', () {
      const input = '''<!-- (```mermaid) -->
# Document Title

Some prose before code block.

```python
def solve():
    return 42
```

**Memory hook:** Here is an equation:
\$\$
f(x) = \\int_{-\\infty}^{\\infty} e^{-x^2} dx
\$\$

```sql
SELECT * FROM users WHERE id = 1;
```

Ending prose with \\( \\alpha + \\beta = \\gamma \\).
''';

      final result = MathDelimiterNormalizer.normalize(input);

      expect(result.hasWarnings, false);
      expect(result.normalizedText, contains('<!-- (```mermaid) -->'));
      expect(result.normalizedText, contains('```python\ndef solve():\n    return 42\n```'));
      expect(result.normalizedText, contains('**Memory hook:** Here is an equation:'));
      expect(result.normalizedText, contains('\$\$\nf(x) = \\int_{-\\infty}^{\\infty} e^{-x^2} dx\n\$\$'));
      expect(result.normalizedText, contains('```sql\nSELECT * FROM users WHERE id = 1;\n```'));
      expect(result.normalizedText, contains('Ending prose with \$\\alpha + \\beta = \\gamma\$.'));
    });
  });
}
