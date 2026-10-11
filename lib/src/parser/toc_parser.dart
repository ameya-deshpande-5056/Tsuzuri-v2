/// Represents an item in the document Table of Contents.
class TocItem {
  final int level;
  final String text;
  final String slug;
  final int lineNumber;

  const TocItem({
    required this.level,
    required this.text,
    required this.slug,
    required this.lineNumber,
  });

  @override
  String toString() => 'TocItem(h$level: "$text", slug: "$slug")';
}

/// Headless pure Dart parser for extracting Table of Contents from Markdown documents.
class TocParser {
  /// Extracts headings from [markdown] while strictly ignoring any headings
  /// located inside fenced code blocks.
  static List<TocItem> parse(String markdown) {
    if (markdown.trim().isEmpty) return const [];

    final items = <TocItem>[];
    final lines = markdown.replaceAll('\r\n', '\n').split('\n');

    bool inCodeFence = false;
    String fenceChar = '';
    int fenceLen = 0;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trimLeft();

      // Check code fence state
      if (inCodeFence) {
        if (trimmed.startsWith(fenceChar * fenceLen)) {
          final rest = trimmed.substring(fenceLen).trim();
          if (rest.isEmpty || rest.replaceAll(fenceChar, '').isEmpty) {
            inCodeFence = false;
          }
        }
        continue;
      }

      // Check for opening fence
      final fenceMatch = RegExp(r'^[ ]{0,3}(`{3,}|~{3,})').firstMatch(line);
      if (fenceMatch != null) {
        inCodeFence = true;
        fenceChar = fenceMatch.group(1)![0];
        fenceLen = fenceMatch.group(1)!.length;
        continue;
      }

      // Atx Heading: ^#{1,6}\s+(.+)
      final headingMatch = RegExp(r'^(#{1,6})[ \t]+(.+)$').firstMatch(line);
      if (headingMatch != null) {
        final level = headingMatch.group(1)!.length;
        final rawText = headingMatch.group(2)!.trim();
        final cleanText = stripMarkdown(rawText);
        final slug = slugify(cleanText);

        items.add(TocItem(
          level: level,
          text: cleanText,
          slug: slug,
          lineNumber: i + 1,
        ));
      }
    }

    return items;
  }

  /// Generates a web-safe slug matching the HTML renderer slug generator.
  static String slugify(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'[\s_-]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  /// Strips inline markdown formatting like bold, italic, code, links.
  static String stripMarkdown(String text) {
    return text
        // Images: ![alt](url) -> alt
        .replaceAllMapped(RegExp(r'!\[([^\]]*)\]\([^)]*\)'), (m) => m.group(1) ?? '')
        // Links: [text](url) -> text
        .replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^)]*\)'), (m) => m.group(1) ?? '')
        // Bold/Italic: **text** or *text* or __text__ or _text_
        .replaceAllMapped(RegExp(r'[*_]{1,3}(.*?)[*_]{1,3}'), (m) => m.group(1) ?? '')
        // Inline code: `code`
        .replaceAllMapped(RegExp(r'`+([^`]+)`+'), (m) => m.group(1) ?? '')
        // Strikethrough: ~~text~~
        .replaceAllMapped(RegExp(r'~~(.*?)~~'), (m) => m.group(1) ?? '')
        // HTML tags
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .trim();
  }
}
