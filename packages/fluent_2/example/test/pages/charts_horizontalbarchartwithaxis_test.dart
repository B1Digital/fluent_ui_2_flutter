import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// HorizontalBarChartWithAxis's five demos carry the densest control strips on
/// the charts pages: size sliders, a data-size slider, two axis radios, a
/// padding checkbox that gates a padding slider, three switches and a
/// sixteen-option ordering dropdown.
///
/// None of it is in the widget tree. The chart is one [CustomPaint] over a
/// [FluentCartesianChartPainter], and everything a knob changes arrives either
/// as a field on that painter's delegate, as a [FluentCartesianChartProps]
/// flag, or as the solved [FluentCartesianLayout]. So the helpers at the foot
/// of this file read the painter, and the assertions are about what it was
/// handed — not about what the demo's own `setState` recorded.
void main() {
  const String page = 'charts-horizontalbarchartwithaxis';

  group('horizontal bar with axis basic', () {
    final DocsSection section = sectionOf(
      'charts-horizontalbarchartwithaxis--horizontal-bar-with-axis-basic',
    );

    testWidgets('the two size sliders resize the plot box', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(_chartSize(tester), const Size(650, 350));

      await dropSliderAt(tester, _slider('Change Width'), 1);
      expect(_chartSize(tester), const Size(1000, 350));

      await dropSliderAt(tester, _slider('Change Height'), 1);
      expect(_chartSize(tester), const Size(1000, 1000));

      await dropSliderAt(tester, _slider('Change Width'), 0);
      await dropSliderAt(tester, _slider('Change Height'), 0);
      expect(
        _chartSize(tester),
        const Size(200, 200),
        reason: 'both rails must run back down to their minimum',
      );
      await expectCleanTeardown(tester, section.id);
    });

    testWidgets('the height slider commits under a real mouse', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // The rails sit above a horizontally scrollable chart box, so a press
      // whose travel is claimed by that scrollable's drag recogniser would
      // never reach the rail. `tester.tap` synthesises no travel and cannot
      // catch it.
      await mouseClick(tester, _slider('Change Height'));
      expect(
        _chartSize(tester).height,
        greaterThan(350),
        reason: 'a press near the middle of a 200..1000 rail must raise 350',
      );
    });

    testWidgets('the single-colour checkbox collapses the bar palette', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(
        _fills(tester).toSet(),
        hasLength(4),
        reason: 'four points, four data-viz colours',
      );

      await mouseClick(tester, find.byType(FluentCheckbox));
      expect(
        tester.widget<FluentCheckbox>(find.byType(FluentCheckbox)).checked,
        isTrue,
      );
      // `HorizontalBarChartWithAxis.tsx:432` is
      // `point.color && !useSingleColor ? point.color : startColor`: with the
      // flag set, a point's own colour is deliberately discarded so every bar
      // takes the one palette entry. Every point in this story carries a
      // colour, so this flag has nothing else to change — collapsing the
      // palette IS the demo.
      expect(
        _fills(tester).toSet(),
        hasLength(1),
        reason: 'use single color must override each point\'s own colour',
      );

      await mouseClick(tester, find.byType(FluentCheckbox));
      expect(_fills(tester).toSet(), hasLength(4));
    });

    testWidgets('the rounded-corners switch reaches the painter', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(_delegate(tester).roundCorners, isFalse);

      await mouseClick(tester, find.text('Rounded Corners OFF'));
      expect(find.text('Rounded Corners ON'), findsOneWidget);
      expect(
        _delegate(tester).roundCorners,
        isTrue,
        reason: 'the radius is applied at paint time, not in the widget tree',
      );

      await mouseClick(tester, find.text('Rounded Corners ON'));
      expect(_delegate(tester).roundCorners, isFalse);
    });

    testWidgets(
      'the multi-legend switch turns replace-select into add-select',
      (WidgetTester tester) async {
        await pumpSection(tester, section);

        await mouseClick(tester, find.text('Oranges'));
        expect(_delegate(tester).selectedLegends, <String>['Oranges']);
        await mouseClick(tester, find.text('Dogs'));
        expect(
          _delegate(tester).selectedLegends,
          <String>['Dogs'],
          reason: 'single mode replaces the selection rather than adding to it',
        );

        await mouseClick(tester, find.text('Select multiple legends OFF'));
        expect(find.text('Select multiple legends ON'), findsOneWidget);

        await mouseClick(tester, find.text('Oranges'));
        expect(
          _delegate(tester).selectedLegends,
          <String>['Dogs', 'Oranges'],
          reason:
              'multiple mode must keep the legend that was already selected',
        );
        await mouseClick(tester, find.text('Dogs'));
        expect(
          _delegate(tester).selectedLegends,
          <String>['Oranges'],
          reason: 'a second press on a selected legend removes just that one',
        );
      },
    );

    testWidgets('keyboard traversal walks the bars and reads each one out', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.byType(FluentChartPopover), findsNothing);

      _focusChart(tester);
      await settle(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await settle(tester);

      expect(find.byType(FluentChartPopover), findsOneWidget);
      expect(_popoverText(tester), containsAll(<String>['Oranges', '10%']));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await settle(tester);
      expect(
        _popoverText(tester),
        isNot(containsAll(<String>['Oranges', '10%'])),
        reason: 'a second step must move to another bar, not restate the first',
      );
    });

    testWidgets('the callout radio commits, though the port keeps it inert', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Rect before = _plot(tester);
      final List<Color> fills = _fills(tester);

      // Upstream's handler for this pair only flips a boolean, and the
      // `onRenderCalloutPerHorizontalBar` it would have driven is commented
      // out in the story itself. The port says so in a comment and keeps the
      // same inert behaviour, so the honest assertion is that the control
      // commits and that the chart is deliberately untouched.
      await mouseClick(tester, find.text('Custom Callout Example'));
      expect(
        tester
            .widget<FluentRadioGroup<String>>(
              find.byType(FluentRadioGroup<String>),
            )
            .value,
        'Custom Callout Example',
      );
      expect(_plot(tester), before);
      expect(_fills(tester), fills);
    });
  });

  group('horizontal bar with axis string axis tooltip', () {
    final DocsSection section = sectionOf(
      'charts-horizontalbarchartwithaxis--horizontal-bar-with-axis-string-'
      'axis-tooltip',
    );

    testWidgets('expanding the y ticks widens the gutter they sit in', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // The default arm truncates instead of reserving, so the left margin is
      // the bare 40 of `_getDefaultMargins`.
      expect(_painter(tester).props.showYAxisLablesTooltip, isTrue);
      expect(_plot(tester).left, 40);

      await mouseClick(tester, find.text('Expand Y Axis Ticks'));
      expect(_painter(tester).props.showYAxisLables, isTrue);
      expect(
        _plot(tester).left,
        greaterThan(40),
        reason:
            'expanded ticks reserve max(40, longest label + 20) on the left, '
            'and "String Three" is wider than 20',
      );
      expect(
        _plot(tester).right,
        _painter(tester).layout.size.width - 20,
        reason: 'only the left gutter moves; the plot loses width, not sides',
      );

      await mouseClick(tester, find.text('Show Tooltip at Y Axis Ticks'));
      expect(
        _plot(tester).left,
        40,
        reason: 'switching back to the tooltip arm must give the gutter back',
      );
      await expectCleanTeardown(tester, section.id);
    });

    testWidgets('the rounded-corners switch reaches the painter', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(_delegate(tester).roundCorners, isFalse);

      await tapAndSettle(tester, find.text('Rounded Corners OFF'));
      expect(_delegate(tester).roundCorners, isTrue);

      await tapAndSettle(tester, find.text('Rounded Corners ON'));
      expect(_delegate(tester).roundCorners, isFalse);
    });
  });

  group('horizontal bar with axis dynamic', () {
    final DocsSection section = sectionOf(
      'charts-horizontalbarchartwithaxis--horizontal-bar-with-axis-dynamic',
    );

    testWidgets('the data-size slider changes how many bars are plotted', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(_delegate(tester).points, hasLength(5));

      await dropSliderAt(tester, _slider('Change Data Size'), 1);
      expect(
        _delegate(tester).points,
        hasLength(50),
        reason: 'the rail tops out at 50 and the chart must follow it there',
      );

      // Where a press inside the rail's own padding lands is the slider's
      // business; that the chart carries exactly as many bars as the rail
      // reports is this demo's. Reading the rail is what keeps the assertion
      // about the second thing.
      await dropSliderAt(tester, _slider('Change Data Size'), 0.1);
      final int size = _sliderValue(tester, 'Change Data Size');
      expect(size, lessThan(50));
      expect(_delegate(tester).points, hasLength(size));
      await expectCleanTeardown(tester, section.id);
    });

    testWidgets('the width slider resizes the plot box', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(_chartSize(tester).width, 650);

      await mouseClick(tester, _slider('Change Width'));
      expect(_chartSize(tester).width, isNot(650));

      await dropSliderAt(tester, _slider('Change Width'), 0);
      expect(_chartSize(tester).width, 200);
    });

    testWidgets('the axis-type radio retypes the axis and unlocks the padding '
        'controls', (WidgetTester tester) async {
      await pumpSection(tester, section);
      expect(_delegate(tester).yAxisType, FluentChartAxisType.numeric);
      expect(
        tester.widget<FluentCheckbox>(find.byType(FluentCheckbox)).onChanged,
        isNull,
        reason: 'yAxisPadding is meaningless on a numeric axis',
      );
      expect(
        tester.widget<FluentSlider>(_slider('yAxisPadding')).onChanged,
        isNull,
      );

      await mouseClick(tester, find.text('String'));
      expect(
        _delegate(tester).yAxisType,
        FluentChartAxisType.category,
        reason: 'string labels must retype the y axis, not just relabel it',
      );
      expect(
        tester.widget<FluentCheckbox>(find.byType(FluentCheckbox)).onChanged,
        isNotNull,
      );

      await mouseClick(tester, find.text('Number'));
      expect(_delegate(tester).yAxisType, FluentChartAxisType.numeric);
    });

    testWidgets('the padding checkbox hands the slider through to the band', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await mouseClick(tester, find.text('String'));

      // Cleared, the demo passes the chart's own 0.5 default rather than the
      // slider's 0 — so ticking the box is itself a visible change.
      expect(_delegate(tester).yAxisPadding, 0.5);

      await mouseClick(tester, find.byType(FluentCheckbox));
      expect(_delegate(tester).yAxisPadding, 0);
      expect(
        tester.widget<FluentSlider>(_slider('yAxisPadding')).onChanged,
        isNotNull,
        reason: 'the checkbox is the only thing that enables the rail',
      );

      await dropSliderAt(tester, _slider('yAxisPadding'), 0.8);
      expect(_delegate(tester).yAxisPadding, 0.8);
      expect(
        find.text('0.8'),
        findsOneWidget,
        reason: 'the readout beside the rail must agree with the chart',
      );

      await mouseClick(tester, find.byType(FluentCheckbox));
      expect(
        _delegate(tester).yAxisPadding,
        0.5,
        reason: 'clearing the box must put the default back, not keep 0.8',
      );
    });

    testWidgets('the change-data button redraws with fresh values', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final List<double> before = _xValues(tester);

      await tapAndSettle(tester, find.text('Change data'));
      final List<double> after = _xValues(tester);
      expect(after, hasLength(before.length));
      expect(
        after,
        isNot(before),
        reason: 'the button must advance the generator, not re-emit it',
      );
    });

    testWidgets('the rounded-corners switch reaches the painter', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await tapAndSettle(tester, find.text('Rounded Corners OFF'));
      expect(_delegate(tester).roundCorners, isTrue);
      await tapAndSettle(tester, find.text('Rounded Corners ON'));
      expect(_delegate(tester).roundCorners, isFalse);
    });
  });

  group('horizontal bar with axis negative', () {
    final DocsSection section = sectionOf(
      'charts-horizontalbarchartwithaxis--horizontal-bar-with-axis-negative',
    );

    testWidgets('the value axis is drawn through zero, not from it', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(_delegate(tester).groups, hasLength(5));
      expect(
        _painter(tester).xAxis.tickLabels,
        contains(startsWith('-')),
        reason: 'a chart with negative bars must tick below zero',
      );
      expect(
        _painter(tester).yAxisPrimary.tickLabels,
        containsAll(<String>['A', 'B', 'C', 'D', 'E']),
      );
      await expectCleanTeardown(tester, section.id);
    });

    testWidgets('the y-tick radio reaches the chart', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(_painter(tester).props.showYAxisLables, isFalse);
      expect(_painter(tester).props.showYAxisLablesTooltip, isTrue);

      await mouseClick(tester, find.text('Expand Y Axis Ticks'));
      expect(_painter(tester).props.showYAxisLables, isTrue);
      expect(_painter(tester).props.showYAxisLablesTooltip, isFalse);
      // The gutter does not widen here and that is arithmetic, not a broken
      // knob: the reserve is max(40, longest label + 20) and this story's
      // categories are single letters. The tooltip section drives the same
      // pair over "String Three" and proves the geometry follows.

      await mouseClick(tester, find.text('Show Tooltip at Y Axis Ticks'));
      expect(_painter(tester).props.showYAxisLablesTooltip, isTrue);
    });

    testWidgets('the rounded-corners switch reaches the painter', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await tapAndSettle(tester, find.text('Rounded Corners OFF'));
      expect(_delegate(tester).roundCorners, isTrue);
      await tapAndSettle(tester, find.text('Rounded Corners ON'));
      expect(_delegate(tester).roundCorners, isFalse);
    });
  });

  group('horizontal bar with axis category order', () {
    final DocsSection section = sectionOf(
      'charts-horizontalbarchartwithaxis--horizontal-bar-with-axis-category-'
      'order',
    );

    testWidgets('the ordering dropdown reorders the y categories', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder dropdown = find.byType(FluentDropdown<String>);

      // `default` is the one arm that neither sorts nor deduplicates — it is
      // the reversed point list, repeats included — so its length alone
      // separates it from every sorted arm.
      expect(_categories(tester), hasLength(5));

      expect(
        await pickDropdown<String>(tester, dropdown, 'category ascending'),
        'category ascending',
      );
      final List<String> ascending = _categories(tester);
      expect(ascending, <String>['Label 1', 'Label 2']);

      expect(
        await pickDropdown<String>(tester, dropdown, 'category descending'),
        'category descending',
      );
      expect(
        _categories(tester),
        ascending.reversed.toList(),
        reason: 'descending must be the mirror of ascending, not a reshuffle',
      );

      expect(
        await pickDropdown<String>(tester, dropdown, 'total descending'),
        'total descending',
      );
      // Label 2 sums to +175 and Label 1 to -197, so the aggregate order is
      // not the alphabetical one — which is what proves the aggregator ran.
      expect(_categories(tester), <String>['Label 2', 'Label 1']);

      expect(
        await pickDropdown<String>(tester, dropdown, 'default'),
        'default',
      );
      expect(_categories(tester), hasLength(5));
      await expectCleanTeardown(tester, section.id);
    });

    testWidgets('the ordering dropdown commits under a real mouse', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder dropdown = find.byType(FluentDropdown<String>);

      await mouseClick(tester, dropdown);
      expect(
        find.text('category ascending'),
        findsWidgets,
        reason: 'a mouse press on the trigger must open the listbox',
      );

      await mouseClick(tester, find.text('category ascending').last);
      expect(
        tester.widget<FluentDropdown<String>>(dropdown).value,
        'category ascending',
        reason: 'a mouse press on a row must commit, not merely dismiss',
      );
      expect(_categories(tester), <String>['Label 1', 'Label 2']);
    });

    testWidgets('the three sliders size the plot and its data', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(_chartSize(tester), const Size(650, 350));
      expect(find.text('650'), findsOneWidget);

      await dropSliderAt(tester, _slider('Change Width'), 1);
      await dropSliderAt(tester, _slider('Change Height'), 1);
      expect(_chartSize(tester), const Size(1000, 1000));
      expect(find.text('1000'), findsNWidgets(2));

      await dropSliderAt(tester, _slider('Change Data Size'), 0.4);
      final int size = _sliderValue(tester, 'Change Data Size');
      expect(size, isNot(5), reason: 'the rail must have left its initial 5');
      expect(
        _delegate(tester).points,
        hasLength(size),
        reason: 'the chart must carry as many bars as the rail reports',
      );
      expect(
        find.text('$size'),
        findsOneWidget,
        reason: 'the readout beside the rail must agree with the chart',
      );
    });

    testWidgets('the change-data button redraws with fresh values', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final List<double> before = _xValues(tester);

      await mouseClick(tester, find.text('Change data'));
      expect(_xValues(tester), isNot(before));
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

/// The slider whose `semanticLabel` is [semanticLabel].
///
/// Three of these demos declare identical-looking rails side by side, and an
/// index would silently follow a reordering of the control strip; the semantic
/// label is the one thing about a rail that names which number it drives.
Finder _slider(String semanticLabel) => find.byWidgetPredicate(
  (Widget widget) =>
      widget is FluentSlider && widget.semanticLabel == semanticLabel,
  description: 'FluentSlider("$semanticLabel")',
);

/// The whole number the rail named [semanticLabel] currently holds.
int _sliderValue(WidgetTester tester, String semanticLabel) =>
    tester.widget<FluentSlider>(_slider(semanticLabel)).value.round();

/// The painter the chart actually handed the canvas.
///
/// Nothing this page's knobs do reaches the widget tree — the whole chart is
/// one [CustomPaint] — so this is where every assertion has to look.
FluentCartesianChartPainter _painter(WidgetTester tester) =>
    paintersOf<FluentCartesianChartPainter>(tester).single;

FluentHorizontalBarChartWithAxisDelegate _delegate(WidgetTester tester) =>
    _painter(tester).delegate as FluentHorizontalBarChartWithAxisDelegate;

/// The solved plot rectangle, in the chart's own coordinates.
Rect _plot(WidgetTester tester) => _painter(tester).layout.plotRect;

Size _chartSize(WidgetTester tester) =>
    tester.getSize(find.byType(FluentHorizontalBarChartWithAxis));

/// The fill each bar is painted with, in group then in-group order.
///
/// `barColour` is the function `paintSeries` calls per bar, so reading it is
/// reading what was drawn — a palette knob that changed a field without
/// changing this would have changed nothing a viewer can see.
List<Color> _fills(WidgetTester tester) {
  final FluentHorizontalBarChartWithAxisDelegate delegate = _delegate(tester);
  return <Color>[
    for (final FluentHorizontalBarGroup group in delegate.groups)
      for (int i = 0; i < group.points.length; i++)
        delegate.barColour(group.points[i], i),
  ];
}

/// The y-axis category domain, in the order the ordering knob put it in.
List<String> _categories(WidgetTester tester) =>
    _delegate(tester).stringDatasetForYAxisDomain!;

/// Every plotted bar length, in data order.
List<double> _xValues(WidgetTester tester) => _delegate(
  tester,
).points.map((FluentHorizontalBarChartWithAxisDataPoint p) => p.x).toList();

/// The lines the popover is currently showing.
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

/// Gives the chart shell's own focus node the focus, so arrow keys reach it.
///
/// The shell keeps that node private and the demo passes none of its own, so
/// the [Focus] it built is the only handle on it.
void _focusChart(WidgetTester tester) => tester
    .widget<Focus>(
      find
          .descendant(
            of: find.byType(FluentCartesianChart),
            matching: find.byType(Focus),
          )
          .first,
    )
    .focusNode!
    .requestFocus();
