import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// ProgressBar's page has no knobs: seven sections, four of them static
/// variants and three of them clocks — the indeterminate sweep, the custom
/// alternating motion, and the counter that drives Max. The static sections are
/// asserted as geometry and tokens; the moving ones are asserted by sampling
/// the indicator across pumped frames, because "it animates" is the only claim
/// they make and a frozen bar renders identically to a working one on frame
/// zero.
///
/// Nothing here may call `pumpAndSettle`: every clock on this page repeats
/// forever, so settling is a hang rather than a wait.
void main() {
  const String page = 'components-progressbar';

  group('default', () {
    testWidgets('a value of 0.5 fills exactly half the rail', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-progressbar--default'));

      expect(find.text('Default ProgressBar'), findsOneWidget);
      expect(
        fillFraction(tester, 0),
        closeTo(0.5, 0.001),
        reason:
            'the fraction is the entire component; a bar that renders its '
            'rail and ignores its value looks fine until you read it',
      );
      expect(
        tester.getRect(barAt(0)).height,
        2,
        reason: 'medium is a 2px rail',
      );
      expect(
        decorationUnder(tester, barAt(0)).borderRadius,
        FluentRadius.allCircular,
      );
    });
  });

  group('color', () {
    final DocsSection section = sectionOf('components-progressbar--color');

    testWidgets('each status paints its own family', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final FluentColors colors = themeOf(tester).colors;
      final List<Color?> inks = <Color?>[
        indicatorInk(tester, 0),
        indicatorInk(tester, 1),
        indicatorInk(tester, 2),
      ];
      expect(inks[0], colors.statusDangerBackground3);
      // Severe, not Warning: Figma binds the dark-orange family here and the
      // library carries the gap deliberately. A bar that quietly resolved the
      // Warning family would be a near-miss nobody would notice by eye.
      expect(inks[1], colors.statusSevereBackground3);
      expect(inks[2], colors.statusSuccessBackground3);
      expect(
        inks.toSet(),
        hasLength(3),
        reason: 'three statuses resolving to one colour would satisfy nothing',
      );
      for (final Color? ink in inks) {
        expect(
          ink,
          isNot(colors.compoundBrandBackground),
          reason:
              'a status bar still painted in the default brand means the '
              'status never reached the style',
        );
      }
    });

    testWidgets('each bar fills the fraction it was given', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(fillFraction(tester, 0), closeTo(0.75, 0.001));
      expect(fillFraction(tester, 1), closeTo(0.95, 0.001));
      expect(fillFraction(tester, 2), closeTo(1, 0.001));
      expect(find.text('Error ProgressBar'), findsOneWidget);
      expect(find.text('Warning ProgressBar'), findsOneWidget);
      expect(find.text('Success ProgressBar'), findsOneWidget);
    });

    testWidgets('only the error field recolours its message', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final FluentColors colors = themeOf(tester).colors;
      expect(
        textStyleOf(tester, find.text('Error ProgressBar'))?.color,
        colors.statusDangerForeground1,
      );
      // Not an oversight, and not a colour to "fix": upstream applies its error
      // text style for `error` alone and leaves warning and success on
      // `colorNeutralForeground3`, and `resolveFluentFieldStyle` reproduces
      // that asymmetry verbatim. Pinned here so the section keeps rendering
      // what the React docs render.
      expect(
        textStyleOf(tester, find.text('Warning ProgressBar'))?.color,
        colors.neutralForeground3,
      );
      expect(
        textStyleOf(tester, find.text('Success ProgressBar'))?.color,
        colors.neutralForeground3,
      );
    });
  });

  group('indeterminate', () {
    testWidgets('the sweep is a third of the rail and keeps moving', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-progressbar--indeterminate'),
      );

      expect(
        fillFraction(tester, 0),
        closeTo(1 / 3, 0.001),
        reason:
            "upstream's 33.33%: an indeterminate bar has no fraction to "
            'show, so its width is fixed',
      );

      // Six samples inside one 3s loop, so a wrap cannot masquerade as travel.
      final List<double> lefts = <double>[];
      for (int i = 0; i < 6; i++) {
        lefts.add(tester.getRect(indicatorOf(0)).left);
        await tester.pump(const Duration(milliseconds: 300));
      }
      for (int i = 1; i < lefts.length; i++) {
        expect(
          lefts[i],
          greaterThan(lefts[i - 1]),
          reason: 'sample $i did not advance: the sweep is stalled',
        );
      }
    });
  });

  group('motion custom', () {
    testWidgets('the custom motion swings back instead of wrapping', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-progressbar--motion-custom'),
      );

      final double rail = tester
          .getRect(find.byType(FractionallySizedBox))
          .width;
      final List<double> lefts = <double>[];
      // 4s of samples: the controller runs 2s out and 2s back, so anything
      // shorter could catch only the outbound half and pass on a bar that
      // sweeps exactly like the built-in one.
      for (int i = 0; i < 11; i++) {
        lefts.add(tester.getRect(customIndicator()).left);
        await tester.pump(const Duration(milliseconds: 400));
      }

      final List<double> deltas = <double>[
        for (int i = 1; i < lefts.length; i++) lefts[i] - lefts[i - 1],
      ];
      expect(
        deltas.any((double d) => d > 0),
        isTrue,
        reason: 'the bar never travelled',
      );
      expect(
        deltas.any((double d) => d < 0),
        isTrue,
        reason:
            "`reverse: true` is the section's whole point — a bar that only "
            'ever moves right is the stock indeterminate animation',
      );
      // A wrap would show up as one jump of about four bar-widths back to the
      // start; an alternation never moves further in a step than it did going
      // out. This is what separates "swings" from "restarts".
      for (final double delta in deltas) {
        expect(delta.abs(), lessThan(rail * 2));
      }
    });
  });

  group('max', () {
    final DocsSection section = sectionOf('components-progressbar--max');

    testWidgets('the fill tracks the count it prints', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // Read on the same frame: the label and the fraction come from one build,
      // so a bar that lagged its own counter by a frame — or divided by the
      // wrong maximum — shows up here as a mismatch.
      final int first = downloadedCount(tester);
      expect(fillFraction(tester, 0), closeTo(first / 42, 0.002));

      await tester.pump(const Duration(milliseconds: 900));
      final int second = downloadedCount(tester);
      expect(
        second,
        greaterThan(first),
        reason: 'the counter is stalled, so the demo shows a static bar',
      );
      expect(fillFraction(tester, 0), closeTo(second / 42, 0.002));

      // 42 is the maximum, not the fraction: a bar that passed the count
      // straight through would have saturated long before here.
      expect(fillFraction(tester, 0), lessThanOrEqualTo(1));
    });
  });

  group('shape', () {
    final DocsSection section = sectionOf('components-progressbar--shape');

    testWidgets('square is the pill radius replaced, and nothing else', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(
        decorationUnder(tester, barAt(0)).borderRadius,
        FluentRadius.allCircular,
      );
      expect(
        decorationUnder(tester, barAt(1)).borderRadius,
        BorderRadius.zero,
        reason: 'the style override must reach the rail, not just the widget',
      );
      // The shape knob is a radius, so the two bars must still agree on
      // everything else the section holds constant.
      expect(tester.getRect(barAt(0)).height, tester.getRect(barAt(1)).height);
      expect(fillFraction(tester, 0), closeTo(fillFraction(tester, 1), 0.001));
    });

    testWidgets('the indicator takes the square corners too', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(
        (tester.widget<DecoratedBox>(indicatorOf(1)).decoration
                as BoxDecoration)
            .borderRadius,
        BorderRadius.zero,
        reason:
            'a rounded indicator inside a square rail would show its own '
            'corners at the leading edge',
      );
    });
  });

  group('thickness', () {
    testWidgets('medium and large are 2 and 4 high', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-progressbar--thickness'));

      expect(tester.getRect(barAt(0)).height, 2);
      expect(tester.getRect(barAt(1)).height, 4);
      // Both bars carry the same value, so a size axis that leaked into the
      // fill would show here rather than in the height.
      expect(fillFraction(tester, 0), closeTo(0.7, 0.001));
      expect(fillFraction(tester, 1), closeTo(0.7, 0.001));
    });
  });

  group('pointer', () {
    testWidgets('a real mouse over the bar changes nothing', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-progressbar--default'));

      final Color? rail = decorationUnder(tester, barAt(0)).color;
      final double fill = fillFraction(tester, 0);
      // Fluent gives a progress bar no interaction states at all: no hover, no
      // press, no focus ring. `tester.tap` synthesises no hover, so a rail that
      // repainted under a pointer could only be caught with a real one.
      final Color? hovered = await whileHovering(
        tester,
        barAt(0),
        () => decorationUnder(tester, barAt(0)).color,
      );
      expect(hovered, rail);
      expect(fillFraction(tester, 0), closeTo(fill, 0.001));

      // And a press is not an interaction either: the bar never consumes a
      // pointer, so a real click has to leave it exactly as it was.
      await mouseClick(tester, barAt(0));
      expect(decorationUnder(tester, barAt(0)).color, rail);
      expect(fillFraction(tester, 0), closeTo(fill, 0.001));
    });
  });

  group('lifecycle', () {
    testWidgets('every section unmounts without throwing', (
      WidgetTester tester,
    ) async {
      for (final DocsSection section in sectionsOf(page)) {
        await pumpSection(tester, section);
        // Max and Motion Custom each own a repeating AnimationController, so
        // this is where a controller that outlives its widget surfaces.
        await expectCleanTeardown(tester, section.id);
      }
    });
  });
}

/// The [index]-th progress bar on the mounted section.
Finder barAt(int index) => find.byType(FluentProgressBar).at(index);

/// The filled portion of the [index]-th bar.
///
/// `buildFluentProgressBar` sizes the indicator with a `FractionallySizedBox`,
/// which lays *itself* out at the full rail width and only its child at the
/// fraction — so the child is the thing to measure, and the parent is the rail
/// to measure it against.
Finder indicatorOf(int index) => find.descendant(
  of: find.descendant(
    of: barAt(index),
    matching: find.byType(FractionallySizedBox),
  ),
  matching: find.byType(DecoratedBox),
);

/// The indicator of the hand-composed bar on the Motion Custom section, which
/// has no [FluentProgressBar] to descend from.
Finder customIndicator() => find.descendant(
  of: find.byType(FractionallySizedBox),
  matching: find.byType(DecoratedBox),
);

/// How much of the [index]-th rail is filled, as a fraction.
double fillFraction(WidgetTester tester, int index) =>
    tester.getRect(indicatorOf(index)).width /
    tester.getRect(barAt(index)).width;

/// The colour the [index]-th bar's filled portion actually painted.
Color? indicatorInk(WidgetTester tester, int index) =>
    (tester.widget<DecoratedBox>(indicatorOf(index)).decoration
            as BoxDecoration)
        .color;

/// The count the Max section is currently printing.
int downloadedCount(WidgetTester tester) {
  final RegExpMatch? match = RegExp(
    r'been (\d+) files',
  ).firstMatch(textSnapshot(tester));
  if (match == null) fail('the Max demo printed no count');
  return int.parse(match.group(1)!);
}

/// The theme the mounted section resolved against.
FluentThemeData themeOf(WidgetTester tester) =>
    FluentTheme.of(tester.element(find.byType(FluentProgressBar).first));
