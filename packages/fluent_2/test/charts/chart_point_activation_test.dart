import 'dart:ui' show PointerDeviceKind;

import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// A per-point `onClick` reaches the canvas charts only through
/// [FluentChartHitRegion.onActivate], so every chart below is clicked on each
/// of the marks its own delegate declares.
void main() {
  late List<String> hits;
  setUp(() => hits = <String>[]);
  VoidCallback hit(String key) =>
      () => hits.add(key);

  Future<void> pump(WidgetTester tester, Widget chart) async {
    await tester.pumpWidget(
      FluentApp(
        theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
        home: Center(child: SizedBox(width: 600, height: 360, child: chart)),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Clicks the centre of every region the chart's delegate builds, in order.
  ///
  /// A real mouse, not a bare tap: press, dwell, drift 1.5px, release — the
  /// drift is what a hand does between pressing and letting go.
  Future<void> clickEveryMark(WidgetTester tester) async {
    final plot = find
        .descendant(
          of: find.byType(FluentCartesianChart),
          matching: find.byType(CustomPaint),
        )
        .first;
    final painter =
        tester.widget<CustomPaint>(plot).painter!
            as FluentCartesianChartPainter;
    // The shell builds exactly this before calling buildHitRegions.
    final regions = painter.delegate.buildHitRegions(
      FluentCartesianChildContext(
        xScale: painter.xAxis.scale,
        yScalePrimary: painter.yAxisPrimary.scale,
        yScaleSecondary: painter.yAxisSecondary?.scale,
        containerWidth: painter.layout.size.width,
        containerHeight: painter.layout.size.height,
      ),
      painter.layout,
    );
    expect(regions, isNotEmpty);
    for (final region in regions) {
      final gesture = await tester.startGesture(
        tester.getTopLeft(plot) + region.bounds.center,
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump(const Duration(milliseconds: 90));
      await gesture.moveBy(const Offset(1.5, 0));
      await gesture.up();
      await tester.pump();
      await gesture.removePointer();
    }
  }

  testWidgets('VerticalBarChart runs each bar onClick', (tester) async {
    await pump(
      tester,
      FluentVerticalBarChart(
        data: <FluentVerticalBarChartDataPoint>[
          FluentVerticalBarChartDataPoint(x: 'a', y: 10, onClick: hit('a')),
          FluentVerticalBarChartDataPoint(x: 'b', y: 20, onClick: hit('b')),
        ],
      ),
    );
    await clickEveryMark(tester);
    expect(hits, <String>['a', 'b']);
  });

  testWidgets('Enter runs the focused bar onClick', (tester) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    await pump(
      tester,
      FluentVerticalBarChart(
        focusNode: node,
        data: <FluentVerticalBarChartDataPoint>[
          FluentVerticalBarChartDataPoint(x: 'a', y: 10, onClick: hit('a')),
          FluentVerticalBarChartDataPoint(x: 'b', y: 20, onClick: hit('b')),
        ],
      ),
    );
    node.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(hits, <String>['b']);
  });

  testWidgets('HorizontalBarChartWithAxis runs each bar onClick', (
    tester,
  ) async {
    await pump(
      tester,
      FluentHorizontalBarChartWithAxis(
        data: <FluentHorizontalBarChartWithAxisDataPoint>[
          FluentHorizontalBarChartWithAxisDataPoint(
            x: 10,
            y: 'a',
            onClick: hit('a'),
          ),
          FluentHorizontalBarChartWithAxisDataPoint(
            x: 20,
            y: 'b',
            onClick: hit('b'),
          ),
        ],
      ),
    );
    await clickEveryMark(tester);
    expect(hits, unorderedEquals(<String>['a', 'b']));
  });

  testWidgets('HeatMapChart runs each cell onClick', (tester) async {
    await pump(
      tester,
      FluentHeatMapChart(
        data: <FluentHeatMapChartData>[
          FluentHeatMapChartData(
            legend: 'l',
            value: 0,
            data: <FluentHeatMapChartDataPoint>[
              for (final (x, y, value) in <(String, String, double)>[
                ('a', 'p', 1),
                ('b', 'p', 2),
                ('a', 'q', 3),
                ('b', 'q', 4),
              ])
                FluentHeatMapChartDataPoint(
                  x: x,
                  y: y,
                  value: value,
                  onClick: hit('$x$y'),
                ),
            ],
          ),
        ],
        domainValuesForColorScale: const <double>[0, 4],
        rangeValuesForColorScale: const <Color>[
          Color(0xFF000000),
          Color(0xFFFFFFFF),
        ],
      ),
    );
    await clickEveryMark(tester);
    expect(hits, unorderedEquals(<String>['ap', 'bp', 'aq', 'bq']));
  });

  testWidgets('GanttChart runs each bar onClick', (tester) async {
    await pump(
      tester,
      FluentGanttChart(
        data: <FluentGanttChartDataPoint>[
          FluentGanttChartDataPoint(
            x: const FluentGanttSpan(start: 0, end: 10),
            y: 'a',
            onClick: hit('a'),
          ),
          FluentGanttChartDataPoint(
            x: const FluentGanttSpan(start: 2, end: 10),
            y: 'b',
            onClick: hit('b'),
          ),
        ],
      ),
    );
    await clickEveryMark(tester);
    expect(hits, unorderedEquals(<String>['a', 'b']));
  });

  for (final isCalloutForStack in <bool>[false, true]) {
    testWidgets('GroupedVerticalBarChart runs each bar onClick '
        '(isCalloutForStack: $isCalloutForStack)', (tester) async {
      await pump(
        tester,
        FluentGroupedVerticalBarChart(
          isCalloutForStack: isCalloutForStack,
          data: <FluentGroupedVerticalBarChartData>[
            for (final name in <String>['g1', 'g2'])
              FluentGroupedVerticalBarChartData(
                name: name,
                series: <FluentGroupedBarSeriesPoint>[
                  for (final legend in <String>['a', 'b'])
                    FluentGroupedBarSeriesPoint(
                      key: '$name-$legend',
                      data: 10,
                      legend: legend,
                      onClick: hit('$name-$legend'),
                    ),
                ],
              ),
          ],
        ),
      );
      await clickEveryMark(tester);
      // A stack callout merges each group into one keyboard stop, but every
      // rect keeps its own `onClick` (`GroupedVerticalBarChart.tsx:594`).
      expect(hits, unorderedEquals(<String>['g1-a', 'g1-b', 'g2-a', 'g2-b']));
    });
  }

  testWidgets('AreaChart runs each point onDataPointClick', (tester) async {
    await pump(
      tester,
      FluentAreaChart(
        data: FluentChartData(
          lineChartData: <FluentLineChartSeries>[
            FluentLineChartSeries(
              legend: 's',
              data: <FluentLineChartDataPoint>[
                for (final x in <int>[0, 1, 2])
                  FluentLineChartDataPoint(
                    x: x,
                    y: 5,
                    onDataPointClick: hit('$x'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
    await clickEveryMark(tester);
    expect(hits, <String>['0', '1', '2']);
  });

  testWidgets('AreaChart with a missing x value leaves its points inert', (
    tester,
  ) async {
    await pump(
      tester,
      FluentAreaChart(
        data: FluentChartData(
          lineChartData: <FluentLineChartSeries>[
            FluentLineChartSeries(
              legend: 's',
              data: <FluentLineChartDataPoint>[
                for (final x in <int>[0, 1, 2])
                  FluentLineChartDataPoint(
                    x: x,
                    y: 5,
                    onDataPointClick: hit('s$x'),
                  ),
              ],
            ),
            FluentLineChartSeries(
              legend: 't',
              data: <FluentLineChartDataPoint>[
                for (final x in <int>[0, 2])
                  FluentLineChartDataPoint(
                    x: x,
                    y: 5,
                    onDataPointClick: hit('t$x'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
    await clickEveryMark(tester);
    // `_getOnClickHandler` (`AreaChart.tsx:846-853`) hangs no `onClick` on a
    // circle once the series disagree on their x values.
    expect(hits, isEmpty);
  });

  testWidgets('ScatterChart runs each point onDataPointClick', (tester) async {
    await pump(
      tester,
      FluentScatterChart(
        data: FluentChartData(
          scatterChartData: <FluentScatterChartSeries>[
            FluentScatterChartSeries(
              legend: 's',
              data: <FluentScatterChartDataPoint>[
                FluentScatterChartDataPoint(
                  x: 1,
                  y: 2,
                  onDataPointClick: hit('a'),
                ),
                FluentScatterChartDataPoint(
                  x: 3,
                  y: 8,
                  onDataPointClick: hit('b'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    await clickEveryMark(tester);
    expect(hits, unorderedEquals(<String>['a', 'b']));
  });
}
