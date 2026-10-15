import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsuzuri/src/models/library_entry.dart';
import 'package:tsuzuri/src/services/library_service.dart';
import 'package:tsuzuri/src/services/thumbnail_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ThumbnailService.clearCache();
  });

  group('LibraryService Tests', () {
    test('Extension validation recognizes supported markdown extensions case-insensitively', () {
      expect(LibraryService.isSupportedFile('document.md'), isTrue);
      expect(LibraryService.isSupportedFile('DOCUMENT.MD'), isTrue);
      expect(LibraryService.isSupportedFile('notes.markdown'), isTrue);
      expect(LibraryService.isSupportedFile('notes.MARKDOWN'), isTrue);
      expect(LibraryService.isSupportedFile('readme.mdown'), isTrue);
      expect(LibraryService.isSupportedFile('doc.mkdn'), isTrue);

      // Unsupported extensions
      expect(LibraryService.isSupportedFile('file.txt'), isFalse);
      expect(LibraryService.isSupportedFile('image.png'), isFalse);
      expect(LibraryService.isSupportedFile('data.json'), isFalse);
      expect(LibraryService.isSupportedFile('file.pdf'), isFalse);
    });

    test('addFile adds new entry and deduplicates canonical paths', () async {
      var entries = <LibraryEntry>[];

      // Add file
      entries = await LibraryService.addFile(entries, '/tmp/doc_test_1.md');
      expect(entries.length, 1);
      expect(entries.first.filename, 'doc_test_1.md');

      // Add duplicate with same path
      entries = await LibraryService.addFile(entries, '/tmp/doc_test_1.md');
      expect(entries.length, 1, reason: 'Duplicate path should not create a second entry');

      // Add second unique file
      entries = await LibraryService.addFile(entries, '/tmp/doc_test_2.markdown');
      expect(entries.length, 2);
    });

    test('removeEntry removes entry from library without deleting file', () async {
      // Create temporary physical file to prove it is not deleted
      final tempDir = await Directory.systemTemp.createTemp('tsuzuri_test_');
      final tempFile = File('${tempDir.path}/test_remove.md');
      await tempFile.writeAsString('# Persistent Content\n');

      var entries = <LibraryEntry>[];
      entries = await LibraryService.addFile(entries, tempFile.path);
      expect(entries.length, 1);

      // Remove entry
      entries = await LibraryService.removeEntry(entries, tempFile.path);
      expect(entries.isEmpty, isTrue);

      // Verify physical file still exists on disk!
      expect(await tempFile.exists(), isTrue);

      // Clean up temp dir
      await tempDir.delete(recursive: true);
    });

    test('searchEntries filters by filename and parent directory case-insensitively', () {
      final entries = [
        const LibraryEntry(
          filePath: '/home/user/notes/Flutter_Guide.md',
          filename: 'Flutter_Guide.md',
          parentDir: '/home/user/notes',
          addedAtMs: 1000,
        ),
        const LibraryEntry(
          filePath: '/home/user/work/Dart_Architecture.markdown',
          filename: 'Dart_Architecture.markdown',
          parentDir: '/home/user/work',
          addedAtMs: 2000,
        ),
        const LibraryEntry(
          filePath: '/home/user/notes/Meeting_Notes.md',
          filename: 'Meeting_Notes.md',
          parentDir: '/home/user/notes',
          addedAtMs: 3000,
        ),
      ];

      // Search by filename (case-insensitive)
      final flutterMatches = LibraryService.searchEntries(entries, 'flutter');
      expect(flutterMatches.length, 1);
      expect(flutterMatches.first.filename, 'Flutter_Guide.md');

      // Search by directory path
      final workMatches = LibraryService.searchEntries(entries, 'work');
      expect(workMatches.length, 1);
      expect(workMatches.first.filename, 'Dart_Architecture.markdown');

      // Empty query returns all
      expect(LibraryService.searchEntries(entries, '').length, 3);
      expect(LibraryService.searchEntries(entries, '   ').length, 3);
    });

    test('sortEntries sorts correctly with deterministic tie-breaking', () {
      final entries = [
        const LibraryEntry(
          filePath: '/b/Beta.md',
          filename: 'Beta.md',
          lastModifiedMs: 200,
          lastOpenedMs: 50,
          addedAtMs: 1000,
        ),
        const LibraryEntry(
          filePath: '/a/Alpha.md',
          filename: 'Alpha.md',
          lastModifiedMs: 100,
          lastOpenedMs: 300,
          addedAtMs: 2000,
        ),
        const LibraryEntry(
          filePath: '/c/Gamma.md',
          filename: 'Gamma.md',
          lastModifiedMs: 300,
          lastOpenedMs: 100,
          addedAtMs: 3000,
        ),
      ];

      // Sort by Name Ascending
      final byNameAsc = LibraryService.sortEntries(entries, LibrarySortMode.name, SortDirection.ascending);
      expect(byNameAsc.map((e) => e.filename).toList(), ['Alpha.md', 'Beta.md', 'Gamma.md']);

      // Sort by Name Descending
      final byNameDesc = LibraryService.sortEntries(entries, LibrarySortMode.name, SortDirection.descending);
      expect(byNameDesc.map((e) => e.filename).toList(), ['Gamma.md', 'Beta.md', 'Alpha.md']);

      // Sort by Last Modified Ascending
      final byModAsc = LibraryService.sortEntries(entries, LibrarySortMode.lastModified, SortDirection.ascending);
      expect(byModAsc.map((e) => e.filename).toList(), ['Alpha.md', 'Beta.md', 'Gamma.md']);

      // Sort by Recently Opened Descending
      final byOpenedDesc = LibraryService.sortEntries(entries, LibrarySortMode.recentlyOpened, SortDirection.descending);
      expect(byOpenedDesc.map((e) => e.filename).toList(), ['Alpha.md', 'Gamma.md', 'Beta.md']);
    });

    test('ThumbnailService parses markdown structures and creates safe placeholders', () {
      const markdown = '''
# Main Heading 1
Some introductory paragraph text with **bold** and *italic*.

## Secondary Heading 2
- Bullet item one
- Bullet item two
1. Numbered item A
2. Numbered item B

```mermaid
flowchart LR
  A --> B
```

\$\$
\\int e^x dx = e^x
\$\$

```dart
void main() => print('Hello');
```

> A famous blockquote quote.
---
''';

      final blocks = ThumbnailService.parseSnippet(markdown);
      expect(blocks.isNotEmpty, isTrue);

      final blockTypes = blocks.map((b) => b.type).toList();
      expect(blockTypes, contains(ThumbnailBlockType.heading1));
      expect(blockTypes, contains(ThumbnailBlockType.paragraph));
      expect(blockTypes, contains(ThumbnailBlockType.heading2));
      expect(blockTypes, contains(ThumbnailBlockType.bulletItem));
      expect(blockTypes, contains(ThumbnailBlockType.mermaidBlock));
      expect(blockTypes, contains(ThumbnailBlockType.mathBlock));
      expect(blockTypes, contains(ThumbnailBlockType.codeBlock));
      expect(blockTypes, contains(ThumbnailBlockType.blockquote));
      expect(blockTypes, contains(ThumbnailBlockType.divider));

      // Check stripped markdown formatting
      final h1 = blocks.firstWhere((b) => b.type == ThumbnailBlockType.heading1);
      expect(h1.text, 'Main Heading 1');

      final para = blocks.firstWhere((b) => b.type == ThumbnailBlockType.paragraph);
      expect(para.text, 'Some introductory paragraph text with bold and italic.');
    });

    test('ThumbnailService caches results and invalidates on modification change', () async {
      final tempDir = await Directory.systemTemp.createTemp('tsuzuri_thumb_test_');
      final tempFile = File('${tempDir.path}/thumb.md');
      await tempFile.writeAsString('# Initial Title\nParagraph one.\n');

      final thumb1 = await ThumbnailService.getThumbnail(tempFile.path);
      expect(thumb1.blocks.first.text, 'Initial Title');

      // Verify cached
      final cached = ThumbnailService.getCached(tempFile.path, thumb1.lastModifiedMs);
      expect(cached, isNotNull);
      expect(cached!.blocks.first.text, 'Initial Title');

      // Invalidate
      ThumbnailService.invalidate(tempFile.path);
      expect(ThumbnailService.getCached(tempFile.path, thumb1.lastModifiedMs), isNull);

      await tempDir.delete(recursive: true);
    });
  });
}
