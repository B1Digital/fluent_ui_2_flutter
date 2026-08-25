import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Slider's seven sections are one control under a size axis, a step, a range,
/// a rotation and a disabled flag. A slider paints its whole self — rail,
/// progress, ticks and thumb are one [CustomPainter] — so `fraction` on that
/// painter is the only place the value becomes visible, and every test below
/// reads it rather than the demo's own `double`.
void main() {
  const String page = 'components-slider';

  group('default', () {
    final DocsSection section = sectionOf('components-slider--default');

    testWidgets('a real mouse press moves the thumb to where it landed', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(_fraction(tester), closeTo(0.2, 0.001));

      // The centre of the rail, give or take the two pixels of travel
      // `mouseClick` puts between press and release — which is the point of
      // using it: a rail whose drag recogniser loses the arena to the page's
      // own scroll would swallow the whole gesture.
      await mouseClick(tester, find.byType(FluentSlider));
      expect(_fraction(tester), greaterThan(0.45));
      expect(_fraction(tester), lessThan(0.6));
      await expectCleanTeardown(tester, section.id);
    });

    testWidgets('a press lands on the value under the pointer, and back', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await _tapAtFraction(tester, find.byType(FluentSlider), 0.75);
      expect(
        _fraction(tester),
        closeTo(0.75, 0.001),
        reason: 'a continuous rail must land exactly where it was pressed',
      );

      await _tapAtFraction(tester, find.byType(FluentSlider), 0);
      expect(_fraction(tester), 0);

      await _tapAtFraction(tester, find.byType(FluentSlider), 0.2);
      expect(_fraction(tester), closeTo(0.2, 0.001));
    });

    testWidgets('a drag carries the thumb with it', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Rect rail = tester.getRect(find.byType(FluentSlider));

      await tester.dragFrom(rail.center, const Offset(40, 0));
      await settle(tester);
      expectClean(tester, 'dragging the rail');
      expect(
        _fraction(tester),
        greaterThan(0.85),
        reason: 'a slider you can press but not drag is not a slider',
      );
    });
  });

  group('size', () {
    final DocsSection section = sectionOf('components-slider--size');

    testWidgets('the size axis thins the rail it is on, and only that', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // Medium is declared first, small second. Fluent's own numbers, asserted
      // absolutely: a size axis that moved the thumb by a pixel would still
      // pass a relative comparison.
      final List<FluentSliderPainter> rails = _rails(tester);
      expect(rails, hasLength(2));
      expect(
        <double>[rails[0].thumbSize, rails[0].railThickness],
        <double>[20, 4],
      );
      expect(
        <double>[rails[1].thumbSize, rails[1].railThickness],
        <double>[16, 2],
      );

      await _tapAtFraction(tester, find.byType(FluentSlider).at(1), 0.9);
      expect(_rails(tester)[1].fraction, closeTo(0.9, 0.001));
      expect(
        _rails(tester)[0].fraction,
        closeTo(0.2, 0.001),
        reason: 'the two sliders hold separate state; one must not drive both',
      );
    });
  });

  group('controlled', () {
    final DocsSection section = sectionOf('components-slider--controlled');

    testWidgets('the readout tracks the rail and Reset empties it', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // 160 in 20…200 — the readout has to agree with the paint, or the demo is
      // showing a number the thumb never had.
      expect(
        find.text('Control Slider [ Current Value: 160 ]'),
        findsOneWidget,
      );
      expect(_fraction(tester), closeTo((160 - 20) / 180, 0.001));

      await _tapAtFraction(tester, find.byType(FluentSlider), 0.5);
      expect(
        find.text('Control Slider [ Current Value: 110 ]'),
        findsOneWidget,
      );
      expect(_fraction(tester), closeTo(0.5, 0.001));
      // The section's stated reason to be controlled is the custom
      // aria-valuetext, and a screen reader is the only place it shows — so it
      // is also the only knob on this page nothing else would catch.
      expect(
        tester.getSemantics(find.byType(FluentSlider)).value,
        'Value is 110',
      );

      await tapAndSettle(
        tester,
        find.widgetWithText(FluentButton, 'Reset'),
        what: 'Reset',
      );
      expect(find.text('Control Slider [ Current Value: 0 ]'), findsOneWidget);
      expect(
        _fraction(tester),
        0,
        reason:
            'a value below min must park the thumb at the start of the rail',
      );

      await _tapAtFraction(tester, find.byType(FluentSlider), 1);
      expect(
        find.text('Control Slider [ Current Value: 200 ]'),
        findsOneWidget,
      );
      expect(_fraction(tester), 1);
    });
  });

  group('step', () {
    final DocsSection section = sectionOf('components-slider--step');

    testWidgets('the rail is ticked and every press snaps to a multiple', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // 0…12 by 3 is four intervals, which is also four ticks — a stepped rail
      // that draws none is indistinguishable from a continuous one.
      expect(_rails(tester).single.intervals, 4);
      expect(_fraction(tester), closeTo(0.5, 0.001));

      // 0.7 of 0…12 is 8.4, which is not a step. Landing on 9 rather than on
      // 8.4 is the whole of what `step` buys.
      await _tapAtFraction(tester, find.byType(FluentSlider), 0.7);
      expect(_fraction(tester), closeTo(0.75, 0.001));

      await _tapAtFraction(tester, find.byType(FluentSlider), 0.9);
      expect(_fraction(tester), 1);

      await _tapAtFraction(tester, find.byType(FluentSlider), 0.55);
      expect(
        _fraction(tester),
        closeTo(0.5, 0.001),
        reason: 'snapping must round both ways, not only up',
      );
    });
  });

  group('min max', () {
    final DocsSection section = sectionOf('components-slider--min-max');

    testWidgets('the range labels bracket the rail and the ends are reachable', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Rect rail = tester.getRect(find.byType(FluentSlider));

      expect(
        tester.getRect(find.text('10')).right,
        lessThanOrEqualTo(rail.left),
      );
      expect(
        tester.getRect(find.text('50')).left,
        greaterThanOrEqualTo(rail.right),
      );
      // 20 in 10…50, not 20 in 0…100: the min/max knobs have to reach the paint.
      expect(_fraction(tester), closeTo(0.25, 0.001));

      await _tapAtFraction(tester, find.byType(FluentSlider), 1);
      expect(_fraction(tester), 1);

      await _tapAtFraction(tester, find.byType(FluentSlider), 0);
      expect(_fraction(tester), 0);
    });
  });

  group('vertical', () {
    final DocsSection section = sectionOf('components-slider--vertical');

    testWidgets('the maximum is at the top of the rail', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(_rails(tester).single.intervals, 5);
      expect(_fraction(tester), closeTo(0.6, 0.001));

      final Rect rail = tester.getRect(find.byType(RotatedBox));
      // Both presses land outside the rail's 8px inset, so they clamp to an end
      // rather than to a value that depends on the exact geometry.
      await tester.tapAt(Offset(rail.center.dx, rail.top + 2));
      await settle(tester);
      expect(
        _fraction(tester),
        1,
        reason: 'the section promises the max value at the top',
      );

      await tester.tapAt(Offset(rail.center.dx, rail.bottom - 2));
      await settle(tester);
      expect(_fraction(tester), 0);
    });

    testWidgets('a drag up the rail raises the value', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Rect rail = tester.getRect(find.byType(RotatedBox));

      // The page's own claim about this demo: "Dragging and the arrow keys keep
      // working through the rotation." A vertical slider that only answers taps
      // is a slider nobody can use with a mouse held down.
      await tester.dragFrom(rail.center, const Offset(0, -40));
      await settle(tester);
      expectClean(tester, 'dragging the vertical rail');
      expect(_fraction(tester), greaterThan(0.6));
    });

    testWidgets('the arrow keys step up and down the rotated rail', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      _focus(tester, find.byType(FluentSlider));
      await settle(tester);

      // The other half of the page's claim about this demo, and the half no
      // pointer test can reach. Arrow bindings are reading-order — up and right
      // both increase — so a rotation that put the max at the top without the
      // keys following would drive the thumb away from the arrow pressed.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await settle(tester);
      expect(
        _fraction(tester),
        closeTo(0.8, 0.001),
        reason: 'one step of 2 in 0…10, upward',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await settle(tester);
      expect(_fraction(tester), closeTo(0.6, 0.001));
    });
  });

  group('disabled', () {
    final DocsSection section = sectionOf('components-slider--disabled');

    testWidgets('the rail refuses presses and paints the disabled ramp', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-slider--default'));
      final Color? live = _rails(tester).single.railColor;

      await pumpSection(tester, section);
      expect(_fraction(tester), closeTo(0.3, 0.001));
      expect(
        _rails(tester).single.railColor,
        isNot(live),
        reason: 'disabled is a token ramp of its own, not a faded enabled one',
      );

      await _tapAtFraction(tester, find.byType(FluentSlider), 0.9);
      await tester.dragFrom(
        tester.getRect(find.byType(FluentSlider)).center,
        const Offset(40, 0),
      );
      await settle(tester);
      expect(
        _fraction(tester),
        closeTo(0.3, 0.001),
        reason: 'a disabled slider that still moves is not disabled',
      );
    });
  });

  group('lifecycle', () {
    testWidgets('every section unmounts without throwing', (
      WidgetTester tester,
    ) async {
      for (final DocsSection section in sectionsOf(page)) {
        await pumpSection(tester, section);
        await expectCleanTeardown(tester, section.id);
      }
    });
  });
}

/// Gives the keyboard to the control [finder] matches.
///
/// Nothing in a Fluent control takes focus on press — `FluentInteractive`
/// wires activation, not focus — so a keyboard affordance is unreachable from a
/// test until its node is asked for it directly. `FocusableActionDetector`
/// builds two `Focus` widgets and only the inner one carries a node.
void _focus(WidgetTester tester, Finder finder) => tester
    .widgetList<Focus>(
      find.descendant(of: finder, matching: find.byType(Focus)),
    )
    .firstWhere((Focus f) => f.focusNode != null)
    .focusNode!
    .requestFocus();

/// Every slider painter in the tree, in tree order.
List<FluentSliderPainter> _rails(WidgetTester tester) =>
    paintersOf<FluentSliderPainter>(tester);

/// Where the first slider's thumb sits, from 0 to 1.
double _fraction(WidgetTester tester) => _rails(tester).first.fraction;

/// Presses the rail of [slider] at [t] of its travel.
///
/// The rail stops [FluentSpacing.s] short of each end of the control, so a
/// press has to be mapped onto the rail rather than onto the box — pressing at
/// `left + t * width` would be off by 8 at one end and 8 at the other, which is
/// most of the difference between the assertions here and a shrug.
Future<void> _tapAtFraction(
  WidgetTester tester,
  Finder slider,
  double t,
) async {
  final Rect box = tester.getRect(slider);
  const double inset = FluentSpacing.s;
  await tester.tapAt(
    Offset(box.left + inset + t * (box.width - 2 * inset), box.center.dy),
  );
  await settle(tester);
  expectClean(tester, 'pressing the rail at $t');
}
