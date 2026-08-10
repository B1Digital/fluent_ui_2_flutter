import 'dart:math' as math;

import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:fluent_2_web/src/charts/donut_chart.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/oracle_fixture.dart';

/// DonutChart is the first consumer of `shape_arc.dart`'s padAngle branch with
/// the default `padRadius` of `sqrt(r0^2 + r1^2)`. The path assertions here are
/// deliberately coarse — Oracle A's `d3_golden.json` carries the sampled-point
/// comparison at 1e-6 and `donut_chart_layout_test.dart` carries the Oracle B
/// `d`-string comparison — but they catch a padding that was dropped or applied
/// to the wrong ring.
void main() {
  const key = Key('donut');
  final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  Future<void> pump(
    WidgetTester tester,
    Widget chart, {
    Size box = const Size(300, 300),
    FluentThemeData? withTheme,
  }) => tester.pumpWidget(
    FluentApp(
      theme: withTheme ?? theme,
      home: Center(
        child: SizedBox(width: box.width, height: box.height, child: chart),
      ),
    ),
  );

  FluentChartData dataOf(List<(String, double)> entries) => FluentChartData(
    chartTitle: 'Donut',
    chartData: <FluentChartDataPoint>[
      for (final (legend, value) in entries)
        FluentChartDataPoint(legend: legend, data: value),
    ],
  );

  FluentDonutLayout layoutOf(
    List<(String, double)> entries, {
    double padAngle = 0.02,
  }) => FluentDonutLayout.compute(
    points: dataOf(entries).chartData!,
    order: FluentDonutOrder.byDefault,
    size: const Size(200, 200),
    innerRadius: 30,
    hideLabels: true,
    titleHeight: 0,
    labelMarginHorizontal: 0,
    labelMarginVertical: 0,
    padAngle: padAngle,
    isDark: false,
  );

  /// The plot painter of the chart under [key].
  ///
  /// `.first` is the plot: the title above it is a `Text` and the legend below
  /// it comes later in the tree, so nothing else can precede it.
  FluentDonutChartPainter painterOf(WidgetTester tester) =>
      tester
              .widget<CustomPaint>(
                find
                    .descendant(
                      of: find.byKey(key),
                      matching: find.byType(CustomPaint),
                    )
                    .first,
              )
              .painter!
          as FluentDonutChartPainter;

  test('the padded arc is narrower than its unpadded sweep on both rings', () {
    final padded = fluentDonutArcPaths(
      layoutOf(<(String, double)>[('A', 1), ('B', 1), ('C', 1)]),
      cornerRadius: 0,
    ).first;
    final unpadded = fluentDonutArcPaths(
      layoutOf(<(String, double)>[('A', 1), ('B', 1), ('C', 1)], padAngle: 0),
      cornerRadius: 0,
    ).first;
    expect(
      padded.computeMetrics().first.length,
      lessThan(unpadded.computeMetrics().first.length),
      reason:
          'shape_arc.dart trims each ring by asin(rp / r * sin(ap)) with '
          'rp defaulting to sqrt(r0^2 + r1^2), so a padded arc is strictly '
          'shorter than the same arc with padAngle 0.',
    );
  });

  test('the inner ring is trimmed more than the outer one', () {
    // p0 = asin(rp / r0 * sin(ap)) and p1 = asin(rp / r1 * sin(ap)) with
    // r0 < r1, so the smaller radius takes the larger angular trim — that
    // asymmetry is the whole reason the padding cannot be a simple angular
    // subtraction.
    final layout = layoutOf(<(String, double)>[('A', 1), ('B', 1)]);
    final path = fluentDonutArcPaths(layout, cornerRadius: 0).first;
    final bounds = path.getBounds();
    expect(
      bounds.width,
      lessThanOrEqualTo(2 * layout.outerRadius + 1e-9),
      reason: 'A padded arc can never exceed the outer radius in either axis.',
    );
  });

  test('every arc path is shifted onto the plot centre', () {
    final layout = layoutOf(<(String, double)>[('A', 1), ('B', 1)]);
    // A 200x400 box with a 200-pixel title reserves exactly the same
    // min(200, 200) / 2 outer radius, so the two layouts differ only in where
    // DonutChart.tsx:335 leaves the centre — by (0, 100).
    final lower = FluentDonutLayout.compute(
      points: dataOf(<(String, double)>[('A', 1), ('B', 1)]).chartData!,
      order: FluentDonutOrder.byDefault,
      size: const Size(200, 400),
      innerRadius: 30,
      hideLabels: true,
      titleHeight: 200,
      labelMarginHorizontal: 0,
      labelMarginVertical: 0,
      padAngle: 0.02,
      isDark: false,
    );
    expect(
      lower.outerRadius,
      layout.outerRadius,
      reason: 'The two layouts must differ only in the centre.',
    );
    expect(
      fluentDonutArcPaths(lower, cornerRadius: 0).first.getBounds().center -
          fluentDonutArcPaths(layout, cornerRadius: 0).first.getBounds().center,
      // 1e-4 because `Path.getBounds` rounds through Skia's 32-bit floats: the
      // two bounds differ by 7.6e-6 at these radii, which is a float32 ulp near
      // 100 and not a geometric difference.
      offsetMoreOrLessEquals(lower.centre - layout.centre, epsilon: 1e-4),
      reason:
          'Pie.tsx:99 translates the whole group by (width / 2, height / 2), '
          'so the arc geometry is centre-relative and the shift is the only '
          'thing that moves it.',
    );
  });

  test('an arc under fifteen degrees gets no label', () {
    // Ninety-nine parts against one leaves the small arc about 3.6 degrees.
    final layout = FluentDonutLayout.compute(
      points: dataOf(<(String, double)>[('big', 99), ('small', 1)]).chartData!,
      order: FluentDonutOrder.byDefault,
      size: const Size(200, 200),
      innerRadius: 0,
      hideLabels: false,
      titleHeight: 0,
      labelMarginHorizontal: 80,
      labelMarginVertical: 40,
      padAngle: 0.02,
      isDark: false,
    );
    final sweep = layout.slices[1].endAngle - layout.slices[1].startAngle;
    expect(
      sweep,
      lessThan(math.pi / 12),
      reason: 'Arc.tsx:71 skips a label whose absolute sweep is under PI/12.',
    );
  });

  testWidgets('every arc is painted and each carries an option label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      FluentDonutChart(
        key: key,
        data: dataOf(<(String, double)>[('A', 3), ('B', 1), ('C', 1)]),
      ),
    );
    expect(
      painterOf(tester).arcPaths,
      hasLength(3),
      reason: 'Pie.tsx:105 emits one Arc per slice of the layout.',
    );
    expect(
      find.bySemanticsLabel('A, 3.'),
      findsOneWidget,
      reason:
          'Arc.tsx:53-58 — "\${legend}, " then "\${yValue}." where yValue '
          'falls back to the datum value.',
    );
    handle.dispose();
  });

  testWidgets('selecting a legend dims the other arcs to a tenth', (
    tester,
  ) async {
    await pump(
      tester,
      FluentDonutChart(
        key: key,
        data: dataOf(<(String, double)>[('A', 3), ('B', 1), ('C', 1)]),
      ),
    );
    await tester.tap(find.text('A'));
    await tester.pump();
    expect(
      painterOf(tester).opacities,
      <double>[1.0, 0.1, 0.1],
      reason:
          'Arc.tsx:112-113 — activeArc.includes(legend) ? 1 : 0.1, driven '
          'by the multi-select predicate at DonutChart.tsx:237-239.',
    );
  });

  testWidgets('the centre value appears only above the minimum inner radius', (
    tester,
  ) async {
    await pump(
      tester,
      FluentDonutChart(
        key: key,
        innerRadius: 1,
        valueInsideDonut: 'Total',
        data: dataOf(<(String, double)>[('A', 1)]),
      ),
    );
    expect(
      find.text('Total'),
      findsNothing,
      reason:
          'DonutChart.tsx:337-338 requires innerRadius > MIN_DONUT_RADIUS, '
          'and MIN_DONUT_RADIUS is 1 (utilities.ts:90), so exactly 1 is '
          'excluded.',
    );
    await pump(
      tester,
      FluentDonutChart(
        key: key,
        innerRadius: 40,
        valueInsideDonut: 'Total',
        data: dataOf(<(String, double)>[('A', 1)]),
      ),
    );
    expect(
      find.text('Total'),
      findsOneWidget,
      reason: 'An inner radius above 1 shows it.',
    );
  });

  testWidgets('hiding the legend also hides the title', (tester) async {
    await pump(
      tester,
      FluentDonutChart(
        key: key,
        hideLegend: true,
        data: dataOf(<(String, double)>[('A', 1)]),
      ),
    );
    expect(
      find.text('Donut'),
      findsNothing,
      reason:
          'DonutChart.tsx:360 gates the title on '
          '!hideLegend && data.chartTitle — a coupling nothing documents but '
          'the code enforces.',
    );
  });

  testWidgets('a donut with no positive values announces the no-data alert', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      FluentDonutChart(
        key: key,
        data: dataOf(<(String, double)>[('A', 0), ('B', -1)]),
      ),
    );
    expect(
      tester.getSemantics(find.byKey(key)).label,
      'Graph has no data to display',
      reason:
          'DonutChart.tsx:427-429 requires at least one point with '
          'data > 0.',
    );
    handle.dispose();
  });

  testWidgets('a dimmed arc leaves the tab order', (tester) async {
    await pump(
      tester,
      FluentDonutChart(
        key: key,
        data: dataOf(<(String, double)>[('A', 3), ('B', 1), ('C', 1)]),
      ),
    );
    await tester.tap(find.text('A'));
    await tester.pump();
    expect(
      tester
          .widgetList<Focus>(
            find.descendant(of: find.byKey(key), matching: find.byType(Focus)),
          )
          .where(
            (f) =>
                f.debugLabel == kFluentDonutArcFocusLabel && f.canRequestFocus,
          )
          .length,
      1,
      reason:
          'Arc.tsx:148 drops tabIndex from an arc that is neither '
          'highlighted nor part of an unhighlighted chart.',
    );
  });

  testWidgets('percentage labels format with no decimals', (tester) async {
    await pump(
      tester,
      FluentDonutChart(
        key: key,
        hideLabels: false,
        showLabelsInPercent: true,
        data: dataOf(<(String, double)>[('A', 1), ('B', 3)]),
      ),
    );
    expect(
      painterOf(tester).labels.map((label) => label.text).toList(),
      <String>['25%', '75%'],
      reason:
          "Arc.tsx:93 formats with d3Format('.0%'), and the total at "
          'Pie.tsx:52-58 sums ALL points including zeroes.',
    );
  });

  testWidgets('every arc fill flattens to one system colour under high '
      'contrast', (tester) async {
    final highContrast = FluentThemeData.highContrast(
      fontPlatform: FluentFontPlatform.web,
    );
    await pump(
      tester,
      FluentDonutChart(
        key: key,
        data: dataOf(<(String, double)>[('A', 3), ('B', 1), ('C', 1)]),
      ),
      withTheme: highContrast,
    );
    expect(
      painterOf(tester).fills.map((fill) => fill.toARGB32()).toList(),
      List<int>.filled(3, highContrast.colors.neutralForeground1.toARGB32()),
      reason:
          'Spec 5.3 — an upstream arc carries no forced-color-adjust, so a '
          'forced-colours browser rewrites every fill to CanvasText. Without '
          'FluentChartColors.flattenMark the forty-colour palette survives '
          'here and the donut is a single unreadable disc.',
    );
    expect(
      painterOf(tester).layout.legendPoints.map((p) => p.color).toList(),
      everyElement(isNot(highContrast.colors.neutralForeground1)),
      reason:
          'Spec 5.3 — the legend deliberately keeps its palette, so the '
          'flattening must happen on the way to the painter and not inside '
          'the layout.',
    );
  });

  // Oracle B. `charts-donutchart--donut-chart-dynamic` is the only donut story
  // captured with hideLabels off, so it is the only capture that pins the arc
  // label placement — the anchor, the text anchor and the dominant baseline of
  // all four labels at once. `donut_chart_layout_test.dart` already pins the
  // arc `d` strings and the radii from the same fixture; this asserts the layer
  // above them, through the widget rather than a helper.
  group('Oracle B', () {
    testWidgets('charts-donutchart--donut-chart-dynamic places every arc '
        'label', (tester) async {
      final story = loadOracleStory('charts-donutchart--donut-chart-dynamic');
      final labels = story
          .byTag('text')
          .where((element) => element.parent >= 0 && element.x != null)
          .toList(growable: false);
      expect(
        labels,
        hasLength(4),
        reason:
            'One label per slice. A filtered loop without a count guard '
            'asserts nothing when the filter goes empty.',
      );

      await pump(
        tester,
        const FluentDonutChart(
          key: key,
          width: 944,
          height: 248,
          innerRadius: 35,
          hideLabels: false,
          data: FluentChartData(
            chartTitle: 'Donut chart dynamic example',
            chartData: <FluentChartDataPoint>[
              FluentChartDataPoint(legend: 'first', data: 40),
              FluentChartDataPoint(legend: 'second', data: 20),
              FluentChartDataPoint(legend: 'third', data: 30),
              FluentChartDataPoint(legend: 'fourth', data: 10),
            ],
          ),
        ),
        box: const Size(1000, 600),
      );

      final painter = painterOf(tester);
      expect(
        painter.labels,
        hasLength(4),
        reason:
            'Every sweep here clears the PI/12 gate and nothing is dimmed, '
            'so Arc.tsx:69-75 suppresses none of them.',
      );
      // Pie.tsx:99 — the capture's coordinates are relative to the group's
      // translate, which is the layout centre.
      final centre = painter.layout.centre;
      for (var i = 0; i < labels.length; i++) {
        expectOracleOffset(
          'dynamic donut label ${i + 1} anchor (Arc.tsx:85-86)',
          Offset(labels[i].x!, labels[i].y!) + centre,
          painter.labels[i].anchor,
        );
        expect(
          painter.labels[i].align,
          labels[i].textAnchor == 'end' ? TextAlign.end : TextAlign.start,
          reason:
              'Arc.tsx:87 — `angle > PI !== _isRTL ? end : start`, captured '
              'as textAnchor="${labels[i].textAnchor}" on label ${i + 1}.',
        );
        expect(
          painter.labels[i].baseline,
          labels[i].dominantBaseline == 'hanging'
              ? FluentChartTitleBaseline.hanging
              : FluentChartTitleBaseline.alphabetic,
          reason:
              'Arc.tsx:88 — hanging between PI/2 and 3*PI/2 and `auto` — the '
              'alphabetic baseline — otherwise, captured as '
              'dominantBaseline="${labels[i].dominantBaseline}" on label '
              '${i + 1}.',
        );
        expect(
          painter.labels[i].text,
          labels[i].text,
          reason:
              'Arc.tsx:94 formats the arc value with '
              'formatScientificLimitWidth.',
        );
      }
    });
  });
}
