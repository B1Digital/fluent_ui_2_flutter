import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Checkbox's page has no dropdowns or switches driving it — the checkbox *is*
/// the knob on every one of its nine sections. So each test below drives the
/// control and reads the glyph the indicator actually paints, which is the only
/// place the tri-state value becomes visible: a demo whose `setState` runs but
/// whose indicator never repaints would pass a "the value moved" assertion and
/// fail every one of these.
void main() {
  const String page = 'components-checkbox';

  group('default', () {
    final DocsSection section = sectionOf('components-checkbox--default');

    testWidgets('a real mouse press toggles the bare indicator', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder box = find.byType(FluentCheckbox);

      expect(_glyphs(tester), <FluentCheckboxGlyph>[FluentCheckboxGlyph.none]);

      // Mouse rather than tap: FluentInteractive routes press through its own
      // recognizer, and a control that only answers a synthetic tap is
      // unreachable in the browser this showroom ships to.
      await mouseClick(tester, box);
      expect(_glyphs(tester), <FluentCheckboxGlyph>[
        FluentCheckboxGlyph.checkmark,
      ]);

      await mouseClick(tester, box);
      expect(
        _glyphs(tester),
        <FluentCheckboxGlyph>[FluentCheckboxGlyph.none],
        reason: 'a second press must clear the tick, not latch it',
      );
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('checked', () {
    final DocsSection section = sectionOf('components-checkbox--checked');

    testWidgets('starts ticked and clears on tap', (WidgetTester tester) async {
      await pumpSection(tester, section);

      expect(
        _glyphs(tester),
        <FluentCheckboxGlyph>[FluentCheckboxGlyph.checkmark],
        reason: 'the section is called Checked; it must mount ticked',
      );

      await tapAndSettle(tester, find.text('Checked'), what: 'the label');
      expect(
        _glyphs(tester),
        <FluentCheckboxGlyph>[FluentCheckboxGlyph.none],
        reason: 'the label is inside the hit target, so it must toggle too',
      );

      await tapAndSettle(tester, find.text('Checked'), what: 'the label');
      expect(_glyphs(tester), <FluentCheckboxGlyph>[
        FluentCheckboxGlyph.checkmark,
      ]);
    });
  });

  group('mixed', () {
    final DocsSection section = sectionOf('components-checkbox--mixed');

    testWidgets('the parent aggregates and drives its three children', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // Option 2 alone is on, so the parent is the mixed state — a filled
      // square, never a tick. This is the whole point of the section, and it is
      // also the state a two-state checkbox would silently render as unchecked.
      expect(_glyphs(tester), <FluentCheckboxGlyph>[
        FluentCheckboxGlyph.square,
        FluentCheckboxGlyph.none,
        FluentCheckboxGlyph.checkmark,
        FluentCheckboxGlyph.none,
      ]);

      await tapAndSettle(tester, find.text('All options'), what: 'the parent');
      expect(
        _glyphs(tester),
        List<FluentCheckboxGlyph>.filled(4, FluentCheckboxGlyph.checkmark),
        reason:
            'tapping a mixed parent must select every child, not clear them',
      );

      await tapAndSettle(tester, find.text('Option 1'), what: 'option 1');
      expect(
        _glyphs(tester),
        <FluentCheckboxGlyph>[
          FluentCheckboxGlyph.square,
          FluentCheckboxGlyph.none,
          FluentCheckboxGlyph.checkmark,
          FluentCheckboxGlyph.checkmark,
        ],
        reason: 'unticking one child must push the parent back to mixed',
      );

      // Back to exactly the state the section mounted in.
      await tapAndSettle(tester, find.text('Option 3'), what: 'option 3');
      expect(_glyphs(tester), <FluentCheckboxGlyph>[
        FluentCheckboxGlyph.square,
        FluentCheckboxGlyph.none,
        FluentCheckboxGlyph.checkmark,
        FluentCheckboxGlyph.none,
      ]);
    });
  });

  group('disabled', () {
    final DocsSection section = sectionOf('components-checkbox--disabled');

    testWidgets('all three refuse input and keep their glyphs', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      const List<FluentCheckboxGlyph> mounted = <FluentCheckboxGlyph>[
        FluentCheckboxGlyph.none,
        FluentCheckboxGlyph.checkmark,
        FluentCheckboxGlyph.square,
      ];
      expect(_glyphs(tester), mounted);

      for (final String label in <String>[
        'Disabled',
        'Disabled checked',
        'Disabled mixed',
      ]) {
        // warnIfMissed: a disabled checkbox has no hit target at all, so the tap
        // is expected to land on nothing — that is the assertion, not a mistake.
        await tapAndSettle(
          tester,
          find.text(label),
          what: label,
          warnIfMissed: false,
        );
      }
      expect(
        _glyphs(tester),
        mounted,
        reason: 'a disabled checkbox that still toggles is not disabled',
      );
    });
  });

  group('large', () {
    testWidgets('the size axis grows the indicator box', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-checkbox--checked'));
      final double medium = _indicator(tester).width;

      await pumpSection(tester, sectionOf('components-checkbox--large'));
      final double large = _indicator(tester).width;

      // 16 and 20 are Fluent's own numbers, asserted absolutely rather than as
      // "bigger": a size axis that moved the box by a pixel would still pass a
      // relative comparison.
      expect(medium, 16);
      expect(large, 20);
      // The glyph box moves with it — 12 to 16 — and it is a separate style
      // value, so a size axis that grew only the box would draw a small tick
      // rattling around inside a large one.
      expect(_glyphBox(tester), const Size.square(16));

      await tapAndSettle(
        tester,
        find.text('Large'),
        what: 'the large checkbox',
      );
      expect(_glyphs(tester), <FluentCheckboxGlyph>[
        FluentCheckboxGlyph.checkmark,
      ]);
      expect(
        _indicator(tester).width,
        20,
        reason: 'ticking must not resize the box',
      );
    });
  });

  group('label before', () {
    final DocsSection section = sectionOf('components-checkbox--label-before');

    testWidgets('the label sits to the leading side of the indicator', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Rect label = tester.getRect(find.text('Label before'));
      expect(
        label.right,
        lessThan(_indicator(tester).left),
        reason:
            'labelPosition: before must reorder the row, not just restyle it',
      );

      await tapAndSettle(tester, find.text('Label before'), what: 'the label');
      expect(
        _glyphs(tester),
        <FluentCheckboxGlyph>[FluentCheckboxGlyph.checkmark],
        reason: 'a reordered label must still be part of the hit target',
      );
    });
  });

  group('label wrapping', () {
    final DocsSection section = sectionOf(
      'components-checkbox--label-wrapping',
    );

    testWidgets('the label wraps and the box stays on the first line', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(
        find.textContaining('wrap to a second line'),
      );
      // Intrinsic height at unbounded width is exactly one line, so the ratio
      // is a line count that needs no text metrics and survives a font swap.
      final double oneLine = paragraph.getMaxIntrinsicHeight(double.infinity);
      expect(
        paragraph.size.height,
        greaterThan(oneLine * 1.5),
        reason: 'the section is only about wrapping; one line proves nothing',
      );

      // Upstream's promise, verbatim: "The checkbox indicator will stay aligned
      // to the first line of text." Centre-aligning the box against a two-line
      // label would drop it half a line and still look plausible.
      final Rect text = tester.getRect(
        find.textContaining('wrap to a second line'),
      );
      expect(_indicator(tester).center.dy, lessThan(text.top + oneLine));

      await tapAndSettle(
        tester,
        find.textContaining('wrap to a second line'),
        what: 'the wrapped label',
      );
      expect(_glyphs(tester), <FluentCheckboxGlyph>[
        FluentCheckboxGlyph.checkmark,
      ]);
    });
  });

  group('required', () {
    final DocsSection section = sectionOf('components-checkbox--required');

    testWidgets('the asterisk renders and the checkbox still toggles', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(
        find.text('*'),
        findsOneWidget,
        reason: 'required styling is the only thing this section shows',
      );

      await tapAndSettle(tester, find.text('Required'), what: 'the label');
      expect(_glyphs(tester), <FluentCheckboxGlyph>[
        FluentCheckboxGlyph.checkmark,
      ]);
      expect(find.text('*'), findsOneWidget);
    });
  });

  group('circular', () {
    testWidgets('the shape axis rounds the indicator fully', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-checkbox--checked'));
      final BorderRadiusGeometry? square = _radius(tester);

      await pumpSection(tester, sectionOf('components-checkbox--circular'));
      expect(_radius(tester), FluentRadius.allCircular);
      expect(
        square,
        isNot(FluentRadius.allCircular),
        reason: 'the default shape must differ, or the axis drives nothing',
      );

      await tapAndSettle(tester, find.text('Circular'), what: 'the label');
      expect(_glyphs(tester), <FluentCheckboxGlyph>[
        FluentCheckboxGlyph.checkmark,
      ]);
      expect(
        _radius(tester),
        FluentRadius.allCircular,
        reason: 'ticking must not reset the shape',
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

/// The glyph each checkbox in the tree is painting, in tree order.
List<FluentCheckboxGlyph> _glyphs(WidgetTester tester) =>
    paintersOf<FluentCheckboxGlyphPainter>(
      tester,
    ).map((FluentCheckboxGlyphPainter p) => p.glyph).toList();

/// The glyph box the first checkbox paints its tick inside.
Size _glyphBox(WidgetTester tester) => tester
    .widget<CustomPaint>(
      find.byWidgetPredicate(
        (Widget w) =>
            w is CustomPaint && w.painter is FluentCheckboxGlyphPainter,
      ),
    )
    .size;

/// The first checkbox's indicator box.
///
/// The indicator is the only [DecoratedBox] a checkbox builds — the label slot
/// is bare text — so `.first` is unambiguous and stays that way.
Rect _indicator(WidgetTester tester) => tester.getRect(
  find
      .descendant(
        of: find.byType(FluentCheckbox).first,
        matching: find.byType(DecoratedBox),
      )
      .first,
);

/// The corner treatment of the first checkbox's indicator box.
BorderRadiusGeometry? _radius(WidgetTester tester) {
  final DecoratedBox box = tester.widget<DecoratedBox>(
    find
        .descendant(
          of: find.byType(FluentCheckbox).first,
          matching: find.byType(DecoratedBox),
        )
        .first,
  );
  return (box.decoration as BoxDecoration).borderRadius;
}
