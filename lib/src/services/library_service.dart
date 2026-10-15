import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import '../models/library_entry.dart';
import 'file_service.dart';

/// Result of a library rescan operation across authorized folders and entries.
class LibraryScanResult {
  final int totalEntries;
  final int newlyAdded;
  final int inaccessibleCount;
  final int scannedFolders;

  const LibraryScanResult({
    required this.totalEntries,
    required this.newlyAdded,
    required this.inaccessibleCount,
    required this.scannedFolders,
  });
}

/// Service managing the persistent library of Markdown documents.
///
/// Responsibilities:
/// - Persist library entries across app restarts via SharedPreferences.
/// - Persist user-authorized directory paths and deep-scan for Markdown documents.
/// - Add, remove, and update entries.
/// - Validate file accessibility and refresh metadata.
/// - Search and sort entries.
/// - Support user-authorized folder scanning and synchronization.
class LibraryService {
  static const String _entriesKey = 'tsuzuri_library_entries';
  static const String _sortModeKey = 'tsuzuri_library_sort_mode';
  static const String _sortDirectionKey = 'tsuzuri_library_sort_direction';
  static const String _authorizedDirsKey = 'tsuzuri_authorized_directories';

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

  /// Loads all user-authorized directories from persistent storage.
  static Future<List<String>> loadAuthorizedDirectories() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_authorizedDirsKey) ?? [];
    return list.map(_canonicalizePath).toSet().toList();
  }

  /// Saves user-authorized directories to persistent storage.
  static Future<void> saveAuthorizedDirectories(List<String> dirs) async {
    final prefs = await SharedPreferences.getInstance();
    final canonical = dirs.map(_canonicalizePath).toSet().toList();
    await prefs.setStringList(_authorizedDirsKey, canonical);
  }

  /// Adds a directory to authorized directories. Returns the updated list.
  static Future<List<String>> addAuthorizedDirectory(String directoryPath) async {
    final dirs = await loadAuthorizedDirectories();
    final canonical = _canonicalizePath(directoryPath);
    if (!dirs.contains(canonical)) {
      dirs.add(canonical);
      await saveAuthorizedDirectories(dirs);
    }
    return dirs;
  }

  /// Removes a directory from authorized directories. Returns the updated list.
  static Future<List<String>> removeAuthorizedDirectory(String directoryPath) async {
    final dirs = await loadAuthorizedDirectories();
    final canonical = _canonicalizePath(directoryPath);
    dirs.remove(canonical);
    await saveAuthorizedDirectories(dirs);
    return dirs;
  }

  /// Opens a native folder picker to select a directory, registers it as an
  /// authorized directory in the library index, and discovers Markdown files within it.
  ///
  /// Returns discovered file paths.
  static Future<List<String>> pickFolderAndDiscover() async {
    try {
      final directoryPath = await FilePicker.getDirectoryPath(
        dialogTitle: 'Select folder to index in Tsuzuri Library',
      );
      if (directoryPath == null) return [];

      await addAuthorizedDirectory(directoryPath);
      return await discoverInDirectory(directoryPath);
    } catch (e) {
      debugPrint('Error picking folder: $e');
      return [];
    }
  }

  /// Discovers Markdown files within a directory up to [maxDepth] levels (default 4).
  ///
  /// Safely handles symlinks, ignores hidden files/directories (e.g. .git, .cache),
  /// skips common build caches, and handles permission errors gracefully.
  static Future<List<String>> discoverInDirectory(String directoryPath, {int maxDepth = 4}) async {
    if (kIsWeb) return [];

    final dir = Directory(directoryPath);
    if (!await dir.exists()) return [];

    final discovered = <String>[];
    await _scanDirRecursive(dir, 0, maxDepth, discovered);
    return discovered;
  }

  static Future<void> _scanDirRecursive(
    Directory dir,
    int currentDepth,
    int maxDepth,
    List<String> discovered,
  ) async {
    if (currentDepth > maxDepth) return;

    try {
      final entities = await dir.list(followLinks: true).toList();
      for (final entity in entities) {
        final name = p.basename(entity.path);
        // Skip hidden files/directories (e.g. .git, .cache, .config)
        if (name.startsWith('.')) continue;

        if (entity is File) {
          if (isSupportedFile(name)) {
            discovered.add(_canonicalizePath(entity.path));
          }
        } else if (entity is Directory) {
          // Skip noisy build/dependency folders
          if (name == 'node_modules' ||
              name == 'build' ||
              name == '.dart_tool' ||
              name == '.gradle' ||
              name == 'target') {
            continue;
          }
          await _scanDirRecursive(entity, currentDepth + 1, maxDepth, discovered);
        }
      }
    } catch (e) {
      debugPrint('Skipping inaccessible directory ${dir.path}: $e');
    }
  }

  /// Rescans all authorized directories and updates accessibility of all existing entries.
  ///
  /// Discovers newly created or modified Markdown files in authorized directories.
  /// Deduplicates entries by canonical path so manually opened documents and
  /// scanned documents merge seamlessly without duplication.
  static Future<LibraryScanResult> rescanAll(List<LibraryEntry> currentEntries) async {
    final authorizedDirs = await loadAuthorizedDirectories();
    final Map<String, LibraryEntry> entriesByPath = {
      for (final e in currentEntries) _canonicalizePath(e.filePath): e,
    };

    int newlyAdded = 0;
    int inaccessibleCount = 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // 1. Scan all authorized directories
    for (final dirPath in authorizedDirs) {
      final discoveredFiles = await discoverInDirectory(dirPath);
      for (final filePath in discoveredFiles) {
        final canonical = _canonicalizePath(filePath);
        if (entriesByPath.containsKey(canonical)) {
          // Existing document: update metadata and accessibility
          try {
            final file = File(canonical);
            if (await file.exists()) {
              final stat = await file.stat();
              entriesByPath[canonical] = entriesByPath[canonical]!.copyWith(
                lastModifiedMs: stat.modified.millisecondsSinceEpoch,
                isAccessible: true,
              );
            }
          } catch (_) {}
        } else {
          // Newly discovered document: create entry
          try {
            final file = File(canonical);
            if (await file.exists()) {
              final stat = await file.stat();
              entriesByPath[canonical] = LibraryEntry(
                filePath: canonical,
                filename: p.basename(canonical),
                parentDir: p.dirname(canonical),
                lastModifiedMs: stat.modified.millisecondsSinceEpoch,
                addedAtMs: now,
                isAccessible: true,
              );
              newlyAdded++;
            }
          } catch (_) {}
        }
      }
    }

    // 2. Validate accessibility of all entries (including manually opened ones)
    for (final path in entriesByPath.keys.toList()) {
      try {
        final file = File(path);
        if (await file.exists()) {
          final stat = await file.stat();
          entriesByPath[path] = entriesByPath[path]!.copyWith(
            lastModifiedMs: stat.modified.millisecondsSinceEpoch,
            isAccessible: true,
          );
        } else {
          entriesByPath[path] = entriesByPath[path]!.copyWith(isAccessible: false);
          inaccessibleCount++;
        }
      } catch (_) {
        entriesByPath[path] = entriesByPath[path]!.copyWith(isAccessible: false);
        inaccessibleCount++;
      }
    }

    final updatedEntries = entriesByPath.values.toList();
    await saveEntries(updatedEntries);

    return LibraryScanResult(
      totalEntries: updatedEntries.length,
      newlyAdded: newlyAdded,
      inaccessibleCount: inaccessibleCount,
      scannedFolders: authorizedDirs.length,
    );
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

