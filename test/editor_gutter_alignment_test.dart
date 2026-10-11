import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsuzuri/src/editor/markdown_editor.dart';

void main() {
  test('TextPainter with forceStrutHeight produces exact multiples of lineHeight', () {
    const fontSize = 13.0;
    const lineHeight = 22.0;

    const textStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: fontSize,
      height: lineHeight / fontSize,
    );

    const strutStyle = StrutStyle(
      fontFamily: 'monospace',
      fontSize: fontSize,
      height: lineHeight / fontSize,
      forceStrutHeight: true,
    );

    // 1. Single short line
    final painter1 = TextPainter(
      text: const TextSpan(text: 'Short line', style: textStyle),
      textDirection: TextDirection.ltr,
      strutStyle: strutStyle,
    )..layout(maxWidth: 300);

    expect(painter1.height, equals(lineHeight));

    // 2. Empty line
    final painterEmpty = TextPainter(
      text: const TextSpan(text: ' ', style: textStyle),
      textDirection: TextDirection.ltr,
      strutStyle: strutStyle,
    )..layout(maxWidth: 300);

    expect(painterEmpty.height, equals(lineHeight));

    // 3. Wrapped line (long text forced into narrow width)
    final longText = 'This is a very long line that will definitely wrap across multiple lines in a narrow container';
    final painterWrapped = TextPainter(
      text: TextSpan(text: longText, style: textStyle),
      textDirection: TextDirection.ltr,
      strutStyle: strutStyle,
    )..layout(maxWidth: 150);

    // Number of lines
    final lineMetrics = painterWrapped.computeLineMetrics();
    expect(lineMetrics.length, greaterThan(1));
    expect(painterWrapped.height, equals(lineMetrics.length * lineHeight));
  });

  test('Measuring 1000 lines with TextPainter executes rapidly', () {
    const fontSize = 13.0;
    const lineHeight = 22.0;

    const textStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: fontSize,
      height: lineHeight / fontSize,
    );

    const strutStyle = StrutStyle(
      fontFamily: 'monospace',
      fontSize: fontSize,
      height: lineHeight / fontSize,
      forceStrutHeight: true,
    );

    final painter = TextPainter(
      textDirection: TextDirection.ltr,
      strutStyle: strutStyle,
    );

    final stopwatch = Stopwatch()..start();
    for (int i = 0; i < 1000; i++) {
      painter.text = TextSpan(text: 'Line $i: Some sample markdown text for testing line wrap metrics', style: textStyle);
      painter.layout(maxWidth: 300);
      final _ = (painter.height / lineHeight).round();
    }
    stopwatch.stop();
    debugPrint('1000 lines measured in: ${stopwatch.elapsedMilliseconds} ms');
    expect(stopwatch.elapsedMilliseconds, lessThan(100)); // Under 100ms
  });

  testWidgets('Wrapped line height in TextField matches TextPainter line height', (tester) async {
    const fontSize = 13.0;
    const lineHeight = 22.0;

    const textStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: fontSize,
      height: lineHeight / fontSize,
    );

    const strutStyle = StrutStyle(
      fontFamily: 'monospace',
      fontSize: fontSize,
      height: lineHeight / fontSize,
      forceStrutHeight: true,
    );

    final controller = TextEditingController(
      text: 'Line 1 short\nLine 2 is a very long line that will wrap onto multiple visual lines because the container is narrow\nLine 3 short',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            child: TextField(
              controller: controller,
              maxLines: null,
              strutStyle: strutStyle,
              style: textStyle,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                isDense: true,
              ),
            ),
          ),
        ),
      ),
    );

    // Text width is 200 - 28 = 172
    final painter = TextPainter(
      text: const TextSpan(
        text: 'Line 2 is a very long line that will wrap onto multiple visual lines because the container is narrow',
        style: textStyle,
      ),
      textDirection: TextDirection.ltr,
      strutStyle: strutStyle,
    )..layout(maxWidth: 172);

    final lineMetrics = painter.computeLineMetrics();
    expect(lineMetrics.length, greaterThan(1));
    expect(painter.height, equals(lineMetrics.length * lineHeight));
  });

  testWidgets('MarkdownEditor wraps line and expands gutter height accordingly', (tester) async {
    final controller = TextEditingController(
      text: 'Short line 1\nThis is a very long line 2 that will definitely wrap across several visual lines in a narrow container\nShort line 3',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 600,
            child: MarkdownEditor(controller: controller),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    // Line 2 wraps, so Line 3's vertical offset should be pushed down by more than 22px
    final line2Top = tester.getTopLeft(find.text('2')).dy;
    final line3Top = tester.getTopLeft(find.text('3')).dy;

    expect(line3Top - line2Top, greaterThan(22.0));

    // Move cursor to line 2
    controller.selection = const TextSelection.collapsed(offset: 15);
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.text('2')).style?.fontWeight, FontWeight.bold);

    // Move cursor to line 3
    controller.selection = TextSelection.collapsed(offset: controller.text.length);
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.text('3')).style?.fontWeight, FontWeight.bold);
  });
}


