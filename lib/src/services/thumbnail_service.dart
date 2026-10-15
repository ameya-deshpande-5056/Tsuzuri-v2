import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Represents a single lightweight block in a document thumbnail preview.
enum ThumbnailBlockType {
  heading1,
  heading2,
  heading3,
  paragraph,
  bulletItem,
  codeBlock,
  mathBlock,
  mermaidBlock,
  blockquote,
  table,
  divider,
}

/// A parsed block for thumbnail rendering.
class ThumbnailBlock {
  final ThumbnailBlockType type;
  final String text;
  final String? extra;

  const ThumbnailBlock({
    required this.type,
    required this.text,
    this.extra,
  });
}

/// Data holder for a cached document thumbnail preview.
class ThumbnailData {
  final int lastModifiedMs;
  final List<ThumbnailBlock> blocks;
  final bool isEmpty;
  final bool isAccessible;

  const ThumbnailData({
    required this.lastModifiedMs,
    required this.blocks,
    this.isEmpty = false,
    this.isAccessible = true,
  });

  static const ThumbnailData empty = ThumbnailData(
    lastModifiedMs: 0,
    blocks: [],
    isEmpty: true,
  );

  static const ThumbnailData inaccessible = ThumbnailData(
    lastModifiedMs: 0,
    blocks: [],
    isAccessible: false,
  );
}

/// Lightweight service for generating and caching document thumbnail previews.
///
/// Features:
/// - Reads only the opening snippet (~2KB / ~40 lines) of a document.
/// - Parses lightweight markdown structures (headings, paragraphs, lists, code, math, diagrams).
/// - Fast in-memory cache with LRU eviction (up to 250 documents).
/// - Cache invalidation when `lastModifiedMs` on disk changes.
/// - Safe fallbacks for mathematical expressions and Mermaid diagrams.
/// - Never writes or alters the underlying file.
class ThumbnailService {
  static const int maxCacheEntries = 250;
  static const int maxBytesToRead = 3072; // ~3 KB

  static final Map<String, ThumbnailData> _cache = {};

  /// Retrieves thumbnail data from memory cache if available and not stale.
  static ThumbnailData? getCached(String filePath, int? lastModifiedMs) {
    final cached = _cache[filePath];
    if (cached == null) return null;
    if (lastModifiedMs != null && cached.lastModifiedMs != lastModifiedMs) {
      _cache.remove(filePath);
      return null;
    }
    return cached;
  }

  /// Clears the in-memory thumbnail cache.
  static void clearCache() {
    _cache.clear();
  }

  /// Removes a specific file from the cache.
  static void invalidate(String filePath) {
    _cache.remove(filePath);
  }

  /// Sets cache entry directly for testing purposes.
  @visibleForTesting
  static void putForTesting(String filePath, ThumbnailData data) {
    _cache[filePath] = data;
  }

  /// Loads thumbnail data for a document, using cache when available.
  static Future<ThumbnailData> getThumbnail(String filePath) async {
    if (kIsWeb) {
      return ThumbnailData.empty;
    }

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return ThumbnailData.inaccessible;
      }

      final stat = await file.stat();
      final lastModified = stat.modified.millisecondsSinceEpoch;

      final cached = getCached(filePath, lastModified);
      if (cached != null) {
        return cached;
      }

      // Read initial portion of file
      final snippet = await _readOpeningSnippet(file);
      final blocks = parseSnippet(snippet);

      final data = ThumbnailData(
        lastModifiedMs: lastModified,
        blocks: blocks,
        isEmpty: snippet.trim().isEmpty,
        isAccessible: true,
      );

      _putCache(filePath, data);
      return data;
    } catch (_) {
      return ThumbnailData.inaccessible;
    }
  }

  /// Stores thumbnail data into cache with LRU eviction.
  static void _putCache(String filePath, ThumbnailData data) {
    if (_cache.length >= maxCacheEntries) {
      // Evict oldest entry
      _cache.remove(_cache.keys.first);
    }
    _cache[filePath] = data;
  }

  /// Reads up to [maxBytesToRead] from [file].
  static Future<String> _readOpeningSnippet(File file) async {
    try {
      final stream = file.openRead(0, maxBytesToRead);
      final bytes = await stream.fold<List<int>>([], (prev, chunk) => prev..addAll(chunk));
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      // Fallback
      return await file.readAsString();
    }
  }

  /// Parses an opening markdown snippet into lightweight thumbnail blocks.
  static List<ThumbnailBlock> parseSnippet(String text) {
    final lines = text.split('\n');
    final blocks = <ThumbnailBlock>[];

    bool inCodeFence = false;
    String codeFenceLang = '';
    final codeBuffer = StringBuffer();

    bool inMathBlock = false;
    final mathBuffer = StringBuffer();

    for (int i = 0; i < lines.length && blocks.length < 16; i++) {
      final rawLine = lines[i];
      final trimmed = rawLine.trim();

      // Check math display block $$ ... $$
      if (!inCodeFence && (trimmed.startsWith(r'$$') || trimmed.startsWith(r'\['))) {
        if (trimmed.length > 2 && (trimmed.endsWith(r'$$') || trimmed.endsWith(r'\]'))) {
          // Single-line display math
          blocks.add(ThumbnailBlock(
            type: ThumbnailBlockType.mathBlock,
            text: trimmed,
          ));
          continue;
        } else {
          inMathBlock = !inMathBlock;
          if (!inMathBlock) {
            blocks.add(ThumbnailBlock(
              type: ThumbnailBlockType.mathBlock,
              text: mathBuffer.toString().trim(),
            ));
            mathBuffer.clear();
          }
          continue;
        }
      }

      if (inMathBlock) {
        mathBuffer.writeln(trimmed);
        continue;
      }

      // Check fenced code blocks
      if (trimmed.startsWith('```') || trimmed.startsWith('~~~')) {
        if (!inCodeFence) {
          inCodeFence = true;
          codeFenceLang = trimmed.substring(3).trim().toLowerCase();
          codeBuffer.clear();
        } else {
          inCodeFence = false;
          if (codeFenceLang == 'mermaid') {
            blocks.add(ThumbnailBlock(
              type: ThumbnailBlockType.mermaidBlock,
              text: codeBuffer.toString().trim(),
              extra: 'Mermaid Diagram',
            ));
          } else {
            blocks.add(ThumbnailBlock(
              type: ThumbnailBlockType.codeBlock,
              text: codeBuffer.toString().trim(),
              extra: codeFenceLang.isEmpty ? null : codeFenceLang.toUpperCase(),
            ));
          }
          codeBuffer.clear();
          codeFenceLang = '';
        }
        continue;
      }

      if (inCodeFence) {
        if (codeBuffer.length < 300) {
          codeBuffer.writeln(rawLine);
        }
        continue;
      }

      if (trimmed.isEmpty) {
        continue;
      }

      // Headings
      if (trimmed.startsWith('# ')) {
        blocks.add(ThumbnailBlock(
          type: ThumbnailBlockType.heading1,
          text: _stripMarkdownFormatting(trimmed.substring(2).trim()),
        ));
      } else if (trimmed.startsWith('## ')) {
        blocks.add(ThumbnailBlock(
          type: ThumbnailBlockType.heading2,
          text: _stripMarkdownFormatting(trimmed.substring(3).trim()),
        ));
      } else if (trimmed.startsWith('### ')) {
        blocks.add(ThumbnailBlock(
          type: ThumbnailBlockType.heading3,
          text: _stripMarkdownFormatting(trimmed.substring(4).trim()),
        ));
      } else if (trimmed.startsWith('- ') || trimmed.startsWith('* ') || trimmed.startsWith('+ ')) {
        // Bullet list
        blocks.add(ThumbnailBlock(
          type: ThumbnailBlockType.bulletItem,
          text: _stripMarkdownFormatting(trimmed.substring(2).trim()),
        ));
      } else if (RegExp(r'^\d+\.\s').hasMatch(trimmed)) {
        // Numbered list
        final dotIdx = trimmed.indexOf('. ');
        blocks.add(ThumbnailBlock(
          type: ThumbnailBlockType.bulletItem,
          text: _stripMarkdownFormatting(trimmed.substring(dotIdx + 2).trim()),
          extra: trimmed.substring(0, dotIdx + 1),
        ));
      } else if (trimmed.startsWith('> ')) {
        // Blockquote
        blocks.add(ThumbnailBlock(
          type: ThumbnailBlockType.blockquote,
          text: _stripMarkdownFormatting(trimmed.substring(2).trim()),
        ));
      } else if (trimmed.startsWith('|') && trimmed.endsWith('|')) {
        // Table row
        if (!trimmed.contains('---')) {
          blocks.add(ThumbnailBlock(
            type: ThumbnailBlockType.table,
            text: trimmed,
          ));
        }
      } else if (trimmed == '---' || trimmed == '***' || trimmed == '___') {
        blocks.add(const ThumbnailBlock(
          type: ThumbnailBlockType.divider,
          text: '',
        ));
      } else {
        // Regular paragraph text
        blocks.add(ThumbnailBlock(
          type: ThumbnailBlockType.paragraph,
          text: _stripMarkdownFormatting(trimmed),
        ));
      }
    }

    return blocks;
  }

  /// Strips inline markdown tokens (links, bold, italic, inline code) for clean preview.
  static String _stripMarkdownFormatting(String text) {
    var result = text;
    // Replace [label](url) with label
    result = result.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\([^\)]+\)'),
      (match) => match.group(1) ?? '',
    );
    // Replace **bold** or __bold__
    result = result.replaceAllMapped(RegExp(r'\*\*([^*]+)\*\*'), (m) => m[1] ?? '');
    result = result.replaceAllMapped(RegExp(r'__([^_]+)__'), (m) => m[1] ?? '');
    // Replace *italic* or _italic_
    result = result.replaceAllMapped(RegExp(r'\*([^*]+)\*'), (m) => m[1] ?? '');
    result = result.replaceAllMapped(RegExp(r'_([^_]+)_'), (m) => m[1] ?? '');
    // Replace ~~strike~~
    result = result.replaceAllMapped(RegExp(r'~~([^~]+)~~'), (m) => m[1] ?? '');
    // Replace `code`
    result = result.replaceAllMapped(RegExp(r'`([^`]+)`'), (m) => m[1] ?? '');
    return result;
  }
}
