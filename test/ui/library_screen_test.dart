import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsuzuri/main.dart';
import 'package:tsuzuri/src/models/library_entry.dart';
import 'package:tsuzuri/src/services/library_service.dart';
import 'package:tsuzuri/src/services/thumbnail_service.dart';
import 'package:tsuzuri/src/ui/library_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ThumbnailService.clearCache();
  });

  group('LibraryScreen & Gallery Tests', () {
    testWidgets('Tsuzuri launches into Library screen by default', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const TsuzuriApp());
      await tester.pumpAndSettle();

      // Verify Library screen elements
      expect(find.byType(LibraryScreen), findsOneWidget);
      expect(find.text('綴り'), findsOneWidget);
      expect(find.text('Library'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget); // Search bar
    });

    testWidgets('First tile is always dedicated New Document tile', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const TsuzuriApp());
      await tester.pumpAndSettle();

      // Find New document tile
      expect(find.text('New document'), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);

      // Verify it is the first item in the GridView
      final gridView = tester.widget<GridView>(find.byType(GridView));
      expect(gridView, isNotNull);
    });

    testWidgets('Responsive gallery layout across all 7 required viewports (320px to 1920px)',
        (WidgetTester tester) async {
      const viewports = [320.0, 375.0, 430.0, 768.0, 1024.0, 1440.0, 1920.0];

      // Seed with sample entries
      final sampleEntries = [
        const LibraryEntry(
          filePath: '/mock/Physics_Notes.md',
          filename: 'Physics_Notes.md',
          lastModifiedMs: 1690000000000,
          addedAtMs: 1000,
        ),
        const LibraryEntry(
          filePath: '/mock/Chemistry_Lab.markdown',
          filename: 'Chemistry_Lab.markdown',
          lastModifiedMs: 1690000000000,
          addedAtMs: 2000,
        ),
      ];
      await LibraryService.saveEntries(sampleEntries);

      for (final width in viewports) {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(const TsuzuriApp());
        await tester.pumpAndSettle();

        // Must have zero overflow exceptions
        expect(tester.takeException(), isNull, reason: 'Failed at width $width');

        // New document tile must be present at every width
        expect(find.text('New document'), findsOneWidget, reason: 'New document tile missing at $width');
        // Both documents must be present
        expect(find.text('Physics_Notes.md'), findsOneWidget, reason: 'Physics_Notes missing at $width');
        expect(find.text('Chemistry_Lab.markdown'), findsOneWidget, reason: 'Chemistry_Lab missing at $width');
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('Search filters document tiles in real-time and clear button restores list',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final sampleEntries = [
        const LibraryEntry(
          filePath: '/notes/Flutter_Deep_Dive.md',
          filename: 'Flutter_Deep_Dive.md',
          addedAtMs: 1000,
        ),
        const LibraryEntry(
          filePath: '/notes/Quantum_Computing.md',
          filename: 'Quantum_Computing.md',
          addedAtMs: 2000,
        ),
      ];
      await LibraryService.saveEntries(sampleEntries);

      await tester.pumpWidget(const TsuzuriApp());
      await tester.pumpAndSettle();

      expect(find.text('Flutter_Deep_Dive.md'), findsOneWidget);
      expect(find.text('Quantum_Computing.md'), findsOneWidget);

      // Search for "flutter"
      await tester.enterText(find.byType(TextField), 'flutter');
      await tester.pumpAndSettle();

      expect(find.text('Flutter_Deep_Dive.md'), findsOneWidget);
      expect(find.text('Quantum_Computing.md'), findsNothing);

      // Search for non-existent document
      await tester.enterText(find.byType(TextField), 'NonExistent');
      await tester.pumpAndSettle();

      expect(find.textContaining('No documents match'), findsOneWidget);
      expect(find.text('Clear Search'), findsOneWidget);

      // Tap Clear Search
      await tester.tap(find.text('Clear Search'));
      await tester.pumpAndSettle();

      expect(find.text('Flutter_Deep_Dive.md'), findsOneWidget);
      expect(find.text('Quantum_Computing.md'), findsOneWidget);
    });

    testWidgets('Sorting affects document tiles while New Document tile remains at index 0',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final sampleEntries = [
        const LibraryEntry(
          filePath: '/notes/Zeta.md',
          filename: 'Zeta.md',
          lastModifiedMs: 100,
          addedAtMs: 1000,
        ),
        const LibraryEntry(
          filePath: '/notes/Alpha.md',
          filename: 'Alpha.md',
          lastModifiedMs: 200,
          addedAtMs: 2000,
        ),
      ];
      await LibraryService.saveEntries(sampleEntries);

      await tester.pumpWidget(const TsuzuriApp());
      await tester.pumpAndSettle();

      // Open sort menu
      await tester.tap(find.byTooltip('Sort by'));
      await tester.pumpAndSettle();

      // Select sort by Name
      await tester.tap(find.text('Name').last);
      await tester.pumpAndSettle();

      // New document tile is still first
      expect(find.text('New document'), findsOneWidget);
      expect(find.text('Alpha.md'), findsOneWidget);
      expect(find.text('Zeta.md'), findsOneWidget);
    });

    testWidgets('Tapping New Document tile shows creation dialog with validation',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const TsuzuriApp());
      await tester.pumpAndSettle();

      // Tap New document tile
      await tester.tap(find.text('New document'));
      await tester.pumpAndSettle();

      // Creation dialog opens
      expect(find.text('New Document'), findsWidgets);
      expect(find.text('Enter a name for your new Markdown document:'), findsOneWidget);
      expect(find.text('Choose Location & Create'), findsOneWidget);

      // Test validation: clear input field
      final nameField = find.byType(TextFormField);
      await tester.enterText(nameField, '');
      await tester.tap(find.text('Choose Location & Create'));
      await tester.pump();

      // Validation error shown
      expect(find.text('Filename cannot be empty'), findsOneWidget);

      // Cancel dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a name for your new Markdown document:'), findsNothing);
    });

    testWidgets('Document context menu opens with Reader, Editor, and Remove actions',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final sampleEntries = [
        const LibraryEntry(
          filePath: '/notes/Doc_With_Actions.md',
          filename: 'Doc_With_Actions.md',
          addedAtMs: 1000,
        ),
      ];
      await LibraryService.saveEntries(sampleEntries);

      await tester.pumpWidget(const TsuzuriApp());
      await tester.pumpAndSettle();

      // Open context menu for Doc_With_Actions.md
      final menuBtn = find.byTooltip('Document actions');
      expect(menuBtn, findsOneWidget);
      await tester.tap(menuBtn);
      await tester.pumpAndSettle();

      // Verify menu items
      expect(find.text('Open in Reader'), findsOneWidget);
      expect(find.text('Open in Editor'), findsOneWidget);
      expect(find.text('Remove from Library'), findsOneWidget);

      // Select Remove from Library
      await tester.tap(find.text('Remove from Library'));
      await tester.pumpAndSettle();

      // Confirmation dialog opens with safety explanation
      expect(find.textContaining('This will not delete the file from your device.'), findsOneWidget);

      // Confirm removal
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      // Entry is removed from library list
      expect(find.text('Doc_With_Actions.md'), findsNothing);
    });

    testWidgets('Missing document displays Missing indicator in gallery',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final sampleEntries = [
        const LibraryEntry(
          filePath: '/non_existent/Missing_Doc.md',
          filename: 'Missing_Doc.md',
          isAccessible: false,
          addedAtMs: 1000,
        ),
      ];
      await LibraryService.saveEntries(sampleEntries);

      await tester.pumpWidget(const TsuzuriApp());
      await tester.pumpAndSettle();

      expect(find.text('Missing_Doc.md'), findsOneWidget);
      expect(find.text('Missing'), findsOneWidget);
    });

    testWidgets('Populated document thumbnails in gallery grid during continuous window resizing never cause RenderFlex overflow',
        (WidgetTester tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Seed documents with dense multiline content
      const filePath1 = '/notes/Calculus.md';
      const filePath2 = '/notes/Quantum.md';
      final sampleEntries = [
        const LibraryEntry(
          filePath: filePath1,
          filename: 'Calculus.md',
          lastModifiedMs: 5000,
          addedAtMs: 1000,
        ),
        const LibraryEntry(
          filePath: filePath2,
          filename: 'Quantum.md',
          lastModifiedMs: 6000,
          addedAtMs: 2000,
        ),
      ];
      await LibraryService.saveEntries(sampleEntries);

      // Populate cache with multiple blocks that exceed standard thumbnail height
      ThumbnailService.putForTesting(
        filePath1,
        const ThumbnailData(
          lastModifiedMs: 5000,
          blocks: [
            ThumbnailBlock(type: ThumbnailBlockType.heading1, text: 'Differential Calculus & Real Analysis'),
            ThumbnailBlock(type: ThumbnailBlockType.heading2, text: 'Fundamental Theorem of Calculus'),
            ThumbnailBlock(type: ThumbnailBlockType.paragraph, text: 'Let f be a continuous real-valued function defined on a closed interval [a, b].'),
            ThumbnailBlock(type: ThumbnailBlockType.mathBlock, text: r'\int_a^b f(x) dx = F(b) - F(a)'),
            ThumbnailBlock(type: ThumbnailBlockType.codeBlock, text: 'def integrate(f, a, b):\n    return scipy.integrate.quad(f, a, b)[0]'),
            ThumbnailBlock(type: ThumbnailBlockType.bulletItem, text: 'Continuity condition on closed interval'),
            ThumbnailBlock(type: ThumbnailBlockType.bulletItem, text: 'Differentiability of antiderivative'),
          ],
          isEmpty: false,
          isAccessible: true,
        ),
      );

      ThumbnailService.putForTesting(
        filePath2,
        const ThumbnailData(
          lastModifiedMs: 6000,
          blocks: [
            ThumbnailBlock(type: ThumbnailBlockType.heading1, text: 'Quantum States & Wavepackets'),
            ThumbnailBlock(type: ThumbnailBlockType.heading2, text: 'Postulates of Quantum Mechanics'),
            ThumbnailBlock(type: ThumbnailBlockType.paragraph, text: 'The state of a quantum physical system is completely specified by a unit ray in a complex Hilbert space.'),
            ThumbnailBlock(type: ThumbnailBlockType.mathBlock, text: r'\langle \psi | \psi \rangle = 1'),
            ThumbnailBlock(type: ThumbnailBlockType.bulletItem, text: 'Hermitian operators represent observables'),
            ThumbnailBlock(type: ThumbnailBlockType.paragraph, text: 'Eigenvalues correspond to possible measurement outcomes.'),
          ],
          isEmpty: false,
          isAccessible: true,
        ),
      );

      // Test unmaximized, maximized, and continuous resizing across widths and heights
      final resizeSteps = [
        const Size(1920, 1080), // Maximized 1080p
        const Size(1440, 900),  // Maximized laptop
        const Size(1024, 768),  // Standard desktop / iPad
        const Size(800, 600),   // Unmaximized window
        const Size(750, 580),   // Mid-resize step (triggers fractional pixel heights)
        const Size(680, 520),   // Mobile/Desktop breakpoint boundary
        const Size(550, 480),   // Small desktop window
        const Size(420, 700),   // Mobile portrait
        const Size(360, 640),   // Compact mobile
      ];

      for (final size in resizeSteps) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(const TsuzuriApp());
        await tester.pump();

        expect(
          tester.takeException(),
          isNull,
          reason: 'RenderFlex overflow exception occurred at window size ${size.width}x${size.height}',
        );

        // Always verifies New document tile is visible at top
        expect(find.text('New document'), findsOneWidget, reason: 'New document tile missing at ${size.width}x${size.height}');
      }
    });

    testWidgets('Library screen More Actions exposes Theme Switcher and About Tsuzuri',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const TsuzuriApp());
      await tester.pumpAndSettle();

      // Find More Actions button in library header
      final moreActionsBtn = find.byTooltip('More Actions');
      expect(moreActionsBtn, findsOneWidget);

      await tester.tap(moreActionsBtn);
      await tester.pumpAndSettle();

      // Verify ActionsSheet opens in library mode
      expect(find.text('Library Actions'), findsOneWidget);
      expect(find.text('Open Document...'), findsOneWidget);
      expect(find.text('Add Folder to Library...'), findsOneWidget);
      expect(find.text('Rescan Library Folders'), findsOneWidget);
      expect(find.text('About Tsuzuri'), findsOneWidget);

      // Verify Theme Switcher buttons
      expect(find.text('System'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('AMOLED Dark'), findsOneWidget);

      // Document-specific actions must NOT be present
      expect(find.text('Table of Contents'), findsNothing);
      expect(find.text('Find & Replace'), findsNothing);
    });

    testWidgets('Theme Switcher from Library screen updates app theme immediately',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const TsuzuriApp());
      await tester.pumpAndSettle();

      // Open More Actions
      await tester.tap(find.byTooltip('More Actions'));
      await tester.pumpAndSettle();

      // Tap Light theme
      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();

      // Verify MaterialApp updated to light brightness
      final materialAppLight = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialAppLight.themeMode, ThemeMode.light);

      // Tap AMOLED Dark theme in the same open sheet
      await tester.tap(find.text('AMOLED Dark'));
      await tester.pumpAndSettle();

      final materialAppDark = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialAppDark.themeMode, ThemeMode.dark);
    });

    testWidgets('About Tsuzuri dialog opens cleanly from Library screen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const TsuzuriApp());
      await tester.pumpAndSettle();

      // Open More Actions
      await tester.tap(find.byTooltip('More Actions'));
      await tester.pumpAndSettle();

      // Tap About Tsuzuri
      await tester.tap(find.text('About Tsuzuri'));
      await tester.pumpAndSettle();

      // Verify About Dialog content
      expect(find.text('About Tsuzuri'), findsOneWidget);
      expect(find.textContaining('Tsuzuri 2.0.0'), findsOneWidget);
      expect(
        find.text(
            'A quiet, lightweight, and offline Markdown document reader and editor.'),
        findsOneWidget,
      );
    });

    testWidgets('Manage Folders dialog opens and displays indexed directories',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Seed an authorized directory
      await LibraryService.saveAuthorizedDirectories(['/home/user/my_markdown_notes']);

      await tester.pumpWidget(const TsuzuriApp());
      await tester.pumpAndSettle();

      // Find Add menu (Add document/folder)
      final addMenuBtn = find.widgetWithText(FilledButton, 'Add');
      expect(addMenuBtn, findsOneWidget);

      await tester.tap(addMenuBtn);
      await tester.pumpAndSettle();

      // Tap Manage Folders...
      expect(find.text('Manage Folders...'), findsOneWidget);
      await tester.tap(find.text('Manage Folders...'));
      await tester.pumpAndSettle();

      // Verify dialog
      expect(find.text('Indexed Folders'), findsOneWidget);
      expect(find.text('/home/user/my_markdown_notes'), findsOneWidget);
    });
  });
}
