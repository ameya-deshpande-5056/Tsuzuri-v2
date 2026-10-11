import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

/// Service for reliable, safe, and atomic file I/O operations.
class FileService {
  static const List<String> supportedExtensions = [
    'md',
    'markdown',
    'mdown',
    'mkdn',
  ];

  /// Opens a native file picker to select a Markdown document.
  static Future<String?> pickMarkdownFile() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: supportedExtensions,
      );

      if (files.isNotEmpty) {
        return files.first.path;
      }
      return null;
    } catch (e) {
      debugPrint('Error picking file: $e');
      rethrow;
    }
  }

  /// Prompts for a save path and saves [content] to the chosen location.
  static Future<String?> pickSavePathAndSave({
    required String defaultFileName,
    required String content,
  }) async {
    try {
      final bytes = Uint8List.fromList(utf8.encode(content));
      final uri = await FilePicker.saveFile(
        dialogTitle: 'Save Markdown Document',
        fileName: defaultFileName,
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: supportedExtensions,
      );

      if (uri == null) return null;
      return uri.scheme == 'file' ? uri.toFilePath() : uri.path;
    } catch (e) {
      debugPrint('Error picking save path: $e');
      rethrow;
    }
  }

  /// Safely reads the text content from [filePath].
  static Future<String> readFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('File does not exist', filePath);
    }
    return await file.readAsString();
  }

  /// Atomically saves [content] to [filePath] using a temporary file to prevent corruption.
  static Future<void> saveFileAtomic(String filePath, String content) async {
    final targetFile = File(filePath);
    final directory = targetFile.parent;

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    // Create temporary file in the same directory
    final fileName = p.basename(filePath);
    final tempFilePath = p.join(directory.path, '.$fileName.tmp_${DateTime.now().millisecondsSinceEpoch}');
    final tempFile = File(tempFilePath);

    try {
      // 1. Write completely to temporary file
      await tempFile.writeAsString(content, flush: true);

      // 2. Atomically rename/replace target file
      await tempFile.rename(filePath);
    } catch (e) {
      // Cleanup temporary file if it still exists
      if (await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
      rethrow;
    }
  }
}
