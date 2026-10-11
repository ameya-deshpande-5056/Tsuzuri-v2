import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsuzuri/src/services/file_service.dart';

void main() {
  group('FileService Atomic Operations', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('tsuzuri_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('saveFileAtomic writes and overwrites cleanly', () async {
      final filePath = '${tempDir.path}/test_doc.md';
      const initialText = '# Hello World\nInitial content.';

      await FileService.saveFileAtomic(filePath, initialText);

      final readInitial = await FileService.readFile(filePath);
      expect(readInitial, initialText);

      // Overwrite atomically
      const updatedText = '# Hello World\nUpdated content with equations: \$x = 1\$.';
      await FileService.saveFileAtomic(filePath, updatedText);

      final readUpdated = await FileService.readFile(filePath);
      expect(readUpdated, updatedText);

      // Ensure no temp files remained in directory
      final files = await tempDir.list().toList();
      expect(files.length, 1);
      expect(files.first.path, filePath);
    });

    test('readFile throws on non-existent file', () async {
      final missingPath = '${tempDir.path}/non_existent.md';
      expect(() => FileService.readFile(missingPath), throwsA(isA<FileSystemException>()));
    });
  });
}

