import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsuzuri/main.dart';
import 'package:tsuzuri/src/ui/about_dialog.dart';
import 'package:tsuzuri/src/ui/actions_sheet.dart';

void main() {
  testWidgets('AppShell full interaction smoke test', (WidgetTester tester) async {
    // Set a desktop viewport size
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const TsuzuriApp());
    await tester.pump(const Duration(milliseconds: 200));

    // 1. Verify Header Elements
    expect(find.text('綴り'), findsOneWidget);
    expect(find.text('untitled.md'), findsOneWidget);
    expect(find.text('Reader'), findsOneWidget);

    // 2. Switch to Editor View
    final switchModeBtn = find.byTooltip('Switch to Editor (Ctrl+E)');
    expect(switchModeBtn, findsOneWidget);
    await tester.tap(switchModeBtn);
    await tester.pump(const Duration(milliseconds: 200));

    // Editor mode is active
    expect(find.text('Editor'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.textContaining('words'), findsOneWidget);

    // Switch back to Reader view
    final switchReaderBtn = find.byTooltip('Switch to Reader (Ctrl+E)');
    await tester.tap(switchReaderBtn);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Reader'), findsOneWidget);

    // 3. Open More Actions Bottom Sheet
    final moreBtn = find.byTooltip('More Actions');
    expect(moreBtn, findsOneWidget);
    await tester.tap(moreBtn);
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Actions Sheet opened
    expect(find.byType(ActionsSheet), findsOneWidget);
    expect(find.text('Open Document...'), findsOneWidget);
    expect(find.text('Save Document'), findsOneWidget);
    expect(find.text('AMOLED Dark'), findsOneWidget);

    // 4. Open About Dialog from sheet
    final aboutBtn = find.text('About Tsuzuri');
    await tester.ensureVisible(aboutBtn);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(aboutBtn);
    await tester.pump(const Duration(milliseconds: 300));

    // Verify About Dialog is shown with dynamic version from pubspec
    expect(find.byType(TsuzuriAboutDialog), findsOneWidget);
    expect(find.textContaining('Tsuzuri 2.0.0'), findsOneWidget);

    // Close About Dialog via close icon button
    await tester.tap(find.descendant(
      of: find.byType(TsuzuriAboutDialog),
      matching: find.byIcon(Icons.close),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(TsuzuriAboutDialog), findsNothing);
  });
}
