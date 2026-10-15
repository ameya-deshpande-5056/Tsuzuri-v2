import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsuzuri/main.dart';
import 'package:tsuzuri/src/parser/toc_parser.dart';
import 'package:tsuzuri/src/renderer/reader_view.dart';
import 'package:tsuzuri/src/ui/actions_sheet.dart';

void main() {
  group('Adaptive Actions Menu & Editor Gutter Tests', () {
    testWidgets('Desktop/Tablet viewport (>= 681px) renders top-right anchored dropdown popup',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const TsuzuriApp(initialRoute: '/document'));
      await tester.pump(const Duration(milliseconds: 150));

      final moreBtn = find.byTooltip('More Actions');
      expect(moreBtn, findsOneWidget);
      await tester.tap(moreBtn);
      await tester.pumpAndSettle();

      // ActionsSheet is visible
      expect(find.byType(ActionsSheet), findsOneWidget);
      expect(find.text('Document Actions'), findsOneWidget);
      expect(find.text('Open Document...'), findsOneWidget);

      // Verify desktop dropdown container has 290px width and top-right positioning
      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(ActionsSheet),
          matching: find.byType(SizedBox),
        ).first,
      );
      expect(sizedBox.width, 290.0);
    });

    testWidgets('Mobile viewport (< 681px) renders bottom sheet modal with handle bar',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const TsuzuriApp(initialRoute: '/document'));
      await tester.pump(const Duration(milliseconds: 150));

      final moreBtn = find.byTooltip('More Actions');
      expect(moreBtn, findsOneWidget);
      await tester.tap(moreBtn);
      await tester.pumpAndSettle();

      // ActionsSheet is visible
      expect(find.byType(ActionsSheet), findsOneWidget);
      expect(find.text('Document Actions'), findsOneWidget);
      expect(find.text('Open Document...'), findsOneWidget);

      // Under modal bottom sheet, it does not have the 290px fixed desktop SizedBox ancestor
      final sizedBoxFinder = find.ancestor(
        of: find.byType(ActionsSheet),
        matching: find.byWidgetPredicate((w) => w is SizedBox && w.width == 290.0),
      );
      expect(sizedBoxFinder, findsNothing);
    });

    testWidgets('Editor gutter ScrollConfiguration disables visible scrollbars',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const TsuzuriApp(initialRoute: '/document'));
      await tester.pump(const Duration(milliseconds: 150));

      // Switch to editor mode
      final switchBtn = find.byTooltip('Switch to Editor (Ctrl+E)');
      await tester.tap(switchBtn);
      await tester.pumpAndSettle();

      // Find the ScrollConfiguration wrapping the gutter ListView
      final scrollConfigs = tester.widgetList<ScrollConfiguration>(find.byType(ScrollConfiguration));
      expect(scrollConfigs.isNotEmpty, isTrue);

      final dummyContext = tester.element(find.byType(TextField));
      final hasGutterNoScrollbar = scrollConfigs.any((config) {
        final built = config.behavior.buildScrollbar(
          dummyContext,
          const SizedBox(),
          ScrollableDetails.vertical(),
        );
        // When scrollbars is false, buildScrollbar returns the child without wrapping in a Scrollbar
        return built is SizedBox;
      });
      expect(hasGutterNoScrollbar, isTrue);
    });

    testWidgets('ReaderView rightInset tracks More Actions popover lifecycle without hiding reader',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const TsuzuriApp(initialRoute: '/document'));
      await tester.pump(const Duration(milliseconds: 150));

      // Initially in Reader view, rightInset is 0 and isDialogActive is false
      expect(find.byType(ReaderView), findsOneWidget);
      var readerWidget = tester.widget<ReaderView>(find.byType(ReaderView));
      expect(readerWidget.rightInset, 0.0);
      expect(readerWidget.isDialogActive, isFalse);

      // Tap More Actions button
      final moreBtn = find.byTooltip('More Actions');
      await tester.tap(moreBtn);
      await tester.pumpAndSettle();

      // Actions popover is open -> rightInset must be 304, reader view NOT hidden
      readerWidget = tester.widget<ReaderView>(find.byType(ReaderView));
      expect(readerWidget.rightInset, 304.0);
      expect(readerWidget.isDialogActive, isFalse);

      // Dismiss the popover by tapping outside (barrier)
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Actions popover is closed -> rightInset must return to 0.0
      readerWidget = tester.widget<ReaderView>(find.byType(ReaderView));
      expect(readerWidget.rightInset, 0.0);
      expect(readerWidget.isDialogActive, isFalse);
    });

    testWidgets('Theme switcher buttons update selection state immediately on tap',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const TsuzuriApp(initialRoute: '/document'));
      await tester.pump(const Duration(milliseconds: 150));

      // Open More Actions
      final moreBtn = find.byTooltip('More Actions');
      await tester.tap(moreBtn);
      await tester.pumpAndSettle();

      // Verify ActionsSheet is open
      expect(find.byType(ActionsSheet), findsOneWidget);

      // Tap "Light" button
      final lightBtn = find.text('Light');
      expect(lightBtn, findsOneWidget);
      await tester.tap(lightBtn);
      await tester.pump(const Duration(milliseconds: 50));

      // Verify Light button is immediately selected via OutlinedButton style
      final lightOutlined = tester.widget<OutlinedButton>(
        find.ancestor(of: find.text('Light'), matching: find.byType(OutlinedButton)),
      );
      expect(lightOutlined.style?.side?.resolve({})?.width, 1.4);

      // Tap "AMOLED Dark" button
      final darkBtn = find.text('AMOLED Dark');
      expect(darkBtn, findsOneWidget);
      await tester.tap(darkBtn);
      await tester.pump(const Duration(milliseconds: 50));

      // Verify Dark button is now selected
      final darkOutlined = tester.widget<OutlinedButton>(
        find.ancestor(of: find.text('AMOLED Dark'), matching: find.byType(OutlinedButton)),
      );
      expect(darkOutlined.style?.side?.resolve({})?.width, 1.4);

      // Tap "System" button
      final sysBtn = find.text('System');
      expect(sysBtn, findsOneWidget);
      await tester.tap(sysBtn);
      await tester.pump(const Duration(milliseconds: 50));

      // Verify System button is now selected
      final sysOutlined = tester.widget<OutlinedButton>(
        find.ancestor(of: find.text('System'), matching: find.byType(OutlinedButton)),
      );
      expect(sysOutlined.style?.side?.resolve({})?.width, 1.4);
    });

    testWidgets('ReaderView rightInset tracks TOC drawer lifecycle',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const TsuzuriApp(initialRoute: '/document'));
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.byType(ReaderView), findsOneWidget);
      var readerWidget = tester.widget<ReaderView>(find.byType(ReaderView));
      expect(readerWidget.rightInset, 0.0);

      // Tap TOC button
      final tocBtn = find.byTooltip('Table of Contents');
      await tester.tap(tocBtn);
      await tester.pumpAndSettle();

      // TOC drawer is open -> rightInset must be 304
      readerWidget = tester.widget<ReaderView>(find.byType(ReaderView));
      expect(readerWidget.rightInset, 304.0);

      // Close TOC drawer
      final closeBtn = find.byTooltip('Close Contents');
      await tester.tap(closeBtn);
      await tester.pumpAndSettle();

      // TOC drawer is closed -> rightInset must return to 0.0
      readerWidget = tester.widget<ReaderView>(find.byType(ReaderView));
      expect(readerWidget.rightInset, 0.0);
    });

    testWidgets('ReaderView toggleTocPanel and closeTocPanel methods execute without error',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const TsuzuriApp(initialRoute: '/document'));
      await tester.pump(const Duration(milliseconds: 150));

      final readerState = tester.state<ReaderViewState>(find.byType(ReaderView));
      // toggleTocPanel and closeTocPanel execute cleanly
      await readerState.toggleTocPanel([
        const TocItem(level: 1, text: 'Heading 1', slug: 'heading-1', lineNumber: 1),
        const TocItem(level: 2, text: 'Heading 2', slug: 'heading-2', lineNumber: 5),
      ]);
      await readerState.closeTocPanel();
    });
  });
}
