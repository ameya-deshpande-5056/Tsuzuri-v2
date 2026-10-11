import 'package:flutter_test/flutter_test.dart';
import 'package:tsuzuri/src/parser/toc_parser.dart';

void main() {
  group('TocParser', () {
    test('extracts H1-H6 headings with correct hierarchy and slugs', () {
      const input = '''
# Document Title

Introductory paragraph.

## Section 1: Overview
Content here.

### Subsection 1.1: Details
More details.

#### Sub-subsection
Deep detail.

## Section 2: Conclusion
Wrap up.
''';

      final items = TocParser.parse(input);

      expect(items.length, 5);
      expect(items[0].level, 1);
      expect(items[0].text, 'Document Title');
      expect(items[0].slug, 'document-title');

      expect(items[1].level, 2);
      expect(items[1].text, 'Section 1: Overview');
      expect(items[1].slug, 'section-1-overview');

      expect(items[2].level, 3);
      expect(items[2].text, 'Subsection 1.1: Details');
      expect(items[2].slug, 'subsection-11-details');

      expect(items[3].level, 4);
      expect(items[3].text, 'Sub-subsection');
      expect(items[3].slug, 'sub-subsection');

      expect(items[4].level, 2);
      expect(items[4].text, 'Section 2: Conclusion');
      expect(items[4].slug, 'section-2-conclusion');
    });

    test('strictly ignores headings inside fenced code blocks', () {
      const input = '''
# Real Title

```markdown
# Fake Heading in Code
## Another Fake Heading
```

~~~bash
# Comments in bash should not be in TOC
echo "hello"
~~~

## Real Section
''';

      final items = TocParser.parse(input);

      expect(items.length, 2);
      expect(items[0].text, 'Real Title');
      expect(items[1].text, 'Real Section');
    });

    test('strips inline markdown formatting from headings', () {
      const input = '''
# **Bold Title** with *Italic* and `Code`
## [Link Heading](https://example.com) and ~~Strike~~
''';

      final items = TocParser.parse(input);

      expect(items.length, 2);
      expect(items[0].text, 'Bold Title with Italic and Code');
      expect(items[0].slug, 'bold-title-with-italic-and-code');
      expect(items[1].text, 'Link Heading and Strike');
      expect(items[1].slug, 'link-heading-and-strike');
    });

    test('handles empty input gracefully', () {
      final items = TocParser.parse('');
      expect(items, isEmpty);
    });
  });
}

