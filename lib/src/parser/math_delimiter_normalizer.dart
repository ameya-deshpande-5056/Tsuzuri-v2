/// Represents a segment of a Markdown document during math delimiter processing.
enum SegmentType {
  /// A fenced code block (e.g. ```lang ... ``` or ~~~lang ... ~~~). Must remain untouched.
  fencedCode,

  /// An inline code span (e.g. `code`). Must remain untouched.
  inlineCode,

  /// An HTML comment block (<!-- ... -->). Must remain untouched.
  htmlComment,

  /// Standard Markdown prose text where mathematical delimiters can be normalized.
  proseText,
}

/// A slice of Markdown content with its identified type.
class MarkdownSegment {
  final SegmentType type;
  final String text;
  final String? info;

  const MarkdownSegment({
    required this.type,
    required this.text,
    this.info,
  });

  @override
  String toString() => 'MarkdownSegment($type, len=${text.length})';
}

/// Result of normalizing math delimiters in a Markdown document.
class NormalizationResult {
  /// The normalized Markdown content.
  final String normalizedText;

  /// Original character count.
  final int originalLength;

  /// Normalized character count.
  final int normalizedLength;

  /// Number of display math delimiters normalized (`\[...\]` -> `$$...$$`).
  final int displayDelimitersNormalized;

  /// Number of inline math delimiters normalized (`\(...\)` -> `$...$`).
  final int inlineDelimitersNormalized;

  /// Whether any potential unclosed delimiter or structural truncation was detected.
  final bool hasWarnings;

  /// List of warning messages (e.g., unclosed delimiters, potential truncation).
  final List<String> warnings;

  const NormalizationResult({
    required this.normalizedText,
    required this.originalLength,
    required this.normalizedLength,
    required this.displayDelimitersNormalized,
    required this.inlineDelimitersNormalized,
    required this.hasWarnings,
    required this.warnings,
  });
}

/// Normalizer for LaTeX mathematical delimiters in Markdown documents.
///
/// Follows the behavior established in the GATE DA rendering script
/// and the Tsuzuri reference architecture:
/// 1. Converts `\[...\]` to display math `$$...$$`.
/// 2. Converts `\(...\)` to inline math `$...$`.
/// 3. Strictly preserves fenced code blocks (``` and ~~~).
/// 4. Strictly preserves inline code spans (`...`).
/// 5. Strictly preserves HTML comments (`<!-- ... -->`).
/// 6. Preserves existing valid `$...$` and `$$...$$` equations.
/// 7. Protects escaped delimiters (e.g., `\\\[` or `\\(`).
/// 8. Detects unclosed delimiters and unexpected document truncation.
class MathDelimiterNormalizer {
  // Regex to match inline code spans (`...` or ``...``)
  static final RegExp _inlineCodeRegex = RegExp(
    r'(`+)([\s\S]*?)\1',
  );

  /// Normalizes all math delimiters in the provided [markdown] document.
  static NormalizationResult normalize(String markdown) {
    if (markdown.isEmpty) {
      return const NormalizationResult(
        normalizedText: '',
        originalLength: 0,
        normalizedLength: 0,
        displayDelimitersNormalized: 0,
        inlineDelimitersNormalized: 0,
        hasWarnings: false,
        warnings: [],
      );
    }

    final warnings = <String>[];
    int displayCount = 0;
    int inlineCount = 0;

    // Detect unclosed code fences at document level
    final unclosedFence = _detectUnclosedFences(markdown);
    if (unclosedFence != null) {
      warnings.add('Potential document truncation: unclosed code fence "$unclosedFence" detected.');
    }

    // Step 1: Segment the document into protected and non-protected chunks
    final segments = _segmentMarkdown(markdown);

    // Step 2: Transform math delimiters ONLY within proseText segments
    final buffer = StringBuffer();

    for (final segment in segments) {
      if (segment.type != SegmentType.proseText) {
        // Protected segment: leave completely untouched
        buffer.write(segment.text);
      } else {
        // Prose segment: normalize display \[...\] and inline \(...\)
        final prose = segment.text;

        // Process display math \[...\]
        final displayReplaced = prose.replaceAllMapped(
          RegExp(r'(^|[^\\])\\\[([\s\S]*?)\\\]'),
          (match) {
            displayCount++;
            final prefix = match.group(1) ?? '';
            final tex = match.group(2)!.trim();
            return '$prefix\n\n\$\$\n$tex\n\$\$\n\n';
          },
        );

        // Process inline math \(...\)
        final inlineReplaced = displayReplaced.replaceAllMapped(
          RegExp(r'(^|[^\\])\\\(([\s\S]*?)\\\)'),
          (match) {
            inlineCount++;
            final prefix = match.group(1) ?? '';
            final tex = match.group(2)!.trim();
            return '$prefix\$$tex\$';
          },
        );

        // Process bare chemistry \ce{...} and physical units \pu{...} outside math mode
        final chemistryReplaced = _normalizeChemistry(
          inlineReplaced,
          () => inlineCount++,
        );

        buffer.write(chemistryReplaced);
      }
    }

    final normalized = buffer.toString();

    // Verification check: ensure we didn't accidentally wipe document contents
    if (normalized.isEmpty && markdown.isNotEmpty) {
      warnings.add('Critical: Normalization resulted in an empty document from non-empty input.');
    }

    return NormalizationResult(
      normalizedText: normalized,
      originalLength: markdown.length,
      normalizedLength: normalized.length,
      displayDelimitersNormalized: displayCount,
      inlineDelimitersNormalized: inlineCount,
      hasWarnings: warnings.isNotEmpty,
      warnings: warnings,
    );
  }

  /// Segments markdown by isolating fenced code blocks, inline code, and HTML comments.
  static List<MarkdownSegment> _segmentMarkdown(String markdown) {
    final segments = <MarkdownSegment>[];
    final lines = _splitKeepEnds(markdown);

    final currentLines = <String>[];
    bool inCodeFence = false;
    String fenceChar = '';
    int fenceLength = 0;
    String? fenceInfo;

    bool inHtmlComment = false;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final cleanLine = line.replaceAll(RegExp(r'[\r\n]+$'), '');
      final trimmed = cleanLine.trimLeft();

      if (inCodeFence) {
        currentLines.add(line);
        // Check for closing fence matching same char and >= length
        if (trimmed.startsWith(fenceChar * fenceLength)) {
          final rest = trimmed.substring(fenceLength).trim();
          if (rest.isEmpty || rest.replaceAll(fenceChar, '').isEmpty) {
            // Fence closed
            segments.add(MarkdownSegment(
              type: SegmentType.fencedCode,
              text: currentLines.join(''),
              info: fenceInfo,
            ));
            currentLines.clear();
            inCodeFence = false;
          }
        }
        continue;
      }

      if (inHtmlComment) {
        currentLines.add(line);
        if (cleanLine.contains('-->')) {
          segments.add(MarkdownSegment(
            type: SegmentType.htmlComment,
            text: currentLines.join(''),
          ));
          currentLines.clear();
          inHtmlComment = false;
        }
        continue;
      }

      // Check for opening HTML comment on its own line
      if (trimmed.startsWith('<!--')) {
        if (currentLines.isNotEmpty) {
          _splitProseAndInlineCode(currentLines.join(''), segments);
          currentLines.clear();
        }
        currentLines.add(line);
        if (!cleanLine.contains('-->')) {
          inHtmlComment = true;
        } else {
          segments.add(MarkdownSegment(
            type: SegmentType.htmlComment,
            text: currentLines.join(''),
          ));
          currentLines.clear();
        }
        continue;
      }

      // Check for opening fenced code block (``` or ~~~)
      final fenceMatch = RegExp(r'^[ ]{0,3}(`{3,}|~{3,})[ \t]*(.*)$').firstMatch(cleanLine);
      if (fenceMatch != null) {
        final char = fenceMatch.group(1)![0];
        final len = fenceMatch.group(1)!.length;
        final info = fenceMatch.group(2)?.trim();

        // CommonMark: backtick fence info cannot contain backtick
        if (char == '~' || info == null || !info.contains('`')) {
          if (currentLines.isNotEmpty) {
            _splitProseAndInlineCode(currentLines.join(''), segments);
            currentLines.clear();
          }
          fenceChar = char;
          fenceLength = len;
          fenceInfo = info;
          inCodeFence = true;
          currentLines.add(line);
          continue;
        }
      }

      currentLines.add(line);
    }

    if (currentLines.isNotEmpty) {
      if (inCodeFence) {
        // Unclosed fence: treated as fencedCode to protect source from corruption
        segments.add(MarkdownSegment(
          type: SegmentType.fencedCode,
          text: currentLines.join(''),
          info: fenceInfo,
        ));
      } else if (inHtmlComment) {
        segments.add(MarkdownSegment(
          type: SegmentType.htmlComment,
          text: currentLines.join(''),
        ));
      } else {
        _splitProseAndInlineCode(currentLines.join(''), segments);
      }
    }

    return segments;
  }

  /// Splits text into lines while preserving line endings.
  static List<String> _splitKeepEnds(String s) {
    final lines = <String>[];
    int start = 0;
    while (start < s.length) {
      final next = s.indexOf('\n', start);
      if (next == -1) {
        lines.add(s.substring(start));
        break;
      } else {
        lines.add(s.substring(start, next + 1));
        start = next + 1;
      }
    }
    return lines;
  }

  /// Splits a prose chunk into inline code segments (`...`) and plain prose segments.
  static void _splitProseAndInlineCode(String prose, List<MarkdownSegment> output) {
    if (prose.isEmpty) return;

    final matches = _inlineCodeRegex.allMatches(prose);
    if (matches.isEmpty) {
      output.add(MarkdownSegment(type: SegmentType.proseText, text: prose));
      return;
    }

    int lastIndex = 0;
    for (final match in matches) {
      if (match.start > lastIndex) {
        output.add(MarkdownSegment(
          type: SegmentType.proseText,
          text: prose.substring(lastIndex, match.start),
        ));
      }

      output.add(MarkdownSegment(
        type: SegmentType.inlineCode,
        text: prose.substring(match.start, match.end),
      ));

      lastIndex = match.end;
    }

    if (lastIndex < prose.length) {
      output.add(MarkdownSegment(
        type: SegmentType.proseText,
        text: prose.substring(lastIndex),
      ));
    }
  }

  /// Normalizes bare chemistry \ce{...} and physical units \pu{...} expressions in prose.
  static String _normalizeChemistry(String text, void Function() onIncrement) {
    final buffer = StringBuffer();
    int i = 0;
    while (i < text.length) {
      if ((i == 0 || (text[i - 1] != r'\' && text[i - 1] != r'$' && !RegExp(r'\w').hasMatch(text[i - 1]))) &&
          (text.startsWith(r'\ce{', i) || text.startsWith(r'\pu{', i))) {
        const cmdLen = 4; // length of '\ce{' or '\pu{'
        int braceDepth = 1;
        int j = i + cmdLen;
        while (j < text.length && braceDepth > 0) {
          if (text[j] == '{' && (j == 0 || text[j - 1] != r'\')) {
            braceDepth++;
          } else if (text[j] == '}' && (j == 0 || text[j - 1] != r'\')) {
            braceDepth--;
          }
          j++;
        }
        if (braceDepth == 0) {
          final isPrecededByDollar = i > 0 && text[i - 1] == r'$';
          final isFollowedByDollar = j < text.length && text[j] == r'$';
          if (!isPrecededByDollar && !isFollowedByDollar) {
            final expr = text.substring(i, j);
            buffer.write('\$$expr\$');
            onIncrement();
            i = j;
            continue;
          }
        }
      }
      buffer.write(text[i]);
      i++;
    }
    return buffer.toString();
  }

  /// Detects unclosed code fences at document level.
  static String? _detectUnclosedFences(String markdown) {
    final lines = markdown.split('\n');
    bool inFence = false;
    String fenceChar = '';
    int fenceLen = 0;

    for (final line in lines) {
      final trimmed = line.trimLeft();
      if (!inFence) {
        final match = RegExp(r'^[ ]{0,3}(`{3,}|~{3,})').firstMatch(line);
        if (match != null) {
          inFence = true;
          fenceChar = match.group(1)![0];
          fenceLen = match.group(1)!.length;
        }
      } else {
        if (trimmed.startsWith(fenceChar * fenceLen)) {
          final rest = trimmed.substring(fenceLen).trim();
          if (rest.isEmpty || rest.replaceAll(fenceChar, '').isEmpty) {
            inFence = false;
          }
        }
      }
    }

    return inFence ? '$fenceChar$fenceLen' : null;
  }
}
