import 'dart:io';
import 'package:path/path.dart' as p;

/// Resolves relative asset and image links against the active document's directory.
class AssetResolver {
  /// Resolves [assetPath] relative to [baseDir].
  ///
  /// Returns a valid absolute file path or `file://` URI if the asset exists,
  /// or `null` if the asset cannot be resolved.
  static String? resolvePath({
    required String? baseDir,
    required String assetPath,
  }) {
    if (assetPath.isEmpty) return null;

    final trimmed = assetPath.trim();

    // Already an absolute URI or web link
    if (trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.startsWith('data:') ||
        trimmed.startsWith('file://')) {
      return trimmed;
    }

    if (baseDir == null || baseDir.isEmpty) {
      return null;
    }

    // Clean relative path indicators
    String cleanRel = trimmed;
    if (cleanRel.startsWith('./')) {
      cleanRel = cleanRel.substring(2);
    }

    final resolved = p.normalize(p.join(baseDir, cleanRel));
    return resolved;
  }

  /// Converts a resolved file path to a `file://` URI.
  static String? resolveToFileUri({
    required String? baseDir,
    required String assetPath,
  }) {
    final path = resolvePath(baseDir: baseDir, assetPath: assetPath);
    if (path == null) return null;

    if (path.startsWith('file://') || path.startsWith('data:') || path.startsWith('http')) {
      return path;
    }

    return Uri.file(path).toString();
  }

  /// Checks whether a local asset exists on disk.
  static bool exists({
    required String? baseDir,
    required String assetPath,
  }) {
    final path = resolvePath(baseDir: baseDir, assetPath: assetPath);
    if (path == null) return false;

    if (path.startsWith('file://')) {
      return File(Uri.parse(path).toFilePath()).existsSync();
    }
    return File(path).existsSync();
  }
}

