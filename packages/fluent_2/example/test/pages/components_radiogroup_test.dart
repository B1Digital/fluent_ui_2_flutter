import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// RadioGroup's nine sections are one control under a layout axis, a disabled
/// axis and two flavours of preselection. The selection dot is painted, not
/// laid out, so a group whose value moves while every indicator keeps its old
/// paint would satisfy any widget-property assertion — every test below reads
/// the painter instead.
void main() {
  const String page = 'components-radiogroup';

  group('default', () {
    final DocsSection section = sectionOf('components-radiogroup--default');

    testWidgets('a real mouse press moves the selection dot', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(find.text('Favorite Fruit'), findsOneWidget);
      expect(_dots(tester), <bool>[
        false,
        false,
        false,
        false,
      ], reason: 'the default section starts with nothing selected');

      await mouseClick(tester, find.text('Pear'));
      expect(_dots(tester), <bool>[false, true, false, false]);

      await mouseClick(tester, find.text('Orange'));
      expect(
        _dots(tester),
        <bool>[false, false, false, true],
        reason: 'a radio group must deselect the old option, not add to it',
      );

      await mouseClick(tester, find.text('Pear'));
      expect(_dots(tester), <bool>[false, true, false, false]);
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('layout', () {
    testWidgets('vertical stacks the radios and horizontal lines them up', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-radiogroup--default'));
      final List<Rect> stacked = _indicators(tester);
      expect(stacked[1].top, greaterThan(stacked[0].bottom - 1));
      expect(stacked[1].left, closeTo(stacked[0].left, 0.01));

      await pumpSection(tester, sectionOf('components-radiogroup--horizontal'));
      final List<Rect> inline = _indicators(tester);
      for (int i = 1; i < inline.length; i++) {
        expect(
          inline[i].left,
          greaterThan(inline[i - 1].right),
          reason: 'the horizontal layout must put option $i beside its sibling',
        );
        expect(inline[i].top, closeTo(inline[0].top, 0.01));
      }

      // The horizontal layout keeps its labels *after* the indicators; only
      // horizontal-stacked moves them under. Asserting both here is what stops
      // the two layouts silently collapsing into one.
      expect(
        tester.getRect(find.text('Apple')).left,
        greaterThan(inline[0].right),
      );
    });

    testWidgets('horizontal-stacked puts every label under its indicator', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-radiogroup--horizontal-stacked'),
      );

      final List<Rect> inline = _indicators(tester);
      for (int i = 1; i < inline.length; i++) {
        expect(inline[i].left, greaterThan(inline[i - 1].right));
      }
      for (final String fruit in <String>[
        'Apple',
        'Pear',
        'Banana',
        'Orange',
      ]) {
        final int index = <String>[
          'Apple',
          'Pear',
          'Banana',
          'Orange',
        ].indexOf(fruit);
        expect(
          tester.getRect(find.text(fruit)).top,
          greaterThanOrEqualTo(inline[index].bottom),
          reason: 'horizontal-stacked must drop "$fruit" below its indicator',
        );
      }

      await tapAndSettle(tester, find.text('Banana'), what: 'the third option');
      expect(_dots(tester), <bool>[false, false, true, false]);
    });
  });

  group('default value', () {
    final DocsSection section = sectionOf(
      'components-radiogroup--default-value',
    );

    testWidgets('mounts on pear and moves off it', (WidgetTester tester) async {
      await pumpSection(tester, section);

      expect(
        _dots(tester),
        <bool>[false, true, false, false],
        reason: 'the seeded value must reach the indicator, not just the state',
      );

      await tapAndSettle(tester, find.text('Apple'), what: 'the first option');
      expect(_dots(tester), <bool>[true, false, false, false]);

      await tapAndSettle(tester, find.text('Pear'), what: 'the second option');
      expect(_dots(tester), <bool>[false, true, false, false]);
    });
  });

  group('controlled value', () {
    final DocsSection section = sectionOf(
      'components-radiogroup--controlled-value',
    );

    testWidgets('Clear selection empties the group and disables itself', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder clear = find.widgetWithText(FluentButton, 'Clear selection');

      expect(_dots(tester), <bool>[false, false, true, false]);
      expect(
        tester.widget<FluentButton>(clear).onPressed,
        isNotNull,
        reason: 'with a selection to clear the button must be live',
      );

      await tapAndSettle(tester, clear, what: 'Clear selection');
      expect(_dots(tester), <bool>[
        false,
        false,
        false,
        false,
      ], reason: 'clearing to null must unpaint every dot');
      expect(
        tester.widget<FluentButton>(clear).onPressed,
        isNull,
        reason: 'nothing left to clear, so the button must go disabled',
      );

      // Round trip: re-selecting has to bring the button back, or the demo is a
      // one-way street after its first click.
      await mouseClick(tester, find.text('Apple'));
      expect(_dots(tester), <bool>[true, false, false, false]);
      expect(tester.widget<FluentButton>(clear).onPressed, isNotNull);
    });
  });

  group('required', () {
    final DocsSection section = sectionOf('components-radiogroup--required');

    testWidgets('the field asterisk renders and selection still works', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(
        find.text('*'),
        findsOneWidget,
        reason: 'required styling is the only thing this section shows',
      );

      await tapAndSettle(tester, find.text('Orange'), what: 'the last option');
      expect(_dots(tester), <bool>[false, false, false, true]);
      expect(find.text('*'), findsOneWidget);
    });
  });

  group('disabled', () {
    final DocsSection section = sectionOf('components-radiogroup--disabled');

    testWidgets('a disabled group keeps its selection under every press', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-radiogroup--default-value'),
      );
      final Color? live = _rings(tester)[1];

      await pumpSection(tester, section);

      expect(_dots(tester), <bool>[true, false, false, false]);
      expect(
        _rings(tester).first,
        isNot(live),
        reason: 'disabled is a token ramp of its own, not a faded enabled one',
      );

      for (final String fruit in <String>[
        'Pear',
        'Banana',
        'Orange',
        'Apple',
      ]) {
        // A disabled radio builds no hit target, so landing on nothing is the
        // assertion rather than a mistake in the finder.
        await tapAndSettle(
          tester,
          find.text(fruit),
          what: fruit,
          warnIfMissed: false,
        );
      }

      expect(
        _dots(tester),
        <bool>[true, false, false, false],
        reason: 'a disabled group that still selects is not disabled',
      );
    });
  });

  group('disabled item', () {
    final DocsSection section = sectionOf(
      'components-radiogroup--disabled-item',
    );

    testWidgets('only the one disabled radio refuses the press', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(_dots(tester), <bool>[true, false, false, false]);
      expect(
        tester.widget<FluentRadio<String>>(_radioAt(2)).disabled,
        isTrue,
        reason: 'banana is the item this section disables',
      );

      await tapAndSettle(
        tester,
        find.text('Banana'),
        what: 'the disabled item',
        warnIfMissed: false,
      );
      expect(
        _dots(tester),
        <bool>[true, false, false, false],
        reason: 'per-item disabled must beat the group being enabled',
      );

      // Its siblings are still live — a disabled item that took the whole group
      // down with it would pass the assertion above and fail this one.
      await tapAndSettle(tester, find.text('Orange'), what: 'the last option');
      expect(_dots(tester), <bool>[false, false, false, true]);
    });
  });

  group('label subtext', () {
    final DocsSection section = sectionOf(
      'components-radiogroup--label-subtext',
    );

    testWidgets(
      'the subtext sits under its label, smaller, and still selects',
      (WidgetTester tester) async {
        await pumpSection(tester, section);

        final Finder subtext = find.text(
          'This is an example subtext of the first option',
        );
        expect(subtext, findsOneWidget);
        expect(
          tester.getRect(subtext).top,
          greaterThanOrEqualTo(tester.getRect(find.text('Banana')).bottom),
        );
        expect(
          _fontSize(tester, subtext),
          lessThan(_fontSize(tester, find.text('Banana'))),
          reason:
              'the section exists to show smaller text below the main label',
        );

        await tapAndSettle(tester, subtext, what: 'the first option subtext');
        expect(
          _dots(tester),
          <bool>[true, false],
          reason: 'the subtext is inside the label slot, so it must select too',
        );
      },
    );
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

/// Whether each radio in the tree paints its selection dot, in tree order.
///
/// `FluentRadio.groupValue` is inherited through a scope rather than passed, so
/// the widget itself carries no answer — the painter is where the selection
/// becomes visible.
List<bool> _dots(WidgetTester tester) =>
    paintersOf<FluentRadioIndicatorPainter>(
      tester,
    ).map((FluentRadioIndicatorPainter p) => p.dot != null).toList();

/// The ring colour each radio paints, in tree order.
List<Color?> _rings(WidgetTester tester) =>
    paintersOf<FluentRadioIndicatorPainter>(
      tester,
    ).map((FluentRadioIndicatorPainter p) => p.ring).toList();

/// The [at]-th radio in the tree.
Finder _radioAt(int at) => find.byType(FluentRadio<String>).at(at);

/// Every radio's indicator box, in tree order.
///
/// Matched on the painter rather than by position: a radio wraps its indicator
/// in a focus ring that is itself a [CustomPaint] and covers the whole control,
/// so `.first` would measure the wrong box.
List<Rect> _indicators(WidgetTester tester) => find
    .byWidgetPredicate(
      (Widget w) =>
          w is CustomPaint && w.painter is FluentRadioIndicatorPainter,
    )
    .evaluate()
    .map((Element e) => tester.getRect(find.byWidget(e.widget)))
    .toList();

/// The resolved font size of the paragraph [finder] matches.
double _fontSize(WidgetTester tester, Finder finder) =>
    tester.renderObject<RenderParagraph>(finder).text.style?.fontSize ??
    double.nan;
