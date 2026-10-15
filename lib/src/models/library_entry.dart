import 'dart:convert';
import 'package:path/path.dart' as p;

/// Represents a document entry in the Tsuzuri Library.
///
/// Each entry tracks:
/// - The file's path (or platform-specific identifier).
/// - Display metadata: filename, parent directory, last modified time.
/// - Library-specific metadata: when the entry was added, last opened time.
/// - Accessibility status: whether the file is currently reachable.
class LibraryEntry {
  /// Canonical file path or platform document identifier.
  final String filePath;

  /// Human-readable filename (e.g., `README.md`).
  final String filename;

  /// Parent directory path for disambiguation.
  final String? parentDir;

  /// Last modified timestamp of the file on disk (epoch milliseconds).
  final int? lastModifiedMs;

  /// When this entry was first added to the library (epoch milliseconds).
  final int addedAtMs;

  /// When this entry was last opened in Tsuzuri (epoch milliseconds).
  final int? lastOpenedMs;

  /// Whether the file was accessible at last check.
  final bool isAccessible;

  const LibraryEntry({
    required this.filePath,
    required this.filename,
    this.parentDir,
    this.lastModifiedMs,
    required this.addedAtMs,
    this.lastOpenedMs,
    this.isAccessible = true,
  });

  /// The file extension (lowercased), e.g., `.md`.
  String get extension => p.extension(filename).toLowerCase();

  /// Display name without extension.
  String get displayName => p.basenameWithoutExtension(filename);

  /// Creates an entry from a file path, populating metadata automatically.
  factory LibraryEntry.fromFilePath(
    String filePath, {
    int? lastModifiedMs,
    int? lastOpenedMs,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return LibraryEntry(
      filePath: filePath,
      filename: p.basename(filePath),
      parentDir: p.dirname(filePath),
      lastModifiedMs: lastModifiedMs,
      addedAtMs: now,
      lastOpenedMs: lastOpenedMs,
      isAccessible: true,
    );
  }

  /// Creates a copy with updated fields.
  LibraryEntry copyWith({
    String? filePath,
    String? filename,
    String? parentDir,
    int? lastModifiedMs,
    int? addedAtMs,
    int? lastOpenedMs,
    bool? isAccessible,
  }) {
    return LibraryEntry(
      filePath: filePath ?? this.filePath,
      filename: filename ?? this.filename,
      parentDir: parentDir ?? this.parentDir,
      lastModifiedMs: lastModifiedMs ?? this.lastModifiedMs,
      addedAtMs: addedAtMs ?? this.addedAtMs,
      lastOpenedMs: lastOpenedMs ?? this.lastOpenedMs,
      isAccessible: isAccessible ?? this.isAccessible,
    );
  }

  /// Serializes this entry to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'filePath': filePath,
      'filename': filename,
      'parentDir': parentDir,
      'lastModifiedMs': lastModifiedMs,
      'addedAtMs': addedAtMs,
      'lastOpenedMs': lastOpenedMs,
      'isAccessible': isAccessible,
    };
  }

  /// Deserializes an entry from a JSON map.
  factory LibraryEntry.fromJson(Map<String, dynamic> json) {
    return LibraryEntry(
      filePath: json['filePath'] as String,
      filename: json['filename'] as String,
      parentDir: json['parentDir'] as String?,
      lastModifiedMs: json['lastModifiedMs'] as int?,
      addedAtMs: json['addedAtMs'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      lastOpenedMs: json['lastOpenedMs'] as int?,
      isAccessible: json['isAccessible'] as bool? ?? true,
    );
  }

  /// Serializes a list of entries to a JSON string.
  static String encodeList(List<LibraryEntry> entries) {
    return jsonEncode(entries.map((e) => e.toJson()).toList());
  }

  /// Deserializes a list of entries from a JSON string.
  static List<LibraryEntry> decodeList(String jsonStr) {
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list
          .map((e) => LibraryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LibraryEntry &&
          runtimeType == other.runtimeType &&
          filePath == other.filePath;

  @override
  int get hashCode => filePath.hashCode;

  @override
  String toString() => 'LibraryEntry($filename, $filePath)';
}

/// Supported sort modes for library documents.
enum LibrarySortMode {
  name,
  lastModified,
  recentlyOpened,
}

/// Sort direction.
enum SortDirection {
  ascending,
  descending,
}

