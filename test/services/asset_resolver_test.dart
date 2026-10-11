import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsuzuri/src/services/asset_resolver.dart';

void main() {
  group('AssetResolver', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('tsuzuri_asset_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('resolves relative image path with ./ correctly', () async {
      final imgFile = File('${tempDir.path}/img.png');
      await imgFile.writeAsString('fake-image-bytes');

      final resolved = AssetResolver.resolvePath(
        baseDir: tempDir.path,
        assetPath: './img.png',
      );

      expect(resolved, imgFile.path);
      expect(AssetResolver.exists(baseDir: tempDir.path, assetPath: './img.png'), true);
    });

    test('returns web URLs untouched', () {
      const url = 'https://example.com/photo.jpg';
      expect(AssetResolver.resolvePath(baseDir: tempDir.path, assetPath: url), url);
      expect(AssetResolver.resolveToFileUri(baseDir: tempDir.path, assetPath: url), url);
    });

    test('returns null when baseDir is null for relative paths', () {
      expect(AssetResolver.resolvePath(baseDir: null, assetPath: './photo.jpg'), isNull);
    });

    test('correctly converts local file path to file:// URI', () async {
      final imgFile = File('${tempDir.path}/photo.png');
      await imgFile.writeAsString('bytes');

      final uri = AssetResolver.resolveToFileUri(
        baseDir: tempDir.path,
        assetPath: 'photo.png',
      );

      expect(uri, startsWith('file://'));
      expect(uri, contains('photo.png'));
    });
  });
}

