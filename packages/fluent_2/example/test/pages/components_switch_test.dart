import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Switch's page is seven sections of the same control under different flags,
/// so every test here reads the one thing a switch actually renders: where the
/// thumb ended up. A demo that flips its `bool` but leaves the thumb parked is
/// the failure mode these are shaped around — `checked` moving is not evidence,
/// the travel is.
void main() {
  const String page = 'components-switch';

  group('default', () {
    final DocsSection section = sectionOf('components-switch--default');

    testWidgets('a real mouse press slides the thumb and back', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder sw = find.byType(FluentSwitch);

      final Rect off = _thumb(tester);
      expect(
        tester.widget<FluentSwitch>(sw).checked,
        isFalse,
        reason: 'the default section mounts unchecked',
      );

      await mouseClick(tester, sw);
      await settle(tester, frames: 8);
      // 20 is the whole of a medium switch's travel: trackWidth - thumb - 2 x
      // inset. Asserting the number rather than "moved right" is what catches a
      // thumb that animates a couple of pixels and stalls.
      expect(_thumb(tester).left - off.left, closeTo(20, 0.5));
      expect(_thumb(tester).top, closeTo(off.top, 0.01));

      await mouseClick(tester, sw);
      await settle(tester, frames: 8);
      expect(
        _thumb(tester).left,
        closeTo(off.left, 0.5),
        reason: 'a second press must slide the thumb home, not latch it',
      );
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('checked', () {
    final DocsSection section = sectionOf('components-switch--checked');

    testWidgets('the label reports the state it is actually in', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(find.text('Checked'), findsOneWidget);
      final Rect on = _thumb(tester);

      await tapAndSettle(tester, find.text('Checked'), what: 'the label');
      await settle(tester, frames: 8);
      expect(find.text('Unchecked'), findsOneWidget);
      expect(
        _thumb(tester).left,
        lessThan(on.left - 15),
        reason: 'the label may not say Unchecked while the thumb sits on',
      );

      await tapAndSettle(tester, find.text('Unchecked'), what: 'the label');
      await settle(tester, frames: 8);
      expect(find.text('Checked'), findsOneWidget);
      expect(_thumb(tester).left, closeTo(on.left, 0.5));
    });
  });

  group('size', () {
    final DocsSection section = sectionOf('components-switch--size');

    testWidgets('the size axis resizes the track it is on, and only that', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // Small is declared first in the demo, medium second — Fluent's own 32x16
      // and 40x20 tracks, asserted absolutely because a size axis that moved a
      // track by a pixel would pass any relative comparison.
      expect(_track(tester).size, const Size(32, 16));
      expect(_track(tester, 1).size, const Size(40, 20));

      final Rect mediumThumb = _thumb(tester, 1);
      await tapAndSettle(tester, find.text('Small'), what: 'the small switch');
      await settle(tester, frames: 8);

      // Small's travel is 16, not medium's 20 — the axis moves the geometry,
      // not just the paint.
      expect(
        _thumb(tester).left - tester.getRect(_trackOf(0)).left,
        closeTo(16 + (16 - 11.2) / 2, 0.5),
      );
      expect(
        _thumb(tester, 1).left,
        closeTo(mediumThumb.left, 0.01),
        reason: 'the two switches hold separate state; one must not drive both',
      );
    });
  });

  group('disabled', () {
    final DocsSection section = sectionOf('components-switch--disabled');

    testWidgets('none of the four respond to a press', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final List<Rect> before = <Rect>[
        for (int i = 0; i < 4; i++) _thumb(tester, i),
      ];
      expect(
        tester
            .widgetList<FluentSwitch>(find.byType(FluentSwitch))
            .every((FluentSwitch s) => s.onChanged == null),
        isTrue,
      );

      for (final String label in <String>[
        'Unchecked and disabled',
        'Checked and disabled',
        'Unchecked and disabled focusable',
        'Checked and disabled focusable',
      ]) {
        // A disabled switch builds no hit target at all, so the tap landing on
        // nothing is the assertion rather than a mistake in the finder.
        await tapAndSettle(
          tester,
          find.text(label),
          what: label,
          warnIfMissed: false,
        );
      }
      await settle(tester, frames: 8);

      expect(
        <Rect>[for (int i = 0; i < 4; i++) _thumb(tester, i)],
        before,
        reason: 'a disabled switch that still slides is not disabled',
      );
    });
  });

  group('label', () {
    final DocsSection section = sectionOf('components-switch--label');

    testWidgets('each labelPosition puts the label where it says', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Rect before = tester.getRect(
        find.textContaining('With label before'),
      );
      final Rect above = tester.getRect(
        find.textContaining('With label above'),
      );
      final Rect after = tester.getRect(
        find.textContaining('With label after'),
      );

      expect(
        before.right,
        lessThanOrEqualTo(_track(tester).left),
        reason: 'before must reorder the row, not just restyle the label',
      );
      expect(
        above.bottom,
        lessThanOrEqualTo(_track(tester, 1).top),
        reason: 'above must stack the control, which a Row cannot do',
      );
      expect(after.left, greaterThanOrEqualTo(_track(tester, 2).right));
    });

    testWidgets('each switch reports its own state in its own label', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await tapAndSettle(
        tester,
        find.textContaining('With label above'),
        what: 'the middle switch',
      );
      await settle(tester, frames: 8);

      expect(find.text('With label above and checked'), findsOneWidget);
      expect(
        find.text('With label before and unchecked'),
        findsOneWidget,
        reason: 'three switches sharing one bool would flip all three labels',
      );
      expect(find.text('With label after and unchecked'), findsOneWidget);
    });
  });

  group('label wrapping', () {
    final DocsSection section = sectionOf('components-switch--label-wrapping');

    testWidgets('the label wraps and the track stays on the first line', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Finder label = find.textContaining('wrap to a second line');
      final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
        label,
      );
      // Intrinsic height at unbounded width is exactly one line, so the ratio is
      // a line count that needs no text metrics and survives a font swap.
      final double oneLine = paragraph.getMaxIntrinsicHeight(double.infinity);
      expect(
        paragraph.size.height,
        greaterThan(oneLine * 1.5),
        reason: 'the section is only about wrapping; one line proves nothing',
      );

      // Upstream's promise, verbatim: "The Switch track will stay aligned to the
      // first line of text." Centring against a two-line label would drop the
      // track half a line and still look plausible.
      expect(
        _track(tester).center.dy,
        lessThan(tester.getRect(label).top + oneLine),
      );

      await tapAndSettle(tester, label, what: 'the wrapped label');
      await settle(tester, frames: 8);
      expect(
        tester.widget<FluentSwitch>(find.byType(FluentSwitch)).checked,
        isTrue,
        reason: 'a wrapped label must still be part of the hit target',
      );
    });
  });

  group('required', () {
    final DocsSection section = sectionOf('components-switch--required');

    testWidgets('the asterisk renders and the switch still slides', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(
        find.text('*'),
        findsOneWidget,
        reason: 'required styling is the only thing this section shows',
      );

      final Rect off = _thumb(tester);
      await tapAndSettle(tester, find.text('Required'), what: 'the label');
      await settle(tester, frames: 8);
      expect(_thumb(tester).left - off.left, closeTo(20, 0.5));
      expect(find.text('*'), findsOneWidget);
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

/// The travelling thumb of the [at]-th switch in the tree.
///
/// The thumb is the only [PositionedDirectional] a switch builds, and it is
/// positioned rather than laid out precisely so that RTL mirrors the travel —
/// which is why its rect, not the widget's `checked`, is what proves the slide.
Rect _thumb(WidgetTester tester, [int at = 0]) => tester.getRect(
  find
      .descendant(
        of: find.byType(FluentSwitch).at(at),
        matching: find.byType(PositionedDirectional),
      )
      .first,
);

/// The track the [at]-th switch's thumb travels along.
Finder _trackOf(int at) => find
    .ancestor(
      of: find
          .descendant(
            of: find.byType(FluentSwitch).at(at),
            matching: find.byType(PositionedDirectional),
          )
          .first,
      matching: find.byType(DecoratedBox),
    )
    .first;

/// The rect of the [at]-th switch's track.
Rect _track(WidgetTester tester, [int at = 0]) => tester.getRect(_trackOf(at));
