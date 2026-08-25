import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Skeleton's page has no knobs and nothing to press: six sections of
/// stencils that differ in shape, in size, in the tokens they paint and in the
/// loop they run. None of that reaches the widget tree — the whole stencil is
/// one `CustomPaint`, band and all — so [FluentSkeletonPainter]'s own fields
/// are the only honest answer to what is on screen, and the two loops have to
/// be sampled across pumped frames rather than settled for. A skeleton that
/// renders its surface and never moves is exactly the defect a mount-only test
/// waves through.
void main() {
  const String page = 'components-skeleton';

  group('default', () {
    final DocsSection section = sectionOf('components-skeleton--default');

    testWidgets('the bare stencil is 16 high and fills its width', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Rect box = tester.getRect(find.byType(FluentSkeleton));
      expect(box.height, 16, reason: 'the demo pins only the height');
      expect(
        box.width,
        tester.getRect(find.byType(SingleChildScrollView)).width,
        reason:
            'a null axis fills the space available, which is what a '
            'placeholder standing in for a paragraph wants',
      );

      final FluentSkeletonPainter painter = painterAt(tester, 0);
      final FluentColors colors = themeOf(tester).colors;
      expect(painter.backgroundColor, colors.neutralStencil1);
      expect(painter.waveColor, colors.neutralStencil2);
      expect(painter.borderRadius, FluentRadius.allMedium);
    });

    testWidgets('the wave band sweeps across the stencil', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(
        painterAt(tester, 0).bandWidthFactor,
        3,
        reason:
            'the sweeping band is three times the surface wide, so it can '
            'leave the clip entirely at both ends',
      );

      // Four samples inside one 3s loop: the offset runs -3W to +W and never
      // turns back, so a wrap cannot be mistaken for travel.
      final List<double> offsets = <double>[];
      for (int i = 0; i < 4; i++) {
        offsets.add(painterAt(tester, 0).bandOffsetFactor);
        await tester.pump(const Duration(milliseconds: 400));
      }
      for (int i = 1; i < offsets.length; i++) {
        expect(
          offsets[i],
          greaterThan(offsets[i - 1]),
          reason: 'sample $i did not move: the wave is frozen',
        );
      }
      expect(offsets.first, lessThan(0), reason: 'the band starts off-stencil');
    });
  });

  group('appearance', () {
    testWidgets('translucent swaps both stencil tokens for their alphas', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-skeleton--appearance'));

      final FluentColors colors = themeOf(tester).colors;
      final FluentSkeletonPainter opaque = painterAt(tester, 0);
      final FluentSkeletonPainter translucent = painterAt(tester, 1);

      expect(opaque.backgroundColor, colors.neutralStencil1);
      expect(opaque.waveColor, colors.neutralStencil2);
      // Upstream's appearance axis is exactly this pair swap, so a style
      // override that reached only the surface would leave a highlight that
      // cannot be seen through — half a translucent skeleton.
      expect(translucent.backgroundColor, colors.neutralStencil1Alpha);
      expect(translucent.waveColor, colors.neutralStencil2Alpha);
      expect(
        translucent.backgroundColor,
        isNot(opaque.backgroundColor),
        reason: 'two appearances resolving to one colour show nothing',
      );
      expect(find.text('Opaque Appearance'), findsOneWidget);
      expect(find.text('Translucent Appearance'), findsOneWidget);
    });
  });

  group('animation', () {
    final DocsSection section = sectionOf('components-skeleton--animation');

    testWidgets('wave sweeps a band and pulse paints none', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final FluentSkeletonPainter wave = painterAt(tester, 0);
      final FluentSkeletonPainter pulse = painterAt(tester, 1);

      expect(wave.waveColor, isNotNull);
      expect(wave.bandWidthFactor, 3);
      // A pulse fades the whole surface, so it must paint no highlight at all:
      // a pulse that still carried a band would be two animations at once.
      expect(pulse.waveColor, isNull);
      expect(pulse.bandWidthFactor, 1);
      expect(pulse.bandOffsetFactor, 0);

      await tester.pump(const Duration(milliseconds: 400));
      expect(
        painterAt(tester, 0).bandOffsetFactor,
        greaterThan(wave.bandOffsetFactor),
      );
      expect(
        painterAt(tester, 1).bandOffsetFactor,
        0,
        reason: 'the pulse band must stay put; only its opacity moves',
      );
    });

    testWidgets('the pulse fades and comes back while the wave holds still', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // Nine samples across a 1s loop: the opacity is a triangle from 1 down to
      // 0.4 and back, so anything less could land entirely on one flank.
      final List<double> pulse = <double>[];
      final List<double> wave = <double>[];
      for (int i = 0; i < 9; i++) {
        pulse.add(fadeAt(tester, 1));
        wave.add(fadeAt(tester, 0));
        await tester.pump(const Duration(milliseconds: 150));
      }

      expect(
        pulse.reduce((double a, double b) => a < b ? a : b),
        lessThan(0.75),
        reason: 'a pulse that never dims is a static rectangle',
      );
      expect(
        pulse.reduce((double a, double b) => a > b ? a : b),
        greaterThan(0.95),
        reason: 'the loop has to come back to full, not settle half-faded',
      );
      for (final double value in pulse) {
        expect(value, greaterThanOrEqualTo(0.4 - 0.0001));
        expect(value, lessThanOrEqualTo(1));
      }
      // The wave skeleton moves its band, not its opacity: a surface doing both
      // would be twice the motion upstream specifies.
      expect(wave.toSet(), <double>{1});
    });
  });

  group('row', () {
    final DocsSection section = sectionOf('components-skeleton--row');

    testWidgets('the wireframe keeps its percentages of the measured width', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(find.byType(FluentSkeleton), findsNWidgets(12));
      final double width = tester.getRect(find.byType(ColoredBox).first).width;
      // Upstream sizes these as CSS percentages of the row; a Flutter Row
      // flexes only what is left over, so the demo resolves them against the
      // measured width instead — and getting that wrong is a layout that looks
      // plausible and is proportionally wrong.
      expect(tester.getRect(skeletonAt(1)).width, closeTo(width * 0.8, 0.5));
      for (final int index in <int>[3, 4, 8, 9]) {
        expect(
          tester.getRect(skeletonAt(index)).width,
          closeTo(width * 0.2, 0.5),
          reason: 'stencil $index',
        );
      }
      for (final int index in <int>[5, 6, 10, 11]) {
        expect(
          tester.getRect(skeletonAt(index)).width,
          closeTo(width * 0.15, 0.5),
          reason: 'stencil $index',
        );
      }
    });

    testWidgets('the two avatar stencils are round and the third is not', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      for (final int index in <int>[0, 2]) {
        expect(tester.getRect(skeletonAt(index)).size, const Size(24, 24));
        expect(
          painterAt(tester, index).borderRadius,
          FluentRadius.allCircular,
          reason: 'stencil $index stands in for an avatar',
        );
      }
      // The third row opens with upstream's `shape="square"`, which is a
      // rectangle with equal sides — so it keeps the rectangle radius.
      expect(tester.getRect(skeletonAt(7)).size, const Size(24, 24));
      expect(painterAt(tester, 7).borderRadius, FluentRadius.allMedium);
    });
  });

  group('size', () {
    testWidgets('every stencil is as tall as the number printed beside it', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-skeleton--size'));

      final int rows = find.byType(FluentSkeleton).evaluate().length;
      expect(rows, 20);
      for (int i = 0; i < rows; i++) {
        // Read the label off the row rather than from a copy of the page's own
        // list: the section's claim is that the printed number IS the height,
        // so a stencil that ignored its size — or a row labelled out of order —
        // has to fail here.
        final Finder label = find.descendant(
          of: find
              .ancestor(of: skeletonAt(i), matching: find.byType(Row))
              .first,
          matching: find.byType(Text),
        );
        final double printed = double.parse(
          tester.widget<Text>(label.first).data!,
        );
        expect(
          tester.getRect(skeletonAt(i)).height,
          printed,
          reason: 'row $i printed $printed and rendered something else',
        );
      }
    });
  });

  group('shape', () {
    testWidgets('circle, rectangle and square take their own geometry', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-skeleton--shape'));

      expect(tester.getRect(skeletonAt(0)).size, const Size(64, 64));
      expect(painterAt(tester, 0).borderRadius, FluentRadius.allCircular);

      expect(tester.getRect(skeletonAt(1)).size, const Size(150, 64));
      expect(painterAt(tester, 1).borderRadius, FluentRadius.allMedium);

      expect(tester.getRect(skeletonAt(2)).size, const Size(64, 64));
      // Figma binds `Corner radius/Circular` rather than a true circle, so a
      // non-square stencil reads as a stadium — which is why the square and the
      // rectangle must differ in nothing but their width.
      expect(painterAt(tester, 2).borderRadius, FluentRadius.allMedium);
    });
  });

  group('pointer', () {
    testWidgets('a real mouse over a stencil changes nothing but time', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-skeleton--shape'));

      final FluentSkeletonPainter resting = painterAt(tester, 0);
      final Size size = tester.getRect(skeletonAt(0)).size;
      // A skeleton is decorative: it takes no callback and reports no
      // interaction state. `tester.tap` synthesises no hover, so a stencil that
      // repainted under a pointer could only be caught with a real one.
      final FluentSkeletonPainter hovered = await whileHovering(
        tester,
        skeletonAt(0),
        () => painterAt(tester, 0),
      );
      expect(hovered.backgroundColor, resting.backgroundColor);
      expect(hovered.waveColor, resting.waveColor);
      expect(hovered.borderRadius, resting.borderRadius);
      expect(tester.getRect(skeletonAt(0)).size, size);

      // A press is not an interaction either: a stencil takes no callback, so
      // a real click has to leave it exactly as it was.
      await mouseClick(tester, skeletonAt(0));
      expect(painterAt(tester, 0).backgroundColor, resting.backgroundColor);
      expect(painterAt(tester, 0).waveColor, resting.waveColor);
      expect(tester.getRect(skeletonAt(0)).size, size);
    });
  });

  group('lifecycle', () {
    testWidgets('every section unmounts without throwing', (
      WidgetTester tester,
    ) async {
      for (final DocsSection section in sectionsOf(page)) {
        await pumpSection(tester, section);
        // Every stencil owns a repeating AnimationController, so a ticker that
        // outlived its element surfaces here and nowhere else.
        await expectCleanTeardown(tester, section.id);
      }
    });
  });
}

/// The [index]-th stencil on the mounted section, in declaration order.
Finder skeletonAt(int index) => find.byType(FluentSkeleton).at(index);

/// The painter drawing the [index]-th stencil.
///
/// Surface, band and corners are all one `drawRRect` plus one shader, so the
/// painter's fields are the only place the resolved tokens and the band's
/// geometry can be read without diffing pixels.
FluentSkeletonPainter painterAt(WidgetTester tester, int index) =>
    paintersOf<FluentSkeletonPainter>(tester, skeletonAt(index)).single;

/// The opacity the [index]-th stencil is currently rendered at.
double fadeAt(WidgetTester tester, int index) => tester
    .widget<FadeTransition>(
      find
          .descendant(
            of: skeletonAt(index),
            matching: find.byType(FadeTransition),
          )
          .first,
    )
    .opacity
    .value;

/// The theme the mounted section resolved against.
FluentThemeData themeOf(WidgetTester tester) =>
    FluentTheme.of(tester.element(find.byType(FluentSkeleton).first));
