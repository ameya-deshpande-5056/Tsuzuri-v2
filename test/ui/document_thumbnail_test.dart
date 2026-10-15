import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tsuzuri/src/services/thumbnail_service.dart';
import 'package:tsuzuri/src/ui/document_thumbnail.dart';

void main() {
  setUp(() {
    ThumbnailService.clearCache();
  });

  group('DocumentThumbnail Responsive & Overflow Prevention Tests', () {
    testWidgets('DocumentThumbnail does not overflow when content exceeds paper height', (tester) async {
      const filePath = '/test/sample.md';
      const sampleBlocks = [
        ThumbnailBlock(type: ThumbnailBlockType.heading1, text: 'Quantum Mechanics and Wave Functions'),
        ThumbnailBlock(type: ThumbnailBlockType.heading2, text: 'The Schrödinger Equation'),
        ThumbnailBlock(
          type: ThumbnailBlockType.paragraph,
          text: 'In quantum mechanics, the Schrödinger equation describes how the quantum state of a physical system changes with time. It is a fundamental equation in quantum physics.',
        ),
        ThumbnailBlock(type: ThumbnailBlockType.mathBlock, text: r'i \hbar \frac{\partial}{\partial t} \Psi = \hat{H} \Psi'),
        ThumbnailBlock(
          type: ThumbnailBlockType.paragraph,
          text: 'The wave function represents the probability amplitude for finding a particle at a given position and time.',
        ),
        ThumbnailBlock(type: ThumbnailBlockType.codeBlock, text: 'def psi(x, t):\n    return A * np.exp(1j * (k * x - w * t))'),
        ThumbnailBlock(type: ThumbnailBlockType.bulletItem, text: 'Conservation of probability density'),
        ThumbnailBlock(type: ThumbnailBlockType.bulletItem, text: 'Superposition principle of states'),
        ThumbnailBlock(type: ThumbnailBlockType.heading3, text: 'Harmonic Oscillator'),
        ThumbnailBlock(
          type: ThumbnailBlockType.paragraph,
          text: 'The quantum harmonic oscillator is an exactly solvable model of paramount importance in field theory.',
        ),
        ThumbnailBlock(type: ThumbnailBlockType.mathBlock, text: r'E_n = \hbar \omega \left( n + \frac{1}{2} \right)'),
        ThumbnailBlock(type: ThumbnailBlockType.divider, text: '---'),
        ThumbnailBlock(type: ThumbnailBlockType.blockquote, text: 'God does not play dice with the universe.'),
      ];

      final data = const ThumbnailData(
        lastModifiedMs: 1000,
        blocks: sampleBlocks,
        isEmpty: false,
        isAccessible: true,
      );
      ThumbnailService.putForTesting(filePath, data);

      // Test across multiple window and tile dimensions (unmaximized, maximized, aspect ratio variations)
      final testSizes = [
        const Size(140, 165),
        const Size(130, 155),
        const Size(120, 145),
        const Size(110, 135),
        const Size(100, 120),
        const Size(80, 100),
        const Size(180, 220),
        const Size(240, 300),
      ];

      for (final size in testSizes) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: const DocumentThumbnail(
                    filePath: filePath,
                    lastModifiedMs: 1000,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Must strictly pass without any RenderFlex overflow exceptions
        final exception = tester.takeException();
        expect(exception, isNull, reason: 'RenderFlex overflow occurred at size $size');

        // Verify the heading block rendered
        expect(find.text('Quantum Mechanics and Wave Functions'), findsOneWidget);
      }
    });

    testWidgets('Empty and inaccessible states render correctly and do not overflow', (tester) async {
      ThumbnailService.putForTesting(
        '/test/empty.md',
        const ThumbnailData(lastModifiedMs: 1000, blocks: [], isEmpty: true, isAccessible: true),
      );
      ThumbnailService.putForTesting(
        '/test/inaccessible.md',
        ThumbnailData.inaccessible,
      );

      // Verify empty state
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 140,
              height: 165,
              child: DocumentThumbnail(
                filePath: '/test/empty.md',
                lastModifiedMs: 1000,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Empty document'), findsOneWidget);

      // Verify inaccessible state
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 140,
              height: 165,
              child: DocumentThumbnail(
                filePath: '/test/inaccessible.md',
                isAccessible: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('File inaccessible'), findsOneWidget);
    });

    testWidgets('Continuous resizing does not trigger RenderFlex overflow during window size transitions',
        (tester) async {
      const filePath = '/test/dense.md';
      final denseBlocks = List.generate(
        15,
        (i) => ThumbnailBlock(
          type: i % 2 == 0 ? ThumbnailBlockType.heading2 : ThumbnailBlockType.paragraph,
          text: 'Section $i: Advanced theoretical analysis and mathematical formulation with multiple clauses.',
        ),
      );

      ThumbnailService.putForTesting(
        filePath,
        ThumbnailData(lastModifiedMs: 2000, blocks: denseBlocks, isEmpty: false, isAccessible: true),
      );

      // Simulate dragging window edge from 1920x1080 down to 400x300 in small increments
      for (double w = 800; w >= 360; w -= 35) {
        final h = (w * 0.75).clamp(300.0, 800.0);
        tester.view.physicalSize = Size(w, h);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: const [
                    Expanded(
                      child: DocumentThumbnail(
                        filePath: filePath,
                        lastModifiedMs: 2000,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(
          tester.takeException(),
          isNull,
          reason: 'Continuous window resize failed with RenderFlex overflow at window size ($w, $h)',
        );
      }

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}

