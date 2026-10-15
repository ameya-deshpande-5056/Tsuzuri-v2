import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import '../models/library_entry.dart';
import 'file_service.dart';

/// Service managing the persistent library of Markdown documents.
///
/// Responsibilities:
/// - Persist library entries across app restarts via SharedPreferences.
/// - Add, remove, and update entries.
/// - Validate file accessibility.
/// - Search and sort entries.
/// - Support user-authorized folder scanning.
class LibraryService {
  static const String _entriesKey = 'tsuzuri_library_entries';
  static const String _sortModeKey = 'tsuzuri_library_sort_mode';
  static const String _sortDirectionKey = 'tsuzuri_library_sort_direction';

  /// Supported Markdown file extensions (lowercase, without dot).
  static const List<String> supportedExtensions = ['md', 'markdown', 'mdown', 'mkdn'];

  /// Checks if a filename has a supported Markdown extension (case-insensitive).
  static bool isSupportedFile(String filename) {
    final ext = p.extension(filename).toLowerCase().replaceFirst('.', '');
    return supportedExtensions.contains(ext);
  }

  /// Loads all library entries from persistent storage.
  static Future<List<LibraryEntry>> loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_entriesKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    return LibraryEntry.decodeList(jsonStr);
  }

  /// Saves library entries to persistent storage.
  static Future<void> saveEntries(List<LibraryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_entriesKey, LibraryEntry.encodeList(entries));
  }

  /// Loads the persisted sort mode.
  static Future<LibrarySortMode> loadSortMode() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_sortModeKey) ?? 0;
    if (index >= 0 && index < LibrarySortMode.values.length) {
      return LibrarySortMode.values[index];
    }
    return LibrarySortMode.name;
  }

  /// Saves the sort mode to persistent storage.
  static Future<void> saveSortMode(LibrarySortMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sortModeKey, mode.index);
  }

  /// Loads the persisted sort direction.
  static Future<SortDirection> loadSortDirection() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_sortDirectionKey) ?? 0;
    if (index >= 0 && index < SortDirection.values.length) {
      return SortDirection.values[index];
    }
    return SortDirection.ascending;
  }

  /// Saves the sort direction to persistent storage.
  static Future<void> saveSortDirection(SortDirection direction) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sortDirectionKey, direction.index);
  }

  /// Adds a file to the library. Returns the updated entry list.
  ///
  /// If the file already exists (by canonical path), updates its metadata
  /// instead of creating a duplicate.
  static Future<List<LibraryEntry>> addFile(
    List<LibraryEntry> entries,
    String filePath, {
    bool markAsOpened = false,
  }) async {
    final canonicalPath = _canonicalizePath(filePath);
    final now = DateTime.now().millisecondsSinceEpoch;

    // Check file metadata
    int? lastModifiedMs;
    bool isAccessible = true;
    try {
      if (!kIsWeb) {
        final file = File(canonicalPath);
        if (await file.exists()) {
          final stat = await file.stat();
          lastModifiedMs = stat.modified.millisecondsSinceEpoch;
        } else {
          isAccessible = false;
        }
      }
    } catch (_) {
      isAccessible = false;
    }

    final existingIndex = entries.indexWhere((e) => _canonicalizePath(e.filePath) == canonicalPath);

    if (existingIndex >= 0) {
      // Update existing entry
      final existing = entries[existingIndex];
      entries[existingIndex] = existing.copyWith(
        lastModifiedMs: lastModifiedMs ?? existing.lastModifiedMs,
        lastOpenedMs: markAsOpened ? now : existing.lastOpenedMs,
        isAccessible: isAccessible,
      );
    } else {
      // Add new entry
      entries.add(LibraryEntry(
        filePath: canonicalPath,
        filename: p.basename(canonicalPath),
        parentDir: p.dirname(canonicalPath),
        lastModifiedMs: lastModifiedMs,
        addedAtMs: now,
        lastOpenedMs: markAsOpened ? now : null,
        isAccessible: isAccessible,
      ));
    }

    await saveEntries(entries);
    return entries;
  }

  /// Removes an entry from the library by file path. NEVER deletes the
  /// underlying file.
  static Future<List<LibraryEntry>> removeEntry(
    List<LibraryEntry> entries,
    String filePath,
  ) async {
    final canonicalPath = _canonicalizePath(filePath);
    entries.removeWhere((e) => _canonicalizePath(e.filePath) == canonicalPath);
    await saveEntries(entries);
    return entries;
  }

  /// Marks an entry as recently opened.
  static Future<List<LibraryEntry>> markOpened(
    List<LibraryEntry> entries,
    String filePath,
  ) async {
    final canonicalPath = _canonicalizePath(filePath);
    final now = DateTime.now().millisecondsSinceEpoch;
    final idx = entries.indexWhere((e) => _canonicalizePath(e.filePath) == canonicalPath);
    if (idx >= 0) {
      entries[idx] = entries[idx].copyWith(lastOpenedMs: now);
      await saveEntries(entries);
    }
    return entries;
  }

  /// Refreshes accessibility and metadata for all entries.
  static Future<List<LibraryEntry>> refreshEntries(List<LibraryEntry> entries) async {
    if (kIsWeb) return entries;

    final updated = <LibraryEntry>[];
    for (final entry in entries) {
      try {
        final file = File(entry.filePath);
        if (await file.exists()) {
          final stat = await file.stat();
          updated.add(entry.copyWith(
            lastModifiedMs: stat.modified.millisecondsSinceEpoch,
            isAccessible: true,
          ));
        } else {
          updated.add(entry.copyWith(isAccessible: false));
        }
      } catch (_) {
        updated.add(entry.copyWith(isAccessible: false));
      }
    }

    await saveEntries(updated);
    return updated;
  }

  /// Opens a native file picker to select a Markdown document.
  /// Returns the selected file path, or null if cancelled.
  static Future<String?> pickMarkdownFile() async {
    return await FileService.pickMarkdownFile();
  }

  /// Opens a native folder picker to select a directory, then discovers
  /// Markdown files within it (non-recursive by default on mobile,
  /// single-level listing).
  ///
  /// Returns discovered file paths.
  static Future<List<String>> pickFolderAndDiscover() async {
    try {
      final directoryPath = await FilePicker.getDirectoryPath(
        dialogTitle: 'Select folder to scan for Markdown files',
      );
      if (directoryPath == null) return [];

      return await discoverInDirectory(directoryPath);
    } catch (e) {
      debugPrint('Error picking folder: $e');
      return [];
    }
  }

  /// Discovers Markdown files within a directory (non-recursive).
  static Future<List<String>> discoverInDirectory(String directoryPath) async {
    if (kIsWeb) return [];

    final dir = Directory(directoryPath);
    if (!await dir.exists()) return [];

    final discovered = <String>[];
    try {
      await for (final entity in dir.list(recursive: false, followLinks: true)) {
        if (entity is File) {
          final name = p.basename(entity.path);
          if (isSupportedFile(name)) {
            discovered.add(entity.path);
          }
        }
      }
    } catch (e) {
      debugPrint('Error scanning directory $directoryPath: $e');
    }

    return discovered;
  }

  /// Sorts entries according to the given mode and direction.
  static List<LibraryEntry> sortEntries(
    List<LibraryEntry> entries,
    LibrarySortMode mode,
    SortDirection direction,
  ) {
    final sorted = List<LibraryEntry>.from(entries);

    sorted.sort((a, b) {
      int result;
      switch (mode) {
        case LibrarySortMode.name:
          result = a.filename.toLowerCase().compareTo(b.filename.toLowerCase());
          if (result == 0) {
            // Deterministic tie-breaking by path
            result = a.filePath.compareTo(b.filePath);
          }
          break;
        case LibrarySortMode.lastModified:
          final aMs = a.lastModifiedMs ?? 0;
          final bMs = b.lastModifiedMs ?? 0;
          result = aMs.compareTo(bMs);
          if (result == 0) {
            result = a.filename.toLowerCase().compareTo(b.filename.toLowerCase());
          }
          break;
        case LibrarySortMode.recentlyOpened:
          final aMs = a.lastOpenedMs ?? 0;
          final bMs = b.lastOpenedMs ?? 0;
          result = aMs.compareTo(bMs);
          if (result == 0) {
            result = a.filename.toLowerCase().compareTo(b.filename.toLowerCase());
          }
          break;
      }

      return direction == SortDirection.descending ? -result : result;
    });

    return sorted;
  }

  /// Filters entries matching a search query (case-insensitive, matches
  /// filename and parent directory path).
  static List<LibraryEntry> searchEntries(
    List<LibraryEntry> entries,
    String query,
  ) {
    if (query.trim().isEmpty) return entries;

    final lowerQuery = query.toLowerCase();
    return entries.where((entry) {
      final nameMatch = entry.filename.toLowerCase().contains(lowerQuery);
      final pathMatch = entry.parentDir?.toLowerCase().contains(lowerQuery) ?? false;
      return nameMatch || pathMatch;
    }).toList();
  }

  /// Canonicalizes a file path for deduplication purposes.
  static String _canonicalizePath(String filePath) {
    try {
      if (!kIsWeb) {
        // Resolve symlinks and normalize
        return p.normalize(p.absolute(filePath));
      }
    } catch (_) {}
    return filePath;
  }
}

