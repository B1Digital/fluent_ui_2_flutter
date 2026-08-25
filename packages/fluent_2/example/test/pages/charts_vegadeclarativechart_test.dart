import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// VegaDeclarativeChart's page is one section with four controls over a chart
/// that is *specified*, not built: a Show more/few switch, a Category picker, a
/// Chart Type picker holding all twenty-five inline specifications, and a
/// width/height pair. Every assertion below reads the rendered preview — the
/// widget the Vega-Lite spec routed to, the box it was laid out in, the numbers
/// written back into the spec, the JSON pane beside it — because those are the
/// only places a picker's value proves it went anywhere.
void main() {
  const String page = 'charts-vegadeclarativechart';
  final DocsSection section = sectionOf('charts-vegadeclarativechart--default');

  group('chart type picker', () {
    testWidgets('all twenty-five specifications render without an error box', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final List<FluentDropdownOption<String>> options = tester
          .widget<FluentDropdown<String>>(_chartTypePicker)
          .options;
      expect(options, hasLength(25));

      // Walking the whole list rather than a sample: the ErrorBoundary is the
      // page's own fallback for a spec the renderer cannot route, so a
      // regression in any one transformer shows up here as a red box rather
      // than as a crash, and a sampled walk would miss nineteen of them.
      for (final FluentDropdownOption<String> option in options) {
        final String label = (option.label as Text).data!;
        await pickDropdown<String>(tester, _chartTypePicker, label);
        expect(
          _preview(tester).key,
          ValueKey<String>('${option.value}-600-400'),
          reason: '"$label" must remount the preview on its own key',
        );
        expect(
          find.text('Error rendering chart:'),
          findsNothing,
          reason: '"$label" fell through to the ErrorBoundary',
        );
      }
    });

    testWidgets('the routed widget follows the mark the spec asks for', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // The remount key proves the picker moved; only the routed widget proves
      // the *spec* was read. These five cover five different Vega-Lite marks.
      for (final MapEntry<String, Type> route in _routes.entries) {
        await pickDropdown<String>(tester, _chartTypePicker, route.key);
        expect(
          find.byType(route.value),
          findsOneWidget,
          reason: '"${route.key}" must render a ${route.value}',
        );
      }
    });

    testWidgets('the JSON pane shows the specification being rendered', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(
        editedText(tester, _schemaPane),
        contains('Ad click-through rate analysis'),
      );

      await pickDropdown<String>(tester, _chartTypePicker, 'Co2EmissionsArea');
      expect(
        editedText(tester, _schemaPane),
        contains('CO2 emissions over time'),
        reason:
            'the read-only pane is the demo\'s window onto the spec; a '
            'picker that only moved the chart would leave it stale',
      );
      await expectCleanTeardown(tester, section.id);
    });

    testWidgets('the chart type picker commits under a real mouse', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // The primary knob of the page. Its listbox is 300 wide inside a demo
      // that scrolls in both axes, and a press whose two-pixel travel a
      // scrollable claims never reaches the row — a dismissible-but-not-
      // selectable popup that `tester.tap` cannot tell apart from a working one.
      await mouseClick(tester, _chartTypePicker);
      expect(
        find.text('BugPriorityDonut'),
        findsWidgets,
        reason: 'a mouse press on the trigger must open the listbox',
      );

      await mouseClick(tester, find.text('BugPriorityDonut').last);
      expect(
        tester.widget<FluentDropdown<String>>(_chartTypePicker).value,
        'bugPriorityDonut',
        reason: 'a mouse press on a row must commit, not just dismiss',
      );
      expect(find.byType(FluentDonutChart), findsOneWidget);
    });
  });

  group('size fields', () {
    testWidgets('the width field resizes the preview and rewrites the spec', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(_previewSize(tester).width, 600);

      await typeAndBlur(tester, _widthField, '900');
      expect(
        _previewSize(tester).width,
        900,
        reason: 'the field must resize the box the chart is laid out in',
      );
      expect(
        _preview(tester).chartSchema.vegaLiteSpec['width'],
        900,
        reason: 'upstream writes the same number into the spec it renders',
      );
      expect(
        _preview(tester).key,
        const ValueKey<String>('adCtrScatter-900-400'),
      );
      expect(
        _previewSize(tester).height,
        400,
        reason: 'the width field must not touch the height',
      );

      await typeAndBlur(tester, _widthField, '600');
      expect(_previewSize(tester).width, 600);
    });

    testWidgets('the height field resizes the preview and rewrites the spec', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(_previewSize(tester).height, 400);

      await typeAndBlur(tester, _heightField, '250');
      expect(_previewSize(tester).height, 250);
      expect(_preview(tester).chartSchema.vegaLiteSpec['height'], 250);
      expect(_previewSize(tester).width, 600);

      await typeAndBlur(tester, _heightField, '400');
      expect(_previewSize(tester).height, 400);
    });

    testWidgets('a size that is not a positive number is refused', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // Both are free-text fields, so every intermediate keystroke of "900" is
      // also submitted — including the empty string the field passes through on
      // its way there. Keeping the last good number is what stops the preview
      // collapsing to nothing mid-edit.
      for (final String rubbish in <String>['', '0', '-40', 'wide']) {
        await typeAndBlur(tester, _widthField, rubbish);
        expect(
          _previewSize(tester).width,
          600,
          reason: '"$rubbish" is not a width and must be ignored',
        );
      }
    });
  });

  group('show more', () {
    testWidgets('the switch widens the category list and rewrites the blurb', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(
        find.text('Vega-Lite Declarative Chart - 25 Schemas'),
        findsOneWidget,
      );
      expect(find.text('Show few'), findsOneWidget);
      expect(
        tester.widget<FluentDropdown<String>>(_categoryPicker).options,
        hasLength(1),
        reason: 'in "show few" the Category list offers All alone',
      );
      expect(find.textContaining('Enable "Show more"'), findsOneWidget);

      await tapAndSettle(tester, find.byType(FluentSwitch), what: 'Show more');
      expect(find.text('Show more'), findsOneWidget);
      expect(
        tester.widget<FluentDropdown<String>>(_categoryPicker).options,
        hasLength(10),
        reason: 'All plus the nine categories the inline schemas fall into',
      );
      expect(
        find.textContaining('Use "Load more"'),
        findsOneWidget,
        reason: 'the blurb under the heading must follow the switch',
      );
    });

    testWidgets('turning the switch back resets the category and the chart', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await pickDropdown<String>(tester, _chartTypePicker, 'Co2EmissionsArea');
      await tapAndSettle(tester, find.byType(FluentSwitch), what: 'Show more');
      await pickDropdown<String>(tester, _categoryPicker, 'Climate (4)');

      await tapAndSettle(tester, find.byType(FluentSwitch), what: 'Show few');
      expect(
        tester.widget<FluentDropdown<String>>(_categoryPicker).value,
        'All',
        reason:
            'the narrowed list no longer holds Climate, so the selection '
            'has to come back to All or the dropdown holds a dead value',
      );
      expect(
        _preview(tester).key,
        const ValueKey<String>('adCtrScatter-600-400'),
        reason: 'leaving "show more" rewinds the gallery to its first schema',
      );
      expect(
        editedText(tester, _schemaPane),
        contains('Ad click-through rate analysis'),
      );
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('category picker', () {
    testWidgets('a category records the choice and leaves the gallery whole', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await tapAndSettle(tester, find.byType(FluentSwitch), what: 'Show more');

      // Upstream reads the selection and then never filters on it —
      // `const filteredOptions = currentOptions` — so an unchanged Chart Type
      // list is the ported behaviour rather than a knob that lost its wire.
      // Asserting it pins the parity: if this page ever starts filtering, this
      // test is where the divergence surfaces.
      await mouseClick(tester, _categoryPicker);
      await mouseClick(tester, find.text('Healthcare (2)').last);
      expect(
        tester.widget<FluentDropdown<String>>(_categoryPicker).value,
        'Healthcare',
      );
      expect(
        tester.widget<FluentDropdown<String>>(_chartTypePicker).options,
        hasLength(25),
      );
      expect(
        _preview(tester).key,
        const ValueKey<String>('adCtrScatter-600-400'),
      );
    });
  });

  group('page content', () {
    testWidgets('the summary lists every category and every feature', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(
        find.text('Chart Categories (25 Total):', skipOffstage: false),
        findsOneWidget,
      );
      // Nine category tallies, each rendered as a `Text.rich` ending in its own
      // count. Anchored at the end of the string because the nine feature
      // bullets below them also say "charts", and a bare `contains` would count
      // eighteen and call a half-built list whole.
      expect(
        find.textContaining(RegExp(r'\d+ charts$'), skipOffstage: false),
        findsNWidgets(9),
      );
      expect(
        find.text('Features Supported:', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.textContaining('Donut Charts:', skipOffstage: false),
        findsOneWidget,
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

/// Five Vega-Lite marks and the Fluent chart each must route to.
const Map<String, Type> _routes = <String, Type>{
  'ApiResponseLine': FluentLineChart,
  'CategorySalesStacked': FluentVerticalStackedBarChart,
  'ChannelDistributionDonut': FluentDonutChart,
  'AttendanceHeatmap': FluentHeatMapChart,
  'Co2EmissionsArea': FluentAreaChart,
};

/// The control inside the [FluentField] labelled [label].
///
/// The page declares two `FluentDropdown<String>`s and two `FluentInput`s, so
/// an index into either type would silently follow a reordering of the control
/// strip. The field label is the one thing that names which number a control
/// drives.
Finder _controlIn(String label, Type type) => find.descendant(
  of: find
      .ancestor(of: find.text(label), matching: find.byType(FluentField))
      .first,
  matching: find.byType(type),
);

Finder get _categoryPicker => _controlIn('Category', FluentDropdown<String>);

Finder get _chartTypePicker => _controlIn('Chart Type', FluentDropdown<String>);

Finder get _widthField => _controlIn('Width (px)', FluentInput);

Finder get _heightField => _controlIn('Height (px)', FluentInput);

/// The read-only JSON pane.
Finder get _schemaPane => find.byType(FluentTextarea);

/// The preview widget, whose key, spec and measured box are what every knob on
/// this page has to reach.
FluentVegaDeclarativeChart _preview(WidgetTester tester) =>
    tester.widget<FluentVegaDeclarativeChart>(
      find.byType(FluentVegaDeclarativeChart),
    );

/// The box the preview was actually laid out in.
Size _previewSize(WidgetTester tester) =>
    tester.getSize(find.byType(FluentVegaDeclarativeChart));
