import 'package:path/path.dart' as p;

/// Authoritative document model managing file identity, content, and dirty state.
class DocumentState {
  final String? filePath;
  final String content;
  final String savedSnapshot;

  const DocumentState({
    this.filePath,
    required this.content,
    required this.savedSnapshot,
  });

  /// Factory for a new empty document.
  factory DocumentState.untitled([String initialContent = '']) {
    return DocumentState(
      filePath: null,
      content: initialContent,
      savedSnapshot: initialContent,
    );
  }

  /// Whether the document currently has unsaved modifications.
  bool get isDirty => content != savedSnapshot;

  /// Human-readable title of the document.
  String get title {
    if (filePath != null && filePath!.isNotEmpty) {
      return p.basename(filePath!);
    }
    return 'untitled.md';
  }

  /// Base directory for resolving relative assets.
  String? get baseDir {
    if (filePath != null && filePath!.isNotEmpty) {
      return p.dirname(filePath!);
    }
    return null;
  }

  /// Word count of the current content.
  int get wordCount {
    if (content.trim().isEmpty) return 0;
    return content.trim().split(RegExp(r'\s+')).length;
  }

  /// Character count of the current content.
  int get charCount => content.length;

  /// Line count of the current content.
  int get lineCount {
    if (content.isEmpty) return 1;
    return content.split('\n').length;
  }

  /// Creates a copy with updated content.
  DocumentState copyWithContent(String newContent) {
    return DocumentState(
      filePath: filePath,
      content: newContent,
      savedSnapshot: savedSnapshot,
    );
  }

  /// Creates a copy marked as saved at the given [savedPath].
  DocumentState markSaved(String savedPath) {
    return DocumentState(
      filePath: savedPath,
      content: content,
      savedSnapshot: content,
    );
  }
}

