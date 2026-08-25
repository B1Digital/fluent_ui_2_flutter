import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// HorizontalBarChart's page is seven demos with only two knobs between them —
/// Absolute Scale's "Hide labels" checkbox and Custom Callout's popover switch
/// — so most of what has to be proven here is the chart's own affordances:
/// the hover popover, the legend's select-and-dim, the legend overflow and the
/// annotation toggle.
///
/// The bars are painted, not laid out: one [FluentHorizontalBarStripPainter]
/// per row carries the fills, the per-bar opacities and the absolute-scale
/// label, and the benchmark marker is a second painter. A demo whose state
/// moved without reaching those painters would look identical to the widget
/// tree, so every geometric assertion below reads a painter rather than a
/// widget field.
void main() {
  const String page = 'charts-horizontalbarchart';

  group('horizontal bar basic', () {
    final DocsSection section = sectionOf(
      'charts-horizontalbarchart--horizontal-bar-basic',
    );

    testWidgets('every row draws a strip and prints its own value', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(_strips(tester), hasLength(8));
      expect(_bars, findsNWidgets(8));
      // Grouping starts at 10000 (`formatter.ts:40`), which is why four of
      // these eight carry a separator and four do not. Pinning the exact
      // strings is what catches a value column silently switching formatter.
      for (final String value in <String>[
        '1543',
        '800',
        '8888',
        '15,888',
        '11,444',
        '14,000',
        '9855',
        '4250',
      ]) {
        expect(find.text(value), findsOneWidget);
      }
      // Every row here is a single point, and `HorizontalBarChart.tsx:485`
      // gates the legend strip on the last row's single-bar verdict.
      expect(find.byType(FluentChartLegend), findsNothing);
      await expectCleanTeardown(tester, section.id);
    });

    testWidgets('a real hover raises the popover for the bar underneath', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.byType(FluentChartPopover), findsNothing);

      // A bar's popover hangs off `MouseRegion.onHover`, which a synthetic tap
      // never produces: without a real pointer this demo has no observable
      // behaviour at all.
      TestGesture mouse = await mouseHover(tester, _bars.first);
      expect(find.byType(FluentChartPopover), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(FluentChartPopover),
          matching: find.text('2020/04/30'),
        ),
        findsOneWidget,
        reason: "the popover's legend row is the point's xAxisCalloutData",
      );
      expect(
        find.descendant(
          of: find.byType(FluentChartPopover),
          matching: find.text('10%'),
        ),
        findsOneWidget,
      );

      await mouseAway(tester, mouse);
      expect(
        find.byType(FluentChartPopover),
        findsNothing,
        reason: 'leaving the chart must close the popover',
      );

      // A different bar must produce a different reading, or the popover is
      // showing the first bar it ever saw.
      mouse = await mouseHover(tester, _bars.at(2));
      expect(
        find.descendant(
          of: find.byType(FluentChartPopover),
          matching: find.text('59%'),
        ),
        findsOneWidget,
      );
      await mouseAway(tester, mouse);
    });
  });

  group('horizontal bar absolute scale', () {
    final DocsSection section = sectionOf(
      'charts-horizontalbarchart--horizontal-bar-absolute-scale',
    );

    testWidgets('the hide-labels checkbox strips the in-bar labels', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // The label lives on the painter, not in a Text: `hideLabels` flipping
      // the demo's own bool while the painter kept its string is exactly the
      // failure this reads through.
      expect(_strips(tester).map(_labelOf), <String>[
        '1.5k',
        '800',
        '8.9k',
        '15.9k',
        '11.4k',
        '14k',
        '9.9k',
        '4.3k',
      ]);

      await mouseClick(tester, find.byType(FluentCheckbox));
      expect(
        tester.widget<FluentCheckbox>(find.byType(FluentCheckbox)).checked,
        isTrue,
      );
      expect(
        _strips(tester).map(_labelOf),
        everyElement(isNull),
        reason: 'hideLabels must reach the painter that draws the label',
      );

      await mouseClick(tester, find.byType(FluentCheckbox));
      expect(
        _strips(tester).map(_labelOf).first,
        '1.5k',
        reason: 'clearing the checkbox must bring the labels back',
      );
      await expectCleanTeardown(tester, section.id);
    });

    testWidgets('the absolute-scale variant anchors its label to the '
        'placeholder', (WidgetTester tester) async {
      await pumpSection(tester, section);

      // Index 1 is the synthesised remainder segment. A label anchored to
      // index 0 would be painted under the value bar rather than beside it.
      expect(
        _strips(
          tester,
        ).map((FluentHorizontalBarStripPainter p) => p.absoluteLabelIndex),
        everyElement(1),
      );
      // Absolute scale suppresses the value column entirely
      // (`HorizontalBarChart.tsx:416-417`).
      expect(find.text('1543'), findsNothing);
    });
  });

  group('horizontal bar benchmark', () {
    final DocsSection section = sectionOf(
      'charts-horizontalbarchart--horizontal-bar-benchmark',
    );

    testWidgets('each row marks its benchmark at the value it names', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // 50/100, 30/200 and 5/50, quantised to whole percentage points by
      // `Math.round` (`HorizontalBarChart.tsx:198`). Three separate ratios is
      // what proves each marker reads its own row rather than the first.
      expect(
        paintersOf<FluentBenchmarkTrianglePainter>(
          tester,
        ).map((FluentBenchmarkTrianglePainter p) => p.ratio),
        <double>[0.5, 0.15, 0.1],
      );
      await expectCleanTeardown(tester, section.id);
    });

    testWidgets('fraction mode prints value and total, not just the value', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      for (final (String value, String total) in <(String, String)>[
        ('10', ' / 100'),
        ('30', ' / 200'),
        ('15', ' / 50'),
      ]) {
        expect(find.text(value), findsOneWidget);
        expect(find.text(total), findsOneWidget);
      }
    });
  });

  group('horizontal bar stacked', () {
    final DocsSection section = sectionOf(
      'charts-horizontalbarchart--horizontal-bar-stacked',
    );

    testWidgets('clicking a legend dims every bar but its own, and back', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(_opacities(tester), everyElement(1.0));

      await mouseClick(tester, find.text('One.One'));
      expect(
        _opacities(tester),
        <double>[1.0, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1],
        reason: 'selecting a legend must dim the other six segments',
      );

      await mouseClick(tester, find.text('One.One'));
      expect(
        _opacities(tester),
        everyElement(1.0),
        reason: 'the legend selection toggles, so a second press clears it',
      );
      await expectCleanTeardown(tester, section.id);
    });

    testWidgets('hovering a legend highlights without selecting it', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // Hover-only highlight is unreachable through `tester.tap`, and it is
      // the one path that must undo itself when the pointer leaves.
      final TestGesture mouse = await mouseHover(tester, find.text('Two.One'));
      expect(_opacities(tester), <double>[0.1, 0.1, 0.1, 1.0, 0.1, 0.1, 0.1]);

      await mouseAway(tester, mouse);
      expect(
        _opacities(tester),
        everyElement(1.0),
        reason: 'a hover must not leave a selection behind it',
      );
    });

    testWidgets('the overflow control reveals the legends it hides', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // Four of the seven legends fit; the rest are behind the overflow
      // trigger, and a trigger that opens an empty surface would still satisfy
      // any assertion about the trigger itself.
      expect(find.text('Three.Two'), findsNothing);
      await mouseClick(tester, find.text('+3 more'));
      for (final String hidden in <String>[
        'Two.Two',
        'Three.One',
        'Three.Two',
      ]) {
        expect(find.text(hidden), findsOneWidget);
      }
    });

    testWidgets('a multi-segment row sums its segments', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // 1543 + 1000 + 547, 987 + 1987 and 872 + 128: a multi-segment row
      // ignores chartDataMode and always shows the sum
      // (`HorizontalBarChart.tsx:151-161`).
      expect(find.text('3090'), findsOneWidget);
      expect(find.text('2974'), findsOneWidget);
      expect(find.text('1000'), findsOneWidget);
    });
  });

  group('horizontal bar custom accessibility', () {
    final DocsSection section = sectionOf(
      'charts-horizontalbarchart--horizontal-bar-custom-accessibility',
    );

    testWidgets('a bar with no callout label falls back to its own data', (
      WidgetTester tester,
    ) async {
      // The fallback half of `HorizontalBarChart.tsx:342` cannot be read off
      // this section: every one of its eight points carries a
      // `callOutSemantics`, and the override wins on each of them — which is
      // precisely what the next test pins. Basic's rows name no accessibility
      // data at all, so its bars are the ones that compose
      // `xAxisCalloutData, yAxisCalloutData.` for themselves.
      final DocsSection fallback = sectionOf(
        'charts-horizontalbarchart--horizontal-bar-basic',
      );
      await pumpSection(tester, fallback);

      expect(_strips(tester), hasLength(8));
      expect(find.bySemanticsLabel('2020/04/30, 10%.'), findsOneWidget);
      await expectCleanTeardown(tester, fallback.id);
    });

    testWidgets("a point's own callout label overrides the derived one", (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // `HorizontalBarChart.tsx:342` reads
      // `point.callOutAccessibilityData?.ariaLabel ||` before it composes the
      // legend/value fallback, and every other chart in the package honours
      // the same field. This section exists to demonstrate that override, so
      // it is the section's whole subject.
      expect(
        find.bySemanticsLabel('Bar series 1 of chart one 2021/06/10 10%'),
        findsOneWidget,
        reason: 'callOutSemantics must win over the derived aria label',
      );
    });

    testWidgets('the row title and the row value carry their own labels', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // `HorizontalBarChart.tsx:436` hangs `chartTitleAccessibilityData` on
      // the title and `:150` hangs `chartDataAccessibilityData` on the value
      // text. Both are declared by this section's data and both must reach
      // the tree, or the row announces only its visible strings.
      expect(
        find.bySemanticsLabel('Bar chart depicting about one'),
        findsOneWidget,
        reason: "chartTitleSemantics must label the row's title",
      );
      expect(
        find.bySemanticsLabel('Data 1543 of 15000'),
        findsOneWidget,
        reason: "chartDataSemantics must label the row's value",
      );
    });
  });

  group('horizontal bar custom callout', () {
    final DocsSection section = sectionOf(
      'charts-horizontalbarchart--horizontal-bar-custom-callout',
    );

    testWidgets('the override switch rewrites what the popover says', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      TestGesture mouse = await mouseHover(tester, _bars.first);
      expect(_popoverText(tester), <String>['2020/04/30', '1.5K']);
      await mouseAway(tester, mouse);

      await mouseClick(tester, find.byType(FluentSwitch));
      expect(
        tester.widget<FluentSwitch>(find.byType(FluentSwitch)).checked,
        isTrue,
      );

      mouse = await mouseHover(tester, _bars.first);
      expect(
        _popoverText(tester),
        <String>['Custom XVal', '1.5K h'],
        reason: 'the switch must rewrite both popover slots, not just one',
      );
      await mouseAway(tester, mouse);

      await mouseClick(tester, find.byType(FluentSwitch));
      mouse = await mouseHover(tester, _bars.first);
      expect(
        _popoverText(tester),
        <String>['2020/04/30', '1.5K'],
        reason: 'turning the override back off must restore the defaults',
      );
      await mouseAway(tester, mouse);
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('horizontal bar stacked annotated inline legend', () {
    final DocsSection section = sectionOf(
      'charts-horizontalbarchart--horizontal-bar-stacked-annotated-inline-'
      'legend',
    );

    testWidgets('the annotation toggle reveals its names and flips its glyph', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Finder toggle = find.bySemanticsLabel('Show annotation');
      expect(toggle, findsNWidgets(3));
      expect(find.text('Person 1'), findsNothing);

      await mouseClick(tester, toggle.first);
      expect(find.text('Person 1'), findsOneWidget);
      expect(find.text('Person 2'), findsOneWidget);
      expect(
        _glyphs(tester).first,
        FluentIcons.cursor_click_20_regular,
        reason: 'the expanded state swaps the filled cursor for the outline',
      );
      expect(
        _glyphs(tester).skip(1),
        everyElement(FluentIcons.cursor_click_20_filled),
        reason: 'one annotation opening must not open its neighbours',
      );

      await mouseClick(tester, toggle.first);
      expect(find.text('Person 1'), findsNothing);
      expect(_glyphs(tester).first, FluentIcons.cursor_click_20_filled);
      await expectCleanTeardown(tester, section.id);
    });

    testWidgets('the legend survives a single-point row and the value column '
        'stays hidden', (WidgetTester tester) async {
      await pumpSection(tester, section);

      // `showLegendForSinglePointBar` is what keeps a one-segment row from
      // suppressing the whole legend strip, and `chartDataMode.hidden` is what
      // keeps the raw 100 off the row while the annotation's own 100% badge
      // stays.
      expect(find.byType(FluentChartLegendRow), findsNWidgets(3));
      expect(find.text('One.One'), findsOneWidget);
      expect(find.text('100'), findsNothing);
      expect(find.text('100%'), findsOneWidget);
    });
  });

  group('lifecycle', () {
    testWidgets('every section unmounts without throwing', (
      WidgetTester tester,
    ) async {
      for (final DocsSection each in sectionsOf(page)) {
        await pumpSection(tester, each);
        await expectCleanTeardown(tester, each.id);
      }
    });
  });
}

/// The hit target minted for each real bar.
///
/// `_buildRow` names the node itself — "the label is what a test and a debug
/// dump identify the bar's own focus node by" — and it is minted only for the
/// points a user can reach, so a synthesised placeholder is excluded for free.
Finder get _bars => find.byWidgetPredicate(
  (Widget widget) =>
      widget is Focus && widget.debugLabel == 'FluentHorizontalBarChart bar',
  description: 'a horizontal bar hit target',
);

/// One strip painter per row, in row order.
List<FluentHorizontalBarStripPainter> _strips(WidgetTester tester) =>
    paintersOf<FluentHorizontalBarStripPainter>(tester);

String? _labelOf(FluentHorizontalBarStripPainter painter) =>
    painter.absoluteLabel;

/// Every bar's painted opacity, all rows concatenated in row order.
///
/// Selection and hover reach the bars as an opacity and nothing else — no
/// widget in the tree changes — so this is the only honest reading of "which
/// series is highlighted".
List<double> _opacities(WidgetTester tester) => _strips(
  tester,
).expand((FluentHorizontalBarStripPainter p) => p.opacities).toList();

/// The two lines the single-value popover shows: its legend and its reading.
List<String> _popoverText(WidgetTester tester) => tester
    .widgetList<Text>(
      find.descendant(
        of: find.byType(FluentChartPopover),
        matching: find.byType(Text),
      ),
    )
    .map((Text text) => text.data ?? '')
    .where((String value) => value.isNotEmpty)
    .toList();

/// The annotation toggles' glyphs, in declaration order.
List<IconData?> _glyphs(WidgetTester tester) => tester
    .widgetList<Icon>(find.byType(Icon))
    .map((Icon icon) => icon.icon)
    .toList();
