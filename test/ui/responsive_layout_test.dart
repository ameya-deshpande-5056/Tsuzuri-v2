import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsuzuri/main.dart';

void main() {
  const List<double> testWidths = [
    320.0,
    375.0,
    430.0,
    768.0,
    1024.0,
    1440.0,
    1920.0,
  ];

  for (final width in testWidths) {
    testWidgets('Responsive Layout Test at ${width}px width', (WidgetTester tester) async {
      tester.view.physicalSize = Size(width, 800.0);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // 1. Build TsuzuriApp in Reader view
      await tester.pumpWidget(const TsuzuriApp(initialRoute: '/document'));
      await tester.pump(const Duration(milliseconds: 150));

      // Verify no overflow errors
      expect(tester.takeException(), isNull);
      expect(find.text('綴り'), findsOneWidget);
      if (width >= 360.0) {
        expect(find.text('Reader'), findsOneWidget);
      }

      // Verify Table of Contents button is accessible at all viewports (including 320px)
      expect(find.byTooltip('Table of Contents'), findsOneWidget);

      // 2. Switch to Editor view at this width
      final switchBtn = find.byTooltip('Switch to Editor (Ctrl+E)');
      await tester.tap(switchBtn);
      await tester.pump(const Duration(milliseconds: 150));

      // Verify no overflow errors in Editor view
      expect(tester.takeException(), isNull);
      if (width >= 360.0) {
        expect(find.text('Editor'), findsOneWidget);
      }
      expect(find.byType(TextField), findsOneWidget);

      // Table of Contents remains accessible in editor view
      expect(find.byTooltip('Table of Contents'), findsOneWidget);

      // 3. Switch back to Reader view
      final readerBtn = find.byTooltip('Switch to Reader (Ctrl+E)');
      await tester.tap(readerBtn);
      await tester.pump(const Duration(milliseconds: 150));

      expect(tester.takeException(), isNull);
    });
  }
}
