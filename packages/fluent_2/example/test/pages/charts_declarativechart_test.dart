import 'dart:async';

import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// DeclarativeChart's page is one section carrying five controls over a chart
/// that is chosen, not built: a schema picker, a colourway picker, a Show
/// more/few switch, a Download button and a free-text legend selection. So the
/// assertions below read the *routed widget* — which chart kind the Plotly JSON
/// resolved to, what colour its series came out, whether its legend rows are
/// dimmed — rather than the picker's own value. A schema knob that changed
/// `_selectedOption` without re-routing would satisfy none of them.
void main() {
  const String page = 'charts-declarativechart';
  final DocsSection section = sectionOf(
    'charts-declarativechart--declarative-chart-basic-example',
  );

  group('schema picker', () {
    testWidgets('every option routes the figure to a different chart', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      for (final MapEntry<String, Type> route in _routes.entries) {
        expect(
          await pickDropdown<String>(tester, _schemaPicker, route.key),
          isNotNull,
        );
        expect(
          find.byType(route.value),
          findsOneWidget,
          reason: '"${route.key}" must render a ${route.value}',
        );
      }
    });

    testWidgets(
      'Pie and Donut route to the same widget with a different hole',
      (WidgetTester tester) async {
        await pumpSection(tester, section);

        // The two options share a routed type, so a picker that ignored the
        // schema and kept re-rendering the previous figure would still pass the
        // walk above. The hole radius is what separates them.
        await pickDropdown<String>(tester, _schemaPicker, 'Donut Chart');
        final double donut = tester
            .widget<FluentDonutChart>(find.byType(FluentDonutChart))
            .innerRadius;
        expect(donut, greaterThan(1));

        await pickDropdown<String>(tester, _schemaPicker, 'Pie Chart');
        expect(
          tester
              .widget<FluentDonutChart>(find.byType(FluentDonutChart))
              .innerRadius,
          lessThan(donut),
          reason: 'a pie is a donut whose hole the schema closed',
        );
      },
    );

    testWidgets('the two hand-built cells leave the declarative shell behind', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.byType(FluentDeclarativeChart), findsOneWidget);

      // Gauge and Funnel are the two routed kinds the page builds by hand,
      // because both need a bounded height the declarative shell never passes
      // down. The absent shell is how a reader knows which branch ran.
      for (final String option in <String>['Gauge Chart', 'Funnel Chart']) {
        await pickDropdown<String>(tester, _schemaPicker, option);
        expect(
          find.byType(FluentDeclarativeChart),
          findsNothing,
          reason: '"$option" is a hand-built cell, not a routed figure',
        );
      }

      await pickDropdown<String>(tester, _schemaPicker, 'Area Chart');
      expect(find.byType(FluentDeclarativeChart), findsOneWidget);
    });

    testWidgets('picking a schema reseeds the legend selection field', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(editedText(tester, _legendField), '["a"]');

      await pickDropdown<String>(tester, _schemaPicker, 'Donut Chart');
      expect(
        editedText(tester, _legendField),
        '["Cadillac"]',
        reason:
            "each schema carries its own selectedLegends and the field "
            'must follow the schema, not keep the last one',
      );

      await pickDropdown<String>(tester, _schemaPicker, 'Area Chart');
      expect(editedText(tester, _legendField), '["a"]');
      await expectCleanTeardown(tester, section.id);
    });

    testWidgets('the schema picker commits under a real mouse', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // The primary knob of the page. A listbox row can be dismissible but not
      // selectable under a real pointer — the press travels two pixels and a
      // scrollable's drag recogniser may claim it — which `tester.tap` cannot
      // see, and this demo lives inside a scroll view.
      await mouseClick(tester, _schemaPicker);
      expect(
        find.text('Sankey Chart'),
        findsWidgets,
        reason: 'a mouse press on the trigger must open the listbox',
      );

      await mouseClick(tester, find.text('Sankey Chart').last);
      expect(
        tester.widget<FluentDropdown<String>>(_schemaPicker).value,
        'sankeychart',
        reason: 'a mouse press on a row must commit, not just dismiss',
      );
      expect(find.byType(FluentSankeyChart), findsOneWidget);
    });
  });

  group('colourway picker', () {
    testWidgets('the palette dropdown repaints the series', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // The area schema declares its own trace colours, so `Default` must let
      // them through and `Builtin` must overrule them. Reading the legend
      // swatches rather than the dropdown proves the colourway reached the
      // transformer instead of stopping at the picker's own field.
      final List<Color> schemaColours = _seriesColours(tester);
      expect(schemaColours, hasLength(4));

      await pickDropdown<FluentPlotlyColorway>(
        tester,
        _colourPicker,
        'Builtin',
      );
      final List<Color> builtin = _seriesColours(tester);
      expect(
        builtin,
        isNot(schemaColours),
        reason: 'Builtin must ignore the schema colours entirely',
      );

      await pickDropdown<FluentPlotlyColorway>(
        tester,
        _colourPicker,
        'Default',
      );
      expect(
        _seriesColours(tester),
        schemaColours,
        reason: 'turning the knob back must restore the schema colours',
      );
    });

    testWidgets('the reserved third colourway behaves as Builtin', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final List<Color> schemaColours = _seriesColours(tester);

      await pickDropdown<FluentPlotlyColorway>(
        tester,
        _colourPicker,
        'Builtin',
      );
      final List<Color> builtin = _seriesColours(tester);

      await pickDropdown<FluentPlotlyColorway>(
        tester,
        _colourPicker,
        'Override',
      );
      expect(_seriesColours(tester), builtin);
      expect(_seriesColours(tester), isNot(schemaColours));
    });
  });

  group('legend selection', () {
    testWidgets('the field filters the chart it names', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(_selectedSeries(tester), <String>['a']);

      await typeAndBlur(tester, _legendField, '["c"]');
      expect(
        _selectedSeries(tester),
        <String>['c'],
        reason: 'the field is the chart\'s selection, not a readout beside it',
      );
      expect(_dimmedSeries(tester), <String>['a', 'b', 'd']);

      await typeAndBlur(tester, _legendField, '');
      expect(
        _selectedSeries(tester),
        isEmpty,
        reason: 'emptying the field must clear the filter',
      );
      expect(_dimmedSeries(tester), isEmpty);
    });

    testWidgets('clicking a legend reports back to the field', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(editedText(tester, _legendField), '["a"]');

      await mouseClick(
        tester,
        find.descendant(
          of: find.byType(FluentChartLegend),
          matching: find.text('B'),
        ),
      );
      expect(_selectedSeries(tester), <String>[
        'b',
      ], reason: 'the click must reach the strip');
      // Upstream spreads `legendProps` — the selection and its change handler —
      // into every non-annotation chart, single-plot figures included, so a
      // click round-trips through `onSchemaChange` and back into this field.
      // Without it the field and the chart hold different selections, and the
      // next remount (a colourway change, a schema change) silently throws the
      // click away.
      expect(
        editedText(tester, _legendField),
        '["b"]',
        reason: 'clicking a legend must round-trip through onSchemaChange',
      );
    });
  });

  group('show more', () {
    testWidgets('the switch swaps the gallery for the load-more branch', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.text('Show few'), findsOneWidget);
      expect(find.text('Load more'), findsNothing);
      expect(_downloadButton(tester).onPressed, isNotNull);

      await tapAndSettle(tester, find.byType(FluentSwitch), what: 'Show more');
      expect(find.text('Show more'), findsOneWidget);
      expect(
        find.text('More examples could not be loaded.'),
        findsOneWidget,
        reason:
            'the showroom ships no network client, so the fetch resolves '
            'with nothing and the story falls through to its own branch',
      );
      expect(
        find.byType(FluentDeclarativeChart),
        findsNothing,
        reason: 'the figure gives way to the fetched gallery',
      );
      expect(find.text('Load more'), findsOneWidget);
      expect(
        _downloadButton(tester).onPressed,
        isNull,
        reason: 'there is no chart left to export',
      );

      await tapAndSettle(tester, find.byType(FluentSwitch), what: 'Show few');
      expect(find.text('Show few'), findsOneWidget);
      expect(find.byType(FluentDeclarativeChart), findsOneWidget);
      expect(_downloadButton(tester).onPressed, isNotNull);
    });

    testWidgets('the load-more branch shows a spinner while it is loading', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await tester.ensureVisible(find.byType(FluentSwitch));
      await settle(tester);

      // Deliberately one frame, not `settle`: the fetch resolves in a
      // post-frame callback, so the loading branch is on screen for exactly the
      // frame after the press and a settled tap would never see it at all.
      await tester.tap(find.byType(FluentSwitch));
      await tester.pump();
      expect(find.byType(FluentSpinner), findsWidgets);
      expect(find.text('Loading'), findsOneWidget);
      expect(
        tester
            .widgetList<FluentButton>(find.byType(FluentButton))
            .any((FluentButton button) => button.onPressed == null),
        isTrue,
        reason: 'the Load more button must disable itself while it loads',
      );

      await settle(tester);
      expect(find.byType(FluentSpinner), findsNothing);
      expect(find.text('Load more'), findsOneWidget);
    });

    testWidgets('the Load more button re-runs the fetch', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await tapAndSettle(tester, find.byType(FluentSwitch), what: 'Show more');

      await tester.ensureVisible(find.text('Load more'));
      await settle(tester);
      await tester.tap(find.text('Load more'));
      await tester.pump();
      expect(
        find.text('Loading'),
        findsOneWidget,
        reason: 'the button must start a fetch of its own, not sit inert',
      );

      await settle(tester);
      expect(find.text('Load more'), findsOneWidget);
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('export', () {
    testWidgets('Download rasterises the chart and reports its size', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.textContaining('Exported'), findsNothing);

      await tester.ensureVisible(find.text('Download'));
      await settle(tester);
      // Inside `runAsync`, because the export bottoms out in
      // `RenderRepaintBoundary.toImage`: its future is driven by the real event
      // loop, and a press dispatched under the fake one starts a rasterisation
      // that can never complete.
      await tester.runAsync(() => tester.tap(find.text('Download')));

      // Polled, not slept. A fixed wait here was flaky: the rasterisation runs
      // on the REAL event loop, so its latency scales with machine load, and a
      // 300ms budget that is ample for this file alone is not ample inside a
      // full-suite run. Each turn of the loop has to leave `runAsync` to pump,
      // because the result arrives via `setState` and the tree does not rebuild
      // while real async work is in flight.
      final exported = find.textContaining(
        RegExp(r'^Exported [1-9]\d* bytes$'),
      );
      for (var i = 0; i < 60 && exported.evaluate().isEmpty; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await settle(tester);
      }

      expect(
        exported,
        findsOneWidget,
        reason: 'the export must produce real PNG bytes, not an empty buffer',
      );
    });

    testWidgets('Download is disabled for the two hand-built cells', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(_downloadButton(tester).onPressed, isNotNull);

      // Neither cell is registered with the controller, so an enabled button
      // here would throw a StateError rather than export anything.
      await pickDropdown<String>(tester, _schemaPicker, 'Gauge Chart');
      expect(_downloadButton(tester).onPressed, isNull);

      await pickDropdown<String>(tester, _schemaPicker, 'Funnel Chart');
      expect(_downloadButton(tester).onPressed, isNull);

      await pickDropdown<String>(tester, _schemaPicker, 'Area Chart');
      expect(_downloadButton(tester).onPressed, isNotNull);
    });
  });

  group('instrumentation', () {
    testWidgets('routing to the heatmap prints nothing to the console', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // A leftover development probe sits inside the heatmap's cell loop, so
      // choosing this option writes one line per rectangle on every frame. It
      // is wrapped in an `assert`, which is what makes it invisible to a
      // release build and to anyone reading the rendered page — capturing
      // `print` is the only way a test can see it at all.
      final List<String> printed = <String>[];
      await runZoned(
        () async {
          await pickDropdown<String>(tester, _schemaPicker, 'Heatmap Chart');
        },
        zoneSpecification: ZoneSpecification(
          print: (Zone self, ZoneDelegate parent, Zone zone, String line) =>
              printed.add(line),
        ),
      );

      // The count and not the list: a failure that dumps eight hundred
      // identical lines buries its own message.
      expect(
        printed.length,
        0,
        reason:
            'the heatmap wrote to the console, starting '
            '"${printed.firstOrNull}"',
      );
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

/// The chart kind each entry of the schema picker must resolve to.
///
/// Upstream's `DEFAULT_OPTIONS`, in its own order, paired with the widget the
/// Plotly router sends it to. Written out rather than derived, because the
/// point of the walk is to catch a route that silently changed.
const Map<String, Type> _routes = <String, Type>{
  'Area Chart': FluentAreaChart,
  'Donut Chart': FluentDonutChart,
  'Gauge Chart': FluentGaugeChart,
  'Heatmap Chart': FluentHeatMapChart,
  'HorizontalBar Chart': FluentHorizontalBarChartWithAxis,
  'Line Chart': FluentLineChart,
  'Pie Chart': FluentDonutChart,
  'Sankey Chart': FluentSankeyChart,
  'VerticalBar Chart': FluentVerticalStackedBarChart,
  'VerticalBar Histogram Chart': FluentVerticalBarChart,
  'Chart Table': FluentChartTable,
  'Scatter Chart': FluentScatterChart,
  'Gantt Chart': FluentGanttChart,
  'Funnel Chart': FluentFunnelChart,
};

/// The schema picker.
Finder get _schemaPicker => find.byType(FluentDropdown<String>);

/// The colourway picker.
Finder get _colourPicker => find.byType(FluentDropdown<FluentPlotlyColorway>);

/// The "Current Legend selection" field, which is both the demo's readout and
/// the value the figure is rebuilt from.
Finder get _legendField => find.byType(FluentInput);

/// The Download button, found through its label rather than by index: the
/// button row grows a second entry as soon as Show more is on.
FluentButton _downloadButton(WidgetTester tester) =>
    tester.widget<FluentButton>(
      find.ancestor(
        of: find.text('Download'),
        matching: find.byType(FluentButton),
      ),
    );

/// The colour each series came out of the transformer with.
///
/// The legend swatch is where a colourway reaches the paint; the picker's own
/// value says nothing about whether the transformer ever read it.
List<Color> _seriesColours(WidgetTester tester) => <Color>[
  for (final FluentChartLegendRow row in _legendRows(tester)) row.item.color,
];

/// The series the chart is rendering as selected.
List<String> _selectedSeries(WidgetTester tester) => <String>[
  for (final FluentChartLegendRow row in _legendRows(tester))
    if (row.selected) row.item.title,
];

/// The series the chart is rendering in its filtered-out treatment.
List<String> _dimmedSeries(WidgetTester tester) => <String>[
  for (final FluentChartLegendRow row in _legendRows(tester))
    if (row.dimmed) row.item.title,
];

List<FluentChartLegendRow> _legendRows(WidgetTester tester) => tester
    .widgetList<FluentChartLegendRow>(find.byType(FluentChartLegendRow))
    .toList();
