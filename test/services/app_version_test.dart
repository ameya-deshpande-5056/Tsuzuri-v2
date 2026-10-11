import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('can read version from pubspec.yaml asset', () async {
    final content = await rootBundle.loadString('pubspec.yaml');
    final versionLine = content
        .split('\n')
        .firstWhere((l) => l.trim().startsWith('version:'));
    final version = versionLine.split(':')[1].trim();
    expect(version, isNotEmpty);
    expect(version, startsWith('2.0.0'));
  });
}
