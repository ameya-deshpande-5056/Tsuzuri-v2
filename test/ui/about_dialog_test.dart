import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsuzuri/src/ui/about_dialog.dart';
import 'package:tsuzuri/src/ui/actions_sheet.dart';

void main() {
  testWidgets('TsuzuriAboutDialog displays original app content with pubspec version',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TsuzuriAboutDialog(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Header
    expect(find.text('About Tsuzuri'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);

    // 2. Heading with pubspec version
    expect(find.textContaining('Tsuzuri 2.0.0'), findsOneWidget);

    // 3. Exact original description
    expect(
      find.text(
          'A quiet, lightweight, and offline Markdown document reader and editor.'),
      findsOneWidget,
    );

    // 4. Original metadata fields
    expect(find.text('Version:'), findsOneWidget);
    expect(find.text('Build time:'), findsOneWidget);
    expect(find.text('Project:'), findsOneWidget);
    expect(find.text('https://github.com/ameya-deshpande-5056/Tsuzuri-v2'),
        findsOneWidget);

    // 5. Verify absence of extraneous elements removed from v2
    expect(find.text('Architecture'), findsNothing);
    expect(find.text('Themes'), findsNothing);
    expect(find.text('LaTeX Support'), findsNothing);
    expect(find.text('Mermaid Support'), findsNothing);
    expect(find.text('Network'), findsNothing);
    expect(find.text('Markdown Editor & Reader'), findsNothing);
  });

  test('TsuzuriAboutDialog.getCleanVersion strips build number', () async {
    final version = await TsuzuriAboutDialog.getCleanVersion();
    expect(version, equals('2.0.0'));
    expect(version.contains('+'), isFalse);
  });

  testWidgets('ActionsSheet triggers onOpenAbout callback when About Tsuzuri is tapped',
      (WidgetTester tester) async {
    bool onOpenAboutCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActionsSheet(
            isEditorMode: false,
            wordWrap: true,
            currentThemeMode: ThemeMode.system,
            onToggleMode: () {},
            onOpenFile: () {},
            onSaveFile: () {},
            onSaveAsFile: () {},
            onToggleFindReplace: () {},
            onToggleWordWrap: () {},
            onThemeChanged: (_) {},
            onOpenAbout: () {
              onOpenAboutCalled = true;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final aboutItem = find.text('About Tsuzuri');
    expect(aboutItem, findsOneWidget);

    await tester.tap(aboutItem);
    await tester.pumpAndSettle();

    expect(onOpenAboutCalled, isTrue);
  });
}

