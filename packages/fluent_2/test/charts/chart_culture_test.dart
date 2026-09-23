// Regression for #18: `culture` never reached the Area, VerticalBar,
// HorizontalBarWithAxis and Scatter delegates, so neither their x tick labels
// nor their popover readings were localized, and the stacked popover body
// formatted its rows in the default locale on every chart.
import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget chart) => tester.pumpWidget(
  FluentApp(
    theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
    home: Center(child: SizedBox(width: 700, height: 350, child: chart)),
  ),
);

Finder get _painterFinder => find.byWidgetPredicate(
  (widget) =>
      widget is CustomPaint && widget.painter is FluentCartesianChartPainter,
);

FluentCartesianChartPainter _painter(WidgetTester tester) =>
    tester.widget<CustomPaint>(_painterFinder).painter!
        as FluentCartesianChartPainter;

/// Moves a mouse onto [local], in the cartesian painter's own space.
Future<void> _hover(WidgetTester tester, Offset local) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: Offset.zero);
  addTearDown(gesture.removePointer);
  await gesture.moveTo(tester.getTopLeft(_painterFinder) + local);
  await tester.pumpAndSettle();
  expect(
    find.byType(FluentChartPopover),
    findsOneWidget,
    reason: 'a count guard: the hover must have opened the popover',
  );
}

/// A popover text containing [text], wherever the body put it.
Finder _popoverText(String text) => find.descendant(
  of: find.byType(FluentChartPopover),
  matching: find.textContaining(text),
);

void _expectLocalizedTicks(WidgetTester tester) {
  final painter = _painter(tester);
  expect(
    painter.delegate.culture,
    'de-DE',
    reason: 'the shell reads the culture off the delegate',
  );
  expect(
    painter.xAxis.tickLabels,
    contains('20.000'),
    reason:
        'CartesianChart.tsx:237-277 hands culture to the x axis builders, '
        'so de-DE groups 20000 with a dot; got ${painter.xAxis.tickLabels}',
  );
}

const _series = <FluentLineChartDataPoint>[
  FluentLineChartDataPoint(x: 10000, y: 1),
  FluentLineChartDataPoint(
    x: 15000,
    y: 12345.6,
    yAxisCalloutBreakdown: <String, double>{'part': 23456.7},
  ),
  FluentLineChartDataPoint(x: 20000, y: 2),
];

void main() {
  testWidgets('FluentLineChart formats its stacked rows in culture', (
    tester,
  ) async {
    await _pump(
      tester,
      const FluentLineChart(
        data: FluentChartData(
          lineChartData: <FluentLineChartSeries>[
            FluentLineChartSeries(legend: 'a', data: _series),
          ],
        ),
        culture: 'de-DE',
      ),
    );
    final painter = _painter(tester);
    await _hover(
      tester,
      Offset(painter.xAxis.scale(15000)!, painter.yAxisPrimary.scale(12345.6)!),
    );
    expect(
      _popoverText('a (12.345,6)'),
      findsOneWidget,
      reason: 'ChartPopover.tsx:190 formats the row header in props.culture',
    );
    expect(
      _popoverText('23.456,7'),
      findsOneWidget,
      reason: 'ChartPopover.tsx:259 formats each subcount in props.culture',
    );
  });

  testWidgets('FluentGroupedVerticalBarChart formats its stacked rows', (
    tester,
  ) async {
    await _pump(
      tester,
      const FluentGroupedVerticalBarChart(
        data: <FluentGroupedVerticalBarChartData>[
          FluentGroupedVerticalBarChartData(
            name: 'q1',
            series: <FluentGroupedBarSeriesPoint>[
              FluentGroupedBarSeriesPoint(key: 'k', data: 12345.6, legend: 'a'),
            ],
          ),
        ],
        culture: 'de-DE',
        isCalloutForStack: true,
      ),
    );
    final painter = _painter(tester);
    final xScale = painter.xAxis.scale;
    await _hover(
      tester,
      Offset(
        xScale('q1')! + xScale.bandwidth / 2,
        painter.yAxisPrimary.scale(3000)!,
      ),
    );
    expect(
      _popoverText('12.345,6'),
      findsOneWidget,
      reason: 'ChartPopover.tsx:233 formats each row in props.culture',
    );
  });

  testWidgets('FluentVerticalStackedBarChart formats its stacked rows', (
    tester,
  ) async {
    await _pump(
      tester,
      const FluentVerticalStackedBarChart(
        data: <FluentVerticalStackedBarGroup>[
          FluentVerticalStackedBarGroup(
            xAxisPoint: 'q1',
            chartData: <FluentStackedBarDatum>[
              FluentStackedBarDatum(data: 12345.6, legend: 'a'),
              FluentStackedBarDatum(data: 5000, legend: 'b'),
            ],
          ),
        ],
        culture: 'de-DE',
        isCalloutForStack: true,
      ),
    );
    final painter = _painter(tester);
    final xScale = painter.xAxis.scale;
    await _hover(
      tester,
      Offset(
        xScale('q1')! + xScale.bandwidth / 2,
        painter.yAxisPrimary.scale(3000)!,
      ),
    );
    expect(
      _popoverText('12.345,6'),
      findsOneWidget,
      reason: 'ChartPopover.tsx:233 formats each row in props.culture',
    );
  });

  testWidgets('FluentAreaChart hands culture to the axis and popover', (
    tester,
  ) async {
    await _pump(
      tester,
      const FluentAreaChart(
        data: FluentChartData(
          lineChartData: <FluentLineChartSeries>[
            FluentLineChartSeries(legend: 'a', data: _series),
          ],
        ),
        culture: 'de-DE',
      ),
    );
    _expectLocalizedTicks(tester);
    final painter = _painter(tester);
    await _hover(
      tester,
      Offset(painter.xAxis.scale(15000)!, painter.yAxisPrimary.scale(12345.6)!),
    );
    expect(_popoverText('15.000'), findsOneWidget, reason: 'the x reading');
    expect(_popoverText('12.345,6'), findsOneWidget, reason: 'the y reading');
  });

  testWidgets('FluentVerticalBarChart hands culture to the axis and popover', (
    tester,
  ) async {
    await _pump(
      tester,
      const FluentVerticalBarChart(
        data: <FluentVerticalBarChartDataPoint>[
          FluentVerticalBarChartDataPoint(x: 10000, y: 5000),
          FluentVerticalBarChartDataPoint(x: 15000, y: 12345.6),
          FluentVerticalBarChartDataPoint(x: 20000, y: 7000),
        ],
        culture: 'de-DE',
      ),
    );
    _expectLocalizedTicks(tester);
    final painter = _painter(tester);
    await _hover(
      tester,
      Offset(painter.xAxis.scale(15000)!, painter.yAxisPrimary.scale(3000)!),
    );
    expect(
      _popoverText('12.345,6'),
      findsOneWidget,
      reason: 'ChartPopover.tsx:89 formats YValue in props.culture',
    );
  });

  testWidgets(
    'FluentHorizontalBarChartWithAxis hands culture to the axis and popover',
    (tester) async {
      await _pump(
        tester,
        const FluentHorizontalBarChartWithAxis(
          data: <FluentHorizontalBarChartWithAxisDataPoint>[
            FluentHorizontalBarChartWithAxisDataPoint(x: 12345.6, y: 'beta'),
            FluentHorizontalBarChartWithAxisDataPoint(x: 20000, y: 'gamma'),
          ],
          culture: 'de-DE',
        ),
      );
      _expectLocalizedTicks(tester);
      final painter = _painter(tester);
      final yScale = painter.yAxisPrimary.scale;
      await _hover(
        tester,
        Offset(
          painter.xAxis.scale(3000)!,
          yScale('beta')! + yScale.bandwidth / 2,
        ),
      );
      expect(
        _popoverText('12.345,6'),
        findsOneWidget,
        reason: 'the bar length, formatted the way ChartPopover.tsx:89 does',
      );
    },
  );

  testWidgets('FluentScatterChart hands culture to the axis and popover', (
    tester,
  ) async {
    await _pump(
      tester,
      const FluentScatterChart(
        data: FluentChartData(
          scatterChartData: <FluentScatterChartSeries>[
            FluentScatterChartSeries(
              legend: 's',
              data: <FluentScatterChartDataPoint>[
                FluentScatterChartDataPoint(x: 10000, y: 1),
                FluentScatterChartDataPoint(x: 15000, y: 12345.6),
                FluentScatterChartDataPoint(x: 20000, y: 2),
              ],
            ),
          ],
        ),
        culture: 'de-DE',
      ),
    );
    _expectLocalizedTicks(tester);
    final painter = _painter(tester);
    await _hover(
      tester,
      Offset(painter.xAxis.scale(15000)!, painter.yAxisPrimary.scale(12345.6)!),
    );
    expect(
      _popoverText('15.000'),
      findsOneWidget,
      reason: 'ScatterChart.tsx:546 and ChartPopover.tsx:128 format the x',
    );
    expect(
      _popoverText('12.345,6'),
      findsOneWidget,
      reason: 'ChartPopover.tsx:190 formats the y in props.culture',
    );
  });
}
